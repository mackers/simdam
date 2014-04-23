CREATE OR REPLACE FUNCTION create_lake (dam_id integer, area text)
RETURNS geometry AS $$

DECLARE
    lake geometry;
    dam_crest geometry;
    start_point geometry;
    end_point geometry;

    dam_crest_midpoint geometry;
    dam_crest_90 geometry;
    point_90_45 geometry;
    point_90_55 geometry;
    altitude_90_55 double precision;
    altitude_90_45 double precision;
    fill_point geometry;

BEGIN

    Select crest into dam_crest from dams where id = dam_id;

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

    SELECT ST_Value(rast, point_90_55) INTO altitude_90_55 FROM areas;
    SELECT ST_Value(rast, point_90_45) INTO altitude_90_45 FROM areas;

    if altitude_90_55 > altitude_90_45 then
        fill_point := point_90_55;
    else
        fill_point := point_90_45;
    end if;

    -- perform flood fill here

    return st_buffer(fill_point, st_distance(start_point, end_point)/2);

END;
$$ LANGUAGE plpgsql;

UPDATE dams set lake = create_lake(1, 'napa') where id = 1;

