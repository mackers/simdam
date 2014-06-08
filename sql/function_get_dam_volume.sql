create or replace function get_dam_volume (dam_id integer)
returns double precision as $$

DECLARE

    dam_rast raster;
    pix_m_x double precision;
    pix_m_y double precision;
    dam_vol double precision;
    w integer;
    h integer;

BEGIN

    select dam_height_rast into dam_rast from dams where id = dam_id;

    -- get pixel size in meters

    pix_m_x := st_distance(
        ST_PixelAsPoint(dam_rast, 0, 0)::geography,
        ST_PixelAsPoint(dam_rast, 1, 0)::geography
    );
 
    pix_m_y := st_distance(
        ST_PixelAsPoint(dam_rast, 0, 0)::geography,
        ST_PixelAsPoint(dam_rast, 0, 1)::geography
    );
    
    raise notice 'pixel size in metres: %', pix_m_y;
    raise notice 'pixel size in metres: %', pix_m_x;

    select st_width(dam_rast) into w;
    select st_height(dam_rast) into h;
    
    select sum(ST_Value(dam_height_rast, hor.n, ver.n)) as cell_h
        into dam_vol
        FROM
            generate_series(1,w) as hor(n),
            generate_series(1,h) as ver(n),
            dams
        WHERE dams.id = dam_id
        AND st_value(dam_height_rast, hor.n, ver.n) is not null;

    return dam_vol * pix_m_y * pix_m_x;

END;
$$ LANGUAGE plpgsql;


create or replace function get_dam_volume_const (dam_id integer)
returns double precision as $$

DECLARE

    dam_rast raster;
    pix_m_x double precision;
    pix_m_y double precision;
    dam_vol double precision;
    w integer;
    h integer;

BEGIN

    select dam_height_const_rast into dam_rast from dams where id = dam_id;

    -- get pixel size in meters

    pix_m_x := st_distance(
        ST_PixelAsPoint(dam_rast, 0, 0)::geography,
        ST_PixelAsPoint(dam_rast, 1, 0)::geography
    );
 
    pix_m_y := st_distance(
        ST_PixelAsPoint(dam_rast, 0, 0)::geography,
        ST_PixelAsPoint(dam_rast, 0, 1)::geography
    );
    
    raise notice 'pixel size in metres: %', pix_m_y;
    raise notice 'pixel size in metres: %', pix_m_x;

    select st_width(dam_rast) into w;
    select st_height(dam_rast) into h;
    
    select sum(ST_Value(dam_height_const_rast, hor.n, ver.n)) as cell_h
        into dam_vol
        FROM
            generate_series(1,w) as hor(n),
            generate_series(1,h) as ver(n),
            dams
        WHERE dams.id = dam_id
        AND st_value(dam_height_const_rast, hor.n, ver.n) is not null;

    return dam_vol * pix_m_y * pix_m_x;

END;
$$ LANGUAGE plpgsql;


-- select get_dam_volume(1);

