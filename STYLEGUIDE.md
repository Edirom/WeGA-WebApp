# WeGA-WebApp Style Guide

Conventions observed in the codebase. Where old and new code disagree, the rule below
follows the newer code; do not reformat, rename or translate old code just to comply —
such changes only as deliberate, separate commits.

## General

- Indentation: **4 spaces**, no tabs (a few older Sass and HTML files still use tabs).
- Encoding UTF-8, Unix line endings.
- Code, comments, commit messages and documentation in **English**. Only the two
  dictionaries in `catalogues/` and user-facing strings are localised.
- No trailing whitespace; one blank line between top-level declarations.

## XQuery (`modules/*.xqm`, `*.xql`)

### File layout

```xquery
xquery version "3.1" encoding "UTF-8";

(:~
 : One-line description of the module
 :)
module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util";

declare namespace tei="http://www.tei-c.org/ns/1.0";          (: 1. plain namespace declarations :)
…
import module namespace functx="http://www.functx.com";       (: 2. external libs :)
import module namespace config="…/modules/config" at "config.xqm";                  (: 3. own modules :)
import module namespace str="…/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";  (: 4. WeGA-WebApp-lib :)
```

- Module namespace URIs follow `http://xquery.weber-gesamtausgabe.de/modules/<name>`;
  the prefix equals the file name (`wega-util.xqm` → `wega-util:`). Short prefixes are
  acceptable when established (`er` for `external-requests`, `gl` for guidelines).
- Modules from WeGA-WebApp-lib are always imported via the absolute `xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/…` path.
- Group related functions with a banner comment:

```xquery
(:
 : ****************************
 : Generic functions
 : ****************************
:)
```

### Functions

- **Every function gets an xqDoc comment** with `@param` for each parameter and
  `@return`. `@author` is customary, `@see` and `@version` optional.

```xquery
(:~
 : Creates an xhtml:a link to a WeGA document
 :
 : @author Peter Stadler
 : @param $doc the document to create the link for
 : @param $lang the language switch (en, de)
 : @return an xhtml:a element
 :)
declare function app:create-doc-link($doc as document-node()?, $lang as xs:string) as element(xhtml:a) {
```

- Names are **lower-case kebab-case**: `wega-util:inject-version-info`,
  `er:cached-external-request`. Older functions are camelCase
  (`app:createDocLink`, `bibl:printCitation`); keep them, but do not add new ones.
  Exception: API functions mirror their OpenAPI path file, e.g.
  `api:documents-findByAuthor` ↔ `api/v1/openapi/paths/documents-findByAuthor.yaml`.
- Always declare parameter and return types (`as xs:string`, `as element(xhtml:span)*`).
- Internal helpers are `declare %private function`.
- Templating functions (called from HTML via `data-template`) take
  `($node as node(), $model as map(*), …)` and return a map or nodes. Use the
  `%templates:wrap` and `%templates:default("param", "value")` annotations instead of
  handling defaults in the body; most live in `app.xqm` or the topical module.
- Refer to functions by name and arity in comments and commits: `er:cached-external-request#2`.

### Variables

- Module variables are kebab-case: `$config:app-root`, `$img:portrait-max-width`.
- Error codes are UPPER_SNAKE: `$api:INVALID_PARAMETER`.
- Local variables are short and lower-case: `$doc`, `$lang`, `$node`, `$model`.
- Always type module variables: `declare variable $config:app-root as xs:string := …;`

### Expressions

- Prefer **single quotes** for string literals; double quotes only when the string
  contains an apostrophe or for namespace URIs in declarations.
- Maps use the `map { 'key' : value }` form with a space around the colon; look up with
  `$model?key`.
- `if(…) then … else …` without a space before the parenthesis; multi-branch
  `else if` chains are aligned at the same indentation level, one branch per line.
- Use `typeswitch` for node-type dispatch, `switch` for string dispatch.
- Comments inside code are `(: lower-case sentence :)`, placed on their own line above
  the expression or at the end of a short line.
