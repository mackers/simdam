create or replace function get_dam_lake_limit (dam_id integer)
returns geometry as $$

DECLARE

    ref_point geometry;

BEGIN

    SELECT ST_line_interpolate_point(crest, 0.5) INTO ref_point from dams where id = dam_id;

    return ST_Expand(ref_point, 0.0015);

END;
$$ LANGUAGE plpgsql;

select st_asgeojson(get_dam_lake_limit(1));

