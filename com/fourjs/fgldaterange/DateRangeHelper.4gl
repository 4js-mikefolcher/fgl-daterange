#+ Reads and writes the value of a date range field: an EDIT whose 4ST style sets
#+ customWidget to dateRange, shown by the GBC widget shipped in this package (gbc/).
#+
#+ The field value is a JSON string, {"startDate":"YYYY-MM-DD","endDate":"YYYY-MM-DD"}.
#+ util.JSON reads and writes DATE in that ISO format, whatever DBDATE is.
#+
#+ tDateRange carries the methods, so a program writes
#+    VAR period DateRangeHelper.tDateRange
#+    IF period.deserialize(rec.period) THEN ... END IF
#+    LET rec.period = period.serialize()
#+ A leaf helper with no UI: controllers and models may import it.

PACKAGE com.fourjs.fgldaterange

IMPORT util

#+ A date range as the field value carries it. The member names are the JSON keys.
PUBLIC TYPE tDateRange RECORD
   startDate DATE,
   endDate   DATE
END RECORD

#+ Both dates are set. A DATE variable starts at 0 (1899-12-31), not NULL, so a range
#+ declared with VAR holds two real dates until clear() or deserialize() is called.
PUBLIC FUNCTION (self tDateRange) isComplete() RETURNS BOOLEAN
   IF self.startDate IS NULL OR self.endDate IS NULL THEN
      RETURN FALSE
   END IF
   RETURN TRUE
END FUNCTION

#+ Sets both dates to NULL: an empty range.
PUBLIC FUNCTION (self tDateRange) clear() RETURNS ()
   INITIALIZE self.* TO NULL
END FUNCTION

#+ Number of days, both ends included. NULL when either date is NULL.
PUBLIC FUNCTION (self tDateRange) days() RETURNS INTEGER
   IF NOT self.isComplete() THEN
      RETURN NULL
   END IF
   RETURN self.endDate - self.startDate + 1
END FUNCTION

#+ The date is inside the range, both ends included. FALSE for an incomplete range or a
#+ NULL date.
PUBLIC FUNCTION (self tDateRange) contains(checkDate DATE) RETURNS BOOLEAN
   IF checkDate IS NULL OR NOT self.isComplete() THEN
      RETURN FALSE
   END IF
   RETURN checkDate >= self.startDate AND checkDate <= self.endDate
END FUNCTION

#+ The two ranges share at least one day. FALSE when either range is incomplete.
PUBLIC FUNCTION (self tDateRange) overlaps(other tDateRange) RETURNS BOOLEAN
   IF NOT self.isComplete() OR NOT other.isComplete() THEN
      RETURN FALSE
   END IF
   RETURN self.startDate <= other.endDate AND other.startDate <= self.endDate
END FUNCTION

#+ Serialize the range into the value of a date range field.
#+ Returns NULL, which empties the field, when either date is NULL.
PUBLIC FUNCTION (self tDateRange) serialize() RETURNS STRING
   IF NOT self.isComplete() THEN
      RETURN NULL
   END IF
   RETURN util.JSON.stringify(self)
END FUNCTION

#+ The range that the value of a date range field holds, or an empty range when it holds
#+ none. For conversions that do not need to know whether the text was a range; use the
#+ deserialize method when they do.
PUBLIC FUNCTION parseDateRange(jsonText STRING) RETURNS tDateRange
   VAR dateRange tDateRange
   VAR valid BOOLEAN
   LET valid = dateRange.deserialize(jsonText)
   RETURN dateRange
END FUNCTION

#+ Deserialize the value of a date range field into the range.
#+ Returns TRUE when the text holds both dates. Returns FALSE and leaves an empty range
#+ for a NULL value, text that is not JSON, or a missing or non-ISO date:
#+ util.JSON.parse turns a date it cannot read into NULL without raising an error.
PUBLIC FUNCTION (self tDateRange) deserialize(jsonText STRING) RETURNS BOOLEAN
   CALL self.clear()
   IF jsonText IS NULL THEN
      RETURN FALSE
   END IF
   TRY
      CALL util.JSON.parse(jsonText, self)
   CATCH
      CALL self.clear()
      RETURN FALSE
   END TRY
   IF NOT self.isComplete() THEN
      CALL self.clear()
      RETURN FALSE
   END IF
   RETURN TRUE
END FUNCTION
