# fgldaterange

A date range field for Genero BDL applications running in the Genero Browser Client (GBC 6).
The user picks a range in a [daterangepicker](https://www.daterangepicker.com/) popup (two
calendars and predefined ranges) or types it. The field shows readable dates
(`11/01/2026 - 11/30/2026`), and the value exchanged with the program is JSON:

```json
{"startDate":"2026-11-01","endDate":"2026-11-30"}
```

It supports `INPUT`, `CONSTRUCT`, `DISPLAY`, `DISPLAY ARRAY` and `INPUT ARRAY`; "Status" below
says what has been tested.

fglpkg package `fgldaterange`. The BDL side is built and tested with Genero BDL 6.00.03. The
widget builds on GBC 6.00.04, 6.00.07 and 6.00.09, and the current code has not yet been run in a
browser: see "Status".

## What is in the package

| Folder | What it is |
| ------ | ---------- |
| `com/fourjs/fgldaterange/` | `DateRangeHelper`: the `tDateRange` record and the methods that read and write the field value in BDL |
| `gbc/` | The GBC widget, ready to drop into a GBC customization |
| `examples/` | A demo application with the date range in each of the five statements, with its fglunit tests and its 4js-fgltest functional tests |
| `tests/` | fglunit tests of the helper |

`fglpkg install fgldaterange` ships the compiled helper and the `gbc/` folder. The examples and
tests stay in the repository.

## Install

In an application with a `fglpkg.json`:

```
fglpkg install fgldaterange
eval "$(fglpkg env)"            # puts the package on FGLLDPATH
```

```4gl
IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper
```

The BDL half is then ready. The GBC half is not: a GBC customization is built from source, and
fglpkg's hooks run only from the consuming project's own manifest and cannot print a message, so
the package cannot install the widget or tell you to. Do the steps in
[GBC-SETUP.md](GBC-SETUP.md) once per GBC customization. It is shipped with the package: read it
with `fglpkg docs fgldaterange GBC-SETUP.md`.

## The GBC widget

### Adding it to a customization

In short (see [GBC-SETUP.md](GBC-SETUP.md) for where fglpkg puts the files): copy both folders
of `gbc/` into the customization, keeping their place, add one line to its stylesheet, and
build with Vite:

```
cp -R <package>/gbc/js/daterange     <gbc-project>/customization/acme/js/
cp -R <package>/gbc/vendor/daterange <gbc-project>/customization/acme/vendor/
```

```scss
// customization/acme/sass/customization.scss
@import "../js/daterange/DateRangeWidget";
```

```
gbc build --customization customization/acme --vite
```

Nothing else: the build picks up every `.js` and `.tpl.html` under `js/`, the libraries need no
npm install in the customization, and the texts need no entry in its locale files. The
stylesheet has to be imported because GBC exposes its theme values only as Sass variables, so
the popup is compiled with the customization's own theme. moment.js is not vendored: the widget
uses the copy every GBC 6 project already has in its `node_modules` (installed by `npm ci` at
the project root, which any GBC build needs).

The two folders keep their relative place because the code refers to the libraries as
`../../vendor/daterange`. The libraries must stay outside `js/`: the build imports every `.js`
file under `js/` at startup.

**Vite only.** The legacy pipeline (`gbc build` without `--vite`, still the default in 6.00.09)
pastes customization files into `gbc.js` as one plain script. The widget is made of ES modules,
so its `import` and `export` statements make that script fail to parse, and the whole GBC fails
to load.

### GBC versions

The same files work in two generations of GBC, with no choice for you to make:

- GBC 6.00.07 and 6.00.09, where classes are written with jsface (`context.oo.Class`) inside
  `modulum(...)` modules.
- A GBC where jsface and `modulum` are removed and classes are native ES6 classes declared with
  `context.declare` (the 6.00.04 tree).

`DateRangeGbcApi.js` is the only file that knows the difference: it picks the generation at run
time (`typeof modulum === "function"`) and creates each class the way that GBC expects.
`DateRangeWidget.js` is written once, against it. The two cannot be separate files, because the
build imports every `.js` under `js/` and the wrong one would fail to load.

It builds on GBC 6.00.04, 6.00.07 and 6.00.09. The built widget has been loaded in a browser on
**none** of them yet: see "Status".

### Using it in a form

