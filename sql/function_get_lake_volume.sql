create or replace function get_lake_volume (dam_id integer)
returns double precision as $$

DECLARE

    study_area_rast raster;
    lake_rast raster;
    alt_at_crest double precision;
    lake_alt double precision;
    pix_m_x double precision;
    pix_m_y double precision;
    lake_vol double precision;
    w integer;
    h integer;

BEGIN

    select st_clip(areas.rast, dams.lake2, true) into study_area_rast from areas left join dams on areas.rid = dams.study_area where dams.id = dam_id;

    select st_value(areas.rast, ST_PointN(dams.crest, 1)) into alt_at_crest from areas left join dams on areas.rid = dams.study_area where dams.id = dam_id;

    lake_alt := alt_at_crest - 1;

    -- raise notice 'lake alt: %', lake_alt;

    -- create lake raster

    select st_asraster(lake2, study_area_rast, '32BF', lake_alt) into lake_rast from dams where dams.id = dam_id;

    -- get pixel size in meters

    pix_m_x := st_distance(
        ST_PixelAsPoint(lake_rast, 0, 0)::geography,
        ST_PixelAsPoint(lake_rast, 1, 0)::geography
    );
 
    pix_m_y := st_distance(
        ST_PixelAsPoint(lake_rast, 0, 0)::geography,
        ST_PixelAsPoint(lake_rast, 0, 1)::geography
    );
    
    -- raise notice 'pixel size in metres: %', pix_m_y;
    -- raise notice 'pixel size in metres: %', pix_m_x;

    -- preform map algebra on lake_rast and study_area_rast.

    update dams set scratch = 
        st_mapalgebra(
            lake_rast, 1,
            study_area_rast, 1,
            '[rast1.val] - [rast2.val]'
            )
        where dams.id = dam_id;

    -- now we have a lake height raster in scratch
    -- put everything in a series and do the calc

    select st_width(scratch) into w from dams where dam_id = id;
    select st_height(scratch) into h from dams where dam_id = id;
    
    select sum(ST_Value(scratch, hor.n, ver.n)) as cell_h
        into lake_vol
        FROM
            generate_series(1,w) as hor(n),
            generate_series(1,h) as ver(n),
            dams
        WHERE dams.id = dam_id
        AND st_value(scratch, hor.n, ver.n) is not null;

    return lake_vol * pix_m_y * pix_m_x;

END;
$$ LANGUAGE plpgsql;


select get_lake_volume(1);
