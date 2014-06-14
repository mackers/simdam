rm /tmp/raster.hex
rm /tmp/raster.tiff

psql gis -c "COPY (SELECT encode(ST_AsTiff(dam_height_const_rast), 'hex') FROM dams WHERE id = 104) TO '/tmp/raster.hex'";

#psql gis -c "COPY (
    #SELECT encode(
        #ST_AsTiff(
            #ST_Clip(
                #rast,
                #1,
                #ST_Expand(
                    #st_setsrid(
                        #ST_geomfromgeojson(
                            #'{\"type\":\"Point\",\"coordinates\":[-122.148873733133,38.3284791840922]}'
                        #),
                        #4269
                    #),
                    #0.0015
                #),
                #true
            #)
        #),
        #'hex'
    #)
    #FROM areas
    #WHERE rid = 1)
    #TO '/tmp/raster.hex'";

xxd -p -r /tmp/raster.hex > /tmp/raster.tiff


