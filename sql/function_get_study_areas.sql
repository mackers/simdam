CREATE OR REPLACE FUNCTION study_areas ()
RETURNS TABLE(name text, description text, attribution text, lowerleft geometry, upperright geometry) AS $$

DECLARE

BEGIN

    return query (
        select
            area_name,
            areas.description, 
            areas.attribution, 
            st_makepoint(
                st_rasterToWorldCoordX(rast, 0, st_height(rast)),
                st_rastertoworldcoordy(rast, 0, st_height(rast))
            ),
            st_makepoint(
                st_rastertoWorldCoordX(rast, st_width(rast), 0),
                ST_RasterToWorldCoordy(rast, st_width(rast), 0)
            )
            from areas
        );

END;
$$ LANGUAGE plpgsql;
