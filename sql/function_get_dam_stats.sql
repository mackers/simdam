CREATE OR REPLACE FUNCTION update_dam_stats (dam_id integer)
RETURNS void
AS $$ 
DECLARE
    combined_slope double precision;
    the_dam_height double precision;
BEGIN
    update dams set dam_height = dam_height(dam_id) where dams.id = dam_id;
    update dams set crest_length = st_distance(st_pointn(dams.crest, 1)::geography, st_pointn(dams.crest, 2)::geography) where dams.id = dam_id;
    update dams set throwback = st_length(st_longestline(dams.crest, dams.lake2)::geography) where dams.id = dam_id;

    select dams.dam_height into the_dam_height from dams where dams.id = dam_id;

    combined_slope := 6;

    if the_dam_height < 6 then
        combined_slope = 5;
    end if;

    if the_dam_height < 3 then
        combined_slope = 4.5;
    end if;

    update dams set stephens_reservoir_volume =
        -- LTH'/6
        (crest_length * throwback * dam_height) / 6
        where dams.id = dam_id;

    update dams set stephens_earthworks_volume =
        -- V = 0.216HL(2C + HS)
        0.216 * dam_height * crest_length * (2 * 3 + dam_height * combined_slope)
        where dams.id = dam_id;


    -- RETURN QUERY( 
        -- SELECT dam_id,
            -- dams.dam_height,
            -- dams.reservoir_area,
            -- dams.reservoir_volume,
            -- dams.earthworks_volume,
            -- dams.earthworks_volume_const,
            -- dams.crest_length,
            -- dams.throwback,
            -- dams.stephens_reservoir_volume,
            -- dams.stephens_earthworks_volume
        -- FROM dams
        -- WHERE dams.reservoir_area IS NOT NULL
        -- AND dams.id = dam_id
        -- ORDER BY dams.id ASC
    -- );
END;
$$ LANGUAGE plpgsql;

select update_dam_stats(1);

