
$(function () {
    'use strict';

    var tilelayers = [];

    tilelayers.push(new L.TileLayer('/countries/{z}/{x}/{y}.png',
        {
            maxZoom: 13
            //attribution: 'TODO'
        }
    ));

    var map = window.map = new L.Map('map', {
        layers: tilelayers,
        center: new L.LatLng(38.304722, -122.158889),
        zoom: 13,
        maxZoom: 20,
        continuousWorld: true
    });

    var dams = window.dams = [];

    var options = {
        draw: {
            damcrest: {
                shapeOptions: {
                    color: '#000000',
                    weight: 10
                }
            },
            marker: false,
            polyline: false,
            polygon: false,
            rectangle: false,
            circle: false
        }
    };

    var drawControl = new L.Control.Draw(options);
    map.addControl(drawControl);

    $.get('/study_areas', function (data) {
        if (data.result === 'error' || !data.payload) {
            window.alert('Could not get study areas');
        } else if (data.result === 'ok') {

            for (var i = 0; i<data.payload.length; i++) {
                console.log(data.payload[i].name);

                new L.TileLayer(
                    '/' + data.payload[i].name + '/{z}/{x}/{y}.png',
                    {
                        name: data.payload[i].description,
                        bounds: [
                            L.GeoJSON.coordsToLatLng(data.payload[i].lowerleft.coordinates, true),
                            L.GeoJSON.coordsToLatLng(data.payload[i].upperright.coordinates, true)
                        ],
                        attribution: data.payload[i].attribution
                    }
                ).addTo(map);
            }

            //$(document).trigger('damfine:has_study_areas', {latlngs: latlngs});
        }
    });

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
                    if (data.result === 'error') {
                        window.alert('Could not create a dam at this location');
                        return;
                    }

                    var dam = {
                        id: data.payload,
                        crestLayer: layer,
                        crestStart: start,
                        crestEnd: end
                    };

                    dams.push(dam);

                    $(document).trigger('damfine:create_lake', dam);

                    console.log('have saved dam');
                });
        }

        // Do whatever else you need to. (save to db, add to map etc)
        map.addLayer(layer);
    });

    $(document).on('damfine:create_lake', function (event, dam) {
        console.log('will create lake for dam id = ' + dam.id);
        
        $.get('/napa/create_lake/' + dam.id, function (data) {
            if (data.result === 'error' || !data.payload) {
                window.alert('Could not create a lake model at this location');
            } else if (data.result === 'ok') {
                // create lake layer from geojson payload
                dam.lakeLayer = L.geoJson(data.payload);
                dam.lakeLayer.addTo(map);

                $(document).trigger('damfine:create_dam', dam);
                //$(document).trigger('damfine:get_lake_area', dam);
            }
        });
    });

    $(document).on('damfine:get_lake_area', function (event, dam) {
        $.get('/napa/get_lake_area/' + dam.id, function (data) {
            if (data.result === 'error' || !data.payload) {
                window.alert('Could not get lake area.');
            } else if (data.result === 'ok') {
                console.log('lake area is ' + data.area);
            }
        });
    });


    $(document).on('damfine:create_watershed', function (event, dam) {
        console.log('will create watershed for dam id = ' + dam.id);
        
        $.get('/napa/create_watershed/' + dam.id, function (data) {
            if (data.result === 'error' || !data.payload) {
                window.alert('Could not create a watershed model at this location');
            } else if (data.result === 'ok') {
                // create lake layer from geojson payload
                dam.watershedLayer = L.geoJson(data.payload);
                dam.watershedLayer.setStyle(function() {
                    return {
                        weight: 2,
                        opacity: 1,
                        color: 'white',
                        dashArray: '3',
                        fillOpacity: 0.3,
                        fillColor: '#666666'
                    };
                });
                dam.watershedLayer.addTo(map);
            }

            dam.crestLayer.setStyle({opacity: 0});

            var source   = $('#popup-template').html();
            var template = Handlebars.compile(source);

            var context = {
                reservoirArea: dam.reservoirArea,
                reservoirVolume: dam.reservoirVolume,
                earthworksVolumeConst: dam.earthworksVolumeConst,
                earthworksVolumeFinal: dam.earthworksVolumeFinal,
            };

            dam.lakeLayer.bringToFront();
            dam.lakeLayer.bindPopup(template(context), {maxWidth: 600}).openPopup();
        });
    });


    $(document).on('damfine:create_dam', function (event, dam) {
        console.log('will create dam for dam id = ' + dam.id);
        
        $.get('/napa/create_dam/' + dam.id, function (data) {
            if (data.result === 'error' || !data.payload.dam) {
                window.alert('Could not create a dam model at this location');
            } else if (data.result === 'ok') {
                var imageBounds = L.latLngBounds(
                    L.GeoJSON.coordsToLatLng(data.payload.upperleft.coordinates, true),
                    L.GeoJSON.coordsToLatLng(data.payload.lowerright.coordinates, true));

                dam.damLayer = L.imageOverlay(
                    data.payload.dam,
                    imageBounds);
                dam.damLayer.addTo(map);
            }

            $(document).trigger('damfine:create_watershed', dam);
        });
    });


    $(document).on('damfine:has_defined_crest_first_point', function (event, param1) {
        // TODO replace 'napa' here with map name

        $.get('/napa/points_at_level_near/' + param1.latlng.lat + '/' + param1.latlng.lng + '/', function (data) {
            var latlngs = [];

            for (var i = 0; i<data.length; i++) {
                latlngs.push(L.latLng(data[i].coordinates[1], data[i].coordinates[0]));
            }

            $(document).trigger('damfine:has_receiving_altitude_match_points', {latlngs: latlngs});
        });
    });


});
