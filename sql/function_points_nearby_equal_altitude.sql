CREATE OR REPLACE FUNCTION points_nearby_equal_altitude (ref_point geometry, area text)
RETURNS TABLE(point geometry, value double precision, geojson text) AS $$

DECLARE
  h double precision;

BEGIN

    RAISE NOTICE 'in points_nearby_equal_altitude with ref_point = %', ST_AsText(ref_point);

    SELECT ST_Value(rast, ref_point) INTO h FROM areas where area_name = area;

    RAISE NOTICE 'in points_nearby_equal_altitude with h = %', h;

    RETURN QUERY (
        WITH bar AS (
            WITH foo AS (
                SELECT ST_Clip(rast, 1, ST_Expand(ref_point, 0.01), true) AS rast
                FROM areas
                WHERE area_name = area
            )
            SELECT ST_MapAlgebra(rast, 1, NULL, 'CASE WHEN (abs([rast] - ' || h || ') < 1) THEN [rast] ELSE NULL END') AS rast FROM foo
        )
        SELECT geom, val as v, st_asgeojson(geom) as j FROM (SELECT (ST_PixelAsPoints(rast)).* FROM bar) AS bar2
    );

END;
$$ LANGUAGE plpgsql;

select * from points_nearby_equal_altitude(ST_SetSRID(ST_MakePoint(43.94411087036133, 26.270558478573598), 4326), 'buraydah')

-- SELECT ST_AsText(point) FROM points_nearby_equal_altitude(
    -- ST_SetSRID(ST_MakePoint(
            -- -122.14861392974855,
            -- 38.328763418388334
    -- ), 4326),
    -- 'napa');

-- SELECT
    -- ST_AsText(point),
    -- ST_Distance(
        -- point,
        -- ST_SetSRID(ST_MakePoint(
                -- -122.14861392974855,
                -- 38.328763418388334
        -- ), 4326)
    -- ) AS dist

    -- FROM points_nearby_equal_altitude(
    -- ST_SetSRID(ST_MakePoint(
            -- -122.14861392974855,
            -- 38.328763418388334
    -- ), 4326),
    -- 'napa')

    -- ORDER BY dist ASC
    -- LIMIT 1;

