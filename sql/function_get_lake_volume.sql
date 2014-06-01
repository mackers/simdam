CREATE OR REPLACE FUNCTION calc_alt_diff(value double precision[][][], pos integer[][], VARIADIC userargs text[])
	RETURNS double precision
	AS $$
    DECLARE
        x double precision;
        y double precision;
        d double precision;
	BEGIN
        x := pos[0][1];
        y := pos[0][2];

        -- raise notice 'val of study area at this pos 0: %', value[2][0][0];
        raise notice 'val of study area at this pos %,%: %', x, y, value[2][y][x];

        if value[2][x][y] is not null then
            d := value[1][x][y] - value[2][x][y];

            raise notice 'height of lake here: %', d;
        end if;

        return d;
	END;
	$$ LANGUAGE 'plpgsql' IMMUTABLE;


create or replace function get_lake_volume (dam_id integer)
returns double precision as $$

DECLARE

    study_area_rast raster;
    lake_rast raster;
    alt_at_crest double precision;
    lake_alt double precision;
    pix_m double precision;
    lake_vol double precision;
    w integer;
    h integer;

BEGIN

    select st_clip(areas.rast, dams.lake2, true) into study_area_rast from areas left join dams on areas.rid = dams.study_area where dams.id = dam_id;



    select st_value(areas.rast, ST_PointN(dams.crest, 1)) into alt_at_crest from areas left join dams on areas.rid = dams.study_area where dams.id = dam_id;

    lake_alt := alt_at_crest - 1;

    raise notice 'lake alt: %', lake_alt;

    -- create lake raster

    select st_asraster(lake2, study_area_rast, '32BF', lake_alt) into lake_rast from dams where dams.id = dam_id;

    -- get pixel size in meters

    pix_m := st_distance(
        ST_PixelAsPoint(lake_rast, 0, 0)::geography,
        ST_PixelAsPoint(lake_rast, 1, 0)::geography
    );
    
    raise notice 'pixel size in metres: %', pix_m;

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

    return lake_vol * pix_m * pix_m;

END;
$$ LANGUAGE plpgsql;


select get_lake_volume(1);
