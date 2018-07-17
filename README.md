WeGA WebApp
===========

This web application is written in XQuery on top of an [eXist-db](http://exist-db.org) and powers [www.weber-gesamtausgabe.de](http://www.weber-gesamtausgabe.de). Needless to say the code is tailor-made to fit our data (see `example-data` and the corresponding [TEI ODD schemata](https://github.com/Edirom/WeGA-ODD)) but can hopefully serve as a starting point for likewise ventures.

Since version 1.2 the WeGA-WebApp is designed as an eXist app package and should happily live together with other installed apps.


Prerequisites
-------------

A recent [eXist-db](http://exist-db.org/) with support for XQuery 3.1 (!)

NB: Due to a regression in the eXist-db code (https://github.com/eXist-db/exist/issues/1550) we currently need to stick to eXist-db version 3.3.0!


Quick start guide
-----------------

If you have a running eXist database you can simply install the WeGA-data-samples.xar  as well as the WeGA-WebApp.xar from the [Release section](https://github.com/Edirom/WeGA-WebApp/releases) via the eXist-Dashboard.

### Dependencies on other eXist apps/libs
* `functx` [http://www.functx.com](http://www.xqueryfunctions.com), installable via dashboard
* `WeGA-WebApp-lib`, get it from [https://github.com/Edirom/WeGA-WebApp-lib](https://github.com/Edirom/WeGA-WebApp-lib)



Branches
--------
* `master` our stable branch, i.e. the current release version
* `develop` our development branch
* other branches are experimental and and will get merged (or just some features) into develop at some point


Documentation
-------------

(Sparse) Documentation can be found on the [Wiki](https://github.com/Edirom/WeGA-WebApp/wiki) as well as the [changelog](https://github.com/Edirom/WeGA-WebApp/wiki/Changelog).


License
-------

This work is available under dual license: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause) and [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)
