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
