#Include %A_ScriptDir%\Utils.ahk

#SingleInstance, force
#Persistent
#NoEnv
SetBatchLines, -1

global CONFIG_FILE := A_ScriptDir . "\Config.ini"
global AUTHCODE_FILE := A_ScriptDir . "\AuthCode.txt"
global CLIENT_ID, CLIENT_SECRET, REDIRECT_URI, SPREADSHEET_ID, SHEET_NAME

IniRead, CLIENT_ID, %CONFIG_FILE%, OAuth, ClientID
IniRead, CLIENT_SECRET, %CONFIG_FILE%, OAuth, ClientSecret
IniRead, REDIRECT_URI, %CONFIG_FILE%, OAuth, RedirectURI
IniRead, SPREADSHEET_ID, %CONFIG_FILE%, GoogleSheets, SpreadsheetID
IniRead, SHEET_NAME, %CONFIG_FILE%, GoogleSheets, SheetName

GetAuthCode()
{
    authUrl := "https://accounts.google.com/o/oauth2/auth?client_id=" . CLIENT_ID . "&redirect_uri=" . REDIRECT_URI . "&response_type=code&scope=https://www.googleapis.com/auth/spreadsheets"
    Run, % authUrl
    InputBox, authCode, Authorization Code, Copy the authorization code from your browser and paste it below.
    if (!authCode) {
        MsgBox % "No authorization code entered. Exiting."
        LogMessage("Authorization failed: no auth code entered.")
        return
    }

    FileDelete, %AUTHCODE_FILE%
    FileAppend, % authCode, %AUTHCODE_FILE%
    LogMessage("Authorization code saved.")
    MsgBox % "Authorization code saved."
    return
}

GetAuthCode()
ExitApp
