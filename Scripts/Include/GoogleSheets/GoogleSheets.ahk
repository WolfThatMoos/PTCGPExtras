#Include %A_ScriptDir%\Utils.ahk

#SingleInstance, force
#Persistent
#NoEnv
SetBatchLines, -1

global CONFIG_FILE := A_ScriptDir . "\Config.ini"
global AUTHCODE_FILE := A_ScriptDir . "\AuthCode.txt"
global TOKEN_FILE := A_ScriptDir . "\Tokens.json"
global CLIENT_ID, CLIENT_SECRET, REDIRECT_URI, SPREADSHEET_ID, SHEET_NAME

global currentAccessToken := ""

IniRead, CLIENT_ID, %CONFIG_FILE%, OAuth, ClientID
IniRead, CLIENT_SECRET, %CONFIG_FILE%, OAuth, ClientSecret
IniRead, REDIRECT_URI, %CONFIG_FILE%, OAuth, RedirectURI
IniRead, SPREADSHEET_ID, %CONFIG_FILE%, GoogleSheets, SpreadsheetID
IniRead, SHEET_NAME, %CONFIG_FILE%, GoogleSheets, SheetName

GSGetAccessToken()
{
    FileRead, tokenData, %TOKEN_FILE%
    accessToken := ExtractJsonValue(tokenData, "access_token")

    if (accessToken) {
        accessToken := GSRefreshAccessToken(tokenData)
        return accessToken
    }

    FileRead, authCode, %AUTHCODE_FILE%
    if (!authCode) {
        LogMessage("Auth code not found.")
        MsgBox % "Token retrieval unsuccessful. Check the logs."
        return false
    }

    jsonData := "{""code"":""" authCode """,""client_id"":""" CLIENT_ID """,""client_secret"":""" CLIENT_SECRET """,""redirect_uri"":""" REDIRECT_URI """,""grant_type"":""authorization_code""}"
    response := SendHttpRequest("https://oauth2.googleapis.com/token", "POST", jsonData)

    if (!response || InStr(response, "error")) {
        LogMessage("Error response when attempting to obtain tokens.")
        LogMessage(response)
        MsgBox % "Token retrieval unsuccessful. Check the logs."
        return false
    }

    FileDelete, %TOKEN_FILE%
    FileAppend, % response, %TOKEN_FILE%
    LogMessage("Tokens obtained and saved successfully.")

    accessToken := ExtractJsonValue(response, "access_token")
    return accessToken
}

GSRefreshAccessToken(tokenData)
{
    accessToken := ExtractJsonValue(tokenData, "access_token")

    ; Ping the Google Sheets API to check if the current access token is still valid.
    payload := SHEET_NAME . "!A1"
    url := "https://sheets.googleapis.com/v4/spreadsheets/" . SPREADSHEET_ID . "/values/" . payload

    response := SendHttpRequest(url, "GET",, accessToken)
    responseError := ExtractJsonValue(response, "error")

    if (!InStr(response, "error")) {
        ; Access token is still valid.
        return accessToken
    }

    refreshToken := ExtractJsonValue(tokenData, "refresh_token")

    jsonData := "{""client_id"":""" CLIENT_ID """,""client_secret"":""" CLIENT_SECRET """,""refresh_token"":""" refreshToken """,""grant_type"":""refresh_token""}"
    response := SendHttpRequest("https://oauth2.googleapis.com/token", "POST", jsonData)

    if (!response || InStr(response, "error")) {
        LogMessage("Error response when attempting to refresh access token.")
        LogMessage(response)
        MsgBox % "Token refresh unsuccessful. Check the logs."
        return false
    }

    FileDelete, %TOKEN_FILE%
    FileAppend, % response, %TOKEN_FILE%
    LogMessage("Access token refreshed successfully.")

    accessToken := ExtractJsonValue(response, "access_token")
    return accessToken
}

getColumnAValues()
{
    ; Get an access token.
    accessToken := ""
    if (!currentAccessToken) {
        accessToken := GSGetAccessToken()
        if (!accessToken) {
            MsgBox % "Access denied. Check the logs."
            return false
        }
    } else {
        accessToken := currentAccessToken
    }

    ; Fetch all values in column A for searching and other stuff.
    searchRange := SHEET_NAME . "!A:A"
    searchUrl := "https://sheets.googleapis.com/v4/spreadsheets/" . SPREADSHEET_ID . "/values/" . searchRange

    response := SendHttpRequest(searchUrl, "GET", "", accessToken)

    if (!response || InStr(response, "error")) {
        LogMessage("isNeedleCollected: Error response when attempting to fetch values in column A.")
        LogMessage(response)
        MsgBox % "D'oh! Something went wrong... Check the logs."
        return false
    }

    ; Manually parse the JSON response to get cell values from column A.
    ; - Remove new lines.
    response := StrReplace(response, "`n", "")
    ; - Remove multiple spaces.
    response := RegExReplace(response, "\s{2,}", "")
    ; - Remove a single space after a colon.
    response := RegExReplace(response, ":\s", ":")

    ; - Grab the value of the "values" key from the JSON object.
    RegExMatch(response, """values"":(.*)", match)
    values := match1

    ; - Remove all JSON object characters to leave a comma-separated list of card names.
    values := StrReplace(values, "{", "")
    values := StrReplace(values, "}", "")
    values := StrReplace(values, "[", "")
    values := StrReplace(values, "]", "")
    values := StrReplace(values, """", "")

    ; Split comma-separated list of card names.
    rows := StrSplit(values, ",")

    return rows
}

cardSearch(card)
{
    ; Search for card in column A.
    rows := getColumnAValues()
    foundRow := 0

    ; Search!
    loop % rows.MaxIndex() {
        if (rows[A_Index] = card) {
            foundRow := A_Index
            break
        }
    }

    return foundRow
}

markNeedleCollected(card, slot, state)
{
    global currentAccessToken

    ; Reset access token.
    currentAccessToken := ""

    ; Get an access token.
    accessToken := GSGetAccessToken()
    if (!accessToken) {
        MsgBox % "Access denied. Check the logs."
        return false
    }

    ; Set access token for remainder of this request.
    currentAccessToken := accessToken

    ; Add card to spreadsheet first if required.
    foundRow := 0
    if (state = -1) {
        ; Get all values in column A to determine the number of the next row.
        rows := getColumnAValues()
        foundRow := rows.Length() + 1

        cellRange := SHEET_NAME . "!A" . foundRow
        url := "https://sheets.googleapis.com/v4/spreadsheets/" . SPREADSHEET_ID . "/values/" . cellRange . "?valueInputOption=RAW"

        payload := "{""values"":[[""" . card . """]]}"

        response := SendHttpRequest(url, "PUT", payload, accessToken)

        if (!InStr(response, "updatedCells")) {
            LogMessage("markNeedleCollected: Error response when attempting to add card " . card . " to row " . foundRow . ", column A.")
            LogMessage(response)
            MsgBox % "Unable to add card " . card . "."
            return false
        }

        LogMessage("Card " . card . " added.")
    }

    ; Search for card row if card hasn't just been added.
    if (!foundRow) {
        foundRow := cardSearch(card)
    }

    ; Add an "X" to mark the specified slot as collected.
    static slotColumnMap := ["B", "C", "D", "E", "F"]

    cellRange := SHEET_NAME . "!" . slotColumnMap[slot] . foundRow
    url := "https://sheets.googleapis.com/v4/spreadsheets/" . SPREADSHEET_ID . "/values/" . cellRange . "?valueInputOption=RAW"

    payload := "{""values"":[[""X""]]}"

    response := SendHttpRequest(url, "PUT", payload, accessToken)

    if (!InStr(response, "updatedCells")) {
        LogMessage("markNeedleCollected: Error response when attempting to add an X for card "  . card . " to row " . foundRow . ", column " . slotColumnMap[slot] . ".")
        LogMessage(response)
        MsgBox % "Unable to mark slot " . slot . " for card " . card . " as collected."
        return false
    }

    LogMessage("Slot " . slot . " for card " . card . " marked as collected.")
    return true
}

isNeedleCollected(card, slot)
{
    global currentAccessToken

    ; Reset access token.
    currentAccessToken := ""

    ; Get an access token.
    accessToken := GSGetAccessToken()
    if (!accessToken) {
        MsgBox % "Access denied. Check the logs."
        return false
    }

    ; Set access token for remainder of this request.
    currentAccessToken := accessToken

    ; Search for card row.
    foundRow := cardSearch(card)

    if (foundRow = 0) {
        LogMessage("isNeedleCollected: " . card . " not found.")
        return -1
    }

    LogMessage("isNeedleCollected: " . card . " found on row " . foundRow . ".")

    ; Check for an 'X' in the column which corresponds to the specified slot.
    static slotColumnMap := ["B", "C", "D", "E", "F"]
    checkRange := SHEET_NAME . "!" . slotColumnMap[slot] . foundRow
    checkUrl := "https://sheets.googleapis.com/v4/spreadsheets/" . SPREADSHEET_ID . "/values/" . checkRange

    response := SendHttpRequest(checkUrl, "GET", "", accessToken)

    if (!response || InStr(response, "error")) {
        LogMessage("isNeedleCollected: Error response when attempting to check for an 'X' in row " . foundRow . ", column " . slotColumnMap[slot] . ".")
        LogMessage(response)
        MsgBox % "D'oh! Something went wrong... Check the logs."
        return false
    }

    if (!InStr(response, "values")) {
        LogMessage("isNeedleCollected: Slot " . slot . " fingerprint for " . card . " has not been collected.")
        return 0
    }

    LogMessage("isNeedleCollected: Slot " . slot . " fingerprint for " . card . " has been collected.")
    return 1
}
