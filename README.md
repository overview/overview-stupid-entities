Stupid entity detection
=======================

This app showcases a few tools that make it easy to build a flat-file website.
You can use it for websites large and small.

Structure
---------

* `js`: CoffeeScript code that will become JavaScript.
* `css`: Less code that will become CSS.
* `lib`: Backend CoffeeScript code.
* `views`: Backend Jade views.

Developing
----------

Keep both of these running:

* `gulp dev`: recompile backend files as they change.
* `npm start`: run the backend server.

And then create a new Overview plugin pointing to http://localhost:9001

Deploying
---------

TBA

License
-------

AGPL. See LICENSE.
