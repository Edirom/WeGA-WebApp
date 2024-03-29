<a href="https://weber-gesamtausgabe.de/">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Edirom/WeGA-WebApp/raw/develop/resources/img/logo_weber_white.png">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/Edirom/WeGA-WebApp/raw/develop/resources/img/logo_weber.png">
    <img alt="WeGA Logo" src="https://github.com/Edirom/WeGA-WebApp/raw/develop/resources/img/logo_weber.png">
  </picture>
</a>

# WeGA WebApp

[![](https://img.shields.io/badge/license-BSD2-green.svg)](https://github.com/Edirom/WeGA-WebApp/blob/develop/LICENSE)
[![](https://img.shields.io/badge/license-CC--BY--4.0-green.svg)](https://github.com/Edirom/WeGA-WebApp/blob/develop/LICENSE)
[![GitHub release](https://img.shields.io/github/release/edirom/WeGA-WebApp.svg)](https://github.com/Edirom/WeGA-WebApp/releases)
[![DOI](https://zenodo.org/badge/7872550.svg)](https://zenodo.org/badge/latestdoi/7872550)
[![Build Status](https://github.com/Edirom/WeGA-WebApp/actions/workflows/docker-testing.yml/badge.svg)](https://github.com/Edirom/WeGA-WebApp/actions/workflows/docker-testing.yml)

This web application is written in XQuery on top of an [eXist-db](http://exist-db.org) and powers [weber-gesamtausgabe.de](https://weber-gesamtausgabe.de). Needless to say the code is tailor-made to fit our data (see `data-samples` from the [release section](https://github.com/Edirom/WeGA-WebApp/releases) and the corresponding [TEI ODD schemata](https://github.com/Edirom/WeGA-ODD)) but can hopefully serve as a starting point for likewise ventures.


## Prerequisites

A running [eXist-db](http://exist-db.org/), v5.2.0 or newer 


## Quick start guide

If you have a running eXist database you can simply install the `WeGA-data-samples.xar` as well as the `WeGA-WebApp.xar` from the [Release section](https://github.com/Edirom/WeGA-WebApp/releases) via the eXist-Dashboard.


### Dependencies on other eXist apps/libs
* `functx` [http://www.functx.com](http://www.xqueryfunctions.com), available and installable via the eXist dashboard
* `eXist HTML Templating Library` [https://github.com/eXist-db/templating](https://github.com/eXist-db/templating), available and installable via the eXist dashboard
* `WeGA-WebApp-lib`, available from [https://github.com/Edirom/WeGA-WebApp-lib](https://github.com/Edirom/WeGA-WebApp-lib) and installable via the eXist dashboard


## Branches

* `main`: our stable branch, i.e. the current release version
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
