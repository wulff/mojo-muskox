// Create the map
var map = L.map('map');

// Create a tile layer based on sat/map tiles from MapQuest
var tiles = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.jpg', {
  attribution: 'Tiles by <a href="http://www.mapquest.com/">MapQuest</a> &mdash; Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>',
  minZoom: 4,
  maxZoom: 17,
  detectRetina: true,
  subdomains: '1234'
});

map.addLayer(tiles);

var geojsonTrackLayer = L.geoJson(null, {
  style: function (feature) {
    return {
      color: '#f60',
      opacity: 0.8,
      weight: 2,
    };
  },
});

var geojsonPointLayer = L.geoJson(null, {
  onEachFeature: function (feature, layer) {
    var content = '';

    content += '<strong>Ox: ' + feature.properties.animal_id + '</strong><br />';
    content += 'Altitude: ' + feature.properties.altitude + 'm<br />';
    content += 'Temperature: ' + feature.properties.temperature + '˚C<br />';
    content += 'Timestamp: ' + feature.properties.recorded + '<br />';
    content += 'Satellites: ' + feature.properties.sat_count + '<br />';
    content += 'Fix: ' + feature.properties.fix;

    layer.bindPopup(content, {
      minWidth: 200,
      closeButton: false
    });
  }
});

$.getJSON('/v1/oxen/all/positions/points.json?count=1', function(data) {
  geojsonPointLayer.addData(data);
  geojsonPointLayer.addTo(map);
});

$.getJSON('/v1/oxen/all/positions/lines.json?count=50', function(data) {
  geojsonTrackLayer.addData(data);
  geojsonTrackLayer.addTo(map);

  var bounds = geojsonTrackLayer.getBounds();
  map.fitBounds(bounds);
});

// Add a scale
L.control.scale({position: 'topright', imperial: false}).addTo(map);
