CREATE OR REPLACE FUNCTION create_lake (dam_crest geometry, area text)
RETURNS geometry AS $$

DECLARE
    start_point geometry;
    end_point geometry;
    next_point geometry;
    lake geometry;
    count integer;

    dam_crest_midpoint geometry;
    dam_crest_90 geometry;
    dam_crest_90_point geometry;
    dam_crest_90_alt geometry;
    dam_crest_270_point geometry;
    dam_crest_270_alt geometry;

BEGIN

    -- first point in dam_crest
    start_point := ST_PointN(dam_crest, 1);
    end_point := ST_PointN(dam_crest, 2);
    next_point := start_point;
    count := 0;

    -- PERFORM * FROM nearest_point_equal_altitude(
        -- ST_SetSRID(ST_MakePoint(
                -- -122.14861392974855,
                -- 38.328763418388334
        -- ), 4326),
        -- 'napa');

    RAISE NOTICE 'start_point: %', ST_AsText(start_point);
    RAISE NOTICE 'end_point: %', ST_AsText(end_point);

    CREATE TEMP TABLE lake_points (point GEOMETRY);
    INSERT INTO lake_points VALUES (start_point);

    LOOP
        SELECT point INTO next_point FROM nearest_point_equal_altitude(
                next_point,
                area
            )
            WHERE point NOT IN (SELECT point FROM lake_points)
            -- AND distance > 4.02356066137857e-05
            LIMIT 1;

        RAISE NOTICE 'next_point: %', ST_AsText(next_point);

        INSERT INTO lake_points VALUES (next_point);

        count := count + 1;

        EXIT WHEN count > 100;
        EXIT WHEN ST_Distance(next_point, end_point) <  10.02356066137857e-05;

    END LOOP;

    INSERT INTO lake_points VALUES (start_point);

    lake := ST_MakeLine(ARRAY(SELECT point FROM lake_points));

    RAISE NOTICE 'num points: %', (SELECT COUNT(*) FROM lake_points);
    RAISE NOTICE 'lake: %', ST_AsText(lake);


    RETURN lake;



    -- -- get middle point of dam_crest
    -- SELECT ST_line_interpolate_point(dam_crest, 0.5) INTO dam_crest_midpoint;

    -- -- 90deg line
    -- SELECT
        -- ST_Rotate(
            -- dam_crest,
            -- pi()/2,
            -- dam_crest_midpoint)
        -- INTO dam_crest_90;

    -- -- 90deg point
    -- RAISE NOTICE 'dam_crest: %', ST_AsText(dam_crest);
    -- RAISE NOTICE 'dam_crest_90: %', ST_AsText(dam_crest_90);

    -- RAISE NOTICE 'midpoint: %', ST_AsText(ST_line_interpolate_point(dam_crest, 0.5));
    -- RAISE NOTICE 'midpoint_90_55: %', ST_AsText(ST_line_interpolate_point(dam_crest_90, 0.55));
    -- RAISE NOTICE 'midpoint_90_45: %', ST_AsText(ST_line_interpolate_point(dam_crest_90, 0.45));



    -- SELECT ST_line_interpolate_point(dam_crest_90, 0.55) INTO dam_crest_90_point;
    -- SELECT ST_Value(area, dam_crest_90_point) INTO dam_crest_90_alt;

    -- RAISE NOTICE 'dam_crest_90_alt: %', dam_crest_90_point;

    -- 270deg point
    -- SELECT ST_line_interpolate_point(dam_crest_270, 0.45) INTO dam_crest_270_point;
    -- SELECT ST_Value(area, dam_crest_270_point) INTO dam_crest_270_alt;

    -- RAISE NOTICE 'dam_crest_270_alt: %', dam_crest_270_point;

    -- select higher
    -- map algebra to 'grow' higher pixel




END;
$$ LANGUAGE plpgsql;

SELECT ST_AsText(create_lake(dam_crests.crest, 'napa')) FROM 
    dam_crests 
    WHERE dam_crests.id = 8;

