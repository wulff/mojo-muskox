// Create the map
var map = L.map('map');

// // Create the basic tile layer using tiles from OpenStreetMap
// var tileLayer = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
//   attribution: 'Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors',
//   minZoom: 6,
//   maxZoom: 17,
//   detectRetina: true
// });
// tileLayer.addTo(map);

// Create a tile layer based on satellite imagery from Google
var satellite = new L.Google('SATELLITE');
map.addLayer(satellite);

var geojsonTrackLayer = L.geoJson(null, {
  style: function (feature) {
    return {
      color: '#f00',
      opacity: 0.9,
      weight: 3,
    };
  },
});

var geojsonPointLayer = L.geoJson(null, {
  onEachFeature: function (feature, layer) {
    var content = '';

    content += '<strong>Ox: ' + feature.properties.animal_id + '</strong><br />';
    content += 'Altitude: ' + feature.properties.altitude + 'm<br />';
    content += 'Temprature: ' + feature.properties.temperature + '˚C<br />';
    content += 'Timestamp: ' + feature.properties.recorded + '<br />';
    content += 'Satellites: ' + feature.properties.sat_count + '<br />';
    content += 'Fix: ' + feature.properties.fix;

    layer.bindPopup(content, {
      minWidth: 200,
      closeButton: false
    });
  }
});

$.getJSON('/v1/oxen/all/positions/points.json', function(data) {
  geojsonPointLayer.addData(data);
  geojsonPointLayer.addTo(map);
});

$.getJSON('/v1/oxen/T5HS-4024/positions/lines.json', function(data) {
  geojsonTrackLayer.addData(data);
  geojsonTrackLayer.addTo(map);
});

map.setView([74.4107, -19.350], 14);
