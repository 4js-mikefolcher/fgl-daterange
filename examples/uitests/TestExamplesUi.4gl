#+ Functional tests of the date range examples (examples/): 4js-fgltest starts MainController
#+ through GGC, the Genero Ghost Client, and drives it over the front-end protocol.
#+
#+ This checks the runtime side of the date range field: what the program sends to the front
#+ end (the JSON value, the AUI tree), what it accepts back (typed JSON, CONSTRUCT criteria)
#+ and how the dialogs react. GGC runs no browser, so the GBC widget itself is NOT exercised:
#+ the browser checklist is TESTING.md.
#+
#+ Run it with `make uitest` in examples/, which sets what the suite relies on:
#+    DBDATE=MDY4/                      the CONSTRUCT criteria are typed as mm/dd/yyyy
#+    an empty SQLite file as database  the Construct screen creates and fills its orders table
#+
#+ Fixtures: the orders are one every two days back from today (order i = TODAY - 2 * i, i = 1
#+ to 60, customer Contoso Ltd for i MOD 5 = 1), so the expected counts are computed from
#+ today's date. The five campaigns are kept in memory by ArrayDemoModel for the life of the
#+ program; tests that change them do not rely on each other.
#+
#+ inspect has no reader for a field value in 4js-fgltest 1.1.2, so fieldValue() and nodes()
#+ go through the driver.

IMPORT xml

IMPORT FGL com.fourjs.fgltest.runner
IMPORT FGL com.fourjs.fgltest.flow
IMPORT FGL com.fourjs.fgltest.expect
IMPORT FGL com.fourjs.fgltest.inspect
IMPORT FGL com.fourjs.fgltest.core
IMPORT FGL com.fourjs.fgltest.driver

#+ Characters of {"startDate":"YYYY-MM-DD","endDate":"YYYY-MM-DD"}.
PRIVATE CONSTANT cJsonLength = 49
PRIVATE CONSTANT cSampleOrders = 60

MAIN
   CALL runner.setApplication("MainController")
   CALL runner.beforeEach(FUNCTION ensureMenu)
   CALL runner.afterAll(FUNCTION leaveApp)
   # the program and its screens
   CALL runner.test("session date format is MDY4/", FUNCTION testDbDate)
   CALL runner.test("menu offers the five screens", FUNCTION testMenu)
   CALL runner.test("input screen opens and closes", FUNCTION testOpenInput)
   CALL runner.test("construct screen opens and closes", FUNCTION testOpenConstruct)
   CALL runner.test("display screen opens and closes", FUNCTION testOpenDisplay)
   CALL runner.test("display array screen opens and closes", FUNCTION testOpenDisplayArray)
   CALL runner.test("input array screen opens and closes", FUNCTION testOpenInputArray)
   # the whole JSON value reaches the front end (needs SCROLL on a field a dialog edits)
   CALL runner.test("value length: display screen", FUNCTION testLengthDisplay)
   CALL runner.test("value length: input screen", FUNCTION testLengthInput)
   CALL runner.test("value length: display array column", FUNCTION testLengthDisplayArray)
   CALL runner.test("value length: input array column", FUNCTION testLengthInputArray)
   # INPUT reads the JSON
   CALL runner.test("input: typed JSON updates the dates and the days", FUNCTION testInputTyped)
   CALL runner.test("input: text that is not a range is refused", FUNCTION testInputNotARange)
   # CONSTRUCT: the criteria the runtime accepts
   CALL runner.test("construct: empty criteria find every order", FUNCTION testConstructEmpty)
   CALL runner.test("construct: range d1:d2", FUNCTION testConstructRange)
   CALL runner.test("construct: range d1 : d2", FUNCTION testConstructSpacedColon)
   CALL runner.test("construct: one day as d1:d1", FUNCTION testConstructSameDay)
   CALL runner.test("construct: single date", FUNCTION testConstructSingleDate)
   CALL runner.test("construct: >= date", FUNCTION testConstructGreaterEqual)
   CALL runner.test("construct: dates without leading zeros", FUNCTION testConstructShortDigits)
   CALL runner.test("construct: customer criteria beside the date", FUNCTION testConstructCustomer)
   # CONSTRUCT: what the runtime refuses, so the widget must never send it
   CALL runner.test("construct refuses: range d1 - d2", FUNCTION testConstructRefusesDash)
   CALL runner.test("construct refuses: ISO dates", FUNCTION testConstructRefusesIso)
   CALL runner.test("construct refuses: open range d1:", FUNCTION testConstructRefusesOpenEnd)
   CALL runner.test("construct refuses: open range :d2", FUNCTION testConstructRefusesOpenStart)
   # the arrays
   CALL runner.test("display array: details action", FUNCTION testDisplayArrayDetails)
   CALL runner.test("input array: edit, days follow, accept saves", FUNCTION testInputArrayEditAndSave)
   CALL runner.test("input array: overlapping campaigns are refused", FUNCTION testInputArrayOverlap)
   CALL runner.run()
