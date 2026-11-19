#+ Controller of the INPUT demo: two date range fields in an INPUT BY NAME, and below them
#+ what BDL reads from their JSON value (dates, day count, the raw JSON, and a LABEL with
#+ the dateRange style). Validation is the model's.

IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper
IMPORT FGL InputDemoModel

#+ The view record. reportPeriod and comparePeriod hold the JSON value of the two
#+ date range fields; the other members show how BDL reads it.
PUBLIC TYPE tReportPeriodsView RECORD
   reportPeriod  STRING,
   comparePeriod STRING,
   reportStart   DATE,
   reportEnd     DATE,
   reportDays    INTEGER,
   compareStart  DATE,
   compareEnd    DATE,
   compareDays   INTEGER,
   reportJson    STRING,
   compareJson   STRING,
   reportLabel   STRING
END RECORD

#+ View record to model record. The JSON bridge does not apply: each JSON field
#+ value becomes a record of two DATEs, which DateRangeHelper deserializes. A field
#+ that holds no valid range gives an empty range.
PUBLIC FUNCTION toDbReportPeriods(viewRec tReportPeriodsView) RETURNS InputDemoModel.tReportPeriods
   VAR dbRec InputDemoModel.tReportPeriods
   LET dbRec.reportPeriod = DateRangeHelper.parseDateRange(viewRec.reportPeriod)
   LET dbRec.comparePeriod = DateRangeHelper.parseDateRange(viewRec.comparePeriod)
   RETURN dbRec
END FUNCTION

PUBLIC FUNCTION inputDemoRun() RETURNS ()
   VAR rec tReportPeriodsView
   VAR monthToDate DateRangeHelper.tDateRange
   OPEN WINDOW wInputDemo WITH FORM "InputDemo"
      ATTRIBUTES(TEXT = "Input")
   # Screen default: the month to date, serialized the way the widget expects it
   LET monthToDate.startDate = MDY(MONTH(TODAY), 1, YEAR(TODAY))
   LET monthToDate.endDate = TODAY
   LET rec.reportPeriod = monthToDate.serialize()
   CALL showPeriods(rec)
   # Accept shows the result and starts over; Cancel closes the screen
   WHILE inputPeriods(rec)
      MESSAGE SFMT("Report from %1 to %2 (%3 days).", rec.reportStart, rec.reportEnd, rec.reportDays)
   END WHILE
   CLOSE WINDOW wInputDemo
END FUNCTION

PRIVATE FUNCTION inputPeriods(rec tReportPeriodsView INOUT) RETURNS BOOLEAN
   VAR periods InputDemoModel.tReportPeriods
   VAR valid BOOLEAN
   VAR errorText STRING
   LET int_flag = FALSE
   INPUT BY NAME rec.reportPeriod, rec.comparePeriod
      ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)
      ON CHANGE reportPeriod
         CALL showPeriods(rec)
      ON CHANGE comparePeriod
         CALL showPeriods(rec)
      AFTER INPUT
         IF NOT int_flag THEN
            CALL showPeriods(rec)
            IF NOT isPeriodText(rec.reportPeriod) THEN
               ERROR "The report period is not a date range."
               NEXT FIELD reportPeriod
            END IF
            IF NOT isPeriodText(rec.comparePeriod) THEN
               ERROR "The comparison period is not a date range."
               NEXT FIELD comparePeriod
            END IF
            LET periods = toDbReportPeriods(rec)
            CALL InputDemoModel.validateReportPeriod(periods.reportPeriod)
               RETURNING valid, errorText
            IF NOT valid THEN
               ERROR errorText
               NEXT FIELD reportPeriod
            END IF
            CALL InputDemoModel.validateComparePeriod(periods.comparePeriod)
               RETURNING valid, errorText
            IF NOT valid THEN
               ERROR errorText
               NEXT FIELD comparePeriod
            END IF
         END IF
   END INPUT
   RETURN NOT int_flag
END FUNCTION

#+ TRUE for an empty field or a valid date range: an empty field is the model's to judge.
PRIVATE FUNCTION isPeriodText(periodText STRING) RETURNS BOOLEAN
   VAR dateRange DateRangeHelper.tDateRange
   IF periodText IS NULL THEN
      RETURN TRUE
   END IF
   RETURN dateRange.deserialize(periodText)
END FUNCTION

#+ Deserializes both fields into the members that show what BDL reads.
PRIVATE FUNCTION showPeriods(rec tReportPeriodsView INOUT) RETURNS ()
   VAR periods InputDemoModel.tReportPeriods
   LET periods = toDbReportPeriods(rec)
   LET rec.reportStart = periods.reportPeriod.startDate
   LET rec.reportEnd = periods.reportPeriod.endDate
   LET rec.reportDays = periods.reportPeriod.days()
   LET rec.compareStart = periods.comparePeriod.startDate
   LET rec.compareEnd = periods.comparePeriod.endDate
   LET rec.compareDays = periods.comparePeriod.days()
   LET rec.reportJson = rec.reportPeriod
   LET rec.compareJson = rec.comparePeriod
   LET rec.reportLabel = rec.reportPeriod
   DISPLAY BY NAME rec.reportStart, rec.reportEnd, rec.reportDays,
         rec.compareStart, rec.compareEnd, rec.compareDays,
         rec.reportJson, rec.compareJson, rec.reportLabel
END FUNCTION
