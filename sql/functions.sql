CREATE OR REPLACE FUNCTION points_nearby_same_height (ref_point geometry, area text)
RETURNS TABLE(point geometry, value double precision, geojson text) AS $$

DECLARE
  h double precision;

BEGIN

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
    SELECT ST_MakePoint(x, y), val as v, st_asgeojson(geom) as j FROM (SELECT (ST_PixelAsPoints(rast)).* FROM bar) AS bar2
  );

END;
$$ LANGUAGE plpgsql;
