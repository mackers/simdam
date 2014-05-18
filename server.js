'use strict';

var express = require('express'),
    app = express(),
    tilelive = require('tilelive'),
    tilecache = require('tilelive-cache')(tilelive, {size: 200}),
    pg = require('pg').native,
    pgc,
    pgConnectionString = 'postgres://localhost:5432/gis';

pgc = new pg.Client(pgConnectionString);
pgc.connect();

require('tilelive-mapnik').registerProtocols(tilelive);
app.use(express.static(__dirname + '/public'));

app.get('/study_areas', function (req, res) {
    var qstr = 'select name, description, attribution, st_asgeojson(lowerleft) as lowerleft, st_asgeojson(upperright) as upperright from study_areas()';

    var q = pgc.query(qstr);
    var r = [];

    q.on('error', function(error) {
        console.log(error);
    });

    q.on('row', function(row, result) {
        r.push({
            name: row.name,
            description: row.description,
            attribution: row.attribution,
            lowerleft: JSON.parse(row.lowerleft),
            upperright: JSON.parse(row.upperright)
        });
        result.addRow(row);
    });

    q.on('end', function(result) {
        console.log(result.rows.length + ' rows were received');

        res.json({'result': 'ok', 'payload': r});
    });
});

app.get('/napa/points_at_level_near/:lat/:lng/', function (req, res) {
    var qstr = 'select * from points_nearby_equal_altitude(ST_SetSRID(ST_MakePoint(' +
        req.param('lng') +
        ', ' +
        req.param('lat') +
        '), 4326), \'napa\')';

    console.log(qstr);

    var q = pgc.query(qstr);
    var r = [];

    q.on('error', function(error) {
        console.log(error);
    });

    q.on('row', function(row, result) {
        if (row.geojson) {
            r.push(JSON.parse(row.geojson));
            result.addRow(row);
        }
    });

    q.on('end', function(result) {
        console.log(result.rows.length + ' rows were received');

        res.json(r);
    });
});

app.post('/napa/save_dam_crest/:startlat/:startlng/:endlat/:endlng', function (req, res) {

    // TODO user id

    var qstr = 'insert into dams (user_id, study_area, crest) values (0, 1, ' +
        'ST_GeomFromText(\'LINESTRING(' +
        req.param('startlng') + ' ' + req.param('startlat') + ', ' +
        req.param('endlng') + ' ' + req.param('endlat') + ')\', 4326)) ' +
        ' RETURNING id';

    console.log(qstr);

    var q = pgc.query(qstr);
    var r = [];

    q.on('error', function(error) {
        console.log(error);
        res.send(500, {'result': 'error'});
    });

    var id;

    q.on('row', function(row, result) {
        id = row.id;
    });

    q.on('end', function(result) {
        console.log('saved a dam with id: ' + id);
        res.json({'result': 'ok', 'payload': id});
    });
});


app.get('/napa/create_lake/:dam_id', function (req, res) {
    var qstr = 'select st_asgeojson(create_lake(' + req.param('dam_id') + ')) as geojson';

    console.log(qstr);

    var q = pgc.query(qstr);
    var r = [];

    q.on('error', function(error) {
        console.log(error);
        res.send(500, {'result': 'error'});
    });

    var lake2;

    q.on('row', function(row, result) {
        if (row.geojson) {
            lake2 = JSON.parse(row.geojson);
        }
    });

    q.on('end', function(result) {
        if (lake2) {
            res.json({'result': 'ok', 'payload': lake2});
        } else {
            res.json({'result': 'wait'});
        }
    });
});

app.get('/napa/create_dam/:dam_id', function (req, res) {
    var qstr = 'select * from dam_as_png(' + req.param('dam_id') + ')';

    console.log(qstr);

    var q = pgc.query(qstr);
    var r = [];

    q.on('error', function(error) {
        console.log(error);
        res.send(500, {'result': 'error'});
    });

    var payload = {};

    q.on('row', function(row, result) {
        if (row.dam) {
            payload.dam = row.dam;
            payload.upperleft = JSON.parse(row.upperleft);
            payload.lowerright = JSON.parse(row.lowerright);
        }
    });

    q.on('end', function(result) {
        res.json({'result': 'ok', 'payload': payload});
    });
});


app.use(function errorHandler(err, req, res, next) {
    res.status(500);
    res.render('error', { error: err });
});

var filename = __dirname + '/data/napa/mapnik.xml';
tilecache.load('mapnik://' + filename, function(err, source) {
    if (err) { throw err; }
    app.get('/napa/:z/:x/:y.*', function(req, res) {
        source.getTile(req.param('z'), req.param('x'), req.param('y'), function(err, tile, headers) {
            if (!err) {
                res.send(tile);
            } else {
                res.send('Tile rendering error: ' + err + '\n');
            }
        });
    });
});

var filename = __dirname + '/data/buraydah/mapnik.xml';
tilecache.load('mapnik://' + filename, function(err, source) {
    if (err) { throw err; }
    app.get('/buraydah/:z/:x/:y.*', function(req, res) {
        source.getTile(req.param('z'), req.param('x'), req.param('y'), function(err, tile, headers) {
            if (!err) {
                res.send(tile);
            } else {
                res.send('Tile rendering error: ' + err + '\n');
            }
        });
    });
});

var filename = __dirname + '/data/countries/mapnik.xml';
tilecache.load('mapnik://' + filename, function(err, source) {
    if (err) { throw err; }
    app.get('/countries/:z/:x/:y.*', function(req, res) {
        source.getTile(req.param('z'), req.param('x'), req.param('y'), function(err, tile, headers) {
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
