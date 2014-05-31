create or replace function watershed_floodfill (columnx integer, rowy integer, a double precision, i raster, dam_id integer) 
returns void as $$

DECLARE

    alt_at_point double precision;
    dam_at_point double precision;
    io raster;
    w integer;
    h integer;
    -- p geometry;

BEGIN

    -- raise notice '%,% <-- this point is next', columnx, rowy;

    select scratch into io from dams where id = dam_id;

    w := st_width(io);
    h := st_height(io);

    if columnx < 0 then
        -- raise notice 'columnx: %', columnx;
    end if;

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

    if alt_at_point < a then

      -- raise notice '%,% <-- this point is lower than previous point', columnx, rowy;

        return;

    end if;

  -- raise notice '%,% <-- filling this point', columnx, rowy;

    io := st_setvalue(io, 1, columnx, rowy, 1);

    update dams set scratch = io where id = dam_id;

    -- raise notice 'out: %', st_asgeojson( st_setsrid(ST_Polygon(io), 4326) );

    perform watershed_floodfill(columnx+1, rowy, alt_at_point, i, dam_id);      -- E
    perform watershed_floodfill(columnx+1, rowy+1, alt_at_point, i, dam_id);    -- SE
    perform watershed_floodfill(columnx-1, rowy, alt_at_point, i, dam_id);      -- W
    perform watershed_floodfill(columnx-1, rowy+1, alt_at_point, i, dam_id);    -- SW
    perform watershed_floodfill(columnx, rowy+1, alt_at_point, i, dam_id);      -- S
    perform watershed_floodfill(columnx, rowy-1, alt_at_point, i, dam_id);      -- N
    perform watershed_floodfill(columnx-1, rowy-1, alt_at_point, i, dam_id);      -- NW
    perform watershed_floodfill(columnx+1, rowy-1, alt_at_point, i, dam_id);      -- NE

    -- TODO other 4 points?

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_watershed (dam_id integer)
RETURNS geometry AS $$

DECLARE
    watershed_geom geometry;
    altitude double precision;

    columnx integer;
    rowy integer;

    study_area_rast raster;
    study_area_id integer;
    watershed_rast raster;
    dam_crest geometry;
    dam_crest_midpoint geometry;
    dam_crest_interpolate_point geometry;
BEGIN
    select study_area into study_area_id from dams where id = dam_id;

    select crest into dam_crest from dams where id = dam_id;
    select st_line_interpolate_point(dam_crest, 0.5) into dam_crest_midpoint;

  -- raise notice 'midpoint: %', ST_asgeojson(dam_crest_midpoint);

  -- raise notice 'altitude at midpoint: %', altitude;

    select ST_Clip(rast, 1, ST_Expand(dam_crest_midpoint, 0.003), true) into study_area_rast from areas where rid = study_area_id;

    -- create an empty raster, same size as study area
    -- select rast into study_area_rast from areas where rid = study_area_id;

    watershed_rast := ST_MakeEmptyRaster(
        st_width(study_area_rast),
        st_height(study_area_rast),
        st_upperleftx(study_area_rast),
        st_upperlefty(study_area_rast),
        st_pixelwidth(study_area_rast));

    watershed_rast := ST_AddBand(watershed_rast,'2BUI'::text, 0);
    watershed_rast := ST_SetBandNoDataValue(watershed_rast, 0);

    -- perform flood fill here

    -- raise notice 'fill_point: %', st_asgeojson(fill_point);


    -- raise notice 'fill_point columnx: %', columnx;
    -- raise notice 'fill_point rowy: %', rowy;

    update dams set scratch = watershed_rast where id = dam_id;


    FOR i IN 1..3 LOOP
        select st_line_interpolate_point(dam_crest, (i/3.0)) into dam_crest_interpolate_point;

        columnx := ST_WorldToRasterCoordX(study_area_rast, dam_crest_interpolate_point);
        rowy := ST_WorldToRasterCoordY(study_area_rast, dam_crest_interpolate_point);
        select st_value(rast, dam_crest_midpoint) into altitude from areas where rid = study_area_id;

        perform watershed_floodfill(
            columnx,
            rowy,
            altitude,
            study_area_rast,
            dam_id);

    END LOOP;



    select scratch into watershed_rast from dams where id = dam_id;

    watershed_geom := st_setsrid(ST_Polygon(watershed_rast), 4326);

    -- raise notice 'lake_geom: %', st_asgeojson(lake_geom);

    update dams set watershed = watershed_geom where id = dam_id;

    update dams set watershed = ST_Multi(st_union(watershed, lake2)) where id = dam_id;

  -- raise notice 'finished';

    select watershed into watershed_geom from dams where id = dam_id;

    return watershed_geom;

END;
$$ LANGUAGE plpgsql;

select st_asgeojson(create_watershed(1));


-- CREATE OR REPLACE FUNCTION sample_callbackfunc(value double precision[][][], pos integer[][], VARIADIC userargs text[])
	-- RETURNS double precision
	-- AS $$
	-- BEGIN
        -- raise notice '%, %: %', pos[0][1], pos[0][2], value;
        -- raise notice 'userargs: %', userargs;
		-- RETURN 0;
	-- END;
	-- $$ LANGUAGE 'plpgsql' IMMUTABLE;

-- select st_mapalgebra(
    -- rast,
    -- 1,
    -- 'sample_callbackfunc(double precision[], int[], text[])'::regprocedure,
    -- NULL,
    -- 'FIRST',
    -- NULL,
    -- 0,
    -- 0,
    -- '1')
    -- from dams where id = 1;

