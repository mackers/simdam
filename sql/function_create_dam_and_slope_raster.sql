CREATE OR REPLACE FUNCTION fill_dam_slope (
    columnx integer,
    rowy integer,
    dam_height double precision,
    alt_at_crest double precision,
    upstream boolean,
    mask raster,
    study raster,
    dam_id integer)
RETURNS void AS $$
DECLARE
    io raster;
    mask raster;
    alt_at_point double precision;
    mask_at_point double precision;
    a double precision; -- desired altitude of dam slope at this point
    dam_crest geometry;
    w integer;
    h integer;
    distance_from_dam double precision;
BEGIN

    select scratch into mask from dams where id = dam_id;
    select rast into io from dams where id = dam_id;

    w := st_width(io);
    h := st_height(io);

    -- raise notice 'w: %', w;
    -- raise notice 'colummx: %', columnx;

    if columnx < 0 or rowy < 0 or columnx > w or rowy > h then
        -- raise notice '%,% <-- this point out of range', columnx, rowy;
        return;
    end if;

    -- alt_at_point := st_value(io, 1, columnx, rowy);
    mask_at_point := st_value(mask, 1, columnx, rowy);

    if mask_at_point is not null then
        -- raise notice '%,% <-- this point is masked', columnx, rowy;
        return;
    end if;

    alt_at_point := st_value(study, 1, columnx, rowy);
    -- select st_value(areas.rast, ST_PointN(dams.crest, 1)) into alt_at_crest from areas left join dams on areas.rid = dams.study_area where dams.id = dam_id;
    select crest into dam_crest from dams where id = dam_id;

    if alt_at_point > alt_at_crest - 1 then
        -- raise notice '%,% <-- this point is too damn high', columnx, rowy;
        return;
    end if;

    distance_from_dam := st_distance_Sphere(
        st_setsrid(
            st_makepoint(
                ST_RasterToWorldCoordx(io, columnx, rowy),
                ST_RasterToWorldCoordy(io, columnx, rowy)),
            4326),
        dam_crest);

    -- raise notice '%,% <-- spherical distance from dam crest: %', columnx, rowy, distance_from_dam;

    if upstream then
        -- assume a 1:2 ratio for now
        a := alt_at_crest - (distance_from_dam / 2);
    else
        -- assume a 1:3 ratio for now
        a := alt_at_crest - (distance_from_dam / 3);
    end if;

    -- raise notice '%,% <-- point has altitude of: %', columnx, rowy, alt_at_point;
    -- raise notice '%,% <-- point set altitude of: %', columnx, rowy, a;

    if a < alt_at_point then
        -- raise notice '%,% <-- this point is higher than slope would be', columnx, rowy;
        mask := st_setvalue(mask, 1, columnx, rowy, 1);
        update dams set scratch = mask where id = dam_id;
        return;
    else 
        io := st_setvalue(io, 1, columnx, rowy, a);
        update dams set rast = io where id = dam_id;
        mask := st_setvalue(mask, 1, columnx, rowy, 1);
        update dams set scratch = mask where id = dam_id;
    end if;

    perform fill_dam_slope(columnx-1, rowy, dam_height, alt_at_crest, upstream, mask, study, dam_id);
    perform fill_dam_slope(columnx+1, rowy, dam_height, alt_at_crest, upstream, mask, study, dam_id);
    perform fill_dam_slope(columnx, rowy-1, dam_height, alt_at_crest, upstream, mask, study, dam_id);
    perform fill_dam_slope(columnx, rowy+1, dam_height, alt_at_crest, upstream, mask, study, dam_id);

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION create_dam_and_slope_raster (dam_id integer)
RETURNS void AS $$

DECLARE

    dam_height double precision;
    alt_at_crest double precision;
    area_and_dam_rast raster;
    upstream_fill_point geometry;
    downstream_fill_point geometry;
    upstream_rast raster;
    downstream_rast raster;
    crest_rast raster;
    mask raster;
    ret_rast raster;

