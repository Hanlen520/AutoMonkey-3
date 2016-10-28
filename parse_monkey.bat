@ECHO OFF
REM     PARAMETERS:
REM         [1] S/N
REM         [2] VERSION
REM         [3] EVENT_DELAY (opt.)
REM         [4]

MKDIR report

IF [%3] EQU [] (
    SET EVENT_DELAY=200
) ELSE (
    SET EVENT_DELAY=%3
)

ECHO Update Time: > report\index.html
DATE /T >> report\index.html
ECHO ^<br^> >> report\index.html
ECHO Device: %1^<br^> >> report\index.html
ECHO Version: %2^<br^> >> report\index.html

REM CHECK PASS/FAIL
    FOR /F %%I IN ('FINDSTR /C:finished mky_event_*.txt') DO (
        GOTO:RESULT
    )
    ECHO Monkey Test Result: FAIL^<br^> >> report\index.html

REM COUNT MTTF (FAIL CASE)
    REM GET EVENT COUNT
    CALL:MKYFINDSTR 5 "Sending event" 0 EVENT_COUNT
    GOTO:MTTF

:RESULT
REM COUNT MTTF (PASS CASE)
    ECHO Monkey Test Result: PASS^<br^> >> report\index.html
    CALL:MKYFINDSTR 3 "Events injected: " 1 EVENT_COUNT


:MTTF
    REM MTTF = EVENT_COUNT*EVENT_DELAY
    ECHO Accumulative Event Counts: %EVENT_COUNT%^<br^> >> report\index.html
    ECHO Event Delay^(ms^): %EVENT_DELAY%^<br^> >> report\index.html
    SET /A MTTF=EVENT_COUNT*EVENT_DELAY
    CALL:GET_HOUR MTTF MTTF
    ECHO Event Count Based MTTF(hrs): %MTTF%^<br^> >> report\index.html


:DROP_EVENT_RATE
    CALL:GET_DROP_COUNT DROP_COUNT
    ECHO Total Dropped Event: %DROP_COUNT%^<br^> >> report\index.html
    IF [%EVENT_COUNT%] EQU [0] (
        ECHO DROP RATE: N/A^<br^> >> report\index.html
    )

    SET /A DROP_COUNT=DROP_COUNT*10000
    SET /A DRATE=DROP_COUNT/EVENT_COUNT
    ECHO DRATE=%DRATE%
    SET /A X=DRATE/100
    SET /A Y=DRATE%%100
    ECHO DROP RATE^(%%^): %X%.%Y%^<br^> >> report\index.html


:EARTH_TIME
    REM GET TEST TIME
    SET START_TIME=
    SET STOP_TIME=
    FOR /F "tokens=8 delims==:] " %%I IN ('FINDSTR /C:calendar_time mky_event_*.txt') DO (
        SET START_TIME=%%I
        GOTO:STOP1
    )
    :STOP1
    FOR /F "tokens=8 delims==:] " %%I IN ('FINDSTR /C:calendar_time mky_event_*.txt') DO (
        SET STOP_TIME=%%I
    )
    SET /A TOTAL_TIME=STOP_TIME-START_TIME
    CALL:GET_MINUTE TOTAL_TIME T
    ECHO Monkey Test Time(minutes): %T% >> report\index.html
GOTO:EOF




REM ====================================================================================================
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
    FOR /F "tokens=3,5,7,9,11 delims== " %%I IN ('FINDSTR /C:Dropped mky_event_*.txt') DO (
        SET /A %1=%%I+%%J+%%K+%%L+%%M
        GOTO:EOF
    )
GOTO:EOF
