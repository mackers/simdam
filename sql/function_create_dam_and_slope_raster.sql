CREATE OR REPLACE FUNCTION fill_dam_slope (
    columnx integer,
    rowy integer,
    dam_height double precision,
    upstream boolean,
    i raster,
    dam_id integer)
RETURNS void AS $$
DECLARE
    io raster;
    alt_at_point double precision;
    alt_at_crest double precision;
    a double precision; -- desired altitude of dam slope at this point
    dam_crest geometry;
    w integer;
    h integer;
    distance_from_dam double precision;
BEGIN

    select scratch into io from dams where id = dam_id;

    w := st_width(io);
    h := st_height(io);

    if columnx < 0 or rowy < 0 or columnx > w or rowy > h then
        return;
    end if;

    alt_at_point := st_value(io, 1, columnx, rowy);

    if alt_at_point is not null then
        -- raise notice '%,% <-- this point is filled', columnx, rowy;
        return;
    end if;

    alt_at_point := st_value(i, 1, columnx, rowy);
    select st_value(areas.rast, ST_PointN(dams.crest, 1)) into alt_at_crest from areas left join dams on areas.rid = dams.study_area where rid = study_area_id;
    select crest into dam_crest from dams where id = dam_id;

    distance_from_dam := st_distance(
        ST_RasterToWorldCoord(io, columnx, rowy),
        crest);

    raise notice '%,% <-- distance from dam crest: %', columnx, rowy, distance_from_dam;

    if upstream then
        -- assume a 1:2 ratio for now
        a := alt_at_crest - (distance_from_dam / 2);
    else
        -- assume a 1:3 ratio for now
        a := alt_at_crest - (distance_from_dam / 3);
    end if;

    -- raise notice '%,% <-- point has altitude of: %', columnx, rowy, alt_at_point;

    if alt_at_point > a - 1 then
        -- raise notice '%,% <-- this point is too damn high', columnx, rowy;
        return;
    end if;

    io := st_setvalue(io, 1, columnx, rowy, a);
    update dams set scratch = io where id = dam_id;

    perform fill_dam_slope(columnx-1, rowy, dam_height, upstream, i, dam_id);
    perform fill_dam_slope(columnx+1, rowy, dam_height, upstream, i, dam_id);
    perform fill_dam_slope(columnx, rowy-1, dam_height, upstream, i, dam_id);
    perform fill_dam_slope(columnx, rowy+1, dam_height, upstream, i, dam_id);

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION create_dam_and_slope_raster (dam_id integer)
RETURNS void AS $$

DECLARE

    dam_height double precision;
    area_and_dam_rast raster;
    upstream_fill_point geometry;
    downstream_fill_point geometry;
    upstream_rast raster;
    downstream_rast raster;

BEGIN

    -- get altitude of crest
    -- get grid unit
    -- get height of dam
    dam_height := dam_height(1);

    -- create composite raster
    area_and_dam_rast := create_composite_raster(dam_id);

    -- get upstream ref_point
    upstream_fill_point := get_upstream_fill_point(dam_id);

    -- make empty upstream slope raster & put into scratch
    upstream_rast := ST_MakeEmptyRaster(
        st_width(area_and_dam_rast),
        st_height(area_and_dam_rast),
        st_upperleftx(area_and_dam_rast),
        st_upperlefty(area_and_dam_rast),
        st_pixelwidth(area_and_dam_rast));
    upstream_rast := ST_AddBand(upstream_rast,'2BUI'::text, 0);
    upstream_rast := ST_SetBandNoDataValue(upstream_rast, 0);

    update dams set scratch = lake_rast where id = dam_id;

    -- perform slope_fill(x, y, area_and_dam_raster, dam_id);
    perform fill_dam_slope(
        ST_WorldToRasterCoordX(area_and_dam_rast, upstream_fill_point),
        ST_WorldToRasterCoordY(area_and_dam_rast, upstream_fill_point),
        dam_height,
        true,
        area_and_dam_rast,
        dam_id);

    -- scratch now has upstream dam raster

    -- get downstream ref_point
    -- downstream_fill_point := get_downstream_fill_point(dam_id);

    -- combine upstream, downstream and crest raster to get dam_and_slope
    -- raster

END;
$$ LANGUAGE plpgsql;

select create_dam_and_slope_raster(1);

