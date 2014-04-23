psql gis -c "COPY (SELECT encode(ST_AsTiff(rast), 'hex') FROM dams WHERE id = 1) TO '/tmp/raster.hex'";

xxd -p -r /tmp/raster.hex > /tmp/raster.tiff


