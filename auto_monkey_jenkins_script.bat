@echo off
SET EVENT_COUNT=500000
SET EVENT_DELAY=200

REM GoTo Local Dir
    cd %WORKSPACE%
    mkdir MS3_Monkey
    cd MS3_Monkey
    mkdir report


REM Get Files Needed
    robocopy /e \\10.57.47.214\AutoMK_TSP\AutoMonkeyTest_EnvSetup\ .\
    robocopy /e \\10.57.47.214\AutoMK_MS3\AutoMonkeyFiles .\


REM Download Images
    call :get_last_images


REM Update via SCSI Commands
    CALL :checkDevice
    CALL :rootDevice
    CALL :burnImageByFastboot


REM Wait 10 mins for First-Boot
    echo Wait 10 mins for First-Boot
    CALL :wait 600


REM Root N Remount
    CALL :checkDevice
    CALL :rootDevice


REM Close Setupwizard
    adb -s %SN% shell "settings put secure user_setup_complete 1"
    adb -s %SN% shell "settings put global device_provisioned 1"


REM Enable Logger
    adb -s %SN% push DefaultDbgConfig.xml /data/local/tmp/DefaultDbgConfig.xml
    adb -s %SN% shell am broadcast -a fih.dbgcfgtool.ENABLE_LOG --es config_path /data/local/tmp/DefaultDbgConfig.xml


REM Reboot
    echo Reboot device and Wait for 300 Sec
    adb -s %SN% reboot
    CALL :wait 300


REM Start Monkey Test
    CALL :checkDevice
    CALL :rootDevice
    CALL :start_monkey_test


REM Get Logs & Analysis & Send Report Mail
    CALL :getMonkeyLog
    CALL :SimpleMonkeyParser
    CALL :uploadMonkeyLog


REM END OF BUILD
EXIT



REM *******************************************************
REM **************** Subroutine Definition ****************

:syncHostTime
    echo Sync Time
    set DATE_Y=%date:~0,4%
    set DATE_M=%date:~5,2%
    set DATE_D=%date:~8,2%
    set TIME_H=%time:~0,2%
    set TIME_M=%time:~3,2%
    set TIME_S=%time:~6,2%
    adb -s %SN% shell setprop persist.sys.timezone Asia/Taipei
    adb -s %SN% shell "date %DATE_M%%DATE_D%%TIME_H%%TIME_M%%DATE_Y%"
    goto:eof

:get_n_upload_logs
    goto:eof

:start_monkey_test
    adb -s %SN% remount
    adb -s %SN% shell mkdir /data/MKY_LOG
    adb -s %SN% push TestData /sdcard/TestData
    adb -s %SN% shell "echo 1 > /sys/module/msm_poweroff/parameters/download_mode"
    adb -s %SN% shell "cat /sys/module/msm_poweroff/parameters/download_mode"

    adb -s %SN% shell "touch /data/BlackList_5013.txt"
    adb -s %SN% shell "touch /data/MKY_LOG/mky_event_123.txt"
    adb -s %SN% shell "echo com.qualcomm.embmstest >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.qualcomm.sensors.qsensortest >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.qualcomm.qualcommsettings >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.qualcomm.location.qvtester >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.qualcomm.wfd.client >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.qualcomm.qti.auth.fidocryptosample >> /data/BlackList_5013.txt"
    adb -s %SN% sehll "echo com.qualcomm.qti.app >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.qualcomm.qct.dlt >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.tools.alt >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.qualcomm.qti.sensors.qsensortest >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.qualcomm.ims.tests >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.android.development >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.fihtdc.phonestatusmonitor >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.android.deskclock >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.qualcomm.qlogcat >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.google.android.apps.plus >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.android.nfc >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo skaf.l001mtm091 >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.google.android.googlequicksearchbox >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.fihtdc.magictorch >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.sktelecom.hoppin.mobile >> /data/BlackList_5013.txt"
    adb -s %SN% shell "echo com.fihtdc.DbgCfgTool >> /data/BlackList_5013.txt"
    adb -s %SN% shell "/system/bin/monkey --pkg-blacklist-file /data/BlackList_5013.txt --ignore-crashes --ignore-timeouts --ignore-security-exceptions --kill-process-after-error --pct-touch 22 --pct-motion 16 --pct-trackball 0 --pct-rotation 3 --pct-syskeys 3 --pct-nav 15 --pct-majornav 15 --pct-appswitch 3 --pct-flip 0 --pct-anyevent 20 --pct-pinchzoom 3 -v -v --throttle %EVENT_DELAY% %EVENT_COUNT% > /data/MKY_LOG/mky_event_123.txt"

    goto:eof