1. A 4ST style sets the `customWidget` attribute, as for TagEdit
   (`examples/DateRangeDemo.4st` has ready-made styles):

   ```xml
   <Style name="Edit.dateRange">
     <StyleAttribute name="customWidget" value="dateRange" />
   </Style>
   <Style name="Label.dateRange">
     <StyleAttribute name="customWidget" value="dateRange" />
   </Style>
   ```

2. The field uses the style **and `SCROLL`**:

   ```
   EDIT cPeriod = FORMONLY.period TYPE VARCHAR, STYLE = "dateRange", SCROLL;
   ```

   `SCROLL` is required on a field that a dialog edits (`INPUT`, `INPUT ARRAY`). The JSON value
   is 49 characters, and without `SCROLL` the runtime cuts it to the field width before the GBC
   receives it, so the widget gets `{"startDate":"2026-11-01","e` and shows that text, and the
   user cannot type more than the width. The program variable is a `STRING`. A field that is only
   displayed (`DISPLAY`, `DISPLAY ARRAY`) is not cut, and does not need it. A CONSTRUCT field is
   different, see below.

3. BDL reads and writes the value with `DateRangeHelper` (see "The BDL helper").

An empty field is an empty value. Text that is not a range (the user typed `next week`) reaches
the program as typed, and BDL rejects it.

| 4ST attribute      | Effect                                                                 |
| ------------------ | ---------------------------------------------------------------------- |
| `customWidget`     | `dateRange` turns an EDIT, or a LABEL, into the widget                 |
| `dateRangeFormat`  | display format in moment.js tokens (`DD/MM/YYYY`, `YYYY-MM-DD`, ...). Default: the short numeric date of the GBC language (`MM/DD/YYYY` in en-US, `DD/MM/YYYY` in fr-FR). Set it to match `DBDATE`; in a CONSTRUCT it must |
| `dateRangePresets` | `no` hides the predefined ranges (Today, Yesterday, Last 7 days, Last 30 days, This month, Last month) |

### Where it works

| Statement | Field | What the widget does |
| --------- | ----- | -------------------- |
| `INPUT`, `INPUT BY NAME` | EDIT, `VARCHAR`, `SCROLL` | The full widget. The value is the JSON. |
| `DISPLAY`, `DISPLAY BY NAME` | EDIT with `NOENTRY`, or a LABEL | Shows the formatted range. Never opens the popup. |
| `DISPLAY ARRAY` | table column | A LABEL cell: the formatted range. |
| `INPUT ARRAY` | table column | An EDIT cell in the current row, the formatted range in the others. |
| `CONSTRUCT` | EDIT bound to a `DATE` | The popup, and a range typed by hand. The value is **not** JSON, see below. |

**CONSTRUCT.** The runtime builds the SQL condition itself from what the field holds, as
criteria for a `DATE`, so the widget sends the range in the runtime's own syntax,
`date1:date2`, in the display format, and the program never reads JSON:

- The field shows `11/01/2026 - 11/30/2026`, and sends `11/01/2026:11/30/2026`. The display
  format must match the `DBDATE` of the program (`MM/DD/YYYY` for `MDY4/`): set `dateRangeFormat`.
- Anything the user types that is not a `start - end` range reaches the runtime exactly as typed:
  `>=11/01/2026`, `*`, a single date, a `date1:date2` range, `|` lists. The runtime itself accepts
  `date1:date2` (also with spaces around the colon), a single date and comparisons, and refuses
  `date1 - date2`, ISO dates, and an open range (`date1:`) with "Error in field": this is why
  the widget converts `start - end` before it reaches the runtime.
- A `date1:date2` value arriving from the program is shown as `date1 - date2`.
- The field is bound to the `DATE` it searches (`FORMONLY.searchDate TYPE DATE`, or the column)
  and is not `SCROLL`; make it wide enough for 21 characters.

```4gl
CONSTRUCT whereText ON orders.orderdate, orders.customer FROM searchDate, searchCustomer
```

`examples/ConstructDemoController.4gl` is a complete search screen.

### Behaviour

- **Opening.** A click opens the popup, and so does Alt+Down. Focus alone does not, so the popup
  does not appear when a dialog starts or `NEXT FIELD` moves there. It opens only while the field
  can be edited. In an `INPUT ARRAY`, only the current row's cell is enabled, so the first click
  on another row moves the focus and a second click opens the popup.
