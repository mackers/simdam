CREATE OR REPLACE FUNCTION points_nearby_equal_altitude (ref_point geometry, area text)
RETURNS TABLE(point geometry, value double precision, geojson text) AS $$

DECLARE
  h double precision;

BEGIN

    -- RAISE NOTICE 'in points_nearby_equal_altitude with ref_point = %', ST_AsText(ref_point);

    SELECT ST_Value(rast, ref_point) INTO h FROM areas;

    RETURN QUERY (
        WITH bar AS (
            WITH foo AS (
                SELECT ST_Clip(rast, 1, ST_Expand(ref_point, 0.001), true) AS rast
                FROM areas
                WHERE area_name = area
            )
            SELECT ST_MapAlgebra(rast, 1, NULL, 'CASE WHEN (abs([rast] - ' || h || ') < 1) THEN [rast] ELSE NULL END') AS rast FROM foo
        )
        SELECT geom, val as v, st_asgeojson(geom) as j FROM (SELECT (ST_PixelAsPoints(rast)).* FROM bar) AS bar2
    );

END;
$$ LANGUAGE plpgsql;

-- SELECT ST_AsText(point) FROM points_nearby_equal_altitude(
    -- ST_SetSRID(ST_MakePoint(
            -- -122.14861392974855,
            -- 38.328763418388334
    -- ), 4269),
    -- 'napa');

SELECT
    ST_AsText(point),
    ST_Distance(
        point,
        ST_SetSRID(ST_MakePoint(
                -122.14861392974855,
                38.328763418388334
        ), 4269)
    ) AS dist

    FROM points_nearby_equal_altitude(
    ST_SetSRID(ST_MakePoint(
            -122.14861392974855,
            38.328763418388334
    ), 4269),
    'napa')

    ORDER BY dist ASC
    LIMIT 1;