END MAIN

#+ Never called: the directive makes a runtime error in a test fail that test instead of
#+ stopping the whole run.
PRIVATE FUNCTION optInToRaise() RETURNS ()
   WHENEVER ANY ERROR RAISE
END FUNCTION

# ---- helpers -------------------------------------------------------------------------

PRIVATE FUNCTION fieldValue(fieldName STRING) RETURNS STRING
   VAR drv driver.Driver = core.getDriver()
   RETURN drv.fieldValue(fieldName)
END FUNCTION

PRIVATE FUNCTION nodes(xpath STRING) RETURNS xml.DomNodeList
   VAR drv driver.Driver = core.getDriver()
   VAR doc xml.DomDocument = drv.auiTree()
   RETURN doc.selectByXPath(xpath, NULL)
END FUNCTION

#+ An attribute of the first AUI node that matches the XPath, NULL when there is none.
PRIVATE FUNCTION auiAttr(xpath STRING, attrName STRING) RETURNS STRING
   VAR list xml.DomNodeList = nodes(xpath)
   VAR node xml.DomNode
   IF list.getCount() = 0 THEN
      RETURN NULL
   END IF
   LET node = list.getItem(1)
   RETURN node.getAttribute(attrName)
END FUNCTION

#+ Every Message element of the AUI (MESSAGE and ERROR text), as "text | text".
PRIVATE FUNCTION messages() RETURNS STRING
   VAR list xml.DomNodeList = nodes("//Message")
   VAR node xml.DomNode
   VAR buffer base.StringBuffer = base.StringBuffer.create()
   VAR i INTEGER
   FOR i = 1 TO list.getCount()
      LET node = list.getItem(i)
      IF i > 1 THEN
         CALL buffer.append(" | ")
      END IF
      CALL buffer.append(node.getAttribute("text"))
   END FOR
   RETURN buffer.toString()
END FUNCTION

PRIVATE FUNCTION lengthOf(text STRING) RETURNS INTEGER
   IF text IS NULL THEN
      RETURN 0
   END IF
   RETURN text.getLength()
END FUNCTION

#+ A sentence when the text is not the whole JSON value, an empty string when it is. The tests
#+ collect these and assert that the collection is empty, so a failure names every culprit.
PRIVATE FUNCTION lengthProblem(subject STRING, text STRING) RETURNS STRING
   IF lengthOf(text) <> cJsonLength THEN
      RETURN SFMT("%1 has %2 characters, expected %3; ", subject, lengthOf(text), cJsonLength)
   END IF
   RETURN ""
END FUNCTION

#+ The length problems of the fields of the current form, read two ways: what the driver
#+ reports for the field and the value the runtime put in the AUI tree.
PRIVATE FUNCTION fieldProblems(names DYNAMIC ARRAY OF STRING) RETURNS STRING
   VAR problems base.StringBuffer = base.StringBuffer.create()
   VAR path STRING
   VAR i INTEGER
   FOR i = 1 TO names.getLength()
      LET path = "//FormField[@name='formonly." || names[i] || "']"
      CALL problems.append(lengthProblem(names[i] || " (field)", fieldValue("formonly." || names[i])))
      CALL problems.append(lengthProblem(names[i] || " (AUI)", auiAttr(path, "value")))
   END FOR
   RETURN problems.toString()
END FUNCTION