- **Keyboard while open.** Enter applies, Escape closes without applying (it does not cancel the
  dialog), and Tab applies and moves on. Typing updates the calendar.
- **Typing.** `start - end` in the display format (a dash or an en dash with spaces around it),
  one-digit months and days accepted (`1/5/2026 - 1/20/2026`), or one date for a one-day range.
- **To the program.** A range picked in the popup is sent at once, as a choice in a completer
  is. Typed text is sent when the focus leaves, like any EDIT, which is also when `ON CHANGE`
  fires.
- **In a table.** The popup is attached to the page, not the cell, so it closes when the table
  scrolls. Column autofit, copy, cut, undo and paste use the readable text, never the JSON.
  `AUTONEXT` has no effect on a range.
- **Loading.** jQuery and daterangepicker are downloaded when a form first shows an editable date
  range field, so the first click does not wait for them. An application that never shows one
  never downloads them; a LABEL with the style does not count. If the download fails, the field
  still accepts a typed range, the popup does not open, and the browser console shows the error.
- **Look.** The popup follows the theme: primary colour selection, dark and high-contrast colours,
  and the font size ratio of each theme. It sits at GBC's dropdown level (z-index 58), above modal
  windows and below GBC messages. Day and month names come from the browser's `Intl` API in the
  GBC language.
- **Texts.** Buttons and predefined ranges are built in (`gbc/js/daterange/DateRangeTexts.js`) for
  the seven languages GBC ships: English, German, Spanish, French, Portuguese, Simplified and
  Traditional Chinese. "Apply" and "Cancel" use GBC's own words; the German, Spanish, Portuguese
  and Chinese range names have not yet been reviewed by native speakers. Another language falls
  back to English. A customization overrides a text, or adds a language, in its own
  `locales/<language>.json`:

  ```json
  { "dateRangeWidget": { "apply": "OK", "lastMonth": "Previous month" } }
  ```

  An override applies to the language of that file only: an override in `en-US.json` does not
  replace the built-in German texts.

### Files

- `gbc/js/daterange/DateRangeWidget.js` and `.tpl.html`: `DateRangeWidget` (extends `EditWidget`,
  registered on `Edit[customWidget=dateRange]`), `DateRangeConstructWidget` (extends
  `DummyEditWidget`, on `DummyEdit[customWidget=dateRange]`) and `DateRangeLabelWidget` (on
  `Label[customWidget=dateRange]`). The value stack and `_oldValue` keep the VM form, and only the
  `<input>` holds the readable text, so change detection compares like with like.
- `gbc/js/daterange/DateRangeGbcApi.js`: how a class is created in each GBC generation.
- `gbc/js/daterange/DateRangePickerLoader.js`: loads jQuery and daterangepicker on demand.
- `gbc/js/daterange/DateRangeTexts.js`: the built-in texts.
- `gbc/js/daterange/DateRangeWidget.scss`: inlines the library stylesheet, then themes it.
- `gbc/vendor/daterange/`: the libraries, unmodified, with their provenance, hashes and licenses
  in its `README.md`.

### Libraries

| Package         | Version | Where | Why this one                                                |
| --------------- | ------- | ----- | ----------------------------------------------------------- |
| daterangepicker | 3.1.0   | `gbc/vendor/daterange` | Stable since 2020. 4.0.1 and 4.0.2 appeared on 2026-11-08, after six years without a release: too recent to adopt without reviewing them. They still need jQuery and moment.js |
| jquery          | 3.7.1   | `gbc/vendor/daterange` | daterangepicker 3.x predates jQuery 4, which removed APIs |
| moment          | GBC's   | GBC project `node_modules` | The copy GBC already bundles (2.31.0 in GBC 6.00.09, a peer dependency of pikaday-time), present in every GBC 6 project |

The vendored files are unmodified copies of the npm packages; `gbc/vendor/daterange/README.md`
lists their npm integrity and SHA-256, and how to check or refresh them with `npm pack`.
Vendoring them, instead of installing them with npm in the customization, is what lets the widget
drop into another customization without an npm step. It also rules out a second copy of
moment.js: daterangepicker's own npm dependencies would install one in the customization, where
the widget's `import "moment"` would find it before GBC's.

