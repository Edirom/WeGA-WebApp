## What

<!-- one or two sentences; link the issue: closes #123 -->

## Checklist

- [ ] Branched off `develop`, PR targets `develop`
- [ ] `ant test` passes locally (or CI is green)
- [ ] Changed HTML output → expected results regenerated, diff reviewed, committed separately (`update expected results`)
- [ ] New UI strings added to **both** `catalogues/dictionary_de.xml` and `dictionary_en.xml`
- [ ] New XQuery functions follow [STYLEGUIDE.md](https://github.com/Edirom/WeGA-WebApp/blob/develop/STYLEGUIDE.md) (kebab-case, typed signature, xqDoc comment)
- [ ] No generated files committed (`dist/`, `build/`, `libs/`, `resources/css/styles.css`, `expath-pkg.xml`)
- [ ] First substantial contribution → added yourself to `CITATION.cff`
