"use strict";

/*
 * Built-in texts of the date range widget, in the languages GBC ships (src/locales), so the
 * widget needs no entries in the customization's locales/*.json. "Apply" and "Cancel" use the
 * words of GBC's own locale files.
 *
 * A customization can still override a text, or add a language, in its locales/<language>.json:
 *   { "dateRangeWidget": { "apply": "OK", "lastMonth": "Previous month" } }
 * DateRangeWidget._t looks there first, in the file of the current language only (an override in
 * en-US.json changes the English text, not the others), then here: the full language tag
 * (zh-TW), then its primary language (de for de-AT), then English.
 */

/** Key prefix of the overrides in the customization's locale files */
export const I18N_PREFIX = "dateRangeWidget.";

/** Texts by lower-case language tag */
export const TEXTS = {
  en: {
    apply: "Apply",
    cancel: "Cancel",
    customRange: "Custom range",
    today: "Today",
    yesterday: "Yesterday",
    last7Days: "Last 7 days",
    last30Days: "Last 30 days",
    thisMonth: "This month",
    lastMonth: "Last month"
  },
  de: {
    apply: "Anwenden",
    cancel: "Abbrechen",
    customRange: "Benutzerdefinierter Zeitraum",
    today: "Heute",
    yesterday: "Gestern",
    last7Days: "Letzte 7 Tage",
    last30Days: "Letzte 30 Tage",
    thisMonth: "Dieser Monat",
    lastMonth: "Letzter Monat"
  },
  es: {
    apply: "Aplicar",
    cancel: "Cancelar",
    customRange: "Período personalizado",
    today: "Hoy",
    yesterday: "Ayer",
    last7Days: "Últimos 7 días",
    last30Days: "Últimos 30 días",
    thisMonth: "Este mes",
    lastMonth: "El mes pasado"
  },
  fr: {
    apply: "Appliquer",
    cancel: "Annuler",
    customRange: "Période personnalisée",
    today: "Aujourd'hui",
    yesterday: "Hier",
    last7Days: "7 derniers jours",
    last30Days: "30 derniers jours",
    thisMonth: "Ce mois-ci",
    lastMonth: "Le mois dernier"
  },
  pt: {
    apply: "Aplicar",
    cancel: "Cancelar",
    customRange: "Período personalizado",
    today: "Hoje",
    yesterday: "Ontem",
    last7Days: "Últimos 7 dias",
    last30Days: "Últimos 30 dias",
    thisMonth: "Este mês",
    lastMonth: "Mês passado"
  },
  "zh-cn": {
    apply: "应用",
    cancel: "取消",
    customRange: "自定义范围",
    today: "今天",
    yesterday: "昨天",
    last7Days: "最近 7 天",
    last30Days: "最近 30 天",
    thisMonth: "本月",
    lastMonth: "上月"
  },
  "zh-tw": {
    apply: "套用",
    cancel: "取消",
    customRange: "自訂範圍",
    today: "今天",
    yesterday: "昨天",
    last7Days: "最近 7 天",
    last30Days: "最近 30 天",
    thisMonth: "本月",
    lastMonth: "上個月"
  }
};
