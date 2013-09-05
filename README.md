WeGA WebApp
===========

This web application is written in XQuery on top of an [eXist-db](http://exist-db.org) and powers [www.weber-gesamtausgabe.de](http://www.weber-gesamtausgabe.de). Needless to say the code is tailor-made to fit our data (see `example-data` and the corresponding [TEI ODD schemata](https://github.com/Edirom/WeGA-ODD)) but can hopefully serve as a starting point for likewise ventures.

It is especially _not_ yet designed as an eXist app package but is supposed to run as the only eXist application within one eXist installation.

Prerequisites
-------------

1. [eXist-db](http://exist-db.org/) v1.4.3 (other versions should work, but may need some adjustements) 
2. [Digilib Image Server](http://developer.berlios.de/projects/digilib/) v1.8.3: All processing of images (except icons under `/webapp/pix`) is done via Digilib. Well, if you don't need images, you don't need Digilib. Also, the exact version shouldn't be crucial.


Quick start guide
-----------------

1. Configure eXist
2. Set up Digilib
3. Upload directory `/webapp` to the eXist database root collection
4. Copy content of `/exist-indices/db` to the eXist database `/db/system/config/db` collection
5. Upload directories from `/example-data` to the eXist database root collection
6. Make all newly created collections readable for "guest" and the XQueries executable by user "guest". Create a database collection `tmp` under `/db/webapp` and set group and owner to "guest" – or use the helper script `scripts/setPermissions.xql`
7. Direct your browser to `http://localhost:8080`


Branches
--------
* `master` our stable branch, based on eXist 2.1
* `develop` our development branch
* `foundation-templating-dev` a complete rework of the WeGA-WebApp which will feature a responsive web design (built with foundation) and will adhere to the eXist templating and app packaging.


Documentation
-------------

(Sparse) Documentation for the master branch can be found on the [Wiki](https://github.com/Edirom/WeGA-WebApp/wiki).


License
-------

This work is licensed under a [Creative Commons Attribution 3.0 Unported License (CC BY 3.0)](http://creativecommons.org/licenses/by/3.0/)