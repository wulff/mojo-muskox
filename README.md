Muskox
======

A simple Mojolicious application which parses and stores GPS data from Televilt/FollowIt tracking collars.


Endpoints
---------

At the moment the service endpoints only support GeoJSON.

### Create

* **POST /v1/oxen** Accepts a parsed e-mail from the Postmark service.

### Read

* **GET /** Renders a simple map showing the latest positions of all animals.
* **GET /v1/oxen/all/names** Provides an array of all animals currently being tracked.
* **GET /v1/oxen/:animal_id/positions/points** Provides a GeoJSON file with all known positions of a single animal as points.
* **GET /v1/oxen/:animal_id/positions/lines** Provides a GeoJSON file with all known positions of a single animal as linestrings.
* **GET /v1/oxen/interpolate** Updates the database by interpolating any missing position data.


Credits
-------

* [Leaflet plugins](https://github.com/shramov/leaflet-plugins)
* [CPANMinus Package Provider for Puppet](https://github.com/torrancew/puppet-cpanm)
