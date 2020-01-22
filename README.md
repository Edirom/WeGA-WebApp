<a href="https://weber-gesamtausgabe.de/" style="float:right;">
<img alt="WeGA Logo" src="https://github.com/Edirom/WeGA-WebApp/raw/develop/resources/img/logo_weber.png"/>
</a>

# WeGA WebApp

[![](https://img.shields.io/badge/license-BSD2-green.svg)](https://github.com/Edirom/WeGA-WebApp/blob/develop/LICENSE)
[![](https://img.shields.io/badge/license-CC--BY--4.0-green.svg)](https://github.com/Edirom/WeGA-WebApp/blob/develop/LICENSE)
[![GitHub release](https://img.shields.io/github/release/edirom/WeGA-WebApp.svg)](https://github.com/Edirom/WeGA-WebApp/releases)
[![DOI](https://zenodo.org/badge/7872550.svg)](https://zenodo.org/badge/latestdoi/7872550)
[![Build Status](https://travis-ci.com/Edirom/WeGA-WebApp.svg?branch=develop)](https://travis-ci.com/Edirom/WeGA-WebApp)

This web application is written in XQuery on top of an [eXist-db](http://exist-db.org) and powers [www.weber-gesamtausgabe.de](http://www.weber-gesamtausgabe.de). Needless to say the code is tailor-made to fit our data (see `example-data` and the corresponding [TEI ODD schemata](https://github.com/Edirom/WeGA-ODD)) but can hopefully serve as a starting point for likewise ventures.

Since version 1.2 the WeGA-WebApp is designed as an eXist app package and should happily live together with other installed apps.


## Prerequisites

A recent [eXist-db](http://exist-db.org/) with support for XQuery 3.1 (!)

NB: Due to a regression in the eXist-db code ([1550](https://github.com/eXist-db/exist/issues/1550), [2678](https://github.com/eXist-db/exist/issues/2678), [2779](https://github.com/eXist-db/exist/issues/2779)) we currently need to stick to eXist-db version 3.3.0!


## Quick start guide

If you have a running eXist database you can simply install the `WeGA-data-samples.xar` as well as the `WeGA-WebApp.xar` from the [Release section](https://github.com/Edirom/WeGA-WebApp/releases) via the eXist-Dashboard.


### Dependencies on other eXist apps/libs
* `functx` [http://www.functx.com](http://www.xqueryfunctions.com), installable via dashboard
* `WeGA-WebApp-lib`, get it from [https://github.com/Edirom/WeGA-WebApp-lib](https://github.com/Edirom/WeGA-WebApp-lib)


## Branches

* `master`: our stable branch, i.e. the current release version
* `develop`: our development branch
* other branches are experimental and and will get merged (or just some features) into develop at some point


## How to build

The 
[Dockerfile](https://github.com/Edirom/WeGA-WebApp/blob/develop/Dockerfile) describes all the necessary steps to build the WeGA-WebApp EXPath xar package. In essence, it boils down to 

* installing [Apache Ant](https://ant.apache.org), [Saxon](https://www.saxonica.com), [NodeJS](https://www.npmjs.com) and [Yarn](https://yarnpkg.com)
* running `ant` from the repository root


## Documentation

(Sparse) Documentation can be found on the [Wiki](https://github.com/Edirom/WeGA-WebApp/wiki) as well as the [changelog](https://github.com/Edirom/WeGA-WebApp/wiki/Changelog).


## License

This work is available under dual license: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause) and [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)
