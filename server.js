var express = require("express"),
    app = express(),
    tilelive = require('tilelive');

require('tilelive-mapnik').registerProtocols(tilelive);


app.use(express.static(__dirname + '/public'));


//// TODO api
//

app.use(function errorHandler(err, req, res, next) {
    res.status(500);
    res.render('error', { error: err });
});


var filename = __dirname + '/scratch/hs.xml';

tilelive.load('mapnik://' + filename, function(err, source) {
    if (err) throw err;
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