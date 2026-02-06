@echo off
echo.
echo   ===============================
echo      Daily Recap Email - Setup
echo   ===============================
echo.
echo   This will open the settings file so you can add your email info.
echo.
echo   You need:
echo     1. Your Gmail address
echo     2. A Gmail App Password (NOT your regular password)
echo.
echo   To get an App Password:
echo     - Go to myaccount.google.com
echo     - Click Security
echo     - Click 2-Step Verification (turn it on if needed)
echo     - Scroll down and click App Passwords
echo     - Pick "Mail" and click Generate
echo     - Copy the 16-letter code it gives you
echo.
echo   Opening the settings file now...
echo.
notepad "%~dp0recap.ps1"
