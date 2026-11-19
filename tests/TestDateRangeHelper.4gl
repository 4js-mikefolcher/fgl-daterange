#+ fglunit suite of DateRangeHelper: the JSON contract with the GBC DateRangeWidget, and the
#+ methods of tDateRange.

IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL com.fourjs.fglunit.CliArgs
IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper

MAIN
   CALL CliArgs.parse()
   CALL FglUnit.suite("DateRangeHelper")
   CALL FglUnit.register("testDeserializeValid", FUNCTION testDeserializeValid)
   CALL FglUnit.register("testDeserializeNullGivesNullDates", FUNCTION testDeserializeNullGivesNullDates)
   CALL FglUnit.register("testDeserializeNotJson", FUNCTION testDeserializeNotJson)
   CALL FglUnit.register("testDeserializeNonIsoDate", FUNCTION testDeserializeNonIsoDate)
   CALL FglUnit.register("testDeserializeMissingEndDate", FUNCTION testDeserializeMissingEndDate)
   CALL FglUnit.register("testDeserializeFailureEmptiesTheRange", FUNCTION testDeserializeFailureEmptiesTheRange)
   CALL FglUnit.register("testDeserializeEmptyObject", FUNCTION testDeserializeEmptyObject)
   CALL FglUnit.register("testDeserializeNullDates", FUNCTION testDeserializeNullDates)
   CALL FglUnit.register("testDeserializeIgnoresUnknownKeys", FUNCTION testDeserializeIgnoresUnknownKeys)
   CALL FglUnit.register("testDeserializeAcceptsWhitespace", FUNCTION testDeserializeAcceptsWhitespace)
   CALL FglUnit.register("testParseDateRange", FUNCTION testParseDateRange)
   CALL FglUnit.register("testSerializeMatchesWidgetFormat", FUNCTION testSerializeMatchesWidgetFormat)
   CALL FglUnit.register("testSerializeIncompleteRange", FUNCTION testSerializeIncompleteRange)
   CALL FglUnit.register("testSerializeOneDayRange", FUNCTION testSerializeOneDayRange)
   CALL FglUnit.register("testRoundTrip", FUNCTION testRoundTrip)
   CALL FglUnit.register("testRoundTripLeapDay", FUNCTION testRoundTripLeapDay)
   CALL FglUnit.register("testDays", FUNCTION testDays)
   CALL FglUnit.register("testDaysAcrossLeapDay", FUNCTION testDaysAcrossLeapDay)
   CALL FglUnit.register("testIsCompleteAndClear", FUNCTION testIsCompleteAndClear)
   CALL FglUnit.register("testContains", FUNCTION testContains)
   CALL FglUnit.register("testContainsOneDayRange", FUNCTION testContainsOneDayRange)
   CALL FglUnit.register("testOverlaps", FUNCTION testOverlaps)
   CALL FglUnit.register("testOverlapsIdenticalAndOneDay", FUNCTION testOverlapsIdenticalAndOneDay)
   EXIT PROGRAM FglUnit.run()
END MAIN

PUBLIC FUNCTION testDeserializeValid() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL Assertions.assertTrue(
      dateRange.deserialize('{"startDate":"2026-11-01","endDate":"2026-11-30"}'),
      "a JSON date range is valid")
   CALL Assertions.assertNotNull(dateRange.startDate, "startDate read")
   CALL Assertions.assertNotNull(dateRange.endDate, "endDate read")
   CALL Assertions.assertTrue(dateRange.startDate = MDY(11, 1, 2026), "startDate is 2026-11-01")
   CALL Assertions.assertTrue(dateRange.endDate = MDY(11, 30, 2026), "endDate is 2026-11-30")
END FUNCTION

#+ A DATE variable starts at 0 (1899-12-31): an empty field must still give NULL dates.
PUBLIC FUNCTION testDeserializeNullGivesNullDates() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL Assertions.assertFalse(dateRange.deserialize(NULL), "NULL is not a range")
   CALL Assertions.assertNull(dateRange.startDate, "startDate NULL, not 1899-12-31")
   CALL Assertions.assertNull(dateRange.endDate, "endDate NULL, not 1899-12-31")
END FUNCTION

PUBLIC FUNCTION testDeserializeNotJson() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL Assertions.assertFalse(dateRange.deserialize("next week"),
      "text typed in the field is not a range")
   CALL Assertions.assertNull(dateRange.startDate, "startDate NULL")
   CALL Assertions.assertNull(dateRange.endDate, "endDate NULL")