:get_last_version
    SET last=last.V0.000
    FOR /F %%I IN ('dir /b /o:-n images\last.*') DO set last=%%I & goto :get_last_version_break
    :get_last_version_break
    set %1=%last:~5,6%
    echo "Last Version is:%result%"
    goto:eof

:get_last_images
    REM set DAILY_BUILD_PATH=\\10.57.35.229\hsuan\Mx3_Dailybuild
    set DAILY_BUILD_PATH=\\10.57.45.217\workspaces\Mx3_DailyBuild\ShareImage\

    mkdir images
    REM check images version and download if needed
    call :get_last_version last_version
    FOR /F "delims=|" %%I IN ('dir %DAILY_BUILD_PATH%\V* /b /o:-n') DO SET NewestFile=%%I & goto :get_last_images_break
    :get_last_images_break
    echo last_version
    echo %last_version%
    echo NewestFile
    echo %NewestFile%
    CALL :TRIM %NewestFile% NewestFile
　　if %NewestFile%==%last_version% (
        echo.
        echo The Last Images Have Been Downloaded
        goto:eof
    )
    del /f /q images\*
    robocopy /e %DAILY_BUILD_PATH%\%NewestFile%\MS3\000T\ images\
    FOR /F %%I IN ('dir /b /o:-n last.*') DO del %%I
    type NUL > images\last.%NewestFile%
    goto:eof


:wait
    echo Wait for %1 seconds
    @PING 127.0.0.1 -n %1 > nul || @PING ::1 -n %1 > nul
    goto:eof


:TRIM
    @SET %2=%1
    @GOTO :EOF


:checkDevice
    echo 'Enable All Port'
    echo Do Nothing
    goto:eof
    ScsiCommandLine.exe D SC_ENABLE_ALL_PORT
    ScsiCommandLine.exe E SC_ENABLE_ALL_PORT
    ScsiCommandLine.exe F SC_ENABLE_ALL_PORT
    ScsiCommandLine.exe G SC_ENABLE_ALL_PORT
    ScsiCommandLine.exe H SC_ENABLE_ALL_PORT
    ScsiCommandLine.exe I SC_ENABLE_ALL_PORT
    ScsiCommandLine.exe J SC_ENABLE_ALL_PORT
    ScsiCommandLine.exe K SC_ENABLE_ALL_PORT
    ScsiCommandLine.exe D SC_SWITCH_PORT_1
    ScsiCommandLine.exe E SC_SWITCH_PORT_1
    ScsiCommandLine.exe F SC_SWITCH_PORT_1
    ScsiCommandLine.exe G SC_SWITCH_PORT_1
    ScsiCommandLine.exe H SC_SWITCH_PORT_1
    ScsiCommandLine.exe I SC_SWITCH_PORT_1
    ScsiCommandLine.exe J SC_SWITCH_PORT_1
    ScsiCommandLine.exe K SC_SWITCH_PORT_1
    call:wait 10
    adb -s %SN% wait-for-device
    goto:eof


:rootDevice
    echo 'Root Device'
    echo Do Nothing
    goto:eof
    ScsiCommandLine.exe D SC_SWITCH_ROOT
    ScsiCommandLine.exe E SC_SWITCH_ROOT
    ScsiCommandLine.exe F SC_SWITCH_ROOT
    ScsiCommandLine.exe G SC_SWITCH_ROOT
    ScsiCommandLine.exe H SC_SWITCH_ROOT
    ScsiCommandLine.exe I SC_SWITCH_ROOT
    ScsiCommandLine.exe J SC_SWITCH_ROOT
    ScsiCommandLine.exe K SC_SWITCH_ROOT
    adb -s %SN% kill-server
    adb -s %SN% start-server
    call:wait 3
    adb -s %SN% root
    call:wait 10
    REM adb -s %SN% wait-for-device
    goto:eof

