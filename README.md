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
* **GET /v1/oxen/:animal_id/positions/points** Provides a GeoJSON file with all known positions of a single animal as points. Use the count parameter to limit the results to the *n* latest points.
* **GET /v1/oxen/:animal_id/positions/lines** Provides a GeoJSON file with all known positions of a single animal as linestrings. Use the count parameter to limit the results to the *n* latest line segments.
* **GET /v1/oxen/interpolate** Updates the database by interpolating any missing position data. *Not yet implemented.*


Examples
--------

Get a list of the names of all the animals in the database:

    /v1/oxen/all/names

Get all positions of all animals:

    /v1/oxen/all/positions/points

Get the 10 latest positions of a specific animal:

    /v1/oxen/T5HS-4024/positions/points?count=10

Get the full path of a specific animal:

    /v1/oxen/T5HS-4024/positions/lines
