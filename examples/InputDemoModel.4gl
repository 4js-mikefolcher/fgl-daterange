#+ Model of the INPUT demo: the record the controller converts the screen into,
#+ and the business rules on the two periods. No UI, no database.

IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper

PRIVATE CONSTANT cMaxReportDays = 366

#+ The two periods of a report, as BDL works with them: DATEs, not JSON.
PUBLIC TYPE tReportPeriods RECORD
   reportPeriod  DateRangeHelper.tDateRange,
   comparePeriod DateRangeHelper.tDateRange
END RECORD

#+ The report period is required, cannot end before it starts, and cannot be longer
#+ than a year. Returns TRUE, or FALSE with a message for the user.
PUBLIC FUNCTION validateReportPeriod(dateRange DateRangeHelper.tDateRange) RETURNS (BOOLEAN, STRING)
   IF dateRange.startDate IS NULL OR dateRange.endDate IS NULL THEN
      RETURN FALSE, "Enter the report period."
   END IF
   IF dateRange.endDate < dateRange.startDate THEN
      RETURN FALSE, "The report period ends before it starts."
   END IF
   IF dateRange.days() > cMaxReportDays THEN
      RETURN FALSE, SFMT("The report period cannot be longer than %1 days.", cMaxReportDays)
   END IF
   RETURN TRUE, NULL
END FUNCTION

#+ The comparison period is optional, and cannot end before it starts.
#+ Returns TRUE, or FALSE with a message for the user.
PUBLIC FUNCTION validateComparePeriod(dateRange DateRangeHelper.tDateRange) RETURNS (BOOLEAN, STRING)
   IF dateRange.startDate IS NULL OR dateRange.endDate IS NULL THEN
      RETURN TRUE, NULL
   END IF
   IF dateRange.endDate < dateRange.startDate THEN
      RETURN FALSE, "The comparison period ends before it starts."
   END IF
   RETURN TRUE, NULL
END FUNCTION