:burnImageByFastboot
    adb -s %SN% shell reboot bootloader
    fastboot.exe oem dm-verity

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-gpt_both0.bin') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash partition %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-sbl1.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash sbl1 %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-sbl1.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash sbl1bak %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-emmc_appsboot.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash aboot %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-emmc_appsboot.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash abootbak %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-rpm.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash rpm %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-rpm.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash rpmbak %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-tz.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash tz %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-tz.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash tzbak %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-hwcfg.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash hwcfg %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-adspso.bin') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash dsp %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-cmnlib.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash cmnlib %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-cmnlib.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash cmnlibbak %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-cmnlib64.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash cmnlib64 %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-cmnlib64.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash cmnlib64bak %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-devcfg.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash devcfg %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-devcfg.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash devcfgbak %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-keymaster.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash keymaster %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-keymaster.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash keymasterbak %image%

    echo 'Wait device enter download mode for 15 sec'
    call :wait 3
    fastboot.exe reboot-bootloader
    call :wait 15

    fastboot.exe oem dm-verity

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-splash.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash splash %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-ftm.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash ftmboot %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-multi-splash.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash multi_splash %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-boot.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash boot %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-system.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    myfastboot.exe simu_flash system %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-userdata.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash userdata %image%
    fastboot.exe erase userdata

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-recovery.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash recovery %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-persist.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash persist %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-cache.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash cache %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-sutinfo.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash sutinfo %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-NON-HLOS.bin') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash modem %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-hidden.img.ext4') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash hidden %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*fver') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash systeminfo %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-userdata-ftm.img.ext4') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash ftmlog %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-NV-default.mbn') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash default_nv %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-sec.dat') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash sec %image%

    set image=NULL
    for /f "tokens=*" %%a in ('dir /S/B .\images\*-mdtp.img') do (
    set image=%%a
    )
    echo "Start burning %image% ..."
    fastboot.exe flash mdtp %image%

    echo 'Wait device restart for 5 sec'
    call :wait 5
    fastboot.exe reboot
    
    goto:eof

