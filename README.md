WeGA WebApp
===========

This web application is written in XQuery on top of an [eXist-db](http://exist-db.org) and powers [www.weber-gesamtausgabe.de](http://www.weber-gesamtausgabe.de). Needless to say the code is tailor-made to fit our data (see `example-data` and the corresponding [TEI ODD schemata](https://github.com/Edirom/WeGA-ODD)) but can hopefully serve as a starting point for likewise ventures.

Since version 1.2 the WeGA-WebApp is designed as an eXist app package and should happily live together with other installed apps.


Prerequisites
-------------

1. [eXist-db](http://exist-db.org/) v2.x with support for XQuery 3.0
2. [Digilib Image Server](http://developer.berlios.de/projects/digilib/) v1.8.3: All processing of images (except icons under `/resources/pix`) is done via Digilib. Well, if you don't want images, you don't need Digilib. Also, the exact version shouldn't be crucial.


Quick start guide
-----------------

If you have a running eXist 2.x database you can simply install the WeGA-data-samples.xar  as well as the WeGA-WebApp.xar from the [Release section](https://github.com/Edirom/WeGA-WebApp/releases) via the eXist-Dashboard.

### Dependencies
* functx (http://www.functx.com), installable via dashboard
* xqjson (http://xqilla.sourceforge.net/lib/xqjson), installable via dashboard



Branches
--------
* `master` our stable branch, based on eXist 2.x
* `develop` our development branch
* other branches are experimental and and will get merged (or just some features) into develop at some point


Documentation
-------------

(Sparse) Documentation for the master branch can be found on the [Wiki](https://github.com/Edirom/WeGA-WebApp/wiki).


License
-------

This work is available under dual license: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause) and [Creative Commons Attribution 3.0 Unported License (CC BY 3.0)](http://creativecommons.org/licenses/by/3.0/)
