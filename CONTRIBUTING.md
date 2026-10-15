# Contributing to WeGA-WebApp

Thanks for your interest. This document describes how development on the WeGA WebApp
actually works today, distilled from the repository itself. Coding conventions are in
[STYLEGUIDE.md](STYLEGUIDE.md).

## Where to start

- **Bugs and feature requests**: open an issue at
  https://github.com/Edirom/WeGA-WebApp/issues. Issues and PRs are added to the project
  board automatically.
- **Questions about the data**: the app is tailor-made for the WeGA TEI/MEI data. The
  schemata live in [WeGA-ODD](https://github.com/Edirom/WeGA-ODD); sample data is attached
  to each [release](https://github.com/Edirom/WeGA-WebApp/releases).
- **Shared XQuery code** used by other Edirom apps lives in
  [WeGA-WebApp-lib](https://github.com/Edirom/WeGA-WebApp-lib), not here.
- **User documentation** (installation, features, API) lives in [`docs/`](docs/) and is
  published with GitHub Pages at https://edirom.github.io/WeGA-WebApp/. Edit the Markdown
  there; no build step is needed.

## Branches

| Branch | Purpose |
|---|---|
| `main` | stable, the current release |
| `develop` | integration branch, target for all pull requests |
| topic branches | named after the issue (`issue-294`, `697-internal-link-text-…`) or the feature (`facets-rewrite`, `sources-04-toc`) |

Large features are split into a numbered series of small branches/PRs
(`sources-01-stability` … `sources-06-hands`) that are merged one after another.

## Pull requests

1. Branch off `develop`.
2. Keep commits small and focused; see commit style below.
3. Run the tests locally (see below) and update expected results if your change
   intentionally alters HTML output. Commit those updates separately
   (`update expected results`).
4. Open the PR against `develop`. Reference the issue it closes.
5. Dependency bumps come from Dependabot (npm, GitHub Actions, Docker; weekly) and are
   merged as-is after CI passes.

### Commit messages

- Imperative mood, lower-case start, no trailing period:
  `add nested source toc`, `prevent unnecessary source editorial span`
- One logical change per commit; subject ≤ 72 characters.
- Name XQuery functions with arity in backticks when they are the subject:
  `` make `lang:translate` wrapping optional ``, `` add function `bt:normalize-hrefs#1` ``
- A body is optional; use it for the *why*, or to reference an issue (`#205`).

## Development setup

Prerequisites: Java 11+, Apache Ant, Saxon HE on Ant's classpath for the test targets
(`ant -lib /usr/share/java` on Debian), Node ≥ 24, Yarn Classic, and a running eXist-db
≥ 5.3.1 with `functx`, the eXist HTML templating library and `WeGA-WebApp-lib` installed.
The `Dockerfile` is the authoritative build recipe.

```bash
cp build.properties local.build.properties   # edit paths/credentials there, never in build.properties
ant                                           # → build/WeGA-WebApp-<version>.xar
```

Install the xar together with a `WeGA-data-*.xar` via the eXist dashboard. Runtime options
(data collection path, environment, …) live in `catalogues/options.xml` and can be
overridden with `WEGA_WEBAPP_<option>` environment variables at install time
(see `post-install.xql`).

What goes where:

| You changed | Required step |
|---|---|
| `modules/`, `templates/`, `xsl/`, `catalogues/`, `api/*.xql` | upload the file into `/db/apps/WeGA-WebApp/…` |
| `resources/sass`, `resources/js`, `package.json`, `api/v1/openapi*` | `ant` (Sass, webpack, OpenAPI bundle) and reinstall |
| `indices/`, `pre-install.xql`, `post-install.xql` | reinstall the xar |

Do not commit build output: `dist/`, `build/`, `tmp/`, `libs/`, `node_modules/`,
`expath-pkg.xml`, `resources/css/styles.css` and `local.build.properties` are ignored.

### Editor setup

Indentation, encoding and line endings are defined in `.editorconfig`.

- **VS Code**: install the [EditorConfig extension](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig); nothing else to configure.
- **Oxygen XML Editor** does not read `.editorconfig`. Set *Preferences → Editor → Format*
  to indent with 4 spaces and enable *Detect indentation on open*.

## Tests

CI (`.github/workflows/docker-testing.yml`) builds the Docker image and runs
`ant test` against it on every push. Locally you need the app running on
`localhost:8080` with the `WeGA-data-testing` package (see `Dockerfile` for the URL),
then:

```bash
ant docker_run          # optional: build + start the test container
ant test                # xqsuite unit tests + HTML regression tests
ant check-html          # validate expected results with the Nu HTML checker
```

Two kinds of tests exist:

- **XQSuite unit tests** in `testing/xqsuite/*-tests.xqm`. New test modules must be
  imported and listed in `run-unit-tests.xql`.
- **HTML regression tests**: `testing/urls/<docType>.txt` lists pages, their HTML is
  curled, flattened with `testing/flatten.xsl` and diffed against
  `testing/expected-results/<docType>/`. Any difference fails the build.

When a change intentionally alters output, regenerate the snapshots with the container
running and review the diff before committing:

```bash
ant -DdocType=letters reset-expected-results   # one document type
ant reset-all-expected-results                 # everything
```

Add new test pages by appending a URL to the matching `testing/urls/*.txt` and resetting
that doc type. New document types need an entry in `build.xml` (`test`) and
`testing/ant-testing.xml` (`reset-all-expected-results`).

## Releases

Maintainers only. Version numbers follow semver and appear in three places that must
stay in sync: `build.properties` (`project.version`), `package.json` and `CITATION.cff`.
Development versions carry an `-alpha` suffix. Tag as `vX.Y.Z`, merge `develop` into
`main`, attach the built xar to the GitHub release, and update the
[Changelog on the wiki](https://github.com/Edirom/WeGA-WebApp/wiki/Changelog).
`CITATION.cff` also lists contributors; add yourself with your first substantial PR.

## License

Contributions are accepted under the project's dual license, BSD 2-Clause and CC BY 4.0
(see `LICENSE`).
