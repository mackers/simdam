rm /tmp/raster.hex
rm /tmp/raster.tiff

psql gis -c "COPY (SELECT encode(ST_AsTiff(dam_height_rast), 'hex') FROM dams WHERE id = 1) TO '/tmp/raster.hex'";

xxd -p -r /tmp/raster.hex > /tmp/raster.tiff