BEGIN

    -- get altitude of crest
    -- get grid unit
    -- get height of dam
    dam_height := dam_height(1);

    select st_value(areas.rast, ST_PointN(dams.crest, 1)) into alt_at_crest from areas left join dams on areas.rid = dams.study_area where dams.id = dam_id;

    -- create composite raster
    perform create_dam_crest_raster(dam_id);
    area_and_dam_rast := create_composite_raster(dam_id);

    raise notice 'width of composite: %', st_width(area_and_dam_rast);
    raise notice 'scale of composite: %', st_scalex(area_and_dam_rast);

    -- get upstream ref_point
    upstream_fill_point := get_upstream_fill_point(dam_id);
    raise notice 'upstream_fill_point: %', st_asgeojson(upstream_fill_point);
    downstream_fill_point := get_downstream_fill_point(dam_id);
    raise notice 'downstream_fill_point: %', st_asgeojson(downstream_fill_point);

    -- make empty upstream slope raster & put into scratch
    -- mask := ST_MakeEmptyRaster(
        -- st_width(area_and_dam_rast),
        -- st_height(area_and_dam_rast),
        -- st_upperleftx(area_and_dam_rast),
        -- st_upperlefty(area_and_dam_rast),
        -- st_pixelwidth(area_and_dam_rast));
    mask := ST_MakeEmptyRaster(area_and_dam_rast);

    mask := ST_AddBand(mask,'32BF'::text, 0);
    mask := ST_SetBandNoDataValue(mask, 0);
    mask := ST_SetSrid(mask, 4326);

    update dams set scratch = mask where id = dam_id;

    -- make empty upstream slope raster & put into scratch
    -- upstream_rast := ST_MakeEmptyRaster(
        -- st_width(area_and_dam_rast),
        -- st_height(area_and_dam_rast),
        -- st_upperleftx(area_and_dam_rast),
        -- st_upperlefty(area_and_dam_rast),
        -- st_pixelwidth(area_and_dam_rast));
    -- upstream_rast := ST_AddBand(upstream_rast,'32BF'::text, 0);
    -- upstream_rast := ST_SetBandNoDataValue(upstream_rast, 0);

    -- update dams set scratch2 = upstream_rast where id = dam_id;

    raise notice 'width of mask: %', st_width(mask);
    raise notice 'scale of mask: %', st_scalex(mask);
    -- update dams set rast = ST_AsRaster(
        -- crest, 
        -- mask,
        -- '32BF',
        -- alt_at_crest,
        -- 0) where id = dam_id;

    update dams set rast = mask where id = dam_id;
    -- perform create_dam_crest_raster(dam_id, mask);

    raise notice 'width of rast: %', (select st_width(rast) from dams where id = dam_id);
    raise notice 'scale of rast: %', (select st_scalex(rast) from dams where id = dam_id);

    -- perform slope_fill(x, y, area_and_dam_raster, dam_id);
    perform fill_dam_slope(
        ST_WorldToRasterCoordX(area_and_dam_rast, upstream_fill_point),
        ST_WorldToRasterCoordY(area_and_dam_rast, upstream_fill_point),
        dam_height,
        alt_at_crest,
        true,
        mask,
        area_and_dam_rast,
        dam_id);

    raise notice 'finished upstream rastrer';

    -- -- scratch2 now has upstream dam raster
    -- select scratch2 into upstream_rast from dams where id = dam_id;

    -- -- make empty upstream slope raster & put into scratch
    -- mask := ST_MakeEmptyRaster(
        -- st_width(area_and_dam_rast),
        -- st_height(area_and_dam_rast),
        -- st_upperleftx(area_and_dam_rast),
        -- st_upperlefty(area_and_dam_rast),
        -- st_pixelwidth(area_and_dam_rast));
    -- mask := ST_AddBand(mask,'2BUI'::text, 0);
    -- mask := ST_SetBandNoDataValue(mask, 0);

    -- get downstream ref_point

    -- make empty downstream slope raster & put into scratch
    -- downstream_rast := ST_MakeEmptyRaster(
        -- st_width(area_and_dam_rast),
        -- st_height(area_and_dam_rast),
        -- st_upperleftx(area_and_dam_rast),
        -- st_upperlefty(area_and_dam_rast),
        -- st_pixelwidth(area_and_dam_rast));
    -- downstream_rast := ST_AddBand(downstream_rast,'32BF'::text, 0);
    -- downstream_rast := ST_SetBandNoDataValue(downstream_rast, 0);

    -- update dams set scratch2 = downstream_rast where id = dam_id;
    -- update dams set scratch = mask where id = dam_id;

    perform fill_dam_slope(
        ST_WorldToRasterCoordX(area_and_dam_rast, downstream_fill_point),
        ST_WorldToRasterCoordY(area_and_dam_rast, downstream_fill_point),
        dam_height,
        alt_at_crest,
        false,
        mask,
        area_and_dam_rast,
        dam_id);

    raise notice 'finished downstream rastrer';

    -- select scratch2 into downstream_rast from dams where id = dam_id;

    -- combine upstream, downstream and crest raster to get dam_and_slope
    -- raster

    -- raise notice 'arg1:%', (select ST_MetaData(upstream_rast);
    -- select ST_MetaData(rast) from dams where id = dam_id;

    create temporary table rasters (rast raster);

    insert into rasters
        select rast from dams where id = dam_id;

    insert into rasters
        select st_asraster(
            (select crest from dams where id = dam_id),
            (select rast from dams where id = dam_id),
            '32BF',
            alt_at_crest,
            0);

    select ST_Union(rast, 'MAX'::text) into ret_rast from rasters;
    discard temp;

    update dams set rast = ret_rast where id = dam_id;

    raise notice 'finished';

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION dam_as_png (dam_id integer)
RETURNS table (dam text, upperleft text, lowerright text) AS $$

DECLARE
    h integer;
    w integer;
BEGIN

    perform create_dam_and_slope_raster(dam_id);

    select st_width(rast) into w from dams where id = dam_id;
    select st_height(rast) into h from dams where id = dam_id;


    update dams set scratch = st_colormap(
        rast,
        1,
        'pseudocolor'
    ) where id = dam_id;

    return query (
        select
            'data:image/png;base64,' ||
            encode(
                st_aspng(
                    st_colormap(
                        st_resize(
                            rast,
                            500,
                            500
                        ),
                        1,
                        'pseudocolor',
                        'EXACT'
                    ),
                    ARRAY['ZLEVEL=1']
                    ),
                'base64'
                ),
            st_asgeojson(
                ST_SetSRID(
                    ST_MakePoint(
                        ST_RasterToWorldCoordX(rast, 0, 0),
                        ST_RasterToWorldCoordY(rast, 0, 0)
                    ),
                    4326
                )
            ),
            st_asgeojson(ST_SetSRID(
                    ST_MakePoint(
                        ST_RasterToWorldCoordX(rast, w, h),
                        ST_RasterToWorldCoordY(rast, w, h)
                    ),
                    4326
                )
            )
            from dams
            where id = dam_id
        );

END;
$$ LANGUAGE plpgsql;


-- select create_dam_and_slope_raster(1);
-- select dam_as_png(1);



