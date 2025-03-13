global LOG_FILE := "GSlog.txt"

LogMessage(message)
{
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] %message%`n, %LOG_FILE%
}

SendHttpRequest(url, method, jsonData := "", access_token := "")
{
    req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    req.Open(method, url, false)
    req.SetRequestHeader("Content-Type", "application/json")

    if (access_token)
        req.SetRequestHeader("Authorization", "Bearer " . access_token)

    try {
        req.Send(jsonData)
        return req.ResponseText
    }
    catch e {
        LogMessage("HTTP Request Error: " . e.Message)
        return ""
    }
}

ExtractJsonValue(json, key)
{
    RegExMatch(json, """" key """:\s*""(.*?)""", match)
    return match1
}