REM GET MONKEY LOGS
REM ================================================================================================================
:getMonkeyLog
    for /f "tokens=1-3 delims=/ " %%i in ('date /t') do (set Info_Date=%%i_%%j_%%k)  
    for /f "tokens=2-3 delims=: " %%i in ('time /t') do (set Info_Time=%%i_%%j)  
    for /f "tokens=1" %%i in ('adb shell getprop ro.serialno') do (set PID=%%i)
    set INFO=[%Info_Date%][%Info_Time%][%PID%]
    set DIR=[Log]%INFO%[%USERNAME%]
    set INTERNAL_STORAGE=Internal_Storage
    set EXTERNAL_STORAGE=External_Storage
    set CAPTURE_LOG=%DIR%/shell_log

    md %DIR%
    md %DIR%\%INTERNAL_STORAGE%
    rem md %DIR%\%EXTERNAL_STORAGE%

    echo Copying FIH Log
    echo %INFO% > %CAPTURE_LOG%
    echo. >> %CAPTURE_LOG%

    call:adbPullCmdFunc /sdcard/MKY_LOG/mky_event_123.txt %DIR%

    echo Copying Log @ Internal Storage
    call:adbPullCmdFunc /data/logs %DIR%/%INTERNAL_STORAGE%/FIH_Log/

    echo Copying Black Box
    call:adbPullCmdFunc /BBSYS/alog_fih %DIR%/%INTERNAL_STORAGE%/BBSYS

    echo Copy FIH Statistics
    call:adbPullCmdFunc /data/fih_statistics %DIR%/%INTERNAL_STORAGE%/FIH_Statistics

    echo Copying MKY Log, ANR, TombStones
    call:adbPullCmdFunc /data/MKY_LOG %DIR%/%INTERNAL_STORAGE%/MKY_Log
    call:adbPullCmdFunc /data/anr %DIR%/%INTERNAL_STORAGE%/ANR
    call:adbPullCmdFunc /data/tombstones %DIR%/%INTERNAL_STORAGE%/Tombstones

    rem dropbox 
    echo Copying Dropbox
    call:adbPullCmdFunc /data/system/dropbox %DIR%/%INTERNAL_STORAGE%/Dropbox

    rem subsystem
    echo Copying Subsystem Ramdump
    call:adbPullCmdFunc /data/ramdump %DIR%/%INTERNAL_STORAGE%/SS_Ramdump
    
    rem last mechanism files
    call:adbPullCmdFunc /proc/last_kmsg %DIR%/last_kmsg

    rem power on cause & reboot reason
    echo Record Power On Cause
    adb -s %SN% shell cat /proc/poweroncause > %DIR%/poweroncause
    echo Record Reboot Reason
    adb -s %SN% shell cat /proc/rebootreason > %DIR%/rebootreason
    echo Record Cmdline
    adb -s %SN% shell cat /proc/cmdline > %DIR%/cmdline
    echo Record Getprop
    adb -s %SN% shell getprop > %DIR%/getprop
    echo Record PS
    adb -s %SN% shell ps -t > %DIR%/ps

    rem report & dumpsys for phone hang case
    echo Create Bug Report
    adb -s %SN% shell bugreport > %DIR%/bugreport
    echo Dump Dropbox List
    adb -s %SN% shell dumpsys dropbox > %DIR%/%INTERNAL_STORAGE%/dropbox_file_list
    echo Dump System Information
    adb -s %SN% shell dumpsys > %DIR%/dumpsys

    REM COPY MONKEY EVENT LOG FOR JENKINS REPORT
    del mky_event_123.txt
    copy %DIR%\%INTERNAL_STORAGE%\MKY_Log\mky_event_123.txt .

@goto:eof


:adbPullCmdFunc
    set SRC_PATH=%1
    set DES_PATH=%2
    echo adb pull %SRC_PATH% %DES_PATH% >> %CAPTURE_LOG%
    adb pull %SRC_PATH% %DES_PATH% >> %CAPTURE_LOG% 2>&1
@goto:eof


REM MONKEY PARSER & HTML REPORTER
REM =========================================================================================
:SimpleMonkeyParser
REM INITIALIZE VARIABLES
SET VER=%NewestFile%
SET EVENT_COUNT=0
REM CHECK PASS/FAIL
    SET RESULT=FAIL
    FOR /F %%I IN ('FINDSTR /C:finished mky_event_*.txt') DO (
        SET RESULT=PASS
    )
REM COUNT MTTF
    REM GET EVENT COUNT
    IF [%RESULT%] EQU [PASS] (
        CALL:MKYFINDSTR 3 "Events injected: " 1 EVENT_COUNT
    ) ELSE (
        CALL:MKYFINDSTR 5 "Sending event" 0 EVENT_COUNT
    )
    REM MTTF = EVENT_COUNT*EVENT_DELAY
    SET /A MTTF=EVENT_COUNT*EVENT_DELAY
    CALL:GET_HOUR %MTTF% MTTF
REM COUNT DROPPED EVENT RATE
    CALL:GET_DROP_COUNT DROP_COUNT
    IF [%EVENT_COUNT%] EQU [0] (
        SET DROP_RATE="N/A"
    ) ELSE  (
        CALL:GET_DROP_RATE DROP_RATE
    )
REM GET MONKEY TEST EARTH TIME
    SET START_TIME=
    SET STOP_TIME=
    CALL:GET_TIME_STAMP 1 START_TIME
    CALL:GET_TIME_STAMP 0 STOP_TIME
    SET /A TOTAL_TIME=STOP_TIME-START_TIME
    CALL:GET_MINUTE %TOTAL_TIME% TOTAL_TIME
