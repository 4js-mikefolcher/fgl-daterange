#+ Controller of the DISPLAY demo: the program puts date ranges on the screen with DISPLAY
#+ BY NAME and DISPLAY TO, and no dialog edits them. A month browser steps through the
#+ months, and three predefined periods are shown once. The same value goes to an EDIT with
#+ NOENTRY and to a LABEL, both with the dateRange style: read-only, so the widget shows the
#+ formatted range and never opens its popup.

IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper
IMPORT FGL DisplayDemoModel

#+ The view record: the JSON value of each date range field.
PUBLIC TYPE tPeriodsView RECORD
   monthPeriod   STRING,
   monthLabel    STRING,
   last30Period  STRING,
   quarterPeriod STRING,
   yearPeriod    STRING
END RECORD

PUBLIC FUNCTION displayDemoRun() RETURNS ()
   VAR rec tPeriodsView
   VAR monthOffset INTEGER = 0
   OPEN WINDOW wDisplayDemo WITH FORM "DisplayDemo"
      ATTRIBUTES(TEXT = "Display")
   CALL showPredefinedPeriods(rec)
   CALL showMonth(rec, monthOffset)
   LET int_flag = FALSE
   MENU "Month browser"
      ON ACTION previous ATTRIBUTES(TEXT = "Previous month")
         LET monthOffset = monthOffset - 1
         CALL showMonth(rec, monthOffset)
      ON ACTION next ATTRIBUTES(TEXT = "Next month")
         LET monthOffset = monthOffset + 1
         CALL showMonth(rec, monthOffset)
      ON ACTION thismonth ATTRIBUTES(TEXT = "This month")
         LET monthOffset = 0
         CALL showMonth(rec, monthOffset)
      ON ACTION close
         EXIT MENU
   END MENU
   CLOSE WINDOW wDisplayDemo
END FUNCTION

#+ DISPLAY BY NAME: the form fields named like the record members get the values.
PRIVATE FUNCTION showMonth(rec tPeriodsView INOUT, monthOffset INTEGER) RETURNS ()
   VAR monthRange DateRangeHelper.tDateRange
   LET monthRange = DisplayDemoModel.monthPeriod(TODAY, monthOffset)
   LET rec.monthPeriod = monthRange.serialize()
   LET rec.monthLabel = rec.monthPeriod
   DISPLAY BY NAME rec.monthPeriod, rec.monthLabel
END FUNCTION

#+ DISPLAY TO: the values go to the named form fields, by position.
PRIVATE FUNCTION showPredefinedPeriods(rec tPeriodsView INOUT) RETURNS ()
   VAR last30Range DateRangeHelper.tDateRange
   VAR quarterRange DateRangeHelper.tDateRange
   VAR yearRange DateRangeHelper.tDateRange
   LET last30Range = DisplayDemoModel.lastDaysPeriod(TODAY, 30)
   LET quarterRange = DisplayDemoModel.quarterPeriod(TODAY)
   LET yearRange = DisplayDemoModel.yearPeriod(TODAY)
   LET rec.last30Period = last30Range.serialize()
   LET rec.quarterPeriod = quarterRange.serialize()
   LET rec.yearPeriod = yearRange.serialize()
   DISPLAY rec.last30Period, rec.quarterPeriod, rec.yearPeriod
      TO last30Period, quarterPeriod, yearPeriod
END FUNCTION
