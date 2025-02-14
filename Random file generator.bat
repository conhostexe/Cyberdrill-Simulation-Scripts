@echo off 
:: Get the current directory
set "current_dir=%cd%"
:: Define folder name
set "folder_name=Criticall files"
:: Create the folder in the current directory
if not exist "%current_dir%\%folder_name%" mkdir "%current_dir%\%folder_name%"
:: Define number of files to create
set num_files=40
:: Enable delayed expansion
setlocal enabledelayedexpansion
:: Loop to create files
for /l %%i in (1,1,%num_files%) do (
   set /a mod=%%i %% 2
   if !mod! equ 0 (
       set "extension=.doc"
   ) else (
       set "extension=.xls"
   )
   set "random_name="
   :: Generate 8 random characters for the file name
   for /l %%j in (1,1,8) do (
       set "random_char=!random:~-1!"
       set "random_name=!random_name!!random_char!"
   )
   :: Create the file
   echo.>"%current_dir%\%folder_name%\!random_name!!extension!"
   :: Add "Critical Data" to the file
   echo Critical Data > "%current_dir%\%folder_name%\!random_name!!extension!"
)
:: Inform the user
echo %num_files% random files created in "%folder_name%" at "%current_dir%", each containing "Critical Data".
pause