#+ The length problems of the first five rows of the period column of the ArrayDemo table, read
#+ two ways: the AUI value list (what the front end receives) and the cell as GGC reads it.
PRIVATE FUNCTION periodColumnProblems(subject STRING) RETURNS STRING
   VAR problems base.StringBuffer = base.StringBuffer.create()
   VAR list xml.DomNodeList = nodes("//TableColumn[@colName='period']/ValueList/Value")
   VAR node xml.DomNode
   VAR i INTEGER
   FOR i = 1 TO 5
      LET node = list.getItem(i)
      CALL problems.append(lengthProblem(subject || " row " || i || " (AUI)", node.getAttribute("value")))
      CALL flow.selectRow("srcampaigns", i)
      CALL problems.append(
         lengthProblem(subject || " row " || i || " (cell)", inspect.cellValue("srcampaigns", "period", i)))
   END FOR
   RETURN problems.toString()
END FUNCTION

PRIVATE FUNCTION isoRange(startDate DATE, endDate DATE) RETURNS STRING
   RETURN '{"startDate":"' || (startDate USING "yyyy-mm-dd") || '","endDate":"'
      || (endDate USING "yyyy-mm-dd") || '"}'
END FUNCTION

#+ A date as the user types it in a CONSTRUCT field under DBDATE=MDY4/.
PRIVATE FUNCTION typedDate(theDate DATE) RETURNS STRING
   RETURN theDate USING "mm/dd/yyyy"
END FUNCTION

PRIVATE FUNCTION firstOfMonth() RETURNS DATE
   RETURN MDY(MONTH(TODAY), 1, YEAR(TODAY))
END FUNCTION

#+ How many sample orders are dated from startDate to endDate, both included.
PRIVATE FUNCTION sampleOrdersBetween(startDate DATE, endDate DATE) RETURNS INTEGER
   VAR found INTEGER = 0
   VAR orderDate DATE
   VAR i INTEGER
   FOR i = 1 TO cSampleOrders
      LET orderDate = TODAY - (i * 2)
      IF orderDate >= startDate AND orderDate <= endDate THEN
         LET found = found + 1
      END IF
   END FOR
   RETURN found
END FUNCTION

#+ Types the criteria into the search date field and accepts. Returns the number of rows of
#+ the result list, or -1 when the dialog did not end because the runtime refused the text.
PRIVATE FUNCTION searchRows(typed STRING) RETURNS INTEGER
   IF typed IS NOT NULL THEN
      CALL flow.fill("formonly.searchdate", typed)
   END IF
   CALL flow.action("accept")
   IF NOT inspect.hasAction("newsearch") THEN
      RETURN -1
   END IF
   RETURN inspect.rowCount("srorders")
END FUNCTION

#+ The text is refused: the search dialog stays open and the runtime says "Error in field".
#+ A failure here means the runtime now accepts it: revisit the CONSTRUCT contract in the README.
PRIVATE FUNCTION expectRefused(typed STRING) RETURNS ()
   CALL flow.action("construct")
   CALL expect.num(searchRows(typed)).toEqual(-1)
   CALL expect.that(messages()).toContainText("Error in field")
END FUNCTION

#+ The menu has the five demo actions and exit; the screens have no exit.
PRIVATE FUNCTION atMenu() RETURNS BOOLEAN
   RETURN inspect.hasAction("inputarray") AND inspect.hasAction("exit")
END FUNCTION

#+ Every test starts from the menu, whatever the previous test left open.
PRIVATE FUNCTION ensureMenu() RETURNS ()
   VAR tries INTEGER
   FOR tries = 1 TO 6
      IF atMenu() THEN
         RETURN
      END IF
      CALL flow.action("close")
   END FOR
END FUNCTION

PRIVATE FUNCTION leaveApp() RETURNS ()
   IF atMenu() THEN
      CALL flow.action("exit")
   END IF
END FUNCTION

PRIVATE FUNCTION backToMenu() RETURNS ()
   CALL flow.action("close")
   CALL expect.bool(atMenu()).toBeTrue()
END FUNCTION

# ---- the program and its screens -----------------------------------------------------

PUBLIC FUNCTION testDbDate() RETURNS ()
   CALL expect.that(auiAttr("/UserInterface", "dbDate")).toEqual("MDY4/")
END FUNCTION

PUBLIC FUNCTION testMenu() RETURNS ()
   VAR names inspect.StringList = inspect.activeActionNames()
   CALL expect.all(names).toContain("input")
   CALL expect.all(names).toContain("construct")
   CALL expect.all(names).toContain("display")
   CALL expect.all(names).toContain("displayarray")
   CALL expect.all(names).toContain("inputarray")
   CALL expect.all(names).toContain("exit")
