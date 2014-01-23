
$(function () {
    'use strict';

    console.log('here');


    var map = new L.Map('map', {
        layers: [
//            new L.TileLayer('http://localhost:8080/hillshade/{z}/{x}/{y}.png')
            new L.TileLayer('/{z}/{x}/{y}.png')
        ],
        center: new L.LatLng(45, -116),
        zoom: 3,
        continuousWorld: true
    });

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