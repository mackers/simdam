create or replace function create_dam_height_raster (dam_id integer)
returns void as $$

DECLARE

    dam_raster raster;
    study_area_raster raster;
    study_area_id integer;

BEGIN

    -- get dam raster

    select rast into dam_raster from dams where id = dam_id;

    -- get study area raster
    
    select study_area into study_area_id from dams where id = dam_id;
    select rast into study_area_raster from areas where rid = study_area_id;

    -- perform algebra to find differential

    update dams set dam_height_rast = ST_MapAlgebra(
        dam_raster,         -- first raster
        1,                  -- first raster band
        study_area_raster,  -- second raster
        1,                  -- second raster band
        '[rast1] - [rast2]' -- expression
    ) where id = dam_id;

END;
$$ LANGUAGE plpgsql;



create or replace function create_dam_height_const_raster (dam_id integer)
returns void as $$

DECLARE

    dam_raster raster;
    study_area_raster raster;
    study_area_id integer;

BEGIN

    -- get dam raster

    select rast into dam_raster from dams where id = dam_id;

    -- get study area raster
    
    select study_area into study_area_id from dams where id = dam_id;
    select rast into study_area_raster from areas where rid = study_area_id;

    -- perform algebra to find differential

    update dams set dam_height_const_rast = ST_MapAlgebra(
        dam_raster,         -- first raster
        1,                  -- first raster band
        study_area_raster,  -- second raster
        1,                  -- second raster band
        '([rast1] - [rast2]) * 1.3' -- expression
    ) where id = dam_id;

END;
$$ LANGUAGE plpgsql;






select create_dam_height_raster(1);
select create_dam_height_const_raster(1);






create or replace function dam_height (dam_id integer)
returns double precision as $$

DECLARE

    return_height double precision;
    w integer;
    h integer;

BEGIN

    -- find highest point in dam_height_rast

    select st_width(dam_height_rast) into w from dams where dam_id = id;
    select st_height(dam_height_rast) into h from dams where dam_id = id;

    select ST_Value(dam_height_rast, hor.n, ver.n) as rast_val
        into return_height
        FROM
            generate_series(1,w) as hor(n),
            generate_series(1,h) as ver(n),
            dams
        WHERE dams.id = dam_id
        AND st_value(dam_height_rast, hor.n, ver.n) is not null
        ORDER BY rast_val DESC
        LIMIT 1;

    return return_height;

END;
$$ LANGUAGE plpgsql;


