
// This example shows how to use node-mapnik to
// render maps tiles based on spatial data stored in postgis
//
// To run you must configure the postgis_settings variable


var mapnik = require('mapnik');
var mercator = require('./sphericalmercator.js');
var url = require('url');
var fs = require('fs');
var http = require('http');
var parseXYZ = require('./tile.js').parseXYZ;
var path = require('path');
var port = 8000;
var TMS_SCHEME = false;

// change this to fit your db connection and settings
var settings = {
    'type' : 'gdal',
    'base' : '/Users/mackers/Dropbox/mscgis/dissertation/data/test_image/',
    'file' : 'start.png'
};

http.createServer(function(req, res) {
    parseXYZ(req, TMS_SCHEME, function(err,params) {
        if (err) {
            res.writeHead(500, {'Content-Type': 'text/plain'});
            res.end(err.message);
        } else {
            try {
                var map = new mapnik.Map(256, 256, mercator.proj4);
                var layer = new mapnik.Layer('tile', mercator.proj4);
                var raster = new mapnik.Datasource(settings);
                var bbox = mercator.xyz_to_envelope(parseInt(params.x),
                    parseInt(params.y),
                    parseInt(params.z), false);

                layer.datasource = raster;

//                layer.styles = ['point'];
//                map.bufferSize = 64;

//                map.load(path.join(__dirname, 'point_vector.xml'), {strict: true}, function(err,map) {
//                    if (err) throw err;
                    map.add_layer(layer);

                    // console.log(map.toXML()); // Debug settings

                    map.extent = bbox;
                    var im = new mapnik.Image(map.width, map.height);
                    map.render(im, function(err, im) {
                        if (err) {
                            throw err;
                        } else {
                            res.writeHead(200, {'Content-Type': 'image/png'});
                            res.end(im.encodeSync('png'));
                        }
                    });
//                });
            }
            catch (err) {
                res.writeHead(500, {'Content-Type': 'text/plain'});
                res.end(err.message);
                console.log(err.message);
            }
        }
    });
}).listen(port);

console.log('Server running on port %d', port);