END FUNCTION

PUBLIC FUNCTION testOpenInput() RETURNS ()
   CALL flow.action("input")
   CALL expect.that(inspect.formName()).toEqual("InputDemo")
   CALL expect.that(inspect.windowName()).toEqual("winputdemo")
   CALL expect.all(inspect.fieldNames()).toContain("formonly.reportperiod")
   CALL expect.all(inspect.fieldNames()).toContain("formonly.compareperiod")
   CALL expect.bool(inspect.hasAction("accept")).toBeTrue()
   CALL expect.that(inspect.applicationError()).toBeEmpty()
   CALL backToMenu()
END FUNCTION

PUBLIC FUNCTION testOpenConstruct() RETURNS ()
   CALL flow.action("construct")
   CALL expect.that(inspect.formName()).toEqual("ConstructDemo")
   CALL expect.all(inspect.fieldNames()).toContain("formonly.searchdate")
   CALL expect.all(inspect.fieldNames()).toContain("formonly.wheretext")
   CALL expect.bool(inspect.hasAction("accept")).toBeTrue()
   CALL expect.that(inspect.applicationError()).toBeEmpty()
   CALL backToMenu()
END FUNCTION

PUBLIC FUNCTION testOpenDisplay() RETURNS ()
   CALL flow.action("display")
   CALL expect.that(inspect.formName()).toEqual("DisplayDemo")
   CALL expect.bool(inspect.hasAction("previous")).toBeTrue()
   CALL expect.bool(inspect.hasAction("next")).toBeTrue()
   CALL expect.that(inspect.applicationError()).toBeEmpty()
   CALL backToMenu()
END FUNCTION

PUBLIC FUNCTION testOpenDisplayArray() RETURNS ()
   CALL flow.action("displayarray")
   CALL expect.that(inspect.formName()).toEqual("ArrayDemo")
   CALL expect.that(inspect.windowName()).toEqual("wdisplayarray")
   CALL expect.num(inspect.rowCount("srcampaigns")).toEqual(5)
   CALL expect.that(inspect.applicationError()).toBeEmpty()
   CALL backToMenu()
END FUNCTION

PUBLIC FUNCTION testOpenInputArray() RETURNS ()
   CALL flow.action("inputarray")
   CALL expect.that(inspect.formName()).toEqual("ArrayDemo")
   CALL expect.that(inspect.windowName()).toEqual("winputarray")
   CALL expect.num(inspect.rowCount("srcampaigns")).toEqual(5)
   CALL expect.that(inspect.applicationError()).toBeEmpty()
   CALL backToMenu()
END FUNCTION

# ---- the whole JSON value reaches the front end ----------------------------------------

PUBLIC FUNCTION testLengthDisplay() RETURNS ()
   VAR names DYNAMIC ARRAY OF STRING
   LET names[1] = "monthperiod"
   LET names[2] = "monthlabel"
   LET names[3] = "last30period"
   LET names[4] = "quarterperiod"
   LET names[5] = "yearperiod"
   CALL flow.action("display")
   CALL expect.that(fieldProblems(names)).toBeEmpty()
END FUNCTION

#+ A field that a dialog edits is cut to its width unless the form says SCROLL.
PUBLIC FUNCTION testLengthInput() RETURNS ()
   VAR names DYNAMIC ARRAY OF STRING
   LET names[1] = "reportperiod"
   LET names[2] = "reportjson"
   LET names[3] = "reportlabel"
   CALL flow.action("input")
   CALL expect.that(fieldProblems(names)).toBeEmpty()
END FUNCTION

PUBLIC FUNCTION testLengthDisplayArray() RETURNS ()
   CALL flow.action("displayarray")
   CALL expect.that(periodColumnProblems("display array")).toBeEmpty()
END FUNCTION

#+ A column that a dialog edits is cut to its width unless the form says SCROLL.
PUBLIC FUNCTION testLengthInputArray() RETURNS ()
   CALL flow.action("inputarray")
   CALL expect.that(periodColumnProblems("input array")).toBeEmpty()
END FUNCTION

# ---- input ---------------------------------------------------------------------------

