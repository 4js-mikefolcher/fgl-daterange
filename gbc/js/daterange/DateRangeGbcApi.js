"use strict";

/*
 * The one place where the date range widget depends on the GBC generation it runs in. The same
 * files load in both, and DateRangeWidget.js is written once, against the two functions below.
 *
 * Official GBC 6.00.07 and 6.00.09 define their classes with jsface (context.oo.Class and $super)
 * inside modulum("Id", [dependencies], function (context, cls) { ... }) modules. A GBC where jsface
 * and modulum are removed defines native ES6 classes, registers their metadata with
 * context.declare(cls, Class, "Name", { widget: true }), has no modulum, and loads its whole core
 * before the first customization file runs.
 *
 * The build imports every .js file under js/, so the widget cannot ship one adapter per
 * generation: the wrong one would fail to build or to load. Both are in this file, and a run-time
 * test picks one. gbc is read from window.gbc and window.gbc.classes, what
 * "@/js/sysinit/context.mjs" re-exports in the newer GBC: that module does not exist in the official
 * releases, so it cannot be imported statically.
 *
 * How a widget is written for both:
 *
 * - Its members are a plain factory, members(parentPrototype), which returns an object of
 *   functions. A function calls the parent with parentPrototype.method.call(this, ...), the
 *   same in both generations (jsface's $super and ES6's super are not available to it).
 * - Its data members (null, false, ...) are in the defaults object: they end up on the prototype,
 *   never as class fields. GBC base constructors call overridable methods while they run, and a
 *   method of the widget that reads _picker then must find the default already.
 * - What a constructor does after the parent constructor is a member named _postConstruct(opts): an
 *   ES6 constructor cannot be written as a function that calls the parent with .call. The class
 *   created here runs the _postConstruct of its own members, once, right after the parent
 *   constructor.
 */

/**
 * @returns {boolean} true in a GBC that still has the modulum loader and the jsface classes
 */
export function isLegacyGbc() {
  return typeof modulum === "function";
}

/**
 * Runs body(context, cls) once the GBC classes it extends exist.
 *
 * Legacy GBC: a modulum module. modulum runs it as soon as its dependencies are loaded, and
 * passes the context and the classes, as for every GBC module.
 * Newer GBC: right away. The whole of GBC is loaded before any customization file.
 *
 * @param {string} moduleName name of the modulum module
 * @param {string[]} dependencies names of the modulum modules whose classes body uses
 * @param {Function} body called with (context, cls): window.gbc and window.gbc.classes
 */
export function whenGbcReady(moduleName, dependencies, body) {
  if (isLegacyGbc()) {
    modulum(moduleName, dependencies, body);
    return;
  }
  const context = window.gbc;
  if (!context?.classes) {
    throw new Error(`${moduleName}: GBC is not loaded (window.gbc is missing)`);
  }
  body(context, context.classes);
}

/**
 * Defines a widget class, registers it as cls[name], and returns it. It is not registered in
 * the WidgetFactory: the caller does it with cls.WidgetFactory.registerBuilder.
 *
 * @param {Object} context window.gbc
 * @param {Object} cls window.gbc.classes
 * @param {Object} definition
 * @param {string} definition.name class name, also the name of its CSS class (gbc_<name>)
 * @param {Function} definition.parent the class it extends
 * @param {string} [definition.templateName] name of the .tpl.html template, the class name by default
 * @param {Object} [definition.defaults] data members and their default values
 * @param {function(Object): Object} definition.members the functions of the class, given the
 * prototype of the parent. A member named _postConstruct(opts) runs after the parent constructor.
 * @returns {Function} the class
 */
export function defineWidget(context, cls, definition) {
  if (typeof definition.parent !== "function") {
    throw new Error(`${definition.name}: the GBC class it extends does not exist in this GBC`);
  }
  const { _postConstruct: postConstruct, ...methods } = definition.members(definition.parent.prototype);
  const options = {
    name: definition.name,
    parent: definition.parent,
    templateName: definition.templateName,
    defaults: definition.defaults ?? {},
    methods,
    postConstruct
  };
  const widget = isLegacyGbc() ? defineJsfaceClass(context, options) : defineNativeClass(context, cls, options);
  cls[definition.name] = widget;
  return widget;
}

/**
 * jsface class, with the metadata jsface generates (__name, __ascendance, ...)
 * @param {Object} context window.gbc
 * @param {Object} options see defineWidget
 * @returns {Function} the class
 * @private
 */
function defineJsfaceClass(context, options) {
  if (typeof context.oo?.Class !== "function") {
    throw new Error(`${options.name}: this GBC has neither context.declare (native classes) nor context.oo.Class (jsface)`);
  }
  return context.oo.Class(options.parent, function ($super) {
    const api = { ...options.defaults, ...options.methods, __name: options.name };
    if (options.templateName) {
      api.__templateName = options.templateName;
    }
    api.constructor = function (opts) {
      $super.constructor.call(this, opts);
      if (options.postConstruct) {
        options.postConstruct.call(this, opts);
      }
    };
    return api;
  });
}

/**
 * Native ES6 class, declared to GBC with context.declare. The methods are not enumerable, as
 * the methods of a class are; the defaults are on the prototype, not class fields.
 * @param {Object} context window.gbc
 * @param {Object} cls window.gbc.classes
 * @param {Object} options see defineWidget
 * @returns {Function} the class
 * @private
 */
function defineNativeClass(context, cls, options) {
  if (typeof context.declare !== "function") {
    throw new Error(`${options.name}: this GBC has neither context.declare (native classes) nor context.oo.Class (jsface)`);
  }
  const Widget = class extends options.parent {
    constructor(opts) {
      super(opts);
      if (options.postConstruct) {
        options.postConstruct.call(this, opts);
      }
    }
  };
  Object.defineProperty(Widget, "name", { value: options.name });
  for (const [key, method] of Object.entries(options.methods)) {
    Object.defineProperty(Widget.prototype, key, { value: method, writable: true, configurable: true, enumerable: false });
  }
  Object.assign(Widget.prototype, options.defaults);
  if (options.templateName) {
    Widget.prototype.__templateName = options.templateName;
  }
  context.declare(cls, Widget, options.name, { widget: true });
  return Widget;
}