- Logging goes through `wega-util:log-to-file($priority, $message)` with priorities
  `debug | info | warn | error`. Do not use `util:log` directly.
- Configuration values come from `config:get-option('key')`, never hard-coded paths.
- Translations come from `lang:get-language-string('key', $lang)`; add the key to both
  `catalogues/dictionary_de.xml` and `dictionary_en.xml` in the same commit.

## XSLT (`xsl/*.xsl`)

- XSLT 2.0, output `method="html"`, `indent="no"`; one stylesheet per document type
  (`letters.xsl`, `sources.xsl`), shared code in `common_*.xsl` included from `common_main.xsl`.
- Default namespace is XHTML; TEI/MEI are prefixed `tei:`/`mei:`.
- Stylesheet functions live in the `wega:` namespace
  (`http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities`) and are
  kebab-case; legacy camelCase names (`wega:getOption`) are kept.
- Mode names are short nouns: `apparatus`, `lemma`, `verbatim`, `source-toc`.
- Parameters passed from XQuery (`lang`, `docID`, `environment`, …) are declared as
  `<xsl:param>` at the top of each stylesheet that uses them, after the global variables.

## HTML templates (`templates/`)

- Valid XHTML, self-closing void elements (`<meta … />`).
- All dynamic content goes through eXist HTML templating attributes:
  `data-template="prefix:function"` plus `data-template-key`, `data-template-attr`, …
  Prefer the generic helpers from WeGA-WebApp-lib (`app-shared:print`,
  `app-shared:if-matches`, `app-shared:each`) over new one-off functions.
- Every visible string is wrapped for translation: `<span data-template="lang:translate">key</span>`.
- Fragments loaded via AJAX live in `templates/ajax/`, shared includes in `templates/includes/`,
  development-only pages in `templates/dev/`.
- Static resources are referenced as `$resources/…`; the controller rewrites the path.

## Sass (`resources/sass/`)

- Single entry point `main.scss`; partials start with `_` and are sorted into
  `base/`, `layout/`, `components/`, `pages/`. Variables only in `base/_variables.scss`.
- Bootstrap 4 is imported module by module; override its variables, do not patch its
  files. Font Awesome is loaded with `@use`.
- Class names are lower-case with hyphens for new code (`.source-toc`); existing
  camelCase classes generated from TEI (`.tei_hi_italic`, `.secLevel1`) stay.
- Line comments `//` for notes, block comments only where they must survive compilation.

## JavaScript (`resources/js/`)

- ES modules (`"type": "module"`), bundled by webpack from `init.js` (site) and
  `swagger.js` (API docs). Third-party code is pulled in via npm, not vendored, except
  `jquery.loadmask.js` and `greedynav.js`.
- New code: `const`/`let`, arrow functions, template literals, JSDoc on exported
  functions (see `wega-common.js`). Legacy jQuery plugins (`$.fn.…`) in `init.js`
  are kept as they are.
- Single quotes and semicolons in new code (older code in `init.js` is inconsistent).

## Tests (`testing/`)

- XQSuite modules are named `<topic>-tests.xqm` with namespace
  `http://weber-gesamtausgabe.de/xqsuite/<topic>-tests` and a short prefix (`bt`, `wdtt`).
- Test functions are `prefix:test-<function-under-test>`; each case is one
  `%test:args(…)  %test:assertEquals(…)` pair, aligned in columns.
- Prefer `%test:assertEmpty` / `%test:assertEquals` over `%test:assertXPath`.

## OpenAPI (`api/v1/`)

- The spec is split: `openapi.yaml` references one file per path in `openapi/paths/`
  and shared responses in `openapi/responses/`. Ant bundles it to `dist/api/v1/openapi.json`.
- Name the path file after the implementing XQuery function where possible
  (`code-findByElement.yaml` ↔ `api:code-findByElement`); the API functions keep camelCase
  for the operation part because it is mirrored in the public URL.