REM CREATE REPORT INDEX.HTML
    CALL:CREATE_REPORT_HTML
REM CREATE JSON REPORT
    CALL:CREATE_REPORT_JSON
GOTO:EOF

REM ====================================================================================================
:CREATE_REPORT_JSON
    SET TODAY_FOLDER=\\MINSMCHIEN-3020\report\json\%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%
    REM CREATE FOLDER %TODAY_FOLDER%
    MKDIR %TODAY_FOLDER%
    REM CD %TODAY_FOLDER%
    CALL:CREATE_JSON_REPORT
GOTO:EOF

:CREATE_JSON_REPORT
ECHO {"CURRENT_TIME":"%DATE:~0,10% %TIME%","SN":"%SN%","VER":"%VER%","RESULT":"%RESULT%","EVENT_COUNT":"%EVENT_COUNT%","EVENT_DELAY":"%EVENT_DELAY%","MTTF":"%MTTF%","DROP_COUNT":"%DROP_COUNT%","DROP_RATE":"%DROP_RATE%","START_TIME":"%START_TIME%","STOP_TIME":"%STOP_TIME%","TOTAL_TIME":"%TOTAL_TIME%"} > %TODAY_FOLDER%\%SN%.json
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
    SET /A Y=%1/3600
    SET /A Y=Y%%1000
    SET /A YYY=Y/100
    SET /A YYY=YYY%%10
    SET /A YY=Y/10
    SET /A YY=YY%%10
    SET /A Y=Y%%10
    SET %2=%X%.%YYY%%YY%%Y%
GOTO:EOF

:GET_MINUTE
ECHO %1
    SET /A X=%1/60000
    SET /A Y=%1/60
    SET /A Y=Y%%1000
    SET /A YYY=Y/100
    SET /A YYY=YYY%%100
    SET /A YY=Y/10
    SET /A YY=YY%%10
    SET /A Y=Y%%10
    SET %2=%X%.%YYY%%YY%%Y%
GOTO:EOF

:GET_DROP_COUNT
REM FIND THE DROPPED EVENT INFORMATION AND COUNT THE TOTAL DROPPED EVENT NUMBER
    FOR /F "tokens=3,5,7,9,11 delims== " %%I IN ('FINDSTR /C:Dropped mky_event_*.txt') DO (
        SET /A %1=%%I+%%J+%%K+%%L+%%M
        GOTO:EOF
    )
GOTO:EOF

:GET_DROP_RATE
    SET /A DROP_COUNT_K=DROP_COUNT*10000
    SET /A DRATE=DROP_COUNT_K/EVENT_COUNT
    SET /A X=DRATE/100
    SET /A Y=DRATE%%100
    SET %1=%X%.%Y%
GOTO:EOF

:CREATE_REPORT_HTML
ECHO ^<table border=^'2^' cellpadding=^'6^'^>^
        ^<tr^>^<td colspan=^'2^' align=^'right^'^>%DATE:~0,10% %TIME%^</td^>^</tr^>^
        ^<tr^>^
            ^<th^>Device^</th^>^
            ^<td align=^'center^'^>%SN%^</td^>^
        ^</tr^>^
        ^<tr^>^
            ^<th^>Version^</th^>^
            ^<td align=^'right^'^>%VER%^</td^>^
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
    ^</table^> > report\index.html
GOTO:EOF


