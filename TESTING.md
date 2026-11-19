# Testing the widget in a browser

The BDL side is covered by fglunit (`make test`), and the runtime side of the examples by
4js-fgltest through GGC (`make uitest`: what the program sends to the front end and what it
accepts). The widget runs in a browser, and neither the build, the Node checks nor GGC can show
how it behaves there. This is the checklist for the first run on a real GBC. `examples/` has a
screen for each section.

Run it on **each** GBC you support: 6.00.09 or 6.00.07 (jsface and `modulum`), and a GBC where
those are removed (the 6.00.04 tree). `make gas` in `examples/` builds the customization with
`gbc build --vite` and serves the examples with a standalone `httpdispatch` (see "Examples" in
the README): once per GBC project, each with its own `GASPORT`. Or deploy the customization
yourself and start the examples on your own GAS. Keep the browser console open.

## A. Both generations, once

- [ ] The widget loads: no `modulum is not defined`, no `context.oo is undefined`, and no
  "this GBC has neither context.declare ... nor context.oo.Class" error in the console.
- [ ] A field with the `dateRange` style is the date range widget, and one without it is a plain
  edit.

## B. Input (menu: Input)

- [ ] The JSON value shows as `11/01/2026 - 11/30/2026` (the second field as `2026-11-01 - ...`,
  without predefined ranges).
- [ ] Typing a range, one date, `1/5/2026 - 1/20/2026` and `next week` behave as in the README.
- [ ] Optional, a field without `dateRangeFormat` and the browser language `bg-BG` or `ar-SA`: the
  default format is `DD.MM.YYYY` or `DD/MM/YYYY`, and typing `05.11.2026 - 20.11.2026` (or with
  `/` for `ar-SA`) is read as a range.
- [ ] The popup opens on click and on Alt+Down. Enter applies, Escape closes without cancelling
  the dialog, Tab applies and moves on.
- [ ] Ctrl+Z, Ctrl+X, Ctrl+V and a right-click Copy never put JSON in the field or on the
  clipboard.
- [ ] `ON CHANGE` fires: the "As BDL reads them" part updates.
- [ ] The LABEL at the bottom shows the range.

## C. Construct (menu: Construct)

- [ ] The search field is the date range widget, with the calendar icon. In the DOM its class is
  `gbc_DateRangeConstructWidget`.
- [ ] The field uses the `dateRangeConstruct` style, and its `dateRangeFormat` equals the program's
  `DBDATE` (the default `MDY4/` is `MM/DD/YYYY`).
- [ ] With the browser language set to one that writes the day first (fr-FR, de-DE), the field
  still shows and sends `MM/DD/YYYY`: the same range gives the same `BETWEEN` as in en-US. (The
  format is pinned by the style, not taken from the language.)
- [ ] Pick a range: the field shows `start - end`. Accept: the "Generated condition" field shows a
  `BETWEEN` on `orders.orderdate`, and the table shows the orders in the range.
- [ ] Type `11/01/2026 - 11/30/2026` and tab away: the same result.
- [ ] `>=11/01/2026`, a single date, `d1:d2`, `d1|d2` and `<>` reach the runtime as typed. The
  runtime refuses `d1 - d2`, ISO dates and `d1:`, with "Error in field": the widget must never
  send those.
- [ ] No console error after the cursor is placed beyond the end of the text.
- [ ] "New search" clears the field, and the widget works again.

## D. Display (menu: Display)

- [ ] The EDIT fields with `NOENTRY` and the LABEL show the formatted range and never open a
  popup.
- [ ] "Previous month" and "Next month" change the month browser, in both the EDIT and the LABEL.

## E. Display array (menu: Display array)

- [ ] The Period column shows the range, never JSON.
- [ ] Autofit (double-click a column border) sizes the column to the readable text.
- [ ] Select cells, copy and paste: the readable text.
- [ ] A current or selected row keeps legible text in the default, dark and high-contrast themes.
- [ ] A narrow column shows an ellipsis.
- [ ] The Details action reports the right dates for the current row.

## F. Input array (menu: Input array)

- [ ] The current row's period is editable, the other rows show the range and are disabled.
- [ ] A click on another row moves the focus, a second click opens the popup.
- [ ] The popup is under the cell, and flips up near the bottom of the table.
- [ ] Picking a range commits to the right row, and the Days column follows.
- [ ] Alt+Down, Escape and Tab behave as in B. Arrow Down with the popup open closes it without
  applying.
- [ ] Scrolling the table closes the popup. The first click does not close it through a scroll
  event.
- [ ] A click on another row applies the choice made so far.
- [ ] Appending rows does not leave a stale popup.
- [ ] Accept saves ("Campaigns saved."). Two overlapping campaigns are refused and the dialog
  stays open.
- [ ] Display array, then Input array, then Display array switches the cells (LABEL, EDIT,
  LABEL) and shows the saved change.
