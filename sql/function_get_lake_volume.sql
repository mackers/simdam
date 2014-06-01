create or replace function get_lake_volume (dam_id integer)
returns double precision as $$

DECLARE

    study_area_rast raster;
    lake_rast raster;
    alt_at_crest double precision;
    lake_alt double precision;

BEGIN

    select areas.rast into study_area_rast from areas left join dams on areas.rid = dams.study_area where dams.id = dam_id;

    select st_value(areas.rast, ST_PointN(dams.crest, 1)) into alt_at_crest from areas left join dams on areas.rid = dams.study_area where dams.id = dam_id;

    lake_alt := alt_at_crest - 1;

    raise notice 'lake alt: %', lake_alt;

    -- create lake raster

    select st_asraster(lake2, study_area_rast, '32BF', lake_alt) into lake_rast from dams where dams.id = dam_id;

    update dams set scratch = lake_rast where dams.id = dam_id;

    return 0.0;

END;
$$ LANGUAGE plpgsql;


select get_lake_volume(1);
