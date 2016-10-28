@ECHO OFF
REM     PARAMETERS:
REM         [1] S/N
REM         [2] VERSION
REM         [3] EVENT_DELAY (opt., default value: 200ms) 
REM         [4]

:MAIN
REM INITIALIZE VARIABLES
SET EVENT_COUNT=0
REM CREATE REPORT FOLDER
MKDIR report
REM INITIALIZE EVENT DELAY
IF [%3] EQU [] (
    SET EVENT_DELAY=200
) ELSE (
    SET EVENT_DELAY=%3
)
REM CHECK PASS/FAIL
    SET RESULT="FAIL"
    FOR /F %%I IN ('FINDSTR /C:finished mky_event_*.txt') DO (
        SET RESULT="PASS"
    )
REM COUNT MTTF
    REM GET EVENT COUNT
    IF [%RESULT%] EQU ["PASS"] (
        CALL:MKYFINDSTR 3 "Events injected: " 1 EVENT_COUNT
    ) ELSE (
        CALL:MKYFINDSTR 5 "Sending event" 0 EVENT_COUNT
    )
    REM MTTF = EVENT_COUNT*EVENT_DELAY
    SET /A MTTF=EVENT_COUNT*EVENT_DELAY
    CALL:GET_HOUR MTTF MTTF
REM COUNT DROPPED EVENT RATE
    CALL:GET_DROP_COUNT DROP_COUNT
    IF [%EVENT_COUNT%] EQU [0] (
        CALL:GET_DROP_RATE DROP_RATE
    ) ELSE  (
        SET DROP_RATE="N/A"
    )
REM GET MONKEY TEST EARTH TIME
    SET START_TIME=
    SET STOP_TIME=
    CALL:GET_TIME_STAMP 1 START_TIME
    CALL:GET_TIME_STAMP 0 STOP_TIME
    SET /A TOTAL_TIME=STOP_TIME-START_TIME
    CALL:GET_MINUTE TOTAL_TIME TOTAL_TIME
REM CREATE REPORT INDEX.HTML
    CALL:CREATE_REPORT_HTML
REM END OF BATCH
GOTO:EOF




REM ====================================================================================================
:GET_TIME_STAMP
    REM PARAMETERS
    REM     [1] 1: BREAK THE LOOP TO GET THE FIRST TIME STAMP
    REM         0: DO NOT BREAK TO GET THE LAST TIME STAMP
    REM     [2] RETURN TIME STAMP
    FOR /F "tokens=8 delims==:] " %%I IN ('FINDSTR /C:calendar_time mky_event_*.txt') DO (
        SET %2=%%I
        IF [%1%] EQU [1] (
            GOTO:EOF
        )
    )
GOTO:EOF

:MKYFINDSTR
    FOR /F "tokens=%1 delims=# " %%I IN ('FINDSTR /C:%2 mky_event_*.txt') DO (
        SET %4=%%I
        IF [%3] EQU [1] (
            GOTO:EOF
        )
    )
GOTO:EOF

:GET_HOUR
    SET /A X=%1/3600000
    SET /A Y=%1/360
    SET /A YY=Y%%1000
    SET %2=%X%.%YY%
GOTO:EOF

:GET_MINUTE
    SET /A X=%1/60000
    SET /A Y=%1/60
    SET /A YY=Y%%1000
    SET %2=%X%.%YY%
GOTO:EOF

:GET_DROP_COUNT
REM FIND THE DROPPED EVENT INFORMATION AND COUNT THE TOTAL DROPPED EVENT NUMBER
    FOR /F "tokens=3,5,7,9,11 delims== " %%I IN ('FINDSTR /C:Dropped mky_event_*.txt') DO (
        SET /A %1=%%I+%%J+%%K+%%L+%%M
        GOTO:EOF
    )
GOTO:EOF

:GET_DROP_RATE
    SET /A DROP_COUNT=DROP_COUNT*10000
    SET /A DRATE=DROP_COUNT/EVENT_COUNT
    SET /A X=DRATE/100
    SET /A Y=DRATE%%100
    SET %1=%X%.%Y%
GOTO:EOF

:CREATE_REPORT_HTML
ECHO ^<table border=^'2^' cellpadding=^'6^'^>^
        ^<tr^>^<td colspan=^'2^' align=^'right^'^>%DATE:~0,10% %TIME%^</td^>^</tr^>^
        ^<tr^>^
            ^<th^>Device^</th^>^
            ^<td align=^'center^'^>%1^</td^>^
        ^</tr^>^
        ^<tr^>^
            ^<th^>Version^</th^>^
            ^<td align=^'right^'^>%2^</td^>^
        ^</tr^>^
        ^<tr^>^
            ^<th^>Monkey Test Result^</th^>^
            ^<td align=^'right^'^>^<font color=#ff0000^>%RESULT%^</font^>^</td^>^
        ^</tr^>^
        ^<tr^>^
            ^<th^>Accumulative Event Counts^</th^>^
            ^<td align=^'right^'^>%EVENT_COUNT%^</td^>^
        ^</tr^>^
        ^<tr^>^
            ^<th^>Event Delay(ms)^</th^>^
            ^<td align=^'right^'^>%EVENT_DELAY%^</td^>^
        ^</tr^>^
        ^<tr^>^
            ^<th^>Event Count Based MTTF(hrs)^</th^>^
            ^<td align=^'right^'^>%MTTF%^</td^>^
        ^</tr^>^
        ^<tr^>^
            ^<th^>Total Dropped Event^</th^>^
            ^<td align=^'right^'^>%DROP_COUNT%^</td^>^
        ^</tr^>^
        ^<tr^>^
            ^<th^>Drop Rate(%)^</th^>^
            ^<td align=^'right^'^>%DROP_RATE%^</td^>^
        ^</tr^>^
        ^<tr^>^
            ^<th^>Monkey Test Time(minutes)^</th^>^
            ^<td align=^'right^'^>%TOTAL_TIME%^</td^>^
        ^</tr^>^
    ^</table^> > index.html
GOTO:EOF

