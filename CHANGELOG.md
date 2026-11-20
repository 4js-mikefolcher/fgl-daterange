# Changelog

## [0.1.0] - 2026-11-19

First packaged release.

- GBC widget (`gbc/js/daterange`, `gbc/vendor/daterange`): a date range field with a
  daterangepicker popup, for GBC 6.
- BDL helper `com.fourjs.fgldaterange.DateRangeHelper`: the `tDateRange` record with the
  methods `serialize`, `deserialize`, `isComplete`, `clear`, `days`, `contains` and
  `overlaps`.
- `examples/`: a demo application with the date range in `INPUT`, `CONSTRUCT`, `DISPLAY`,
  `DISPLAY ARRAY` and `INPUT ARRAY`, with its fglunit tests and 28 functional tests
  (4js-fgltest, driving the application through GGC: `make uitest`).
- 23 fglunit tests of the helper (`make test`).
- `make gas` in `examples/`: builds the widget into a GBC project and serves the examples with a
  standalone `httpdispatch`, to try the widget in a browser (`DateRangeDemo.xcf`). It prints a
  warning: the dispatcher listens on every interface and has no authentication.
- CONSTRUCT fields take a style that pins `dateRangeFormat` to `DBDATE`
  (`Edit.dateRangeConstruct` in `DateRangeDemo.4st`, used by `ConstructDemo.per`). The default
  format follows the browser language, which sent wrong dates when it differed from `DBDATE`.
- The default format drops the direction marks (`ar-SA`) and the trailing literal (`bg-BG`) that
  `Intl` adds, so typed digits are read as a date in those languages. The full format of the
  language, with those literals, is also accepted when typed (`05.11.2026 г.`, `2026. 11. 05.`),
  and a no-break space in it is read as a space. A format set by a style stays the only one.
- A CONSTRUCT field whose style has no `dateRangeFormat` writes a warning to the browser console.
