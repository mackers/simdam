
$(function () {
    'use strict';

    console.log('here');


    var map = new L.Map('map', {
        layers: [
//            new L.TileLayer('http://localhost:8080/hillshade/{z}/{x}/{y}.png')
            new L.TileLayer('/{z}/{x}/{y}.png')
        ],
        center: new L.LatLng(38.304722, -122.158889),
        zoom: 13,
        continuousWorld: true
//        drawControl: true
    });

//    // Initialise the FeatureGroup to store editable layers
//    var drawnItems = new L.FeatureGroup();
//    map.addLayer(drawnItems);
//
//// Initialise the draw control and pass it the FeatureGroup of editable layers
//    var drawControl = new L.Control.Draw({
//        edit: {
//            featureGroup: drawnItems
//        }
//    });
//    map.addControl(drawControl);

    var options = {
//        position: 'topright',
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

        if (type === 'marker') {
            // Do marker specific actions
        }

        // Do whatever else you need to. (save to db, add to map etc)
        map.addLayer(layer);
    });

    map.on('draw:drawstart', function (e) { console.log('draw:drawstart'); });
    map.on('draw:drawstop', function (e) { console.log('draw:drawstop'); });


    // http://localhost:8080/geoserver/workspace1/wms?service=WMS&version=1.1.0&request=GetMap&layers=workspace1:output_hillshade&styles=&bbox=-122.25018518518503,38.2498148148148,-121.99981481481467,38.50018518518517&width=511&height=512&srs=EPSG:4269&format=application/openlayers
//
//    var nexrad = L.tileLayer.wms("http://localhost:8080/geoserver/workspace1/wms", {
//        layers: 'workspace1:output_hillshade',
//        format: 'image/jpeg',
//        transparent: true,
//        attribution: 'atrtr'
//    });

//    nexrad.addTo(map);
});