END FUNCTION

#+ util.JSON.parse turns a date it cannot read into NULL without an error.
PUBLIC FUNCTION testDeserializeNonIsoDate() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL Assertions.assertFalse(
      dateRange.deserialize('{"startDate":"11/01/2026","endDate":"2026-11-30"}'),
      "a non-ISO date is rejected")
   CALL Assertions.assertNull(dateRange.endDate, "no half range is returned")
END FUNCTION

PUBLIC FUNCTION testDeserializeMissingEndDate() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL Assertions.assertFalse(dateRange.deserialize('{"startDate":"2026-11-01"}'),
      "a range needs both dates")
   CALL Assertions.assertNull(dateRange.startDate, "no half range is returned")
END FUNCTION

#+ A range that held a value before a failed deserialize does not keep it.
PUBLIC FUNCTION testDeserializeFailureEmptiesTheRange() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(11, 1, 2026)
   LET dateRange.endDate = MDY(11, 30, 2026)
   CALL Assertions.assertFalse(dateRange.deserialize("next week"), "typed text is not a range")
   CALL Assertions.assertNull(dateRange.startDate, "the old startDate is gone")
   CALL Assertions.assertNull(dateRange.endDate, "the old endDate is gone")
END FUNCTION

#+ parseDateRange gives the range, or an empty range, without a result to check.
PUBLIC FUNCTION testParseDateRange() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET dateRange = DateRangeHelper.parseDateRange('{"startDate":"2026-11-01","endDate":"2026-11-30"}')
   CALL Assertions.assertNotNull(dateRange.startDate, "startDate read")
   CALL Assertions.assertNotNull(dateRange.endDate, "endDate read")
   CALL Assertions.assertTrue(dateRange.startDate = MDY(11, 1, 2026), "startDate is 2026-11-01")
   CALL Assertions.assertTrue(dateRange.endDate = MDY(11, 30, 2026), "endDate is 2026-11-30")
   LET dateRange = DateRangeHelper.parseDateRange("next week")
   CALL Assertions.assertNull(dateRange.startDate, "typed text: startDate NULL")
   CALL Assertions.assertNull(dateRange.endDate, "typed text: endDate NULL")
   LET dateRange = DateRangeHelper.parseDateRange(NULL)
   CALL Assertions.assertNull(dateRange.startDate, "empty field: startDate NULL")
END FUNCTION

#+ The widget parses exactly this text: keys, key order and ISO dates.
PUBLIC FUNCTION testSerializeMatchesWidgetFormat() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(11, 1, 2026)
   LET dateRange.endDate = MDY(11, 30, 2026)
   CALL Assertions.assertEquals('{"startDate":"2026-11-01","endDate":"2026-11-30"}',
      dateRange.serialize(), "JSON value of the field")
END FUNCTION

PUBLIC FUNCTION testSerializeIncompleteRange() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL dateRange.clear()
   LET dateRange.startDate = MDY(11, 1, 2026)
   CALL Assertions.assertNull(dateRange.serialize(), "a half range empties the field")
END FUNCTION

PUBLIC FUNCTION testRoundTrip() RETURNS ()
   VAR original DateRangeHelper.tDateRange
   VAR copy DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET original.startDate = MDY(2, 28, 2024)
   LET original.endDate = MDY(3, 1, 2024)
   CALL Assertions.assertTrue(copy.deserialize(original.serialize()), "the serialized range reads back")
   CALL Assertions.assertNotNull(copy.startDate, "startDate read back")
   CALL Assertions.assertNotNull(copy.endDate, "endDate read back")
   CALL Assertions.assertTrue(copy.startDate = original.startDate, "startDate unchanged")
   CALL Assertions.assertTrue(copy.endDate = original.endDate, "endDate unchanged")
END FUNCTION

PUBLIC FUNCTION testDays() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(11, 1, 2026)
   LET dateRange.endDate = MDY(11, 30, 2026)
   CALL Assertions.assertEqualsInt(30, dateRange.days(), "both ends included")
   LET dateRange.endDate = dateRange.startDate
   CALL Assertions.assertEqualsInt(1, dateRange.days(), "a one-day range")
   LET dateRange.endDate = NULL
   CALL Assertions.assertNull(dateRange.days(), "NULL for a half range")
END FUNCTION