**Size.** At startup the widget costs only its own code, since moment.js is already in GBC.
jQuery and daterangepicker are fetched on demand, about 42 kB gzipped: `jquery.min.js` (87.5 kB,
30.4 kB gzipped) and `daterangepicker.js` (67.8 kB, 11.5 kB gzipped; the package ships no
minified build). The picker stylesheet adds a few kB to each compiled theme.

**Why they are loaded as scripts.** `DateRangePickerLoader.js` imports the two files with `?url`:
Vite copies each one to `assets/` without bundling it, and the loader runs both with `<script>`
elements when they are first needed. Both download in parallel and run in order. As plain
scripts, these UMD files use their browser-globals path (`window.jQuery`, `window.moment`,
`window.daterangepicker`); the loader restores those globals afterwards, and daterangepicker keeps
the jQuery and moment.js it was given. Bundling them as modules would not work:
daterangepicker's CommonJS branch would `require("jquery")` and `require("moment")` at build time.
And the GBC build (`vite.config.js`, `manualChunks`) puts every module from `node_modules` in the
`third-party` chunk that every application loads at startup, even when it is only reached through
a dynamic `import()`.

### Limits

- Builds with Vite only.
- The calendar has no keyboard navigation (a daterangepicker limit). Keyboard users type the
  range.
- `DATEEDIT` is not covered, in a CONSTRUCT either: only an EDIT takes the style.
- Not tested with a ButtonEdit.
- In a CONSTRUCT the display format must match `DBDATE`, and the field must be wide enough for the
  `date1:date2` text.
- The predefined ranges are computed when a field first opens its popup. A form left open past
  midnight keeps the previous day's "Today" until it is reopened.
- The text GBC puts in a table cell drag is still the JSON.

### Status

What has been checked, and what has not. Read this before relying on the widget.

- **Builds:** `gbc build --vite` succeeds with the widget in GBC 6.00.09, 6.00.07 and 6.00.04.
- **Node checks, not in the repository:** the class definition, in both generations, run against
  GBC's real jsface, `modulum` and `WidgetFactory` code, with stand-ins for the widget base
  classes; the value conversions for INPUT, LABEL and CONSTRUCT.
- **Run against the Genero runtime (the Ghost Client, no browser):** the five example screens
  open and close without a runtime error, and the full 49-character JSON reaches the front end in
  every field and table column of the examples. The CONSTRUCT screen was driven with the syntax
  above: `10/21/2026:11/19/2026` gives `orders.orderdate between '2026-10-21' and
  '2026-11-19'` (14 orders), a single date and `>=date` work, and the runtime keeps in the field
  exactly what was typed. These checks are the 28 tests of `make uitest` (see "Examples"). The
  Ghost Client runs no browser code, so none of this involves the widget.
- **Run in a browser:** the original widget, which handled INPUT and LABEL only, was run on GBC
  6.00.09. The current code has **not** been loaded in a browser on any GBC. That includes the
  CONSTRUCT and table support, the changes to INPUT that came with them (clipboard, undo, no
  autonext), and the 6.00.04 generation: all of it was written from GBC's source.
  [TESTING.md](TESTING.md) is the checklist, and each screen of `examples/` exercises one row of
  "Where it works".

## The BDL helper

`DateRangeHelper` is a leaf module with no UI. `tDateRange` carries the methods, so a program
reads and writes the field value without any conversion code:

```4gl
IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper

VAR period DateRangeHelper.tDateRange
IF period.deserialize(rec.period) THEN          -- fills the range from the field's JSON
   DISPLAY period.startDate, period.endDate, period.days()
END IF
LET rec.period = period.serialize()             -- the JSON the widget shows
```

| Member | What it does |
| ------ | ------------ |
| `tDateRange` | The record: `startDate DATE`, `endDate DATE`. The member names are the JSON keys. |
| `period.serialize()` | The JSON value of the field. `NULL`, which empties the field, when a date is `NULL`. |
| `period.deserialize(jsonText)` | `TRUE` and the range filled, or `FALSE` and an empty range for a `NULL` value, text that is not JSON, or a missing or non-ISO date. |
| `DateRangeHelper.parseDateRange(jsonText)` | The range, or an empty range: for conversions that do not need to know which. |
| `period.isComplete()` | Both dates are set. |
| `period.clear()` | Both dates `NULL`. |
| `period.days()` | Days in the range, both ends included. `NULL` for an incomplete range. |
| `period.contains(checkDate)` | The date is inside the range, both ends included. |
| `period.overlaps(other)` | The two ranges share a day. |