PUBLIC FUNCTION testInputTyped() RETURNS ()
   VAR period STRING = isoRange(MDY(11, 1, 2026), MDY(11, 30, 2026))
   CALL flow.action("input")
   CALL flow.fill("formonly.reportperiod", period)
   # ON CHANGE fires when the field is left, as for a user pressing Tab
   CALL flow.field("formonly.compareperiod")
   CALL expect.that(fieldValue("formonly.reportperiod")).toEqual(period)
   CALL expect.that(fieldValue("formonly.reportstart")).toEqual("11/01/2026")
   CALL expect.that(fieldValue("formonly.reportend")).toEqual("11/30/2026")
   CALL expect.that(fieldValue("formonly.reportdays")).toEqual("30")
   CALL expect.that(fieldValue("formonly.reportjson")).toEqual(period)
   CALL flow.action("accept")
   CALL expect.that(messages()).toContainText("Report from 11/01/2026 to 11/30/2026 (30 days).")
END FUNCTION

PUBLIC FUNCTION testInputNotARange() RETURNS ()
   CALL flow.action("input")
   CALL flow.fill("formonly.reportperiod", "11/01/2026 - 11/30/2026")
   CALL flow.action("accept")
   CALL expect.that(messages()).toContainText("The report period is not a date range.")
   CALL expect.bool(inspect.hasAction("accept")).toBeTrue()
END FUNCTION

# ---- construct: what the runtime accepts -----------------------------------------------

PUBLIC FUNCTION testConstructEmpty() RETURNS ()
   CALL flow.action("construct")
   CALL expect.num(searchRows(NULL)).toEqual(cSampleOrders)
   CALL expect.that(messages()).toContainText(cSampleOrders || " orders found.")
END FUNCTION

#+ The last 30 days hold the orders 1 to 14, whatever today is.
PUBLIC FUNCTION testConstructRange() RETURNS ()
   CALL flow.action("construct")
   CALL expect.num(searchRows(typedDate(TODAY - 29) || ":" || typedDate(TODAY))).toEqual(14)
   CALL expect.that(messages()).toContainText("14 orders found.")
   CALL expect.that(fieldValue("formonly.wheretext")).notToBeEmpty()
END FUNCTION

PUBLIC FUNCTION testConstructSpacedColon() RETURNS ()
   CALL flow.action("construct")
   CALL expect.num(searchRows(typedDate(TODAY - 29) || " : " || typedDate(TODAY))).toEqual(14)
END FUNCTION

PUBLIC FUNCTION testConstructSameDay() RETURNS ()
   CALL flow.action("construct")
   CALL expect.num(searchRows(typedDate(TODAY - 6) || ":" || typedDate(TODAY - 6))).toEqual(1)
END FUNCTION

#+ Order 3 is dated TODAY - 6.
PUBLIC FUNCTION testConstructSingleDate() RETURNS ()
   CALL flow.action("construct")
   CALL expect.num(searchRows(typedDate(TODAY - 6))).toEqual(1)
END FUNCTION

PUBLIC FUNCTION testConstructGreaterEqual() RETURNS ()
   CALL flow.action("construct")
   CALL expect.num(searchRows(">=" || typedDate(firstOfMonth())))
      .toEqual(sampleOrdersBetween(firstOfMonth(), TODAY))
END FUNCTION

#+ A user can type 11/1/2026; the widget passes text it does not rewrite on to the runtime.
PUBLIC FUNCTION testConstructShortDigits() RETURNS ()
   VAR monthStart DATE = firstOfMonth()
   VAR typed STRING
   LET typed = (MONTH(monthStart) USING "<<") || "/" || (DAY(monthStart) USING "<<") || "/" || (YEAR(monthStart) USING "<<<<")
      || ":" || (MONTH(TODAY) USING "<<") || "/" || (DAY(TODAY) USING "<<") || "/" || (YEAR(TODAY) USING "<<<<")
   CALL flow.action("construct")
   CALL expect.num(searchRows(typed)).toEqual(sampleOrdersBetween(monthStart, TODAY))
END FUNCTION

#+ Of the orders 1 to 14 of the last 30 days, the customer Contoso Ltd has 1, 6 and 11.
PUBLIC FUNCTION testConstructCustomer() RETURNS ()
   CALL flow.action("construct")
   CALL flow.fill("formonly.searchcustomer", "Contoso*")
   CALL expect.num(searchRows(typedDate(TODAY - 29) || ":" || typedDate(TODAY))).toEqual(3)
