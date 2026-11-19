#+ Entry point of the date range examples: startup only (styles, the database connection),
#+ then the application menu. The connection is made once, here: the CONSTRUCT example reads
#+ the demo database. Run with FGLPROFILE set to the fglprofile in this directory.

IMPORT FGL fgldialog

IMPORT FGL MainMenuController

MAIN
   VAR errorText STRING
   CALL ui.Interface.loadStyles("DateRangeDemo")
   TRY
      CONNECT TO "daterangedemo"
   CATCH
      LET errorText = SFMT("Cannot connect to the database daterangedemo: %1.", SQLERRMESSAGE)
      CALL fgl_winMessage("Date range examples",
            errorText || " Set FGLPROFILE to the fglprofile of the examples, and run make to create the database file.",
            "stop")
      EXIT PROGRAM 1
   END TRY
   CALL MainMenuController.mainMenuRun()
END MAIN
