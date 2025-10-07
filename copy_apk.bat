@echo off
set APK_SRC=build\app\outputs\flutter-apk\app-release.apk
set APK_DST=students_web\downloads\adprofit-latest.apk

if not exist students_web\downloads mkdir students_web\downloads

copy /Y "%APK_SRC%" "%APK_DST%"

echo APK copiado para %APK_DST%
pause
