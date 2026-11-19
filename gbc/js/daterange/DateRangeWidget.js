"use strict";

// Drop-in date range widget for a GBC 6 customization built with Vite (gbc build --vite). To add
// it to a customization: copy js/daterange/ and vendor/daterange/ into it, and add to its
// sass/customization.scss:  @import "../js/daterange/DateRangeWidget";
//
// The same files work in the official GBC 6.00.07 and 6.00.09 (jsface classes, modulum modules) and
// in a GBC with native ES6 classes: DateRangeGbcApi.js is the only code that knows the difference.
//
// moment.js is the copy GBC already bundles. daterangepicker and jQuery are not bundled:
// DateRangePickerLoader loads them when a form first shows an editable date range field.
import moment from "moment";
import { defineWidget, whenGbcReady } from "./DateRangeGbcApi.js";
import { loadDateRangePicker } from "./DateRangePickerLoader.js";
import { I18N_PREFIX, TEXTS } from "./DateRangeTexts.js";

whenGbcReady("DateRangeWidget", ["EditWidget", "DummyEditWidget", "WidgetFactory"], function (context, cls) {
  /** Date format of the value exchanged with the VM, the one util.JSON reads and writes for DATE */
  const ISO_FORMAT = "YYYY-MM-DD";
  /** Separator between the two dates in the displayed text */
  const SEPARATOR = " - ";
  /** Accepted separators when the user types a range: a dash or an en dash with spaces around it */
  const TYPED_SEPARATOR = /\s+[-–]\s+/;
  /** Separator between the two dates of a range in the criteria of a CONSTRUCT (date1:date2) */
  const QUERY_SEPARATOR = ":";
  /** 4ST style attribute: moment.js display format, for example "DD/MM/YYYY" */
  const FORMAT_STYLE_ATTRIBUTE = "dateRangeFormat";
  /** 4ST style attribute: "no" hides the predefined ranges (Today, Last 7 days, ...) */
  const PRESETS_STYLE_ATTRIBUTE = "dateRangePresets";

  /** Data members of the widgets, on the prototype: GBC base constructors call methods that read them */
  const DEFAULTS = {
    /** @type {?Object} daterangepicker instance, created on first opening */
    _picker: null,
    /** @type {boolean} an opening waits for daterangepicker to load */
    _pendingOpen: false,
    /**
     * moment.js format of the displayed dates, resolved on first use. Not _displayFormat:
     * EditWidget keeps the VM display format (the field data type) under that name.
     * @type {?string}
     */
    _rangeFormat: null,
    /** @type {?string[]} moment.js formats a typed date is read with, resolved on first use */
    _dateFormats: null,
    /** @type {?Function} scroll listener of the document, while the picker of a table cell is open */
    _scrollWatcher: null
  };

  /**
   * The members of every date range widget: what they show, how the user picks a range, how the
   * text relates to the value exchanged with the VM. The value is JSON, the one of an INPUT; a
   * widget for another dialog replaces the _parseVmValue / _formatVmValue / _parseText group.
   *
   * @param {Object} base prototype of the class the widget extends: base.method.call(this, ...) is
   * the way to call the parent, whatever the GBC generation
   * @returns {Object} the members
   */
  function rangeMembers(base) {
    return {
      /**
       * Runs after the parent constructor
       * @param {Object} opts constructor options
       */
      _postConstruct(opts) {
        this._prefetchPicker();
      },

      /**
       * Value received from the VM, or set by GBC internals (undo, ...)
       * @inheritDoc
       */
      setValue(value, fromVM = false, cursorPosition = null) {
        const input = this.getInputElement();
        const shownText = input.value;
        // Keeps the VM value in the value stack and _oldValue, then shows the readable text instead
        base.setValue.call(this, value, fromVM, cursorPosition);
        const text = this._toDisplayText(value);
        if (fromVM && shownText !== text) {
          // Another value under an open picker, as in a table cell shown again for another row
          this._cancelPicker();
        }
        input.value = text;
        try {
          if (cursorPosition !== null && this.isEnabled()) {
            input.selectionStart = input.selectionEnd = cursorPosition;
          }
        } catch (e) {
          // the input does not take a selection
        }
      },

      /**
       * The VM form of the current text. A text that is not a range is returned as typed.
       * @returns {?string} the VM value of the range, "" when the field is empty
       * @inheritDoc
       */
      getValue() {
        const input = this.getInputElement();
        if (!input) {
          return null;
        }
        const range = this._parseText(input.value);
        if (!range) {
          return this._unparsedValue(input.value);
        }
        // Same range as the VM value: return the VM text exactly, so an untouched field is never
        // reported as changed because of a formatting difference
        const vmRange = this._parseVmValue(this._oldValue);
        if (vmRange && vmRange.start.isSame(range.start, "day") && vmRange.end.isSame(range.end, "day")) {
          return this._oldValue;
        }
        return this._formatVmValue(range);
      },

      /**
       * The displayed text of a VM value, for the width of a table column to fit (autofit measures
       * this text instead of the VM value) and for the text of a value
       * @param {?string} [value] VM value, the current value by default
       * @returns {string} the text the field shows for it
       */
      getFormattedValue(value = this.getValue()) {
        return this._toDisplayText(value);
      },

      /**
       * The text of the field, not its VM value: it is what the user sees, and what Copy, and a
       * selection of table cells, put in the clipboard
       * @inheritDoc
       */
      getValueForClipboard(ignoreSelection = false) {
        const text = base.getValueForClipboard.call(this, ignoreSelection);
        const input = this.getInputElement();
        // The parent returns the VM value when nothing is selected, or for a disabled field
        return input && text === this.getValue() ? input.value : text;
      },

      /**
       * Cuts from the displayed text: the parent cuts from the VM value, with the cursors of the text
       * @inheritDoc
       */
      manageClipboardCut() {
        const { start, end } = this.getCursors();
        if (this._enabled) {
          context.ClipboardService.setClipboardData(this.getValueForClipboard());
          this.setValue(this.removeCharacters(this.getInputElement().value, start, end), false, start);
        }
      },

      /**
       * Internal setter, used by undo, redo and paste: with the text, never with the VM value
       * @param {string} value
       * @inheritDoc
       */
      _setValue(value) {
        base._setValue.call(this, this._toDisplayText(value));
      },

      /**
       * A range is not an input of a few characters: no automatic move to the next field when the
       * text reaches the field width, which the VM value (longer than the text) would trigger
       * @inheritDoc
       */
      canAutoNext() {
        return false;
      },

      /**
       * Opens the picker on click. Not on focus: the VM moves the focus too (dialog start, NEXT FIELD)
       * @inheritDoc
       */
      manageMouseClick(domEvent) {
        const result = base.manageMouseClick.call(this, domEvent);
        if (this._canOpenPicker()) {
          this._openPicker();
        }
        return result;
      },

      /**
       * Keyboard while the picker is open: Escape cancels, Enter applies, Tab applies and lets GBC
       * move the focus. Alt+Down opens the picker, as it opens a ComboBox.
       * @inheritDoc
       */
      managePriorityKeyDown(keyString, domKeyEvent, repeat) {
        if (this._isPickerOpen()) {
          switch (keyString) {
            case "esc":
            case "escape":
              this._picker.clickCancel();
              return true;
            case "enter":
            case "return":
              this._picker.clickApply();
              return true;
            case "tab":
            case "shift+tab":
              this._picker.hide();
              break;
            default:
              break;
          }
        } else if (keyString === "alt+down" && this._canOpenPicker()) {
          this._openPicker();
          return true;
        }
        return base.managePriorityKeyDown.call(this, keyString, domKeyEvent, repeat);
      },

      /**
       * Keeps the open calendar in sync with what the user types
       * @inheritDoc
       */
      manageInput(dataString = "", event = null) {
        base.manageInput.call(this, dataString, event);
        if (this._isPickerOpen()) {
          const range = this._parseTextForPicker(this.getInputElement().value);
          if (range) {
            this._picker.setStartDate(range.start);
            this._picker.setEndDate(range.end);
            this._picker.updateView();
          }
        }
      },

      /**
       * @inheritDoc
       */
      loseVMFocus(vmNewFocusedWidget = null) {
        this._cancelPicker();
        base.loseVMFocus.call(this, vmNewFocusedWidget);
      },

      /**
       * @inheritDoc
       */
      loseFocus() {
        this._cancelPicker();
        base.loseFocus.call(this);
      },

      /**
       * @inheritDoc
       */
      setEnabled(enabled, ...others) {
        base.setEnabled.call(this, enabled, ...others);
        if (!enabled) {
          this._cancelPicker();
        }
      },

      /**
       * @returns {boolean} true when the user may change the value
       * @private
       */
      _canOpenPicker() {
        return this.isEnabled() && !this.isNotEditable() && !this.isReadOnly();
      },

      /**
       * @returns {boolean} true when the picker is displayed
       * @private
       */
      _isPickerOpen() {
        return Boolean(this._picker?.isShowing);
      },

      /**
       * Starts loading daterangepicker as soon as a form shows the field, so that the first click
       * does not wait for the download. A failure is reported when the user opens the picker.
       * @private
       */
      _prefetchPicker() {
        loadDateRangePicker().catch(() => {});
      },

      /**
       * Opens the picker, once daterangepicker is loaded. An opening still waiting for it is dropped
       * when the field loses the focus, is disabled or is destroyed (_cancelPicker, destroy).
       * @private
       */
      _openPicker() {
        if (this._picker) {
          this._showPicker();
          return;
        }
        this._pendingOpen = true;
        loadDateRangePicker().then(
          (DateRangePicker) => {
            if (!this._pendingOpen || this.isDestroyed()) {
              return;
            }
            this._pendingOpen = false;
            if (!this._picker) {
              this._createPicker(DateRangePicker);
            }
            this._showPicker();
          },
          (error) => {
            this._pendingOpen = false;
            console.error(error);
          }
        );
      },

      /**
       * Shows the picker on the current value, or on today when the field holds no valid range
       * @private
       */
      _showPicker() {
        if (this._picker.isShowing) {
          return;
        }
        const range = this._parseTextForPicker(this.getInputElement().value);
        this._picker.setStartDate(range ? range.start : moment().startOf("day"));
        this._picker.setEndDate(range ? range.end : moment().startOf("day"));
        this._picker.show();
      },

      /**
       * Closes the picker without applying the dates being chosen, or drops an opening still
       * waiting for daterangepicker to load
       * @private
       */
      _cancelPicker() {
        this._pendingOpen = false;
        if (this._isPickerOpen()) {
          this._picker.clickCancel();
        }
      },

      /**
       * Creates the daterangepicker instance, on first opening
       * @param {Function} DateRangePicker the daterangepicker constructor
       * @private
       */
      _createPicker(DateRangePicker) {
        const language = this._getLanguage();
        const names = this._getCalendarNames(language);

        // Attached to the whole field, not the <input>: the popup lines up with the field box, and
        // a click on the calendar icon counts as inside the picker instead of closing it
        this._picker = new DateRangePicker(
          this.getElement(),
          {
            autoUpdateInput: false,
            alwaysShowCalendars: true,
            showDropdowns: true,
            drops: "auto",
            ranges: this._usePresets() ? this._getPresets() : undefined,
            // GBC button looks instead of the Bootstrap classes the library expects
            buttonClasses: "mt-button",
            applyButtonClasses: "gbc_DateRangePicker__apply",
            cancelButtonClasses: "mt-button-flat gbc_DateRangePicker__cancel",
            locale: {
              format: this._getRangeFormat(),
              separator: SEPARATOR,
              applyLabel: this._t("apply"),
              cancelLabel: this._t("cancel"),
              customRangeLabel: this._t("customRange"),
              daysOfWeek: names.daysOfWeek,
              monthNames: names.monthNames,
              firstDay: this._getFirstDayOfWeek(language)
            }
          },
          this._onPickerChanged.bind(this)
        );
        // The library binds click and keydown on its element to toggle the popup. GBC owns the mouse
        // and the keyboard (manageMouseClick, managePriorityKeyDown): the widget drives it instead.
        // element and container are jQuery objects, from the jQuery daterangepicker was loaded with.
        this._picker.element.off(".daterangepicker");
        this._picker.container.addClass("gbc_DateRangePicker");
        // The popup is a child of <body>, placed when it opens: in a table it must not stay behind
        // when the table scrolls (_watchScroll)
        this._picker.element.on("show.daterangepicker", () => this._watchScroll(true));
        this._picker.element.on("hide.daterangepicker", () => this._watchScroll(false));
      },

      /**
       * While the picker of a table cell is open, closes it when the table, or anything around the
       * cell, scrolls: the popup is placed once, from the position of the cell, and the cell moves.
       * Elsewhere the popup stays where it opened.
       * @param {boolean} watch true to start watching, false to stop
       * @private
       */
      _watchScroll(watch) {
        if (watch && this.isInTable() && !this._scrollWatcher) {
          this._scrollWatcher = (event) => {
            const element = this.getElement();
            // scroll does not bubble: the listener is a capturing one on the document, and the
            // scrolled element is the target. The calendar itself may scroll without closing.
            if (element && event.target?.contains?.(element)) {
              this._cancelPicker();
            }
          };
          document.addEventListener("scroll", this._scrollWatcher, true);
        } else if (!watch && this._scrollWatcher) {
          document.removeEventListener("scroll", this._scrollWatcher, true);
          this._scrollWatcher = null;
        }
      },

      /**
       * Called by daterangepicker when the chosen range changes (Apply, a preset, a click outside)
       * @param {Object} start moment of the first day
       * @param {Object} end moment of the last day
       * @private
       */
      _onPickerChanged(start, end) {
        const range = { start: start.clone().startOf("day"), end: end.clone().startOf("day") };
        this.getInputElement().value = this._formatRange(range);
        this._editingTime = Date.now();
        const value = this.getValue();
        this.setEditing(value !== this._oldValue);
        // Sent to the VM right away, as for a choice in a completer
        this.triggerValueChangedEvent(value);
      },

      /**
       * @param {?string} value VM value or text set by GBC
       * @returns {string} the text to show in the input
       * @private
       */
      _toDisplayText(value) {
        if (value === null || value === undefined || value === "") {
          return "";
        }
        const range = this._parseVmValue(value);
        return range ? this._formatRange(range) : String(value);
      },

      /**
       * The VM value of a text that is not a range. BDL then rejects it.
       * @param {string} text what the input holds
       * @returns {string} "" for a text with only spaces, else the text as typed
       * @private
       */
      _unparsedValue(text) {
        return text.trim() === "" ? "" : text;
      },

      /**
       * Parses what the input holds: "start - end", a single date (a one-day range), or JSON
       * (left in the input by an undo)
       * @param {?string} text
       * @returns {?{start: Object, end: Object}} the range, null when the text is not one
       * @private
       */
      _parseText(text) {
        const trimmed = (text ?? "").trim();
        if (!trimmed) {
          return null;
        }
        if (trimmed.startsWith("{")) {
          return this._parseVmValue(trimmed);
        }
        return this._parseDateRange(trimmed, true);
      },

      /**
       * What the calendar opens on, for the text of the field: the range of _parseText, or more
       * @param {?string} text
       * @returns {?{start: Object, end: Object}} the range, null when the text is not one
       * @private
       */
      _parseTextForPicker(text) {
        return this._parseText(text);
      },

      /**
       * Parses "start - end", or a single date, in the display format
       * @param {string} text trimmed text
       * @param {boolean} allowSingleDate true to read a single date as a one-day range
       * @returns {?{start: Object, end: Object}} the range, null when the text is not one
       * @private
       */
      _parseDateRange(text, allowSingleDate) {
        const parts = text.split(TYPED_SEPARATOR);
        if (parts.length > 2 || (parts.length === 1 && !allowSingleDate)) {
          return null;
        }
        const start = this._parseDate(parts[0]);
        const end = parts.length === 2 ? this._parseDate(parts[1]) : start?.clone();
        return start && end ? { start: start, end: end } : null;
      },

      /**
       * Strict parsing, so "11/012026" is not read as a date, but the display format also
       * accepts one-digit months and days ("1/5/2026" for MM/DD/YYYY), and the ISO format
       * @param {string} text one date
       * @returns {?Object} moment of the day, null when the text is not a date
       * @private
       */
      _parseDate(text) {
        if (!this._dateFormats) {
          const format = this._getRangeFormat();
          const shortFormat = format.replace(/(^|[^M])MM(?!M)/, "$1M").replace(/(^|[^D])DD(?!D)/, "$1D");
          this._dateFormats = [format, shortFormat, ISO_FORMAT];
        }
        const date = moment(text, this._dateFormats, true);
        return date.isValid() ? date.startOf("day") : null;
      },

      /**
       * @param {?string} value VM value, {"startDate":"YYYY-MM-DD","endDate":"YYYY-MM-DD"}
       * @returns {?{start: Object, end: Object}} the range, null when the value is not one
       * @private
       */
      _parseVmValue(value) {
        if (typeof value !== "string" || !value.trim().startsWith("{")) {
          return null;
        }
        let data = null;
        try {
          data = JSON.parse(value);
        } catch (e) {
          return null;
        }
        const start = moment(data?.startDate, ISO_FORMAT, true);
        const end = moment(data?.endDate, ISO_FORMAT, true);
        if (!start.isValid() || !end.isValid()) {
          return null;
        }
        return { start: start, end: end };
      },

      /**
       * @param {{start: Object, end: Object}} range
       * @returns {string} the VM value
       * @private
       */
      _formatVmValue(range) {
        return JSON.stringify({ startDate: range.start.format(ISO_FORMAT), endDate: range.end.format(ISO_FORMAT) });
      },

      /**
       * @param {{start: Object, end: Object}} range
       * @returns {string} the displayed text
       * @private
       */
      _formatRange(range) {
        const format = this._getRangeFormat();
        return range.start.format(format) + SEPARATOR + range.end.format(format);
      },

      /**
       * The dateRangeFormat 4ST attribute, or the short numeric date of the GBC language
       * @returns {string} moment.js format
       * @private
       */
      _getRangeFormat() {
        if (!this._rangeFormat) {
          this._rangeFormat = this._getStyleAttribute(FORMAT_STYLE_ATTRIBUTE) || this._getLocaleFormat(this._getLanguage());
        }
        return this._rangeFormat;
      },

      /**
       * @returns {boolean} false when the dateRangePresets 4ST attribute says no
       * @private
       */
      _usePresets() {
        const value = (this._getStyleAttribute(PRESETS_STYLE_ATTRIBUTE) || "").toLowerCase();
        return !["no", "false", "0", "none"].includes(value);
      },

      /**
       * @param {string} name 4ST style attribute name
       * @returns {?string} its value for this field, null when unset or not reachable
       * @private
       */
      _getStyleAttribute(name) {
        const application = context.SessionService.getCurrent()?.getApplicationByHash(this._appHash);
        const node = application?.getNode(this._auiTag);
        return node?.getStyleAttribute ? node.getStyleAttribute(name) : null;
      },

      /**
       * @returns {Object<string, Object[]>} the predefined ranges, label to [start, end]
       * @private
       */
      _getPresets() {
        const today = moment().startOf("day");
        const lastMonth = today.clone().subtract(1, "month");
        return {
          [this._t("today")]: [today.clone(), today.clone()],
          [this._t("yesterday")]: [today.clone().subtract(1, "day"), today.clone().subtract(1, "day")],
          [this._t("last7Days")]: [today.clone().subtract(6, "days"), today.clone()],
          [this._t("last30Days")]: [today.clone().subtract(29, "days"), today.clone()],
          [this._t("thisMonth")]: [today.clone().startOf("month"), today.clone().endOf("month")],
          [this._t("lastMonth")]: [lastMonth.clone().startOf("month"), lastMonth.clone().endOf("month")]
        };
      },

      /**
       * A text in the GBC language: the customization's override (dateRangeWidget.<key> in its
       * locales/<language>.json) when there is one, else the built-in text (DateRangeTexts.js)
       * for the language, its primary language, or English
       * @param {string} key text key, for example "apply"
       * @returns {string} the text
       * @private
       */
      _t(key) {
        const language = this._getLanguage();
        // getResource reads this language only. I18NService.t would fall back to GBC's default
        // language, so an en-US override would replace the built-in German, French, ... texts.
        const override = context.I18NService.i18next?.getResource?.(language, "translation", I18N_PREFIX + key);
        if (typeof override === "string" && override !== "") {
          return override;
        }
        const tag = language.toLowerCase();
        const texts = TEXTS[tag] || TEXTS[tag.split("-")[0]] || TEXTS.en;
        return texts[key] ?? TEXTS.en[key];
      },

      /**
       * @returns {string} the GBC interface language, as a BCP 47 tag
       * @private
       */
      _getLanguage() {
        return context.I18NService.i18next?.language || navigator.language || "en-US";
      },

      /**
       * Builds a moment.js format from the short numeric date of a language: en-US gives
       * MM/DD/YYYY, fr-FR gives DD/MM/YYYY, ...
       * @param {string} language
       * @returns {string} moment.js format
       * @private
       */
      _getLocaleFormat(language) {
        try {
          const parts = new Intl.DateTimeFormat(language, { year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(
            new Date(2026, 10, 30)
          );
          const tokens = { year: "YYYY", month: "MM", day: "DD" };
          // Literal parts are escaped, moment.js would read their letters as tokens
          return parts.map((part) => tokens[part.type] ?? `[${part.value}]`).join("");
        } catch (e) {
          return "MM/DD/YYYY";
        }
      },

      /**
       * Day and month names in the GBC language. moment.js only bundles English.
       * @param {string} language
       * @returns {{daysOfWeek: string[], monthNames: string[]}} names, Sunday and January first
       * @private
       */
      _getCalendarNames(language) {
        try {
          const day = new Intl.DateTimeFormat(language, { weekday: "short", timeZone: "UTC" });
          const month = new Intl.DateTimeFormat(language, { month: "short", timeZone: "UTC" });
          return {
            // 2023-01-01 was a Sunday
            daysOfWeek: Array.from({ length: 7 }, (_, i) => day.format(new Date(Date.UTC(2023, 0, 1 + i)))),
            monthNames: Array.from({ length: 12 }, (_, i) => month.format(new Date(Date.UTC(2023, i, 1))))
          };
        } catch (e) {
          return { daysOfWeek: moment.weekdaysMin(), monthNames: moment.monthsShort() };
        }
      },

      /**
       * @param {string} language
       * @returns {number} first day of the week, 0 for Sunday
       * @private
       */
      _getFirstDayOfWeek(language) {
        try {
          const locale = new Intl.Locale(language);
          const weekInfo = locale.getWeekInfo?.() ?? locale.weekInfo;
          // Intl numbers days 1 (Monday) to 7 (Sunday)
          return weekInfo ? weekInfo.firstDay % 7 : 0;
        } catch (e) {
          return 0;
        }
      },

      /**
       * @inheritDoc
       */
      destroy() {
        this._pendingOpen = false;
        this._watchScroll(false);
        if (this._picker) {
          // hide() would report a pending choice through the callback: drop it first
          this._picker.callback = () => {};
          this._picker.hide();
          this._picker.remove();
          this._picker = null;
        }
        // Last: EditWidget.destroy removes the input the picker is attached to
        base.destroy.call(this);
      }
    };
  }

  /**
   * The members of the widget of a CONSTRUCT. There, the VM does not take JSON: the runtime reads
   * what the field holds as query-by-example criteria, and for a DATE field a range is written
   * date1:date2, in DBDATE format. So the field shows "start - end" as in an INPUT, and the VM gets
   * "start:end" in the display format, which therefore has to be the DBDATE format of the program
   * (the dateRangeFormat 4ST attribute). Any other text is criteria of the user, sent as typed: a
   * single date, ">=11/01/2026", "*", ...
   *
   * @param {Object} base prototype of the class the widget extends
   * @returns {Object} the members that replace those of rangeMembers
   */
  function constructMembers(base) {
    return {
      /**
       * The look of the other date range widgets applies (.gbc_DateRangeWidget), as DummyEditWidget
       * adds gbc_EditWidget
       * @inheritDoc
       */
      _initElement() {
        base._initElement.call(this);
        this.addClasses("gbc_DateRangeWidget");
      },

      /**
       * @param {?string} value VM text, "start:end" is a range
       * @returns {?{start: Object, end: Object}} the range, null when the text is not one
       * @private
       */
      _parseVmValue(value) {
        return typeof value === "string" ? this._parseQuery(value) : null;
      },

      /**
       * @param {{start: Object, end: Object}} range
       * @returns {string} the criteria "start:end", in the display format
       * @private
       */
      _formatVmValue(range) {
        const format = this._getRangeFormat();
        return range.start.format(format) + QUERY_SEPARATOR + range.end.format(format);
      },

      /**
       * @param {string} text what the input holds
       * @returns {string} the text, exactly as typed
       * @private
       */
      _unparsedValue(text) {
        return text;
      },

      /**
       * Only "start - end" is a range here. A single date is criteria of its own (equality), and
       * the VM reads it.
       * @param {?string} text
       * @returns {?{start: Object, end: Object}} the range, null when the text is not one
       * @private
       */
      _parseText(text) {
        const trimmed = (text ?? "").trim();
        return trimmed ? this._parseDateRange(trimmed, false) : null;
      },

      /**
       * The calendar opens on a range, "start:end" or a single date as well
       * @param {?string} text
       * @returns {?{start: Object, end: Object}} the range, null when the text is none of them
       * @private
       */
      _parseTextForPicker(text) {
        const trimmed = (text ?? "").trim();
        return trimmed ? this._parseDateRange(trimmed, true) || this._parseQuery(trimmed) : null;
      },

      /**
       * @param {string} text "start:end", both dates in the display format
       * @returns {?{start: Object, end: Object}} the range, null when the text is not one
       * @private
       */
      _parseQuery(text) {
        const parts = text.split(QUERY_SEPARATOR);
        if (parts.length !== 2) {
          return null;
        }
        const start = this._parseDate(parts[0]);
        const end = this._parseDate(parts[1]);
        return start && end ? { start: start, end: end } : null;
      }
    };
  }

  /**
   * Single-field date range picker, built on daterangepicker (https://www.daterangepicker.com/).
   *
   * The VM value is a JSON string, {"startDate":"YYYY-MM-DD","endDate":"YYYY-MM-DD"}, that BDL
   * deserializes with util.JSON.parse into a record of two DATE members. The input shows the range
   * as readable text ("11/01/2026 - 11/30/2026"): the user picks it in the calendar or types it.
   *
   * Value handling: the FieldWidgetBase value stack and _oldValue keep the VM form (JSON), and only
   * the <input> holds the displayed text. getValue() converts the text back to JSON, so change
   * detection compares JSON with JSON.
   *
   * Activated like TagEdit, through the customWidget 4ST style attribute:
   *   <Style name="Edit.dateRange"><StyleAttribute name="customWidget" value="dateRange"/></Style>
   *
   * @class DateRangeWidget
   * @memberOf classes
   * @extends classes.EditWidget
   */
  const DateRangeWidget = defineWidget(context, cls, {
    name: "DateRangeWidget",
    parent: cls.EditWidget,
    templateName: "DateRangeWidget",
    defaults: DEFAULTS,
    members: rangeMembers
  });

  /**
   * The date range widget for a LABEL, and for a display-only cell of a table: never enabled, so
   * the picker never opens. Its own class lets the stylesheet show the formatted range as text
   * instead of a field.
   * @class DateRangeLabelWidget
   * @memberOf classes
   * @extends classes.DateRangeWidget
   */
  const DateRangeLabelWidget = defineWidget(context, cls, {
    name: "DateRangeLabelWidget",
    parent: DateRangeWidget,
    templateName: "DateRangeWidget",
    members: () => ({
      /**
       * A label never opens the picker: a form that only shows ranges does not load it
       * @inheritDoc
       */
      _prefetchPicker() {}
    })
  });

  /**
   * The date range widget of a CONSTRUCT, where GBC uses DummyEditWidget instead of EditWidget
   * (EditController._getWidgetType). See constructMembers for the text it shows and sends.
   * @class DateRangeConstructWidget
   * @memberOf classes
   * @extends classes.DummyEditWidget
   */
  const DateRangeConstructWidget = defineWidget(context, cls, {
    name: "DateRangeConstructWidget",
    parent: cls.DummyEditWidget,
    templateName: "DateRangeWidget",
    defaults: DEFAULTS,
    members: (base) => ({ ...rangeMembers(base), ...constructMembers(base) })
  });

  cls.WidgetFactory.registerBuilder("Edit[customWidget=dateRange]", DateRangeWidget);
  cls.WidgetFactory.registerBuilder("Label[customWidget=dateRange]", DateRangeLabelWidget);
  cls.WidgetFactory.registerBuilder("DummyEdit[customWidget=dateRange]", DateRangeConstructWidget);
});
