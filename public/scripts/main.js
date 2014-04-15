
$(function () {
    'use strict';

    var map = new L.Map('map', {
        layers: [
            new L.TileLayer('/{z}/{x}/{y}.png')
        ],
        center: new L.LatLng(38.304722, -122.158889),
        zoom: 13,
        maxZoom: 20,
        continuousWorld: true
    });

    var options = {
        draw: {
            damcrest: {
                shapeOptions: {
                    color: '#000000',
                    weight: 10
                }
            },
            polyline: false,
            polygon: false,
            rectangle: false,
            circle: false
        }
    };

    var drawControl = new L.Control.Draw(options);
    map.addControl(drawControl);

    map.on('draw:created', function (e) {
        var type = e.layerType,
            layer = e.layer;

        if (type === 'polyline') {
            // Do marker specific actions
            var start = layer.getLatLngs()[0];
            var end = layer.getLatLngs()[1];

            $.post('/napa/save_dam_crest/' +
                start.lat + '/' + start.lng + '/' +
                end.lat + '/' + end.lng, function (data) {
                console.log('have saved dam crest');
            });
        }

        // Do whatever else you need to. (save to db, add to map etc)
        map.addLayer(layer);
    });

//    map.on('draw:drawstart', function (e) { console.log('draw:drawstart'); });
//    map.on('draw:drawstop', function (e) { console.log('draw:drawstop'); });

    $(document).on('damfine:has_defined_crest_first_point', function (event, param1) {
        console.log('got damfine:firstpoint, param1 = ' + param1.latlng.lat);

        // TODO replace 'napa' here with map name
        // TODO replace this with api call

        $.get('/napa/points_at_level_near/' + param1.latlng.lat + '/' + param1.latlng.lng + '/', function (data) {
            var latlngs = [];

            for (var i = 0; i<data.length; i++) {
                latlngs.push(L.latLng(data[i].coordinates[1], data[i].coordinates[0]));
            }

            $(document).trigger('damfine:has_receiving_altitude_match_points', {latlngs: latlngs});
        });
    });

    $(document).on('damfine:have_created_dam_crest', function (event, latlng1, latlng2) {
        console.log(latlng1);
        console.log(latlng2);
    });

});