The dates are ISO because that is the format `util.JSON` reads and writes for `DATE`, whatever
`DBDATE` is. `deserialize` has to check: `util.JSON.parse` turns a date it cannot read into NULL
without raising, and a `DATE` declared with `VAR` starts at 1899-12-31, not NULL.

Two things to know about methods in Genero: a method that returns a value cannot be called with
the result thrown away (`-6611`), so write `IF period.deserialize(text) THEN` or
`LET valid = period.deserialize(text)`; and a `DYNAMIC ARRAY` is shared by `LET`, so copy it with
`copyTo`.

## Examples

`examples/` is one application, `MainController` → `MainMenuController`, with a screen for each
statement. It follows the model, view and controller split: a `.per` form, a `<Feature>Model`
and a `<Feature>Controller` for each.

| Menu entry | Feature | Shows |
| ---------- | ------- | ----- |
| Input | `InputDemo` | Two date range fields in an `INPUT BY NAME`, one with `dateRangeFormat` and `dateRangePresets`, and what BDL reads from their JSON |
| Construct | `ConstructDemo` | A search on a `DATE` column with `CONSTRUCT`, the generated condition, and the orders found in a `DISPLAY ARRAY` |
| Display | `DisplayDemo` | A month browser and predefined periods put on the screen with `DISPLAY BY NAME` and `DISPLAY TO`, in EDIT fields with `NOENTRY` and in a LABEL |
| Display array | `ArrayDemo` | Campaigns in a table, with the period as one date range column |
| Input array | `ArrayDemo` | The same table edited: the days column follows the period, and accept saves through the model, which refuses an invalid or overlapping campaign |

The CONSTRUCT example reads a small SQLite database that `make` creates (an empty file; the
example creates and fills its `orders` table). The other examples need no database.

```
cd examples
make                 # every module with fglcomp -Wall -Werror, the forms with fglform -W all
fglpkg install       # once: fglunit and 4js-fgltest, the dev dependencies
make test            # 29 fglunit tests: model rules, conversions, the orders table
make uitest          # 28 functional tests of the running application, through GGC
```

`make uitest` runs `uitests/TestExamplesUi.4gl` with 4js-fgltest. It starts `MainController`
through GGC, the Genero Ghost Client, so there is no browser, and checks what the runtime sends
to the front end and what it takes back: the whole JSON value in every field and column, the
`INPUT` and `INPUT ARRAY` rules, the `CONSTRUCT` criteria the runtime accepts, and the ones it
refuses (`d1 - d2`, ISO dates, open ranges), which is why the widget never sends them. It needs
Java and a GGC. Recent Genero installs have one in `testing_utilities/ggc`, which is the default;
otherwise `make uitest GGCDIR=/path/to/ggc`, a path without a space. It sets `DBDATE=MDY4/` and
runs the application on an empty SQLite file in `bin/uitest/run`, so it never touches
`examples/daterangedemo.db`. Reports and logs are in `bin/uitest/out`. The widget itself is not
involved: that is [TESTING.md](TESTING.md).

Run it through a GAS with a GBC built with the widget (`<GBC>acme</GBC>` in the application
`.xcf`, or `?gbc=acme` in the URL), with `examples/bin` on `FGLLDPATH` and `FGLRESOURCEPATH`,
`FGLPROFILE` set to `examples/fglprofile`, and the application's directory set to `examples/`
(the database file is there). `ui.Interface.loadStyles("DateRangeDemo")` loads
`DateRangeDemo.4st`, the styles of the widget.

## Developing

```
export PATH=<Genero 6>/bin:$PATH   # fglpkg labels the package with the Genero major on PATH
make                 # compile the library, in place
fglpkg install       # once: fglunit (examples/ also needs 4js-fgltest: fglpkg install there)
make test            # 23 fglunit tests of the helper
make examples        # build the example application
make uitest          # 28 functional tests of the examples through GGC, needs Java and a GGC
make check           # fglpkg lint and fglpkg pack --list
```

`make check` shows what a release would contain: the compiled `DateRangeHelper.42m` under
`com/fourjs/fgldaterange/`, the `gbc/` folder, and the docs.

## License

MIT, see `LICENSE`. The vendored jQuery and daterangepicker are MIT licensed too; their
licenses are in `gbc/vendor/daterange/`.
