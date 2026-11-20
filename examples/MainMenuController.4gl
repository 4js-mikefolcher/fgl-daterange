#+ Application menu of the date range examples: one entry per dialog statement.

IMPORT FGL InputDemoController
IMPORT FGL ConstructDemoController
IMPORT FGL DisplayDemoController
IMPORT FGL ArrayDemoController

PUBLIC FUNCTION mainMenuRun() RETURNS ()
   LET int_flag = FALSE
   MENU "Date range examples"
      ON ACTION input ATTRIBUTES(TEXT = "Input")
         CALL InputDemoController.inputDemoRun()
      ON ACTION construct ATTRIBUTES(TEXT = "Construct")
         CALL ConstructDemoController.constructDemoRun()
      ON ACTION display ATTRIBUTES(TEXT = "Display")
         CALL DisplayDemoController.displayDemoRun()
      ON ACTION displayarray ATTRIBUTES(TEXT = "Display array")
         CALL ArrayDemoController.displayArrayRun()
      ON ACTION inputarray ATTRIBUTES(TEXT = "Input array")
         CALL ArrayDemoController.inputArrayRun()
      ON ACTION exit ATTRIBUTES(TEXT = "Exit")
         EXIT MENU
      ON ACTION close
         EXIT MENU
   END MENU
END FUNCTION
