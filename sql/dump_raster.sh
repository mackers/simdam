psql gis -c "COPY (SELECT encode(ST_AsTiff(scratch), 'hex') FROM dams WHERE id = 20) TO '/tmp/raster.hex'";

xxd -p -r /tmp/raster.hex > /tmp/raster.tiff


