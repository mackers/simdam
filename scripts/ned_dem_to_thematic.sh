#!/bin/bash

# TODO lakes and water bodies
# TODO osm streets proxy
# TODO crop

OUT_DIRECTORY=`pwd`/out
MAPNIK_XML=$OUT_DIRECTORY/mapnik.xml
OUT_DEM_WEBMERC=$OUT_DIRECTORY/dem_webmerc.geotiff
OUT_HILLSHADE=$OUT_DIRECTORY/dem_hillshade.geotiff
TMP_SLOPE=/tmp/dem_slope.geotiff
TMP_SLOPE_SHADE_INDEX=/tmp/slope_shade_index.txt
OUT_COLOR_RELIEF=$OUT_DIRECTORY/dem_color.geotiff
TMP_COLOR_RELIEF_INDEX=/tmp/color_relief_index.txt
OUT_SLOPE_SHADE=$OUT_DIRECTORY/dem_slope_shade.geotiff
COUNTRIES=/Users/mackers/Documents/MapBox/project/hillshade1/layers/countries/82945364-10m-admin-0-countries.shp
OUT_SQL=$OUT_DIRECTORY/`basename $1`.sql

if [ ! -d "$OUT_DIRECTORY" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  echo "Directory '$OUT_DIRECTORY' does not exist."
  exit;
fi

# reproject ned dem to web mercator
gdalwarp -r bilinear -s_srs EPSG:4269 -t_srs EPSG:3857 $1 $OUT_DEM_WEBMERC

# create psql import script
#raster2pgsql -c -C $OUT_DEM_WEBMERC > $OUT_SQL

# create hillshade
gdaldem hillshade $OUT_DEM_WEBMERC $OUT_HILLSHADE

# create slope shading
gdaldem slope $OUT_DEM_WEBMERC $TMP_SLOPE
cat > $TMP_SLOPE_SHADE_INDEX <<EOM
0 255 255 255
90 0 0 0
EOM
gdaldem color-relief $TMP_SLOPE $TMP_SLOPE_SHADE_INDEX $OUT_SLOPE_SHADE

# create colour relief
cat > $TMP_COLOR_RELIEF_INDEX <<EOM
0 110 220 110
400 240 250 160
800 230 220 170
1500 220 220 220
2500 250 250 250
EOM
gdaldem color-relief $OUT_DEM_WEBMERC $TMP_COLOR_RELIEF_INDEX $OUT_COLOR_RELIEF

# output xml
cat > $MAPNIK_XML << EOM
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE Map[]>
<Map srs="+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over" background-color="#b8dee6" maximum-extent="-20037508.34,-20037508.34,20037508.34,20037508.34">

<Parameters>
  <Parameter name="bounds">-180,-85.05112877980659,180,85.05112877980659</Parameter>
  <Parameter name="center">0,0,2</Parameter>
  <Parameter name="format">png</Parameter>
  <Parameter name="minzoom">0</Parameter>
  <Parameter name="maxzoom">22</Parameter>
</Parameters>

<Style name="countries" filter-mode="first" >
  <Rule>
    <PolygonSymbolizer fill="#ffffff" />
  </Rule>
</Style>
<Style name="countries-outline" filter-mode="first" >
  <Rule>
    <LineSymbolizer stroke="#85c5d3" stroke-width="2" stroke-linejoin="round" />
  </Rule>
</Style>

<Layer name="countries"
  srs="+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over">
    <StyleName>countries-outline</StyleName>
    <StyleName>countries</StyleName>
    <Datasource>
       <Parameter name="file"><![CDATA[$COUNTRIES]]></Parameter>
       <Parameter name="type"><![CDATA[shape]]></Parameter>
       <Parameter name="id"><![CDATA[countries]]></Parameter>
       <Parameter name="project"><![CDATA[hillshade1]]></Parameter>
       <Parameter name="srs"><![CDATA[+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0.0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over]]></Parameter>
    </Datasource>
</Layer>

<Style name="color relief style">
<Rule>
<RasterSymbolizer comp-op="src-over" />
</Rule>
</Style>
<Style name="slopeshade style">
<Rule>
<RasterSymbolizer opacity="0.1" comp-op="multiply" />
</Rule>
</Style>
<Style name="hillshade style">
<Rule>
<RasterSymbolizer opacity="0.4" comp-op="multiply" />
</Rule>
</Style>
 
<Layer name="color relief">
<StyleName>color relief style</StyleName>
<Datasource>
<Parameter name="type">gdal</Parameter>
<Parameter name="file">$OUT_COLOR_RELIEF</Parameter>
</Datasource>
</Layer>
<Layer name="slopeshade">
<StyleName>hillshade style</StyleName>
<Datasource>
<Parameter name="type">gdal</Parameter>
<Parameter name="file">$OUT_SLOPE_SHADE</Parameter>
</Datasource>
</Layer>
<Layer name="hillshade">
<StyleName>hillshade style</StyleName>
<Datasource>
<Parameter name="type">gdal</Parameter>
<Parameter name="file">$OUT_HILLSHADE</Parameter>
</Datasource>
</Layer> 

</Map>
EOM

# delete temporary files
rm $TMP_SLOPE
rm $TMP_SLOPE_SHADE_INDEX
rm $TMP_COLOR_RELIEF_INDEX
