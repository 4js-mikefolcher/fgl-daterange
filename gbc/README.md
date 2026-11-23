# @fourjs/gbc-daterange

A date range field for Genero BDL applications in the Genero Browser Client (GBC 6): one field,
a [daterangepicker](https://www.daterangepicker.com/) popup with two calendars and predefined
ranges, and a JSON value that BDL reads:

```json
{"startDate":"2026-11-01","endDate":"2026-11-30"}
```

This package is the GBC widget. The BDL side, the helper that reads and writes that value, is the
fglpkg package `fgldaterange`. Both come from
[fgl-daterange](https://github.com/4js-mikefolcher/fgl-daterange), whose README describes the
widget in full.

Needs a GBC 6 project built with Vite (`gbc build --vite`). Tested with GBC 6.00.09 and 6.00.10.

## Install it in a customization

The examples use a customization `customization/acme` of a GBC project.

1. Tell npm where the `@fourjs` packages are. Add a file `customization/acme/.npmrc`:

   ```
   @fourjs:registry=https://fourjs.jfrog.io/artifactory/api/npm/gbc-packages/
   ```

   Only the `@fourjs` packages come from there; everything else still comes from npmjs. Your
   Artifactory credentials go in your own `~/.npmrc` (the "Set Me Up" page of the `gbc-packages`
   repository gives the line), never in the customization.

2. Give the customization its own `package.json`, then install the package there. Without one,
   npm uses the `package.json` of the GBC project and adds the package to GBC's own
   dependencies. A minimal one is enough:

   ```json
   { "name": "acme", "private": true }
   ```

   ```
   cd customization/acme
   npm install @fourjs/gbc-daterange
   ```

   npm adds the package to that `package.json` and writes a `package-lock.json` next to it.
   Commit both with the customization, but not `node_modules`.

3. Import the widget from any `.js` file in the customization's `js/` folder, for example a new
   `js/Packages.js`:

   ```js
   import "@fourjs/gbc-daterange";
   ```

4. Import its stylesheet in `sass/customization.scss`:

   ```scss
   @import "@fourjs/gbc-daterange";
   ```

   It has to be compiled there, with the customization's theme: the popup takes its colours and
   sizes from the theme.

5. Build from the GBC project root. A fresh copy of the project needs both installs:

   ```
   npm install                             # GBC's own dependencies (GBC ships no package-lock.json)
   npm ci --prefix customization/acme      # the customization's packages, from its package-lock.json
   gbc build --customization customization/acme --vite
   ```

`npm update` in the customization folder brings a newer version.

## Use it in a form

A 4ST style turns an EDIT (or a LABEL) into the widget, and the field needs `SCROLL`, because the
JSON value is longer than the field:

```xml
<Style name="Edit.dateRange">
  <StyleAttribute name="customWidget" value="dateRange" />
</Style>
```

```
EDIT cPeriod = FORMONLY.period TYPE VARCHAR, STYLE = "dateRange", SCROLL;
```

The `fgldaterange` README covers the style attributes, the dialog statements it works in, and
the BDL helper.

## What it brings

- **No extra download at startup.** jQuery 3.7.1 and daterangepicker 3.1.0 are in the package,
  unmodified (`vendor/daterange/README.md` has their checksums and licenses). The build copies
  them to `assets/`, and the widget downloads them when a form first shows an editable date
  range field, about 42 kB gzipped.
- **moment.js is GBC's own copy.** It is an optional peer dependency, so npm does not install a
  second one.
- **Texts in the seven languages GBC ships.** A customization overrides one, for one language, in
  its `locales/<language>.json`: `{ "dateRangeWidget": { "apply": "OK" } }`.

## Copying the files instead

Without npm, copy `js/daterange/` and `vendor/daterange/` into the customization, keeping their
place, and import the stylesheet with `@import "../js/daterange/DateRangeWidget";`. The fglpkg
package `fgldaterange` ships these two folders under `gbc/`.

## License

MIT. jQuery and daterangepicker are MIT too; their licenses are in `vendor/daterange/`.