END FUNCTION

# ---- construct: what the runtime refuses -----------------------------------------------

PUBLIC FUNCTION testConstructRefusesDash() RETURNS ()
   CALL expectRefused(typedDate(TODAY - 29) || " - " || typedDate(TODAY))
END FUNCTION

PUBLIC FUNCTION testConstructRefusesIso() RETURNS ()
   CALL expectRefused((TODAY - 29 USING "yyyy-mm-dd") || ":" || (TODAY USING "yyyy-mm-dd"))
END FUNCTION

PUBLIC FUNCTION testConstructRefusesOpenEnd() RETURNS ()
   CALL expectRefused(typedDate(firstOfMonth()) || ":")
END FUNCTION

PUBLIC FUNCTION testConstructRefusesOpenStart() RETURNS ()
   CALL expectRefused(":" || typedDate(TODAY - 30))
END FUNCTION

# ---- the arrays ----------------------------------------------------------------------

PUBLIC FUNCTION testDisplayArrayDetails() RETURNS ()
   CALL flow.action("displayarray")
   CALL flow.selectRow("srcampaigns", 1)
   CALL flow.action("details")
   CALL expect.that(messages()).toContainText("Welcome series runs from")
   CALL expect.that(messages()).toContainText("(30 days).")
END FUNCTION

#+ Row 3 is Black Friday. A shorter period keeps it clear of the next campaign, which starts at
#+ TODAY + 19, so this works from the sample campaigns and from an earlier run of this test.
PUBLIC FUNCTION testInputArrayEditAndSave() RETURNS ()
   VAR newPeriod STRING = isoRange(TODAY + 15, TODAY + 17)
   CALL flow.action("inputarray")
   CALL flow.focusCell("srcampaigns", "period", 3)
   CALL flow.enter(newPeriod)
   CALL flow.focusCell("srcampaigns", "campaignname", 3)
   CALL expect.that(inspect.currentCellValue("srcampaigns", "period")).toEqual(newPeriod)
   CALL expect.that(inspect.currentCellValue("srcampaigns", "days")).toEqual("3")
   CALL flow.action("accept")
   CALL expect.that(messages()).toContainText("Campaigns saved.")
   CALL expect.bool(atMenu()).toBeTrue()
   # the saved change is what the display array shows (leave the dialog first if the save failed,
   # so that the failure above is the one reported)
   CALL ensureMenu()
   CALL flow.action("displayarray")
   CALL flow.selectRow("srcampaigns", 3)
   CALL expect.that(inspect.currentCellValue("srcampaigns", "campaignname")).toEqual("Black Friday")
   CALL expect.that(inspect.currentCellValue("srcampaigns", "period")).toEqual(newPeriod)
   CALL expect.that(inspect.currentCellValue("srcampaigns", "days")).toEqual("3")
END FUNCTION

#+ Black Friday stretched to TODAY + 20 runs into Holiday mailing, which starts at TODAY + 19.
PUBLIC FUNCTION testInputArrayOverlap() RETURNS ()
   VAR overlapPeriod STRING = isoRange(TODAY + 15, TODAY + 20)
   CALL flow.action("inputarray")
   CALL flow.focusCell("srcampaigns", "period", 3)
   CALL flow.enter(overlapPeriod)
   CALL flow.focusCell("srcampaigns", "campaignname", 3)
   CALL flow.action("accept")
   CALL expect.that(messages()).toContainText("Black Friday and Holiday mailing overlap.")
   # the dialog stays open
   CALL expect.bool(atMenu()).toBeFalse()
   CALL expect.that(inspect.windowName()).toEqual("winputarray")
   CALL expect.bool(inspect.hasAction("accept")).toBeTrue()
   CALL expect.that(inspect.applicationError()).toBeEmpty()
   # leave the dialog (a closed dialog would mean the overlap was accepted: ensureMenu does not
   # close the menu, so the failures above are the ones reported)
   CALL ensureMenu()
   CALL expect.bool(atMenu()).toBeTrue()
   # and nothing was saved
   CALL flow.action("displayarray")
   CALL flow.selectRow("srcampaigns", 3)
   CALL expect.that(inspect.currentCellValue("srcampaigns", "period")).notToEqual(overlapPeriod)
END FUNCTION
