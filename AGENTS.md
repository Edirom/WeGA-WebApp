# AGENTS.md

Entry point for AI coding agents working in this repository. Humans: start with
[CONTRIBUTING.md](CONTRIBUTING.md). Keep this file short; details live in the files it links.

## What this is

- XQuery 3.1 web application on eXist-db (≥ 5.3.1) rendering the TEI/MEI data of the
  Complete Works of Carl Maria von Weber (https://weber-gesamtausgabe.de).
- The data is a separate eXist package (`WeGA-data`, `WeGA-data-testing` for tests);
  its path is the `dataCollectionPath` option in `catalogues/options.xml`.
- Shared XQuery code lives in [WeGA-WebApp-lib](https://github.com/Edirom/WeGA-WebApp-lib)
  and is imported by absolute DB path. The minimum lib version is pinned in `expath-pkg.xml.tmpl`.

## Where things are

| Path | Purpose |
|---|---|
| `controller.xql` → `modules/controller.xqm` | URL routing, forwarding, redirects |
| `modules/wdt.xqm` | document types as maps of closures — the central abstraction |
| `modules/app.xqm` | templating functions called from HTML via `data-template` |
| `modules/config.xqm` | options, paths, environment (`config:get-option`) |
| `modules/api.xqm`, `api/v1/` | REST API; OpenAPI spec split into `paths/`, `schemas/`, `parameters/` |
| `templates/` | eXist HTML-templating pages; `ajax/` fragments, `includes/`, `dev/` |
| `xsl/` | TEI → HTML, one stylesheet per document type, called via `wega-util:transform` |
| `catalogues/` | `options.xml`, `dictionary_de.xml` / `dictionary_en.xml`, URL mappings |
| `indices/` | index definitions, applied only on package install |
| `resources/sass/`, `resources/js/` | sources for CSS and the webpack bundle |
| `testing/` | XQSuite unit tests, regression URL lists, expected results |

## Read before changing anything

- [CONTRIBUTING.md](CONTRIBUTING.md) — branches, pull requests, development setup, tests, releases.
- [STYLEGUIDE.md](STYLEGUIDE.md) — naming, file layout, templates, Sass, JS, test conventions.

## Things that go wrong regularly

- **Generated paths are never edited**: `build/`, `dist/`, `tmp/`, `libs/`, `guidelines/`,
  `resources/css/styles.css`, `expath-pkg.xml`. Edit the sources and rebuild.
- **The build hides two failures.** The `sass` and `swagger-cli` Ant targets do not fail the
  build. After `ant`, check that `dist/resources/css/styles.css` and
  `dist/api/v1/openapi.json` exist.
- **Any change to rendered HTML breaks the regression tests.** Regenerate the affected
  expected results (`ant -DdocType=<type> reset-expected-results`), read the diff, and commit
  it separately from the code change.
- **UI strings need both dictionaries.** A key missing from `dictionary_de.xml` or
  `dictionary_en.xml` only logs a warning, so the page looks fine and the string is silently empty.
- **Templates must be well-formed XHTML.** eXist refuses to parse anything else.
- **Check WeGA-WebApp-lib before writing a new templating function.** `app-shared:print`,
  `app-shared:if-matches`, `app-shared:each` and friends cover most cases.
- **Do not rename, reformat or translate old code as a side effect.** Older camelCase
  functions and German comments stay as they are; new code follows STYLEGUIDE.md.
- **A new document type touches many places**: a `wdt:` function, templates, `testing/urls/`,
  expected results, the `test` target in `build.xml` and `testing/ant-testing.xml`.

## Verifying a change

```bash
ant                 # builds build/WeGA-WebApp-<version>.xar
ant xqsuite         # unit tests, needs the app running on localhost:8080
ant test            # unit + HTML regression tests, same requirement
```

See CONTRIBUTING.md for how to get the app running on `localhost:8080`.