REM UPLOAD MONKEY LOG TO SERVER
REM ================================================================================================================
:uploadMonkeyLog
    echo "uploadMonkeylog"
    set LocalMonkeyBatchDir=%cd%
    set DEV=MS3
    set FTPServer=10.57.47.214
    set FTPUser=stanley
    set FTPPw=22685511
    set FTPMonkeyLogDir=/home/stanley/AutoMK_MS3/AutoMonkeyLog/%DEV%/Logs
    set Today=%DATE:/=%
    set /A FoloderYMD=%Today:~0,8% 
    set  uconfig=autoUploadMonkeylog.cfg
    echo open %FTPServer% > "%uconfig%"
    echo %FTPUser%>> "%uconfig%"
    echo %FTPPw%>> "%uconfig%"
    echo prompt >> "%uconfig%"
    echo bin >> "%uconfig%"
    echo cd %FTPMonkeyLogDir% >> "%uconfig%"
    echo mkdir %FTPMonkeyLogDir%/%FoloderYMD% >> "%uconfig%"
    echo mkdir %FTPMonkeyLogDir%/%FoloderYMD%/%DIR% >> "%uconfig%"
    echo mkdir %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage >> "%uconfig%"
    echo mkdir %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/ANR >> "%uconfig%"
    echo mkdir %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/Dropbox >> "%uconfig%"
    echo mkdir %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/FIH_Log >> "%uconfig%"
    echo mkdir %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/MKY_Log >> "%uconfig%"
    echo mkdir %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/Tombstones >> "%uconfig%"
    echo mkdir %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/Power_Log >> "%uconfig%"

    REM Layer1
    if exist %LocalMonkeyBatchDir%\%DIR% (
      echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR% >> "%uconfig%"
      echo lcd %LocalMonkeyBatchDir%\%DIR% >> "%uconfig%"
      echo mput * >> "%uconfig%"
    )

    REM Layer2
    echo "%LocalMonkeyBatchDir%%DIR%\Internal_Storage"
    if exist %LocalMonkeyBatchDir%\%DIR%\Internal_Storage (
      echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage >> "%uconfig%"
      echo lcd %LocalMonkeyBatchDir%\%DIR%\Internal_Storage >> "%uconfig%"
      echo mput * >> "%uconfig%"
    )

    REM Layer3
    if exist %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\ANR (
      echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/ANR >> "%uconfig%"
      echo lcd %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\ANR >> "%uconfig%"
      echo mput * >> "%uconfig%"
    )

    REM Layer3
    if exist %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\Dropbox (
      echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/Dropbox >> "%uconfig%"
      echo lcd %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\Dropbox >> "%uconfig%"
      echo mput * >> "%uconfig%"
    )

    REM Layer3
    if exist %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\FIH_Log (
      echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/FIH_Log >> "%uconfig%"
      echo lcd %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\FIH_Log >> "%uconfig%"
      echo mput * >> "%uconfig%"
    )

    REM Layer3
    if exist %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\MKY_Log (
      echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/MKY_Log >> "%uconfig%"
      echo lcd %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\MKY_Log >> "%uconfig%"
      echo mput * >> "%uconfig%"
    REM Layer4
      for /f "tokens=*" %%i in ('dir /B %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\MKY_Log') do (
        if not "%%i" == "WhiteList.txt" (
          echo mkdir %%i >> "%uconfig%"
          echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/MKY_Log/%%i >> "%uconfig%"
          echo lcd %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\MKY_Log\%%i >> "%uconfig%"
        echo mput * >> "%uconfig%"
      )
    )
    REM   if not "%seedDir%" == "default" (
    REM     echo mkdir %seedDir% >> "%uconfig%"
    REM     echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/MKY_Log/%seedDir% >> "%uconfig%"
    REM     echo lcd %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\MKY_Log\%seedDir% >> "%uconfig%"
    REM     echo mput * >> "%uconfig%"
    REM   )
    )

    REM Layer3
    if exist %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\Tombstones (
      echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/Tombstones >> "%uconfig%"
      echo lcd %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\Tombstones >> "%uconfig%"
      echo mput * >> "%uconfig%"
    )

    REM Layer3
    if exist %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\Power_Log (
      echo cd %FTPMonkeyLogDir%/%FoloderYMD%/%DIR%/Internal_Storage/Power_Log >> "%uconfig%"
      echo lcd %LocalMonkeyBatchDir%\%DIR%\Internal_Storage\Power_Log >> "%uconfig%"
      echo mput * >> "%uconfig%"
    )
    echo lcd %LocalMonkeyBatchDir% >> "%uconfig%"
    echo bye >> "%uconfig%"

    ftp -s:"%uconfig%"
    del "Temp%uconfig%"
    copy "%uconfig%" "Temp%uconfig%"
    del "%uconfig%"
@goto:eof



