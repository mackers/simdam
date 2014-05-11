CREATE OR REPLACE FUNCTION create_dam_crest_raster (dam_id integer, ref_rast raster)
RETURNS void AS $$

DECLARE
    start_point geometry;
    altitude double precision;
    dam_raster raster;
    scalex double precision;
    scaley double precision;
    gridx double precision;
    gridy double precision;
    w integer;
    h integer;
    area_id integer;
    dam_crest geometry;

BEGIN

    select crest into dam_crest from dams where id = dam_id;

    select study_area into area_id from dams where id = dam_id;

    -- get altitude of first point
    start_point := ST_PointN(dam_crest, 1);

    SELECT ST_Value(rast, start_point) INTO altitude FROM areas where rid = area_id;
    raise notice 'altitude at start_point: %', altitude;

    select ST_ScaleX(ref_rast) INTO scalex;
    select ST_ScaleY(ref_rast) INTO scaley;

    select ST_UpperLeftX(ref_rast) INTO gridx;
    select ST_UpperLeftY(ref_rast) INTO gridy;

    select ST_Width(ref_rast) INTO w;
    select ST_Height(ref_rast) INTO h;

    raise notice 'width of source raster: %', w;

    select ST_AsRaster(
        dam_crest,
        w,
        h,
        gridx,
        gridy,
        '32BF',
        altitude,
        0) into dam_raster;

    raise notice 'altitude at start_point (dam raster): %', st_nearestvalue(dam_raster, start_point);
    raise notice 'width of dam raster: %', st_width(dam_raster);

    update dams set rast = dam_raster where id = dam_id;

END;
$$ LANGUAGE plpgsql;


-- CREATE OR REPLACE FUNCTION create_dam_raster (dam_crest geometry, area text)
CREATE OR REPLACE FUNCTION create_dam_crest_raster (dam_id integer)
RETURNS void AS $$

DECLARE
    start_point geometry;
    altitude double precision;
    dam_raster raster;
    scalex double precision;
    scaley double precision;
    w integer;
    h integer;
    area_id integer;
    dam_crest geometry;

BEGIN

    -- get raster of neighbourhood

        -- geometry ST_Buffer(geometry g1, float radius_of_buffer);
        -- raster ST_Clip(raster rast, geometry geom, boolean crop);

    select crest into dam_crest from dams where id = dam_id;

    select study_area into area_id from dams where id = dam_id;

    -- get altitude of first point
    start_point := ST_PointN(dam_crest, 1);
    SELECT ST_Value(rast, start_point) INTO altitude FROM areas where rid = area_id;

    raise notice 'altitude at start_point: %', altitude;

    select ST_ScaleX(rast) INTO scalex FROM areas where rid = area_id;
    select ST_ScaleY(rast) INTO scaley FROM areas where rid = area_id;

    select ST_Width(rast) INTO w FROM areas where rid = area_id;
    select ST_Height(rast) INTO h FROM areas where rid = area_id;

    -- convert dam_crest geometry to raster
    -- altitude of dam is altitude of raster at first point of crest

        -- raster ST_AsRaster(geometry geom, raster ref, text pixeltype, double precision value=1, double precision nodataval=0, boolean touched=false);

    select ST_AsRaster(dam_crest, rast, '32BF', altitude, 0) into dam_raster from areas where rid = area_id;

    raise notice 'altitude at start_point (dam raster): %', st_nearestvalue(dam_raster, start_point);

    raise notice 'width of source raster: %', w;
    raise notice 'width of dam raster: %', st_width(dam_raster);

    update dams set rast = dam_raster where id = dam_id;


END;
$$ LANGUAGE plpgsql;

-- UPDATE dams SET rast = create_dam_raster(crest, 'napa') WHERE id = 1;

SELECT create_dam_raster(1);




SELECT create_dam_crest_raster(1);