PUBLIC FUNCTION testIsCompleteAndClear() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(11, 1, 2026)
   LET dateRange.endDate = MDY(11, 30, 2026)
   CALL Assertions.assertTrue(dateRange.isComplete(), "both dates set")
   LET dateRange.endDate = NULL
   CALL Assertions.assertFalse(dateRange.isComplete(), "one date missing")
   LET dateRange.endDate = MDY(11, 30, 2026)
   CALL dateRange.clear()
   CALL Assertions.assertNull(dateRange.startDate, "clear empties startDate")
   CALL Assertions.assertNull(dateRange.endDate, "clear empties endDate")
   CALL Assertions.assertFalse(dateRange.isComplete(), "a cleared range is not complete")
END FUNCTION

PUBLIC FUNCTION testContains() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(11, 1, 2026)
   LET dateRange.endDate = MDY(11, 30, 2026)
   CALL Assertions.assertTrue(dateRange.contains(MDY(11, 1, 2026)), "the first day is inside")
   CALL Assertions.assertTrue(dateRange.contains(MDY(11, 15, 2026)), "a middle day is inside")
   CALL Assertions.assertTrue(dateRange.contains(MDY(11, 30, 2026)), "the last day is inside")
   CALL Assertions.assertFalse(dateRange.contains(MDY(10, 31, 2026)), "the day before is outside")
   CALL Assertions.assertFalse(dateRange.contains(MDY(12, 1, 2026)), "the day after is outside")
   CALL Assertions.assertFalse(dateRange.contains(NULL), "a NULL date is outside")
   CALL dateRange.clear()
   CALL Assertions.assertFalse(dateRange.contains(MDY(11, 15, 2026)), "an empty range holds nothing")
END FUNCTION

PUBLIC FUNCTION testOverlaps() RETURNS ()
   VAR november DateRangeHelper.tDateRange
   VAR other DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET november.startDate = MDY(11, 1, 2026)
   LET november.endDate = MDY(11, 30, 2026)
   LET other.startDate = MDY(11, 30, 2026)
   LET other.endDate = MDY(12, 15, 2026)
   CALL Assertions.assertTrue(november.overlaps(other), "sharing the last day is an overlap")
   CALL Assertions.assertTrue(other.overlaps(november), "overlap is symmetric")
   LET other.startDate = MDY(12, 1, 2026)
   CALL Assertions.assertFalse(november.overlaps(other), "the next day starts a new range")
   LET other.startDate = MDY(11, 10, 2026)
   LET other.endDate = MDY(11, 12, 2026)
   CALL Assertions.assertTrue(november.overlaps(other), "a range inside another overlaps it")
   CALL other.clear()
   CALL Assertions.assertFalse(november.overlaps(other), "an empty range overlaps nothing")
END FUNCTION

#+ Two ranges that share only the first or only the last day, one range inside the other,
#+ and a range that is the same as the other: the boundaries are included on both sides.
PUBLIC FUNCTION testOverlapsIdenticalAndOneDay() RETURNS ()
   VAR november DateRangeHelper.tDateRange
   VAR other DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET november.startDate = MDY(11, 1, 2026)
   LET november.endDate = MDY(11, 30, 2026)
   LET other.startDate = MDY(11, 1, 2026)
   LET other.endDate = MDY(11, 30, 2026)
   CALL Assertions.assertTrue(november.overlaps(other), "the same range overlaps itself")
   LET other.startDate = MDY(10, 15, 2026)
   LET other.endDate = MDY(11, 1, 2026)
   CALL Assertions.assertTrue(november.overlaps(other), "sharing only the first day is an overlap")
   LET other.startDate = MDY(10, 15, 2026)
   LET other.endDate = MDY(10, 31, 2026)
   CALL Assertions.assertFalse(november.overlaps(other), "ending the day before is no overlap")
   CALL Assertions.assertFalse(other.overlaps(november), "no overlap is symmetric too")
   LET other.startDate = MDY(11, 15, 2026)
   LET other.endDate = MDY(11, 15, 2026)
   CALL Assertions.assertTrue(november.overlaps(other), "a one-day range inside overlaps")
   CALL Assertions.assertTrue(other.overlaps(november), "a one-day range overlaps the longer one")
END FUNCTION

#+ A range of one day holds exactly that day.
PUBLIC FUNCTION testContainsOneDayRange() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(11, 15, 2026)
   LET dateRange.endDate = MDY(11, 15, 2026)
   CALL Assertions.assertTrue(dateRange.contains(MDY(11, 15, 2026)), "the day itself is inside")
   CALL Assertions.assertFalse(dateRange.contains(MDY(11, 14, 2026)), "the day before is outside")
   CALL Assertions.assertFalse(dateRange.contains(MDY(11, 16, 2026)), "the day after is outside")
