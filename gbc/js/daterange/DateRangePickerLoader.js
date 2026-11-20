"use strict";

/*
 * Loads daterangepicker 3.1.0 and jQuery 3.7.1 on demand, so an application without a date range
 * field never downloads them.
 *
 * Both are unmodified copies in ../../vendor/daterange (see the README there), so the widget
 * needs no npm install in the customization. They sit outside js/ because the GBC build imports
 * every .js file under js/ at startup. The ?url imports below copy each file to assets/ unbundled, and
 * loadDateRangePicker() runs them with <script> elements. Bundling them as modules is not an
 * option: daterangepicker's CommonJS branch would require("jquery") and require("moment") at
 * build time.
 *
 * Both files are UMD scripts, so as plain scripts they take their browser-globals path: jQuery sets
 * window.jQuery and window.$, and daterangepicker reads window.moment and window.jQuery and sets
 * window.daterangepicker. The globals are put back as they were once both have run:
 * daterangepicker keeps the jQuery and moment.js it was given.
 *
 * moment.js is imported normally: it resolves to the copy every GBC 6 project already bundles
 * (node_modules/moment at the project root, a peer dependency of pikaday-time).
 */
import moment from "moment";
import jqueryUrl from "../../vendor/daterange/jquery.min.js?url";
import dateRangePickerUrl from "../../vendor/daterange/daterangepicker.js?url";

/** Globals the two scripts read or set */
const GLOBAL_NAMES = ["moment", "jQuery", "$", "daterangepicker"];

/** @type {?Promise<Function>} the loading in progress or done, null before it or after a failure */
let loading = null;

/**
 * @param {string} url
 * @returns {Promise<void>} resolved once the script has run
 */
function loadScript(url) {
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    // Downloaded at once, but run in the order the scripts were added
    script.async = false;
    script.src = url;
    script.onload = () => {
      script.remove();
      resolve();
    };
    script.onerror = () => {
      script.remove();
      reject(new Error(`Date range widget: cannot load ${url}`));
    };
    document.head.appendChild(script);
  });
}

/**
 * @returns {Promise<Function>} the DateRangePicker constructor
 */
async function load() {
  const saved = new Map(GLOBAL_NAMES.map((name) => [name, Object.getOwnPropertyDescriptor(window, name)]));
  window.moment = moment;
  try {
    // Both downloads run in parallel. jQuery is added first, so it runs first: daterangepicker takes
    // jQuery from window.jQuery when it runs.
    await Promise.all([loadScript(jqueryUrl), loadScript(dateRangePickerUrl)]);
    const DateRangePicker = window.daterangepicker;
    if (typeof DateRangePicker !== "function") {
      throw new Error("Date range widget: daterangepicker did not register");
    }
    return DateRangePicker;
  } finally {
    for (const [name, descriptor] of saved) {
      if (descriptor) {
        Object.defineProperty(window, name, descriptor);
      } else {
        delete window[name];
      }
    }
  }
}

/**
 * Loads daterangepicker and jQuery once. Later calls share the same promise; after a failure, the
 * next call tries again.
 * @returns {Promise<Function>} the DateRangePicker constructor
 */
export function loadDateRangePicker() {
  if (!loading) {
    loading = load().catch((error) => {
      loading = null;
      throw error;
    });
  }
  return loading;
}
