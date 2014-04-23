'use strict';

var express = require('express'),
    app = express(),
    tilelive = require('tilelive'),
    pg = require('pg').native,
    pgc,
    pgConnectionString = 'postgres://localhost:5432/gis';


pgc = new pg.Client(pgConnectionString);
pgc.connect();


require('tilelive-mapnik').registerProtocols(tilelive);
app.use(express.static(__dirname + '/public'));


app.get('/napa/points_at_level_near/:lat/:lng/', function (req, res) {
   // TODO

//    client.query('SELECT name FROM users WHERE email = $1', ['brian@example.com'], function(err, result) {
//        assert.equal('brianc', result.rows[0].name);
//        done();
//    });

//    var q = pgc.query('select COUNT(rid) AS count from ned19_n38x50_w122x25_ca_sanfrancisco_topobathy_2010');

//    var q = pgc.query('WITH bar AS (WITH foo AS (SELECT ST_Clip(rast, 1, ST_Expand(ST_SetSRID(ST_MakePoint(-122.16454, 38.30273), 4269), 0.0001), true) AS rast FROM ned19_n38x50_w122x25_ca_sanfrancisco_topobathy_2010)    SELECT ST_MapAlgebra(rast, 1, NULL, \'CASE WHEN (abs([rast] - 505) < 10) THEN [rast] ELSE NULL END\') AS rast FROM foo)    SELECT x, y, val, st_asgeojson(geom) as j FROM (SELECT (ST_PixelAsPoints(rast)).* FROM bar) AS bar2');

    var qstr = 'select * from points_nearby_equal_altitude(ST_SetSRID(ST_MakePoint(' +
        req.param('lng') +
        ', ' +
        req.param('lat') +
        '), 4269), \'napa\')';

    console.log(qstr);

    var q = pgc.query(qstr);
    var r = [];

    q.on('error', function(error) {
        console.log(error);
    });

    q.on('row', function(row, result) {
//        console.log(row);
        if (row.geojson) {
            r.push(JSON.parse(row.geojson));
            result.addRow(row);
        }
    });

    q.on('end', function(result) {
        console.log(result.rows.length + ' rows were received');

        res.json(r);
    });

//    q.on('row', function(result) {
//        console.log(result);
//
//        if (!result) {
//            return res.send('No data found');
//        } else {
//            res.send('count = ' + result.count);
//        }
//    });
});

app.post('/napa/save_dam_crest/:startlat/:startlng/:endlat/:endlng', function (req, res) {

    // TODO user id

    var qstr = 'insert into dams(user_id, crest) values (0, ' +
        'ST_GeomFromText(\'LINESTRING(' +
        req.param('startlng') + ' ' + req.param('startlat') + ', ' +
        req.param('endlng') + ' ' + req.param('endlat') + ')\', 4269))';

    console.log(qstr);

    var q = pgc.query(qstr);
    var r = [];

    q.on('error', function(error) {
        console.log(error);
        res.send(500, {'result': 'error'});
    });

    q.on('end', function(result) {
        console.log('saved a dam crest');
        // TODO return id
        res.json({'result': 'ok'});
    });

});


app.use(function errorHandler(err, req, res, next) {
    res.status(500);
    res.render('error', { error: err });
});

var filename = __dirname + '/scripts/out/mapnik.xml';

tilelive.load('mapnik://' + filename, function(err, source) {
    if (err) { throw err; }
    app.get('/:z/:x/:y.*', function(req, res) {
        source.getTile(req.param('z'), req.param('x'), req.param('y'), function(err, tile, headers) {
            // `err` is an error object when generation failed, otherwise null.
            // `tile` contains the compressed image file as a Buffer
            // `headers` is a hash with HTTP headers for the image.
            if (!err) {
                res.send(tile);
            } else {
                res.send('Tile rendering error: ' + err + '\n');
            }
        });
    });
});


app.listen(3000);
console.log('Listening on port 3000');
