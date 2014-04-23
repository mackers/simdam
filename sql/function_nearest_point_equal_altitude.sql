CREATE OR REPLACE FUNCTION nearest_point_equal_altitude (ref_point geometry, area text)
RETURNS TABLE(point geometry, distance double precision) AS $$

DECLARE
    p geometry;

BEGIN

    -- RAISE NOTICE 'in nearest_point_equal_altitude with ref_point = %', ST_AsText(ref_point);

    -- WITH foo AS (
    RETURN QUERY (
        SELECT
            points_nearby_equal_altitude.point,
            ST_Distance(
                ST_SetSRID(ref_point, 4269),
                ST_SetSRID(points_nearby_equal_altitude.point, 4269)) AS distance
            FROM points_nearby_equal_altitude(ST_SetSRID(ref_point, 4269), area)
            ORDER BY distance ASC
    );

    -- )
    -- SELECT point INTO p FROM Foo;

    -- RETURN p;

END;
$$ LANGUAGE plpgsql;

SELECT * FROM nearest_point_equal_altitude(
    ST_SetSRID(ST_MakePoint(
            -122.14861392974855,
            38.328763418388334
    ), 4269),
    'napa')
    WHERE distance > 4.02356066137857e-05;

