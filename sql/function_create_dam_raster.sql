CREATE OR REPLACE FUNCTION create_dam_raster (dam_crest geometry, area text)
RETURNS RASTER AS $$

DECLARE
    start_point geometry;
    altitude double precision;
    dam_raster raster;
    scalex double precision;
    scaley double precision;
    w integer;
    h integer;

BEGIN

    -- get raster of neighbourhood

        -- geometry ST_Buffer(geometry g1, float radius_of_buffer);
        -- raster ST_Clip(raster rast, geometry geom, boolean crop);

    -- get altitude of first point
    start_point := ST_PointN(dam_crest, 1);
    SELECT ST_Value(rast, start_point) INTO altitude FROM areas;

    raise notice 'altitude at start_point: %', altitude;

    select ST_ScaleX(rast) INTO scalex FROM areas;
    select ST_ScaleY(rast) INTO scaley FROM areas;

    select ST_Width(rast) INTO w FROM areas;
    select ST_Height(rast) INTO h FROM areas;

    -- convert dam_crest geometry to raster
    -- altitude of dam is altitude of raster at first point of crest

        -- raster ST_AsRaster(geometry geom, raster ref, text pixeltype, double precision value=1, double precision nodataval=0, boolean touched=false);

    select ST_AsRaster(dam_crest, rast, '8BUI', altitude, 0) into dam_raster from areas;

    -- raise notice 'width of source raster: %', w;
    -- raise notice 'width of dam raster: %', st_width(dam_raster);

    return dam_raster;


END;
$$ LANGUAGE plpgsql;

UPDATE dams SET rast = create_dam_raster(crest, 'napa') WHERE id = 1;

