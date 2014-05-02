create or replace function lake_floodfill (columnx integer, rowy integer, a double precision, i raster, dam_id integer) 
returns void as $$

DECLARE

    alt_at_point double precision;
    dam_at_point double precision;
    io raster;
    w integer;
    h integer;
    -- p geometry;

BEGIN

    -- raise notice 'in lake_floodfill, altitude: %', a;
    -- raise notice '%,% <-- this point is next', columnx, rowy;

    select scratch into io from dams where id = dam_id;

    w := st_width(io);
    h := st_height(io);

    if columnx < 0 or rowy < 0 or columnx > w or rowy > h then
        return;
    end if;

    alt_at_point := st_value(io, 1, columnx, rowy);

    if alt_at_point = 1 then
        -- raise notice '%,% <-- this point is filled', columnx, rowy;
        return;
    end if;

    alt_at_point := st_value(i, 1, columnx, rowy);

    -- raise notice '%,% <-- point has altitude of: %', columnx, rowy, alt_at_point;

    if alt_at_point is null then
        return;
    end if;

    if alt_at_point > a then

        -- raise notice '%,% <-- this point is too damn high', columnx, rowy;

        return;

    end if;

    -- raise notice '%,% <-- filling this point', columnx, rowy;

    io := st_setvalue(io, 1, columnx, rowy, 1);

    update dams set scratch = io where id = dam_id;

    -- raise notice 'out: %', st_asgeojson( st_setsrid(ST_Polygon(io), 4269) );

    perform lake_floodfill(columnx+1, rowy, a, i, dam_id);
    perform lake_floodfill(columnx-1, rowy, a, i, dam_id);
    perform lake_floodfill(columnx, rowy+1, a, i, dam_id);
    perform lake_floodfill(columnx, rowy-1, a, i, dam_id);

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_composite_raster (dam_id integer)
RETURNS raster AS $$

DECLARE
    ret_rast raster;
    ref_point geometry;
    study_area_id integer;
BEGIN
    select study_area into study_area_id from dams where id = dam_id;

    create temporary table rasters (rast raster);
    insert into rasters select rast from areas where rid = study_area_id;
    insert into rasters select rast from dams where id = dam_id;

    select ST_Union(rast, 'MAX'::text) into ret_rast from rasters;
    select ST_line_interpolate_point(crest, 0.5) INTO ref_point from dams where id = dam_id;

    discard temp;

    return ST_Clip(ret_rast, 1, ST_Expand(ref_point, 0.001), true);

    --return ret_rast;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION create_lake (dam_id integer)
RETURNS geometry AS $$

DECLARE
    lake_geom geometry;
    dam_crest geometry;
    start_point geometry;
    end_point geometry;
    altitude double precision;

    dam_crest_midpoint geometry;
    dam_crest_90 geometry;
    point_90_45 geometry;
    point_90_55 geometry;
    altitude_90_55 double precision;
    altitude_90_45 double precision;
    fill_point geometry;
    columnx integer;
    rowy integer;

    study_area_rast raster;
    study_area_id integer;
    lake_rast raster;
    area_and_dam_rast raster;
    dam_raster raster;
BEGIN

    -- extend crest here
    
    select crest into dam_crest from dams where id = dam_id;

    raise notice 'crest before scale: %', st_asgeojson(dam_crest);
    dam_crest := ST_Scale(dam_crest, 1.00001, 1.00001);
    raise notice 'crest after scale: %', st_asgeojson(dam_crest);

    select create_dam_raster(dam_id) into dam_raster;
    update dams set rast = dam_raster where id = dam_id;

    -- first point in dam_crest
    start_point := ST_PointN(dam_crest, 1);
    end_point := ST_PointN(dam_crest, 2);

    -- -- get middle point of dam_crest
    SELECT ST_line_interpolate_point(dam_crest, 0.5) INTO dam_crest_midpoint;

    -- -- 90deg line
    SELECT
        ST_Rotate(
            dam_crest,
            pi()/2,
            dam_crest_midpoint)
        INTO dam_crest_90;

    -- -- 90deg point
    -- RAISE NOTICE 'dam_crest: %', ST_AsText(dam_crest);
    -- RAISE NOTICE 'dam_crest_90: %', ST_AsText(dam_crest_90);

    -- RAISE NOTICE 'midpoint: %', ST_AsText(ST_line_interpolate_point(dam_crest, 0.5));
    -- RAISE NOTICE 'midpoint_90_55: %', ST_AsText(ST_line_interpolate_point(dam_crest_90, 0.55));
    -- RAISE NOTICE 'midpoint_90_45: %', ST_AsText(ST_line_interpolate_point(dam_crest_90, 0.45));

    SELECT ST_line_interpolate_point(dam_crest_90, 0.55) INTO point_90_55;
    SELECT ST_line_interpolate_point(dam_crest_90, 0.45) INTO point_90_45;

    select study_area into study_area_id from dams where id = dam_id;

    SELECT ST_Value(rast, point_90_55) INTO altitude_90_55 FROM areas where rid = study_area_id;
    SELECT ST_Value(rast, point_90_45) INTO altitude_90_45 FROM areas where rid = study_area_id;

    select st_value(rast, start_point) into altitude from areas where rid = study_area_id;

    if altitude_90_55 > altitude_90_45 then
        fill_point := point_90_55;
    else
        fill_point := point_90_45;
    end if;

    -- raise notice 'dam_crest_midpoint: %', st_asgeojson(dam_crest_midpoint);
    raise notice 'dam_crest: %', st_asgeojson(dam_crest);
    raise notice 'fill_point: %', st_asgeojson(fill_point);

    -- create a raster of study area + dam
    area_and_dam_rast := create_composite_raster(dam_id);

    -- create an empty raster, same size as study area
    select rast into study_area_rast from areas where rid = study_area_id;

    lake_rast := ST_MakeEmptyRaster(
        st_width(area_and_dam_rast),
        st_height(area_and_dam_rast),
        st_upperleftx(area_and_dam_rast),
        st_upperlefty(area_and_dam_rast),
        st_pixelwidth(area_and_dam_rast));

    lake_rast := ST_AddBand(lake_rast,'2BUI'::text, 0);
    lake_rast := ST_SetBandNoDataValue(lake_rast, 0);

    -- perform flood fill here

    -- raise notice 'fill_point: %', st_asgeojson(fill_point);

    columnx := ST_WorldToRasterCoordX(area_and_dam_rast, fill_point);
    rowy := ST_WorldToRasterCoordY(area_and_dam_rast, fill_point);

    -- raise notice 'fill_point columnx: %', columnx;
    -- raise notice 'fill_point rowy: %', rowy;

    update dams set scratch = lake_rast where id = dam_id;

    perform lake_floodfill(
        columnx,
        rowy,
        altitude,
        area_and_dam_rast,
        dam_id);

    select scratch into lake_rast from dams where id = dam_id;

    lake_geom := st_setsrid(ST_Polygon(lake_rast), 4269);

    -- raise notice 'lake_geom: %', st_asgeojson(lake_geom);

    update dams set lake2 = lake_geom where id = dam_id;

    -- raise notice 'finished';

    return lake_geom;

END;
$$ LANGUAGE plpgsql;

-- UPDATE dams set lake2 = create_lake(1, 'napa') where id = 1;

select st_asgeojson(create_lake(28));

