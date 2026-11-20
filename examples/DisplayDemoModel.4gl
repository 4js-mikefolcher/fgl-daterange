#+ Model of the DISPLAY demo: the calendar periods the screen shows, derived from a date.
#+ No UI, no database.

IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper

#+ The month that lies monthOffset months from the month of refDate: 0 is that month, -1 the
#+ month before it, 1 the month after it.
PUBLIC FUNCTION monthPeriod(refDate DATE, monthOffset INTEGER) RETURNS DateRangeHelper.tDateRange
   VAR firstDay DATE
   VAR nextFirstDay DATE
   VAR period DateRangeHelper.tDateRange
   LET firstDay = MDY(MONTH(refDate), 1, YEAR(refDate)) + monthOffset UNITS MONTH
   LET nextFirstDay = firstDay + 1 UNITS MONTH
   LET period.startDate = firstDay
   LET period.endDate = nextFirstDay - 1
   RETURN period
END FUNCTION

#+ The last dayCount days up to and including refDate.
PUBLIC FUNCTION lastDaysPeriod(refDate DATE, dayCount INTEGER) RETURNS DateRangeHelper.tDateRange
   VAR period DateRangeHelper.tDateRange
   LET period.startDate = refDate - (dayCount - 1)
   LET period.endDate = refDate
   RETURN period
END FUNCTION

#+ The calendar quarter of refDate.
PUBLIC FUNCTION quarterPeriod(refDate DATE) RETURNS DateRangeHelper.tDateRange
   VAR firstMonth INTEGER
   VAR firstDay DATE
   VAR nextFirstDay DATE
   VAR period DateRangeHelper.tDateRange
   LET firstMonth = MONTH(refDate) - ((MONTH(refDate) - 1) MOD 3)
   LET firstDay = MDY(firstMonth, 1, YEAR(refDate))
   LET nextFirstDay = firstDay + 3 UNITS MONTH
   LET period.startDate = firstDay
   LET period.endDate = nextFirstDay - 1
   RETURN period
END FUNCTION

#+ The calendar year of refDate.
PUBLIC FUNCTION yearPeriod(refDate DATE) RETURNS DateRangeHelper.tDateRange
   VAR period DateRangeHelper.tDateRange
   LET period.startDate = MDY(1, 1, YEAR(refDate))
   LET period.endDate = MDY(12, 31, YEAR(refDate))
   RETURN period
END FUNCTION