END FUNCTION

#+ 2024 is a leap year: 1 February to 1 March has 30 days, not 29.
PUBLIC FUNCTION testDaysAcrossLeapDay() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(2, 1, 2024)
   LET dateRange.endDate = MDY(3, 1, 2024)
   CALL Assertions.assertEqualsInt(30, dateRange.days(), "29 February is counted")
   LET dateRange.startDate = MDY(2, 1, 2026)
   LET dateRange.endDate = MDY(3, 1, 2026)
   CALL Assertions.assertEqualsInt(29, dateRange.days(), "no 29 February in 2026")
END FUNCTION

#+ 29 February must survive the JSON text, in both directions.
PUBLIC FUNCTION testRoundTripLeapDay() RETURNS ()
   VAR original DateRangeHelper.tDateRange
   VAR copy DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET original.startDate = MDY(2, 29, 2024)
   LET original.endDate = MDY(2, 29, 2024)
   CALL Assertions.assertEquals('{"startDate":"2024-02-29","endDate":"2024-02-29"}',
      original.serialize(), "the leap day is written")
   CALL Assertions.assertTrue(copy.deserialize(original.serialize()), "the leap day reads back")
   CALL Assertions.assertNotNull(copy.startDate, "startDate read back")
   CALL Assertions.assertTrue(copy.startDate = MDY(2, 29, 2024), "startDate is 2024-02-29")
   CALL Assertions.assertTrue(copy.endDate = MDY(2, 29, 2024), "endDate is 2024-02-29")
END FUNCTION

#+ The widget writes a range of one day with the same date twice.
PUBLIC FUNCTION testSerializeOneDayRange() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(11, 15, 2026)
   LET dateRange.endDate = MDY(11, 15, 2026)
   CALL Assertions.assertEquals('{"startDate":"2026-11-15","endDate":"2026-11-15"}',
      dateRange.serialize(), "both dates are written")
END FUNCTION

#+ The widget may format the JSON with spaces; the dates are the same.
PUBLIC FUNCTION testDeserializeAcceptsWhitespace() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL Assertions.assertTrue(
      dateRange.deserialize('{ "startDate" : "2026-11-01",  "endDate" : "2026-11-30" }'),
      "spaces around the tokens are fine")
   CALL Assertions.assertNotNull(dateRange.startDate, "startDate read")
   CALL Assertions.assertNotNull(dateRange.endDate, "endDate read")
   CALL Assertions.assertTrue(dateRange.startDate = MDY(11, 1, 2026), "startDate is 2026-11-01")
   CALL Assertions.assertTrue(dateRange.endDate = MDY(11, 30, 2026), "endDate is 2026-11-30")
END FUNCTION

#+ A key that is not part of the range (a later version of the widget may add one) is skipped.
PUBLIC FUNCTION testDeserializeIgnoresUnknownKeys() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL Assertions.assertTrue(
      dateRange.deserialize('{"startDate":"2026-11-01","endDate":"2026-11-30","label":"November"}'),
      "an extra key does not make the range invalid")
   CALL Assertions.assertNotNull(dateRange.startDate, "startDate read")
   CALL Assertions.assertNotNull(dateRange.endDate, "endDate read")
   CALL Assertions.assertTrue(dateRange.endDate = MDY(11, 30, 2026), "endDate is 2026-11-30")
END FUNCTION

#+ JSON null dates, as an emptied widget could send them.
PUBLIC FUNCTION testDeserializeNullDates() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL Assertions.assertFalse(dateRange.deserialize('{"startDate":null,"endDate":null}'),
      "null dates are no range")
   CALL Assertions.assertNull(dateRange.startDate, "startDate NULL")
   CALL Assertions.assertNull(dateRange.endDate, "endDate NULL")
END FUNCTION

PUBLIC FUNCTION testDeserializeEmptyObject() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   CALL Assertions.assertFalse(dateRange.deserialize("{}"), "an empty object is no range")
   CALL Assertions.assertNull(dateRange.startDate, "startDate NULL, not 1899-12-31")
   CALL Assertions.assertNull(dateRange.endDate, "endDate NULL, not 1899-12-31")
   CALL Assertions.assertFalse(dateRange.deserialize(""), "an empty string is NULL, so no range")
   CALL Assertions.assertNull(dateRange.startDate, "startDate NULL after the empty string")
END FUNCTION
