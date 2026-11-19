# Adding the date range widget to a GBC customization

`fglpkg install fgldaterange` puts the BDL library on `FGLLDPATH` (through `fglpkg env`), but
a Genero Browser Client customization is built from source, so fglpkg cannot install the GBC
half for you. The widget ships in the package as plain files under `gbc/`. Do these steps
once per GBC customization.

You can read this page again at any time with `fglpkg docs fgldaterange GBC-SETUP.md`.

## 1. Find the installed files

| Install | Directory |
| ------- | --------- |
| Project (the project has a `fglpkg.json`) | `.fglpkg/packages/fgldaterange/gbc/` |
| Global, `FGLDIR` set and writable | `$FGLDIR/fglpkg/packages/fgldaterange/gbc/` |
| Global, otherwise | `~/.fglpkg/packages/fgldaterange/gbc/` |

It holds two folders: `js/daterange/` (the widget) and `vendor/daterange/` (jQuery and
daterangepicker, unmodified).

## 2. Copy both folders into the customization

Keep their place: the widget imports its libraries as `../../vendor/daterange`. For a
customization `customization/acme` in a GBC project:

```
PKG=.fglpkg/packages/fgldaterange/gbc
cp -R $PKG/js/daterange     <gbc-project>/customization/acme/js/
cp -R $PKG/vendor/daterange <gbc-project>/customization/acme/vendor/
```

## 3. Import the stylesheet

Add one line to `customization/acme/sass/customization.scss`:

```scss
@import "../js/daterange/DateRangeWidget";
```

GBC exposes its theme values only as Sass variables, so the popup is compiled with the
customization's own theme.

## 4. Build with Vite

From the GBC project root:

```
gbc build --customization customization/acme --vite
```

The widget is made of ES modules, so the legacy pipeline (`gbc build` without `--vite`) cannot
build it. No npm install is needed in the customization: the libraries are vendored, and the
widget uses the moment.js every GBC 6 project already has (`npm ci` at the GBC project root).

## 5. Use it

Select the customization in the application's `.xcf` (`<GBC>acme</GBC>`) or in the URL
(`?gbc=acme`). In the application, a 4ST style sets the `customWidget` attribute, and the
form field uses that style:

```xml
<Style name="Edit.dateRange">
  <StyleAttribute name="customWidget" value="dateRange" />
</Style>
<Style name="Label.dateRange">
  <StyleAttribute name="customWidget" value="dateRange" />
</Style>
```

```
EDIT cPeriod = FORMONLY.period TYPE VARCHAR, STYLE = "dateRange", SCROLL;
```

`SCROLL` is required on a field that a dialog edits, because of the JSON value. The package
README describes the style attributes, the statements the widget works in, and the BDL helper.
