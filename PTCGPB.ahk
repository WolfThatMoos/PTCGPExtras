#Include %A_ScriptDir%\Scripts\Include\Gdip_All.ahk
#Include %A_ScriptDir%\Scripts\Include\Gdip_Imagesearch.ahk
#Include %A_ScriptDir%\Scripts\Include\MooExtras.ahk
Progress, zh0 fs16 B1, Verifying Files...
VerifyFiles()

version = Arturos PTCGP Bot
#SingleInstance, force
CoordMode, Mouse, Screen
SetTitleMatchMode, 3

githubUser := "Arturo-1212"
repoName := "PTCGPB"
localVersion := "v6.3.16M"
scriptFolder := A_ScriptDir
zipPath := A_Temp . "\update.zip"
extractPath := A_Temp . "\update"

if not A_IsAdmin {
	; Relaunch script with admin rights
	Run *RunAs "%A_ScriptFullPath%"
	ExitApp
}

KillADBProcesses()

global jsonFileName, PacksText, pokedexFilePath

totalFile := A_ScriptDir . "\json\total.json"
backupFile := A_ScriptDir . "\json\total-backup.json"
if FileExist(totalFile) {
	FileCopy, %totalFile%, %backupFile%, 1 ; Copy source file to target
	if (ErrorLevel)
		MsgBox, Failed to create %backupFile%. Ensure permissions and paths are correct.
}
FileDelete, %totalFile%

packsFile := A_ScriptDir . "\json\Packs.json"
backupFile := A_ScriptDir . "\json\Packs-backup.json"
if FileExist(packsFile) {
	FileCopy, %packsFile%, %backupFile%, 1 ; Copy source file to target
	if (ErrorLevel)
		MsgBox, Failed to create %backupFile%. Ensure permissions and paths are correct.
}

InitializeJsonFile() ; Create or open the JSON file

CreateMainGUI()

Start() {
	global bRunMain, iTotalInstances, iInstanceStartDelay, bHeartBeat
	bRunMain := GetMainCheckBox()
	iTotalInstances := GetTotalInstances()
	iInstanceStartDelay := GetInstanceStartDelay()

	Gui, Submit  ; Collect the input values from the first page
	Gui, Destroy ; Close the first page

	; Run main before instances to account for instance start delay
	If (bRunMain) {
		FileName := "Scripts\Main.ahk"
		Run, %FileName%
	}

	SourceFile := "Scripts\1.ahk" ; Path to the source .ahk file
	TargetFolder := "Scripts\" ; Path to the target folder

	; Loop to process each instance
	Loop % iTotalInstances {
		; Duplicate 1.ahk for each remaining instance
		if (A_Index != 1) {
			TargetFile := TargetFolder . A_Index . ".ahk" ; Generate target file path
			; Delete any existing file, replace with new duplicate
			if(iTotalInstances > 1) {
				FileDelete, %TargetFile%
				FileCopy, %SourceFile%, %TargetFile%, 1
			}
			if (ErrorLevel)
				MsgBox, Failed to create %TargetFile%. Ensure permissions and paths are correct.
		}

		; Generate the file name to run
		FileName := TargetFolder . A_Index . ".ahk"

		; Account for Instance Delay
		if (A_Index != 1 && iInstanceStartDelay > 0)
			Sleep, iInstanceStartDelay * 1000

		Run, %FileName%
	}

	CreateSettingsFile() ; Read all control data and save it

	; Fetch friends list if online
	if(inStr(FriendID, "https"))
		DownloadFile(FriendID, "ids.txt")

	rerollTime := A_TickCount
	bHeartBeat := GetHeartbeatCheckBox()
	iHeartBeatID := GetHeartbeatID()
	iDiscordID := GetDiscordID()

	Loop {
		Sleep, 30000

		; Sum all variable values and write to total.json
		total := SumVariablesInJsonFile()

		totalSeconds := Round((A_TickCount - rerollTime) / 1000) ; Total time in seconds
		mminutes := Floor(totalSeconds / 60)
		if(total = 0)
			total := "0                             "
		packStatus := "Time: " . mminutes . "m Packs: " . total

		CreateStatusMessage(packStatus, 287, 490)

		if(bHeartBeat)
			if((A_Index = 1 || (Mod(A_Index, 60) = 0))) {
				onlineAHK := "Online: "
				offlineAHK := "Offline: "
				Online := []

				if(bRunMain) {
					IniRead, value, HeartBeat.ini, HeartBeat, Main
					if(value)
						onlineAHK := "Online: Main, "
					else
						offlineAHK := "Offline: Main, "
					IniWrite, 0, HeartBeat.ini, HeartBeat, Main
				}

				Loop %iTotalInstances% {
					IniRead, value, HeartBeat.ini, HeartBeat, Instance%A_Index%
					if(value)
						Online.push(1)
					else
						Online.Push(0)
					IniWrite, 0, HeartBeat.ini, HeartBeat, Instance%A_Index%
				}

				for index, value in Online {
					if(index = Online.MaxIndex())
						commaSeparate := "."
					else
						commaSeparate := ", "
					if(value)
						onlineAHK .= A_Index . commaSeparate
					else
						offlineAHK .= A_Index . commaSeparate
				}

				if(offlineAHK = "Offline: ")
					offlineAHK := "Offline: none."
				if(onlineAHK = "Online: ")
					onlineAHK := "Online: none."

				discMessage := "\n" . onlineAHK . "\n" . offlineAHK . "\n" . packStatus
				if(iHeartBeatID)
					iDiscordID := iHeartBeatID
				LogToDiscord(discMessage, , iDiscordID)
			}
	}
}

LogToDiscord(message, screenshotFile := "", ping := false, xmlFile := "") {
	
	global iDiscordID, sDiscordWebhookURL, sHeartBeatWebhookURL

	iDiscordID := GetDiscordID()
	sDiscordWebhookURL := GetDiscordWebhook()
	sHeartBeatWebhookURL := GetHeartbeatWebhook()

	discordPing := iDiscordID
	if(sHeartBeatWebhookURL)
		sDiscordWebhookURL := sHeartBeatWebhookURL

	if (sDiscordWebhookURL != "") {
		MaxRetries := 10
		RetryCount := 0
		Loop {
			try {
				; If an image file is provided, send it
				if (screenshotFile != "") {
					; Check if the file exists
					if (FileExist(screenshotFile)) {
						; Send the image using curl
						curlCommand := "curl -k "
							. "-F ""payload_json={\""content\"":\""" . discordPing . message . "\""};type=application/json;charset=UTF-8"" " . sDiscordWebhookURL
						RunWait, %curlCommand%,, Hide
					}
				}
				else {
					curlCommand := "curl -k "
						. "-F ""payload_json={\""content\"":\""" . discordPing . message . "\""};type=application/json;charset=UTF-8"" " . sDiscordWebhookURL
					RunWait, %curlCommand%,, Hide
				}
				break
			}
			catch {
				RetryCount++
				if (RetryCount >= MaxRetries) {
					CreateStatusMessage("Failed to send discord message.")
					break
				}
				Sleep, 250
			}
			Sleep, 250
		}
	}
}

DownloadFile(url, filename) {
	url := url  ; Change to your hosted .txt URL "https://pastebin.com/raw/vYxsiqSs"
	localPath = %A_ScriptDir%\%filename% ; Change to the folder you want to save the file

	URLDownloadToFile, %url%, %localPath%
}

CreateStatusMessage(Message, X := 0, Y := 80) {
	global PacksText, iDisplayProfile
	iDisplayProfile := GetSelectedMonitor()

	try {
		GuiName := 22
		SysGet, Monitor, Monitor, %iDisplayProfile%
		X := MonitorLeft + X
		Y := MonitorTop + Y
		Gui %GuiName%:+LastFoundExist
		if WinExist() {
			GuiControl, , PacksText, %Message%
		} else {
			OwnerWND := WinExist(1)
			if(!OwnerWND)
				Gui, %GuiName%:New, +ToolWindow -Caption
			else
				Gui, %GuiName%:New, +Owner%OwnerWND% +ToolWindow -Caption
			Gui, %GuiName%:Margin, 2, 2  ; Set margin for the GUI
			Gui, %GuiName%:Font, s8  ; Set the font size to 8 (adjust as needed)
			Gui, %GuiName%:Add, Text, vPacksText, %Message%
			Gui, %GuiName%:Show, NoActivate x%X% y%Y%, NoActivate %GuiName%
		}
	}
}

; Global variable to track the current JSON file
global jsonFileName := ""

; Function to create or select the JSON file
InitializeJsonFile() {
	global jsonFileName
	fileName := A_ScriptDir . "\json\Packs.json"
	if FileExist(fileName)
		FileDelete, %fileName%
	if !FileExist(fileName) {
		; Create a new file with an empty JSON array
		FileAppend, [], %fileName%  ; Write an empty JSON array
		jsonFileName := fileName
		return
	}
}

; Function to append a time and variable pair to the JSON file
AppendToJsonFile(variableValue) {
	global jsonFileName
	if (jsonFileName = "") {
		MsgBox, JSON file not initialized. Call InitializeJsonFile() first.
		return
	}

	; Read the current content of the JSON file
	FileRead, jsonContent, %jsonFileName%
	if (jsonContent = "") {
		jsonContent := "[]"
	}

	; Parse and modify the JSON content
	jsonContent := SubStr(jsonContent, 1, StrLen(jsonContent) - 1) ; Remove trailing bracket
	if (jsonContent != "[")
		jsonContent .= ","
	jsonContent .= "{""time"": """ A_Now """, ""variable"": " variableValue "}]"

	; Write the updated JSON back to the file
	FileDelete, %jsonFileName%
	FileAppend, %jsonContent%, %jsonFileName%
}

; Function to sum all variable values in the JSON file
SumVariablesInJsonFile() {
	global jsonFileName
	if (jsonFileName = "") {
		return
	}

	; Read the file content
	FileRead, jsonContent, %jsonFileName%
	if (jsonContent = "") {
		return 0
	}

	; Parse the JSON and calculate the sum
	sum := 0

	; Clean and parse JSON content
	jsonContent := StrReplace(jsonContent, "[", "") ; Remove starting bracket
	jsonContent := StrReplace(jsonContent, "]", "") ; Remove ending bracket
	Loop, Parse, jsonContent, {, }
	{
		; Match each variable value
		if (RegExMatch(A_LoopField, """variable"":\s*(-?\d+)", match)) {
			sum += match1
		}
	}

	; Write the total sum to a file called "total.json"
	if(sum > 0) {
		totalFile := A_ScriptDir . "\json\total.json"
		totalContent := "{""total_sum"":" sum "}"
		FileDelete, %totalFile%
		FileAppend, %totalContent%, %totalFile%
	}

	return sum
}

KillADBProcesses() {
	; Use AHK's Process command to close adb.exe
	Process, Close, adb.exe
	; Fallback to taskkill for robustness
	RunWait, %ComSpec% /c taskkill /IM adb.exe /F /T,, Hide
}

CheckForUpdate() {
	global githubUser, repoName, localVersion, zipPath, extractPath, scriptFolder
	url := "https://api.github.com/repos/" githubUser "/" repoName "/releases/latest"

	response := HttpGet(url)
	if !response
	{
		MsgBox, Failed to fetch release info.
		return
	}
	latestReleaseBody := FixFormat(ExtractJSONValue(response, "body"))
	latestVersion := ExtractJSONValue(response, "tag_name")
	zipDownloadURL := ExtractJSONValue(response, "zipball_url")
	Clipboard := latestReleaseBody
	if (zipDownloadURL = "" || !InStr(zipDownloadURL, "http"))
	{
		MsgBox, Failed to find the ZIP download URL in the release.
		return
	}

	if (latestVersion = "")
	{
		MsgBox, Failed to retrieve version info.
		return
	}

	if (VersionCompare(latestVersion, localVersion) > 0)
	{
		; Get release notes from the JSON (ensure this is populated earlier in the script)
		releaseNotes := latestReleaseBody  ; Assuming `latestReleaseBody` contains the release notes

		; Show a message box asking if the user wants to download
		MsgBox, 4, Update Available %latestVersion%, %releaseNotes%`n`nDo you want to download the latest version?

		; If the user clicks Yes (return value 6)
		IfMsgBox, Yes
		{
			MsgBox, 64, Downloading..., Downloading the latest version...

			; Proceed with downloading the update
			URLDownloadToFile, %zipDownloadURL%, %zipPath%
			if ErrorLevel
			{
				MsgBox, Failed to download update.
				return
			}
			else {
				MsgBox, Download complete. Extracting...

				; Create a temporary folder for extraction
				tempExtractPath := A_Temp "\PTCGPB_Temp"
				FileCreateDir, %tempExtractPath%

				; Extract the ZIP file into the temporary folder
				RunWait, powershell -Command "Expand-Archive -Path '%zipPath%' -DestinationPath '%tempExtractPath%' -Force",, Hide

				; Check if extraction was successful
				if !FileExist(tempExtractPath)
				{
					MsgBox, Failed to extract the update.
					return
				}

				; Get the first subfolder in the extracted folder
				Loop, Files, %tempExtractPath%\*, D
				{
					extractedFolder := A_LoopFileFullPath
					break
				}

				; Check if a subfolder was found and move its contents recursively to the script folder
				if (extractedFolder)
				{
					MoveFilesRecursively(extractedFolder, scriptFolder)

					; Clean up the temporary extraction folder
					FileRemoveDir, %tempExtractPath%, 1
					MsgBox, Update installed. Restarting...
					Reload
				}
				else
				{
					MsgBox, Failed to find the extracted contents.
					return
				}
			}
		}
		else
		{
			MsgBox, The update was canceled.
			return
		}
	}
	else
	{
		MsgBox, You are running the latest version (%localVersion%).
	}
}

MoveFilesRecursively(srcFolder, destFolder) {
	; Loop through all files and subfolders in the source folder
	Loop, Files, % srcFolder . "\*", R
	{
		; Get the relative path of the file/folder from the srcFolder
		relativePath := SubStr(A_LoopFileFullPath, StrLen(srcFolder) + 2)

		; Create the corresponding destination path
		destPath := destFolder . "\" . relativePath

		; If it's a directory, create it in the destination folder
		if (A_LoopIsDir)
		{
			; Ensure the directory exists, if not, create it
			FileCreateDir, % destPath
		}
		else
		{
			if ((relativePath = "ids.txt" && FileExist(destPath)) || (relativePath = "usernames.txt" && FileExist(destPath)) || (relativePath = "discord.txt" && FileExist(destPath))) {
                continue
            }
			if (relativePath = "usernames.txt" && FileExist(destPath)) {
                continue
            }
			if (relativePath = "usernames.txt" && FileExist(destPath)) {
                continue
            }
			; If it's a file, move it to the destination folder
			; Ensure the directory exists before moving the file
			FileCreateDir, % SubStr(destPath, 1, InStr(destPath, "\", 0, 0) - 1)
			FileMove, % A_LoopFileFullPath, % destPath, 1
		}
	}
}

HttpGet(url) {
	http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	http.Open("GET", url, false)
	http.Send()
	return http.ResponseText
}

; Existing function to extract value from JSON
ExtractJSONValue(json, key1, key2:="", ext:="") {
	value := ""
	json := StrReplace(json, """", "")
	lines := StrSplit(json, ",")

	Loop, % lines.MaxIndex()
	{
		if InStr(lines[A_Index], key1 ":") {
			; Take everything after the first colon as the value
			value := SubStr(lines[A_Index], InStr(lines[A_Index], ":") + 1)
			if (key2 != "")
			{
				if InStr(lines[A_Index+1], key2 ":") && InStr(lines[A_Index+1], ext)
					value := SubStr(lines[A_Index+1], InStr(lines[A_Index+1], ":") + 1)
			}
			break
		}
	}
	return Trim(value)
}

FixFormat(text) {
	; Replace carriage return and newline with an actual line break
	text := StrReplace(text, "\r\n", "`n")  ; Replace \r\n with actual newlines
	text := StrReplace(text, "\n", "`n")    ; Replace \n with newlines

	; Remove unnecessary backslashes before other characters like "player" and "None"
	text := StrReplace(text, "\player", "player")   ; Example: removing backslashes around words
	text := StrReplace(text, "\None", "None")       ; Remove backslash around "None"
	text := StrReplace(text, "\Welcome", "Welcome") ; Removing \ before "Welcome"

	; Escape commas by replacing them with %2C (URL encoding)
	text := StrReplace(text, ",", "")

	return text
}

VersionCompare(v1, v2) {
	; Remove non-numeric characters (like 'alpha', 'beta')
	cleanV1 := RegExReplace(v1, "[^\d.]")
	cleanV2 := RegExReplace(v2, "[^\d.]")

	v1Parts := StrSplit(cleanV1, ".")
	v2Parts := StrSplit(cleanV2, ".")

	Loop, % Max(v1Parts.MaxIndex(), v2Parts.MaxIndex()) {
		num1 := v1Parts[A_Index] ? v1Parts[A_Index] : 0
		num2 := v2Parts[A_Index] ? v2Parts[A_Index] : 0
		if (num1 > num2)
			return 1
		if (num1 < num2)
			return -1
	}

	; If versions are numerically equal, check if one is an alpha version
	isV1Alpha := InStr(v1, "alpha") || InStr(v1, "beta")
	isV2Alpha := InStr(v2, "alpha") || InStr(v2, "beta")

	if (isV1Alpha && !isV2Alpha)
		return -1 ; Non-alpha version is newer
	if (!isV1Alpha && isV2Alpha)
		return 1 ; Alpha version is older

	return 0 ; Versions are equal
}

~+F7::ExitApp








; #############################################################################################
; SETTINGS MANAGEMENT
; #############################################################################################
;
CreateSettingsFile() {
	global iMainID, bRunMain, iTotalInstances, iTotalColumns, sMuMuInstallPath, bSpeedMod
	global iMinPackVal, sPackToOpen, iThresholdVal, iNumPacksToOpen, bThreshold, bOnePackMode, bInjectionMode, bMenuDelete
	global iGeneralDelay, iSwipeSpeed, iAddMainDelay, iInstanceStartDelay
	global iDiscordID, sDiscordWebhookURL, iHeartBeatID, sHeartBeatWebhookURL, bHeartBeat
	global iDisplayProfile, iScale
	global bSkipAddingMain, bFingerprintMode, bTradeMode, bShowStatusWindow, bSelectPackPerInstance
	global bSkipLicense

	; Instances
	iMainID  := GetMainFriendID()
	bRunMain := GetMainCheckBox()
	iTotalInstances := GetTotalInstances()
	iTotalColumns := GetTotalColumns()
	bSpeedMod := GetSpeedModCheckBox()
	sMuMuInstallPath := GetMuMuInstallPath()
	; Packs
	iMinPackVal := GetMinPackVal()
	iThresholdVal := GetThresholdVal()
	sPackToOpen := GetPackToOpen()
	iNumPacksToOpen := GetNumPacksToOpen()
	bThreshold := GetThresholdCheckBox()
	bOnePackMode := GetOnePackModeCheckBox()
	bInjectionMode := GetInjectionModeCheckBox()
	bMenuDelete := GetMenuDeleteAccountCheckBox()
	; Timings
	iGeneralDelay := GetGeneralDelay()
	iSwipeSpeed := GetSwipeSpeed()
	iAddMainDelay := GetAddMainDelay()
	iInstanceStartDelay := GetInstanceStartDelay()
	; Discord
	iDiscordID := GetDiscordID()
	sDiscordWebhookURL := GetDiscordWebhook()
	bHeartBeat := GetHeartbeatCheckBox()
	iHeartBeatID := GetHeartbeatID()
	sHeartBeatWebhookURL := GetHeartbeatWebhook()
	; Display
	iDisplayProfile := GetSelectedMonitor()
	iScale := GetScaleVal()
	; Moo
	bSkipAddingMain := GetSkipMainCheckBox()
	bFingerprintMode := GetFingerprintModeCheckBox()
	bTradeMode := GetTradeModeCheckBox()
	bShowStatusWindow := GetStatusWindowCheckBox()
	; About
	bSelectPackPerInstance := GetSelectPackPerInstanceCheckBox()
	bSkipLicense := GetLicenseSkipCheckBox()

	; Check if settings.ini exists
    if !FileExist("Settings.ini")
		bFirstTime = true

	; Instances
    IniWrite, %iMainID%, Settings.ini, Instances, iMainID
    IniWrite, %bRunMain%, Settings.ini, Instances, bRunMain
    IniWrite, %iTotalInstances%, Settings.ini, Instances, iTotalInstances
    IniWrite, %iTotalColumns%, Settings.ini, Instances, iTotalColumns
    IniWrite, %sMuMuInstallPath%, Settings.ini, Instances, cMuMuInstallPath
    IniWrite, %bSpeedMod%, Settings.ini, Instances, bSpeedMod
	; Packs
    IniWrite, %iMinPackVal%, Settings.ini, Packs, iMinPackVal
    IniWrite, %iThresholdVal%, Settings.ini, Packs, iThresholdVal
    IniWrite, %sPackToOpen%, Settings.ini, Packs, sPackToOpen
    IniWrite, %iNumPacksToOpen%, Settings.ini, Packs, iNumPacksToOpen
    IniWrite, %bThreshold%, Settings.ini, Packs, bThreshold
    IniWrite, %bOnePackMode%, Settings.ini, Packs, bOnePackMode
    IniWrite, %bInjectionMode%, Settings.ini, Packs, bInjectionMode
    IniWrite, %bMenuDelete%, Settings.ini, Packs, bMenuDelete
	; Timings
    IniWrite, %iGeneralDelay%, Settings.ini, Timings, iGeneralDelay
    IniWrite, %iSwipeSpeed%, Settings.ini, Timings, iSwipeSpeed
    IniWrite, %iAddMainDelay%, Settings.ini, Timings, iAddMainDelay
    IniWrite, %iInstanceStartDelay%, Settings.ini, Timings, iInstanceStartDelay
	; Discord
    IniWrite, %iDiscordID%, Settings.ini, Discord, iDiscordID
    IniWrite, %sDiscordWebhookURL%, Settings.ini, Discord, sDiscordWebhookURL
    IniWrite, %iHeartBeatID%, Settings.ini, Discord, iHeartBeatID
    IniWrite, %sHeartBeatWebhookURL%, Settings.ini, Discord, sHeartBeatWebhookURL
    IniWrite, %bHeartBeat%, Settings.ini, Discord, bHeartBeat
	; Displays
    IniWrite, %iDisplayProfile%, Settings.ini, Displays, iDisplayProfile
    IniWrite, %iScale%, Settings.ini, Displays, iScale
	; Moo
    IniWrite, %bSkipAddingMain%, Settings.ini, Moo, bSkipAddingMain
    IniWrite, %bFingerprintMode%, Settings.ini, Moo, bFingerprintMode
    IniWrite, %bTradeMode%, Settings.ini, Moo, bTradeMode
    IniWrite, %bShowStatusWindow%, Settings.ini, Moo, bShowStatusWindow
	IniWrite, %bSelectPackPerInstance%, Settings.ini, Moo, bSelectPackPerInstance
	; About
	IniWrite, %bSkipLicense%, Settings.ini, About, bSkipLicense

	if (bFirstTime) {
		; Load settings
		FileRead, settings, Settings.ini

		; Split the content into lines
		StringSplit, lines, settings, `n

		; Initialize the newSettings variable to hold the updated content
		newSettings := ""

		; Loop through each line of the settings
		Loop, % lines0
		{
			; Check if the line contains a section header
			if (InStr(lines%A_Index%, "[")) {
				; If it's not the first section, add a blank line before it
				if (A_Index > 1) {
					newSettings .= "`n"  ; Add a blank line before the section header
				}
			}

			; Add the current line to newSettings
			newSettings .= lines%A_Index% . "`n"
		}

		; Save the modified content back to the settings.ini file
		FileDelete, Settings.ini
		FileAppend, %newSettings%, Settings.ini
	}
}
;LoadSettingsFile()
RunPokedexCheck() {
	global cOpenPokedex, pokedexFilePath
	pokedexFilePath := A_ScriptDir . "\Scripts\Pokedex\Pokedex.csv"

    if FileExist(pokedexFilePath) {
		GuiControl, Enable, cOpenPokedex
	} else {
		GuiControl, Disable, cOpenPokedex
	}
}

; #############################################################################################
; GUI FUNCTIONS
; #############################################################################################
;
CreateMainGUI() {
	; Form controls --------------------------------------------------------------
	; Instances
	global cMainID, cRunMainCheckbox, cTotalInstances, cTotalColumns, cMuMuInstallPath, cSpeedModCheckbox, cStart, cArrangeWindows
	; Packs
	global cMinPackValLabel, cMinPackVal, cPackList, cThresholdCheckbox, cNumPacksToOpenLabel, CNumPacksToOpen, cOnePackModeCheckbox, cInjectCheckbox, cMenuDeleteCheckbox, cThresholdVal
	; Timings
	global cGeneralDelay, cSwipeSpeed, cAddMainDelay, cInstanceStartDelay
	; Discord
	global cDiscordID, cDiscordWebhookURL, cHeartBeatID, cHeartBeatWebhookURL, cHeartBeatCheckbox
	; Displays
	global cMonitorList, cScale100, cScale125
	; Moo
	global cSkipMainCheckbox, cFingerprintCheckbox, cTradeCheckbox, cStatusWindowCheckbox, cPackPerInstanceCheckbox
	; About
	global cSkipLicenseCheckbox

	; Todo Buttons
	global cOpenPokedex, OpenFriends, OpenMoo, OpenGithub, OpenDiscord, OpenLink

	; Form data ------------------------------------------------------------------
	; Instances
	global iMainID, bRunMain, iTotalInstances, iTotalColumns, sMuMuInstallPath, bSpeedMod
	; Packs
	global iMinPackVal, sPackToOpen, sPackList, sDefaultPack, iThresholdVal, iSavedPackCount, bThreshold, iNumPacksToOpen, bOnePackMode, bInjectionMode, bMenuDelete
	; Timings
	global iGeneralDelay, iSwipeSpeed, iAddMainDelay, iInstanceStartDelay
	; Discord
	global iDiscordID, sDiscordWebhookURL, bHeartBeat, iHeartBeatID, sHeartBeatWebhookURL
	; Displays
	global iDisplayProfile, sMonitors
	; Moo
	global bSkipAddingMain, bFingerprintMode, bTradeMode, bShowStatusWindow, bSelectPackPerInstance
	; About
	global bSkipLicense, localVersion

	; Preload GUI data
	InitializePackManager()
	LoadSettingsFile()
	iMainID := NormalizeMainFriendID(iMainID)
	iSavedPackCount := iNumPacksToOpen
	sPackList := GetPackList()
	sDefaultPack := GetPackIndex(sPackToOpen)
	iDiscordID := NormalizeDiscordUserID(iDiscordID)
	sDiscordWebhookURL := NormalizeDiscordWebhookURL(sDiscordWebhookURL)
	iHeartBeatID := NormalizeHeartBeatName(iHeartBeatID)
	sHeartBeatWebhookURL := NormalizeHeartBeatWebhookURL(sHeartBeatWebhookURL)
	sMonitors := GetMonitorList()

	; Reference resolution for scaling
	ReferenceWidth := 2560
	ReferenceHeight := 1600
	ScaleFactor := Min(A_ScreenWidth / ReferenceWidth, A_ScreenHeight / ReferenceHeight)
	iGuiWidth := 650
	iGuiHeight := 312

	; Set GUI Design Defaults
	Gui, Color, White
	Gui, Margin, 10, 10
	Gui_SetFont()

	AddImageTab("", "Instances|Packs|Timings|Discord|Displays|Moo|About")
		Gui, Tab, 1 ; Instances
			; Main Friend ID
			Gui_CreateText("Main Friend ID:")
			ScaledOptions := "w" Round(215 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% +Limit16 Number Center gSetMainFriendID vcMainID, %iMainID%

			; Run Main Checkbox
			Gui_SetFont(16)
			ScaledOptions := "x" Round(450 * ScaleFactor) " y" Round(84 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, %ScaledOptions% hwndhRunMainCB
			Gui, Add, Text, x+5 yp-0 hp hwndhRunMainLabel, Run Main
			cRunMainCheckbox := new CustomCheckbox(bRunMain, hRunMainCB, hRunMainLabel, "ToggleMainCheckBox")
			cRunMainCheckbox.status := bRunMain

			; Instances
			Gui_SetFont()
			Gui_CreateText("Instances:", , 140)
			ScaledOptions := "w" Round(40 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% +Limit2 Number Center gSetTotalInstances vcTotalInstances, %iTotalInstances%

			; Columns
			Gui_CreateText("Columns:", 210, 140)
			ScaledOptions := "w" Round(40 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% +Limit2 Number Center gSetTotalColumns vcTotalColumns, %iTotalColumns%

			; Open Friends (id.txt)
			Gui_SetFont(16)
			Gui, Add, Button, x+50 yp w130 hWndhOpenFriendsBtn gOpenFriends, % "Open Friends List"
			Gui_StyleButton(hOpenFriendsBtn)

			; Base Compatability (No Speed Mod)
			ScaledOptions := "x" Round(450 * ScaleFactor) " y" Round(200 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, Disabled %ScaledOptions% hwndhSpeedModCB
			Gui, Add, Text, Disabled x+5 yp-0 hp hwndhSpeedModLabel, No Speed Mod
			cSpeedModCheckbox := new CustomCheckbox(bSpeedMod, hSpeedModCB, hSpeedModLabel, "ToggleSpeedModCheckBox")
			cSpeedModCheckbox.status := bSpeedMod

			; MuMu Install Path
			Gui_SetFont()
			Gui_CreateText("Folder Path:", , 200)
			Gui_SetFont(16)
			ScaledOptions := "w" Round(250 * ScaleFactor) " h28"
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% gSetMuMuInstallPath vcMuMuInstallPath, %sMuMuInstallPath%

			; Start Button
			iStartXPos := Round((Round(iGuiWidth * ScaleFactor) / 4) - (Round(220 * ScaleFactor) / 2))
			ScaledOptions := "x" iStartXPos " y" Round(255 * ScaleFactor) " w" Round(220 * ScaleFactor)
			Gui, Add, Button, %ScaledOptions% hWndhStartBtn vcStart gStart, Start
			Gui_StyleButton(hStartBtn)

			; Arrange Windows Button
			iStartXPos := Round(((Round(iGuiWidth * ScaleFactor) / 4) * 3) - (Round(220 * ScaleFactor) / 2))
			ScaledOptions := "x" iStartXPos " y" Round(255 * ScaleFactor) " w" Round(220 * ScaleFactor)
			Gui, Add, Button, %ScaledOptions% hWndhArrangeWinBtn vcArrangeWindows gArrangeWindows, Arrange Windows
			Gui_StyleButton(hArrangeWinBtn)

		Gui, Tab, 2 ; Packs
			; Minimum Pack Value
			Gui_SetFont()
			ScaledOptions := "x" Round(18 * ScaleFactor) " y" Round(80 * ScaleFactor)
			Gui, Add, Text, %ScaledOptions% vcMinPackValLabel, Minimum Pack Value:
			ScaledOptions := "w" Round(50 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% +Limit2 Number Center HwndhMinPackVal gSetMinPackVal vcMinPackVal, %iMinPackVal%

			; Threshold Value (Hidden)
			GuiControlGet, MinValEditPos, Pos, %hMinPackVal%
			MatchingPos := "x" MinValEditPosX " y" MinValEditPosY " w" MinValEditPosW " h" MinValEditPosH " Hidden"
			Gui, Add, Edit, %MatchingPos% +Limit3 Center gSetThresholdVal vcThresholdVal, %iThresholdVal%

			; Pokedex Button
			Gui_SetFont(16)
			Gui, Add, Button, x+50 yp+5 w130 hWndhOpenPokedexBtn vcOpenPokedex gOpenPokedex, % "Open Pokedex"
			Gui_StyleButton(hOpenPokedexBtn)
			RunPokedexCheck()

			; Choose Pack
			Gui_SetFont()
			Gui_CreateText("Pack to Open:", , 140)
			ScaledOptions := "w" Round(128 * ScaleFactor)
			Gui, Add, DropDownList, x+10 yp-2 %ScaledOptions% vcPackList gPackListChanged Choose%sDefaultPack%, %sPackList%

			; Packs To Open
			Gui_CreateText("Number of Packs to Open:", , 200)
			Gui, Add, Text, x+10 yp-0 w20 vcNumPacksToOpenLabel, %iNumPacksToOpen%
			ScaledOptions := "x" Round(18 * ScaleFactor) " y" Round(250 * ScaleFactor)
			Gui, Add, Slider, %ScaledOptions% vcNumPacksToOpen gSetNumPacksToOpen Range1-13, %iNumPacksToOpen%

			; Threshold Mode
			Gui_SetFont(16)
			ScaledOptions := "x" Round(380 * ScaleFactor) " y" Round(140 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, Disabled %ScaledOptions% hwndhThresholdCB
			Gui, Add, Text, Disabled x+5 yp-0 hp hwndhThresholdLabel, Use Threshold
			cThresholdCheckbox := new CustomCheckbox(bThreshold, hThresholdCB, hThresholdLabel, "ToggleThresholdCheckBox")
			cThresholdCheckbox.status := bThreshold

			; One Pack Mode
			ScaledOptions := "x" Round(380 * ScaleFactor) " y" Round(180 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, Disabled %ScaledOptions% hwndhOnePackModeCB
			Gui, Add, Text, Disabled x+5 yp-0 hp hwndhOnePackModeLabel, One Pack Mode
			cOnePackModeCheckbox := new CustomCheckbox(bOnePackMode, hOnePackModeCB, hOnePackModeLabel, "ToggleOnePackModeCheckBox")
			cOnePackModeCheckbox.status := bOnePackMode

			; Injection Mode
			ScaledOptions := "x" Round(380 * ScaleFactor) " y" Round(220 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, %ScaledOptions% hwndhInjectCB
			Gui, Add, Text, x+5 yp-0 hp hwndhInjectLabel, Injection Mode
			cInjectCheckbox := new CustomCheckbox(bInjectionMode, hInjectCB, hInjectLabel, "ToggleInjectionModeCheckBox")
			cInjectCheckbox.status := bInjectionMode

			; Menu Delete Account
			ScaledOptions := "x" Round(380 * ScaleFactor) " y" Round(260 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, Disabled %ScaledOptions% hwndhMenuDeleteCB
			Gui, Add, Text, Disabled x+5 yp-0 hp hwndhMenuDeleteLabel, Menu Delete Account
			cMenuDeleteCheckbox := new CustomCheckbox(bMenuDelete, hMenuDeleteCB, hMenuDeleteLabel, "ToggleMenuDeleteAccountCheckBox")
			cMenuDeleteCheckbox.status := bMenuDelete

		Gui, Tab, 3 ; Timings
			; General Delay
			Gui_SetFont()
			Gui_CreateText("General Delay:")
			ScaledOptions := "w" Round(70 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% +Limit4 Number Center gSetGeneralDelay vcGeneralDelay, %iGeneralDelay%

			; Swipe Speed
			Gui, Add, Text, x+30 yp+3, Swipe Speed:
			ScaledOptions := "w" Round(70 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% +Limit4 Number Center gSetSwipeSpeed vcSwipeSpeed, %iSwipeSpeed%

			; Add Main Delay
			Gui_CreateText("Add Main Delay:", , 140)
			ScaledOptions := "w" Round(50 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% +Limit2 Number Center gSetAddMainDelay vcAddMainDelay, %iAddMainDelay%

			; Instance Start Delay
			Gui, Add, Text, x+30 yp+3, Instance Start Delay:
			ScaledOptions := "w" Round(50 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% +Limit2 Number Center gSetInstanceStartDelay vcInstanceStartDelay, %iInstanceStartDelay%

		Gui, Tab, 4 ; Discord
			; Discord ID
			Gui_SetFont()
			Gui_CreateText("Discord ID:")
			ScaledOptions := "w" Round(250 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% Number Center gSetDiscordID vcDiscordID, %iDiscordID%

			; Open Discord List (id.txt)
			Gui_SetFont(16)
			Gui, Add, Button, x+25 yp w130 hWndhOpenDiscordListBtn gOpenDiscordList, % "Open Discord List"
			Gui_StyleButton(hOpenDiscordListBtn)

			; Discord Webhook
			Gui_SetFont()
			Gui_CreateText("Discord Webhook URL:", , 140)
			ScaledOptions := "w" Round(370 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% h28 left gSetDiscordWebhook vcDiscordWebhookURL, %sDiscordWebhookURL%

			; Heartbeat ID
			Gui_CreateText("Heartbeat ID:", , 200)
			ScaledOptions := "w" Round(250 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% +Disabled gSetHeartbeatID vcHeartBeatID, %iHeartBeatID%

			; Heartbeat Webhook
			Gui_CreateText("Heartbeat Webhook:", , 260)
			ScaledOptions := "w" Round(390 * ScaleFactor)
			Gui, Add, Edit, x+10 yp-3 %ScaledOptions% h28 +Disabled left gSetHeartbeatWebhook vcHeartBeatWebhookURL, %sHeartBeatWebhookURL%

			; Heartbeat Checkbox
			Gui_SetFont(16)
			ScaledOptions := "x" Round(440 * ScaleFactor) " y" Round(202 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, %ScaledOptions% hwndhHeartBeatCB
			Gui, Add, Text, x+5 yp-0 hp hwndhHeartBeatLabel, Heartbeat Mode
			cHeartBeatCheckbox := new CustomCheckbox(bHeartBeat, hHeartBeatCB, hHeartBeatLabel, "ToggleHeartbeatCheckBox")
			cHeartBeatCheckbox.status := bHeartBeat

		Gui, Tab, 5 ; Display
			; Monitor
			Gui_SetFont()
			Gui_CreateText("Monitor:")
			ScaledOptions := "w" Round(250 * ScaleFactor)
			Gui, Add, DropDownList, x+10 yp-3 %ScaledOptions% gMonitorChanged vcMonitorList Choose%iDisplayProfile%, %sMonitors%

			; Scale
			Gui_CreateText("Scale:", , 140)
			ScaledOptions := "w" Round(100 * ScaleFactor)
			Gui, Add, Radio, Disabled x+20 yp-0 %ScaledOptions% gScaleChanged vcScale100, 100`%
			Gui, Add, Radio, x+20 yp-0 %ScaledOptions% gScaleChanged vcScale125, 125`%
			InitializeScale()

		Gui, Tab, 6 ; Moo
			; Warning Title
			Gui_SetFont(16)
			sWarning := "Warning: Features in this section are experimental. You should not change anything here unless you know what you're doing!"
			ScaledOptions := "x" Round(18 * ScaleFactor) " y" Round(80 * ScaleFactor) " w410"
			Gui, Add, Text, %ScaledOptions% Center cRed, %sWarning%

			; Skip Main Checkbox
			Gui_SetFont()
			ScaledOptions := "x" Round(40 * ScaleFactor) " y" Round(160 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, %ScaledOptions% hwndhSkipMainCB
			Gui, Add, Text, x+5 yp-1 hp hwndhSkipMainLabel, Skip Adding Main
			cSkipMainCheckbox := new CustomCheckbox(bSkipAddingMain, hSkipMainCB, hSkipMainLabel, "ToggleSkipMainCheckBox")
			cSkipMainCheckbox.status := bSkipAddingMain

			; Fingerprint Mode Checkbox
			ScaledOptions := "x" Round(300 * ScaleFactor) " y" Round(160 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, %ScaledOptions% hwndhFingerprintCB
			Gui, Add, Text, x+5 yp-1 hp hwndhFingerprintLabel, Fingerprint Mode
			cFingerprintCheckbox := new CustomCheckbox(bFingerprintMode, hFingerprintCB, hFingerprintLabel, "ToggleFingerprintModeCheckBox")
			cFingerprintCheckbox.status := bFingerprintMode

			; Trade Mode Checkbox
			ScaledOptions := "x" Round(40 * ScaleFactor) " y" Round(210 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, Disabled %ScaledOptions% hwndhTradeCB
			Gui, Add, Text, Disabled x+5 yp-1 hp hwndhTradeLabel, Trade Mode
			cTradeCheckbox := new CustomCheckbox(bTradeMode, hTradeCB, hTradeLabel, "ToggleTradeModeCheckBox")
			cTradeCheckbox.status := bTradeMode

			; Show botStatus Checkbox
			ScaledOptions := "x" Round(300 * ScaleFactor) " y" Round(210 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, %ScaledOptions% hwndhStatusWindowCB
			Gui, Add, Text, x+5 yp-1 hp hwndhStatusWindowLabel, Show Status Window
			cStatusWindowCheckbox := new CustomCheckbox(bShowStatusWindow, hStatusWindowCB, hStatusWindowLabel, "ToggleStatusWindowCheckBox")
			cStatusWindowCheckbox.status := bShowStatusWindow

			; Select Pack Per Instance
			ScaledOptions := "x" Round(40 * ScaleFactor) " y" Round(260 * ScaleFactor) " w" Round(23 * ScaleFactor)
			Gui, Add, Pic, Disabled %ScaledOptions% hwndhPackPerInstanceCB
			Gui, Add, Text, Disabled x+5 yp-1 hp hwndhPackPerInstanceLabel, Select Pack Per Instance
			cPackPerInstanceCheckbox := new CustomCheckbox(bSelectPackPerInstance, hPackPerInstanceCB, hPackPerInstanceLabel, "ToggleSelectPackPerInstanceCheckBox")
			cPackPerInstanceCheckbox.status := bSelectPackPerInstance

		Gui, Tab, 7 ; About
			; About Title
			sTitle := "Arturo's PTCGP Bot - Version: " . localVersion
			Gui_SetFont(20)
			ScaledOptions := "x" Round(18 * ScaleFactor) " y" Round(80 * ScaleFactor) " w410"
			Gui, Add, Text, %ScaledOptions% Center cBlue, %sTitle%

			; Buy Coffee Button
			Gui_SetFont(16)
			iStartXPos := 62 ;Round((Round(650 * ScaleFactor) / 3) - (Round(220 * ScaleFactor) / 2))
			ScaledOptions := "x" iStartXPos " y" Round(140 * ScaleFactor) " w" Round(220 * ScaleFactor)
			Gui, Add, Button, %ScaledOptions% hWndhOpenLinkBtn gOpenLink, % "Buy Arturo Coffee!"
			Gui_StyleButton(hOpenLinkBtn)

			; Join Discord Button
			iStartXPos := 229 ;Round(Round((Round(650 * ScaleFactor) / 3) * 2) - (Round(220 * ScaleFactor) / 2))
			ScaledOptions := "x" iStartXPos " y" Round(140 * ScaleFactor) " w" Round(220 * ScaleFactor)
			Gui, Add, Button, %ScaledOptions% hWndhOpenDiscordBtn gOpenDiscord, % "Join Discord!"
			Gui_StyleButton(hOpenDiscordBtn)

			; Art's Github Button
			iStartXPos := 62 ;Round((Round(650 * ScaleFactor) / 3) - (Round(220 * ScaleFactor) / 2))
			ScaledOptions := "x" iStartXPos " y" Round(200 * ScaleFactor) " w" Round(220 * ScaleFactor)
			Gui, Add, Button, %ScaledOptions% hWndhOpenGithubBtn gOpenGithub, % "Arturo's Github"
			Gui_StyleButton(hOpenGithubBtn)

			; My Github Button
			iStartXPos := 229 ;Round(Round((Round(650 * ScaleFactor) / 3) * 2) - (Round(220 * ScaleFactor) / 2))
			ScaledOptions := "x" iStartXPos " y" Round(200 * ScaleFactor) " w" Round(220 * ScaleFactor)
			Gui, Add, Button, %ScaledOptions% hWndhOpenMooBtn gOpenMoo, % "Wolfeh's Github"
			Gui_StyleButton(hOpenMooBtn)

			; Skip License Checkbox
			ScaledOptions := "x" Round(18 * ScaleFactor) " y" Round(270 * ScaleFactor) " w" Round(20 * ScaleFactor)
			Gui, Add, Pic, %ScaledOptions% hwndhSkipLicenseCB
			Gui, Add, Text, x+5 yp+0 hp hwndhSkipLicenseLabel, Show License Details On Startup
			cSkipLicenseCheckbox := new CustomCheckbox(bSkipLicense, hSkipLicenseCB, hSkipLicenseLabel, "ToggleLicenseSkipCheckBox")
			cSkipLicenseCheckbox.status := bSkipLicense
			ShowLicenseDetails()

			; Update
			sUpdateText := "Check For Updates"
			Gui_SetFont(16, "cRed underline")
			Gui, Add, Text, Disabled x+80 yp+0 Right gCheckForUpdates, %sUpdateText%
			Gui, Show, % "w" Round(iGuiWidth * ScaleFactor) " h" Round(iGuiHeight * ScaleFactor), %sTitle%
		Progress, Off
		return
}
GuiClose() {
	ExitApp
}
Gui_SetFont(iFontSize := 18, sOtherAttributes := "") {
	ReferenceWidth := 2560
	ReferenceHeight := 1600
	ScaleFactor := Min(A_ScreenWidth / ReferenceWidth, A_ScreenHeight / ReferenceHeight)
	Gui, Font, % "s" Round(iFontSize * ScaleFactor) " " sOtherAttributes, Calibri
}
Gui_GetScale(iX := 18, iY := 18, iW := 23, iH := 28) {
	ReferenceWidth := 2560
	ReferenceHeight := 1600
	ScaleFactor := Min(A_ScreenWidth / ReferenceWidth, A_ScreenHeight / ReferenceHeight)
	return "x" Round(iX * ScaleFactor) " y" Round(iY * ScaleFactor) " w" Round(iW * ScaleFactor) " h" Round(iH * ScaleFactor)
}
Gui_CreateText(sDefaultText, iXPos := 18, iYPos := 80) {
	ReferenceWidth := 2560
	ReferenceHeight := 1600
	ScaleFactor := Min(A_ScreenWidth / ReferenceWidth, A_ScreenHeight / ReferenceHeight)
	Gui, Add, Text, % "x" Round(iXPos * ScaleFactor) " y" Round(iYPos * ScaleFactor), % sDefaultText
}
Gui_StyleButton(hBtn, sStyle := "Default") {
	switch sStyle
	{
		case "Default":
			aBtnStyle := [ [0, 0x80F0F0F0, , , 8, 0xFFFFFFFF, 0x8046B8DA, 1]      			  ; normal
						 , [0, 0x80C6E9F4, , , 8, 0xFFFFFFFF, 0x8046B8DA, 1]      			  ; hover
						 , [0, 0x8086D0E7, , , 8, 0xFFFFFFFF, 0x8046B8DA, 1]      			  ; pressed
						 , [0, 0x80F0F0F0, , 0x80A1A1A1, 8, 0xFFFFFFFF, 0x80CACACA, 1] ]	  ; disabled
		case "Moo":
			aBtnStyle := [ [0, 0x80F0F0F0, , , 0, , 0x80F0AD4E, 1]
						 , [0, 0x80FCEFDC, , , 0, , 0x80F0AD4E, 1]
						 , [0, 0x80F6CE95, , , 0, , 0x80F0AD4E, 1]
						 , [0, 0x80F0F0F0, , 0x80A1A1A1, 0, , 0x80CACACA, 1] ]
	}
	ImageButton.Create(hBtn, aBtnStyle*)
}
; INSTANCES #############################------------------------------------------------------
;
; Main Friend ID
SetMainFriendID() {
    global cMainID, iMainID
    GuiControlGet, iMainID,, cMainID
}
GetMainFriendID() {
    global cMainID, iMainID
    GuiControlGet, iMainID,, cMainID
	return iMainID
}
NormalizeMainFriendID(iMainID) {
	if(iMainID = "ERROR") {
		return
	} else {
		return iMainID
	}
}
; Open Friends list txt
OpenFriends() {
	sIdsFilePath := A_ScriptDir "\ids.txt"
	Run, %sIdsFilePath%
}
; Run Main Checkbox
ToggleMainCheckBox() {
	global cRunMainCheckbox, cMainID, bRunMain

	; Enable/Disable Main Friend ID Control
    If (cRunMainCheckbox.status = 1) {
        GuiControl, Enable, cMainID
    } else {
        GuiControl, Disable, cMainID
    }
}
GetMainCheckBox() {
    global bRunMain, cRunMainCheckbox
    bRunMain := cRunMainCheckbox.status
    return bRunMain
}
; Instances
SetTotalInstances() {
    global cTotalInstances, iTotalInstances
    GuiControlGet, iTotalInstances,, cTotalInstances
}
GetTotalInstances() {
    global cTotalInstances, iTotalInstances
    GuiControlGet, iTotalInstances,, cTotalInstances
	return iTotalInstances
}
; Columns
SetTotalColumns() {
    global cTotalColumns, iTotalColumns
    GuiControlGet, iTotalColumns,, cTotalColumns
}
GetTotalColumns() {
    global cTotalColumns, iTotalColumns
    GuiControlGet, iTotalColumns,, cTotalColumns
	return iTotalColumns
}
; Base Game Compatibility (SpeedMod) Checkbox
ToggleSpeedModCheckBox() {
	global cSpeedModCheckbox, bSpeedMod

    If (cSpeedModCheckbox.status = 1) {
        ; If Enabled
    } else {
        ; If Disabled
    }
}
GetSpeedModCheckBox() {
    global bSpeedMod, cSpeedModCheckbox
    bSpeedMod := cSpeedModCheckbox.status
    return bSpeedMod
}
; Mumu Install Path
SetMuMuInstallPath() {
    global cMumuInstallPath, sMumuInstallPath
    GuiControlGet, sMumuInstallPath,, cMumuInstallPath
}
GetMuMuInstallPath() {
    global cMumuInstallPath, sMumuInstallPath
    GuiControlGet, sMumuInstallPath,, cMumuInstallPath
	return sMumuInstallPath
}
; Arrange Windows
ArrangeWindows() {
	global bRunMain, iTotalInstances, iTotalColumns, iScale, iDisplayProfile

	; Initialize values
	bRunMain := GetMainCheckBox()
	iTotalInstances := GetTotalInstances()
	iTotalColumns := GetTotalColumns()
	iScale := GetScaleVal(1)
	iDisplayProfile := GetSelectedMonitor()
	SysGet, Monitor, Monitor, %iDisplayProfile%

	; Check: Are there instances to arrange?
	if (bRunMain && !WinExist("Main")) {
        MsgBox, 48, Error - ArrangeWindows(), Unable to locate Main instance`nStopping...
        return false
    }
	Loop % iTotalInstances {
        if !WinExist(A_Index) {
            MsgBox, 48, Error - ArrangeWindows(), Unable to locate instance %A_Index%`nStopping...
            return false
        }
    }

	; Instance dimensions
	iMuMuInstanceHeight := 533 ; Fixed height
	If (iScale = 0) { ; 100%
		iMumuInstanceWidth := 287
	} else { ; 125%
		iMumuInstanceWidth := 277
	}

	; Determine max possible columns and rows
	iMaxSupportedColumns := Floor(MonitorRight / iMumuInstanceWidth)
	iMaxSupportedRows := Floor(MonitorBottom / iMuMuInstanceHeight)

	; Determine the total instances that will be arranged
	iTotalEffectiveInstances := iTotalInstances
	if (bRunMain)
		iTotalEffectiveInstances += 1 ; Include "Main" as an instance

	; Calculate required rows based on user entered columns
	iRequiredRows := Ceil(iTotalEffectiveInstances / iTotalColumns)

	; Validate that user-defined column count does not exceed the max possible columns, and that the required rows do not exceed max possible rows
	if (iTotalColumns > iMaxSupportedColumns) {
		MsgBox, 48, Error - ArrangeWindows(), Monitor only supports %iMaxSupportedColumns% column per row!`nReduce the number of instances or increase columns.
		return false
	} else if (iRequiredRows > iMaxSupportedRows) {
		MsgBox, 48, Error - ArrangeWindows(), Monitor only supports %iMaxRows% rows of instances!`nReduce the number of instances or increase columns.
		return false
	}

	; Position "Main" instance first, if it exists
	iStartColumn := 0
	if (bRunMain && WinExist("Main")) {
		WinMove, Main, , MonitorLeft, MonitorTop, iMumuInstanceWidth, iMuMuInstanceHeight
		iStartColumn := 1 ; Include Main as first instance in first row
	}

	; Arrange regular instances
	Loop %iTotalInstances% {
		iPosition := A_Index - 1 + iStartColumn ; Offset position if Main exists
		iCurrentRow := Floor(iPosition / iTotalColumns)
		iCurrentColumn := Mod(iPosition, iTotalColumns)

		x := MonitorLeft + (iCurrentColumn * iMumuInstanceWidth)
		y := MonitorTop + (iCurrentRow * iMuMuInstanceHeight)

		WinMove, %A_Index%, , x, y, iMumuInstanceWidth, iMuMuInstanceHeight
	}
}

;
; PACKS #############################------------------------------------------------------
;
; Minimum Pack Value
SetMinPackVal() {
    global cMinPackVal, iMinPackVal
    GuiControlGet, iMinPackVal,, cMinPackVal
}
GetMinPackVal() {
    global cMinPackVal, iMinPackVal
    GuiControlGet, iMinPackVal,, cMinPackVal
	return iMinPackVal
}
; Threshold Value
SetThresholdVal() {
    global cThresholdVal, iThresholdVal
    GuiControlGet, iThresholdVal,, cThresholdVal
}
GetThresholdVal() {
    global cThresholdVal, iThresholdVal
    GuiControlGet, iThresholdVal,, cThresholdVal
	return iThresholdVal
}
; Pack List Drop Down
PackListChanged() {
	global cPackList, sPackToOpen
    GuiControlGet, sPackToOpen,, cPackList
}
GetPackToOpen() {
    global cPackList, sPackToOpen
    GuiControlGet, sPackToOpen,, cPackList
	return sPackToOpen
}
; Number of Packs to Open
SetNumPacksToOpen() {
    global cNumPacksToOpenLabel, cNumPacksToOpen, iNumPacksToOpen
    GuiControlGet, iNumPacksToOpen,, cNumPacksToOpen
	GuiControl,, cNumPacksToOpenLabel, %iNumPacksToOpen%  ; Update display text
}
GetNumPacksToOpen() {
    global cNumPacksToOpen, iNumPacksToOpen
    GuiControlGet, iNumPacksToOpen,, cNumPacksToOpen
	return iNumPacksToOpen
}
; Open Pokedex
OpenPokedex() {
	global pokedexFilePath
	Run, %pokedexFilePath%
}
; Threshold Mode Checkbox
ToggleThresholdCheckBox() {
	global cThresholdVal, iThresholdVal, cThresholdCheckbox, bThreshold, cMinPackValLabel, cMinPackVal, iMinPackVal

    If (cThresholdCheckbox.status = 0) {
		bThreshold := 0
        GuiControl,,cMinPackValLabel,% "Minimum Pack Value:"
		GuiControl,,cMinPackVal, %iMinPackVal%
		GuiControl, Hide, cThresholdVal
		GuiControl, Show, cMinPackVal
    } else if (cThresholdCheckbox.status = 1) {
		bThreshold := 1
		GuiControl,,cMinPackValLabel,% "Threshold Value:"
		GuiControl,,cThresholdVal, %iThresholdVal%
		GuiControl, Show, cThresholdVal
		GuiControl, Hide, cMinPackVal
    } else {
		; Skip
	}
}
GetThresholdCheckBox() {
    global bThreshold, cThresholdCheckbox
    bThreshold := cThresholdCheckbox.status
    return bThreshold
}
; One Pack Mode Checkbox
ToggleOnePackModeCheckBox() {
	global cOnePackModeCheckbox, bOnePackMode

    If (cOnePackModeCheckbox.status = 1) {
        ; If Enabled
    } else {
        ; If Disabled
    }
}
GetOnePackModeCheckBox() {
    global bOnePackMode, cOnePackModeCheckbox
    bOnePackMode := cOnePackModeCheckbox.status
    return bOnePackMode
}
; Injection Mode Checkbox
ToggleInjectionModeCheckBox() {
	global cInjectCheckbox, cNumPacksToOpen, iNumPacksToOpen, cNumPacksToOpenLabel, iSavedPackCount

	If (cInjectCheckbox.status = 1) {
		GuiControlGet, iSavedPackCount,, cNumPacksToOpen ; Store current pack count from slider before locking
		GuiControl,, cNumPacksToOpen, 2  ; Set slider to 2
		iNumPacksToOpen := 2 ; Update global status
		GuiControl,, cNumPacksToOpenLabel, 2  ; Update the display text
		GuiControl, Disable, cNumPacksToOpen  ; Disable the slider
    } else {
		GuiControl,, cNumPacksToOpen, %iSavedPackCount%  ; Set slider back to previously saved value
		iNumPacksToOpen := iSavedPackCount ; Update global status
		GuiControl,, cNumPacksToOpenLabel, %iSavedPackCount%  ; Update display text
		GuiControl, Enable, cNumPacksToOpen  ; Re-enable slider
    }
}
GetInjectionModeCheckBox() {
    global bInjectionMode, cInjectCheckbox
    bInjectionMode := cInjectCheckbox.status
    return bInjectionMode
}
; Menu Delete Account Checkbox
ToggleMenuDeleteAccountCheckBox() {
	global cMenuDeleteCheckbox, bMenuDelete

    If (cMenuDeleteCheckbox.status = 1) {
        ; If Enabled
    } else {
        ; If Disabled
    }
}
GetMenuDeleteAccountCheckBox() {
    global bMenuDelete, cMenuDeleteCheckbox
    bMenuDelete := cMenuDeleteCheckbox.status
    return bMenuDelete
}
;
; TIMINGS #############################------------------------------------------------------
;
; General Delay
SetGeneralDelay() {
    global cGeneralDelay, iGeneralDelay
    GuiControlGet, iGeneralDelay,, cGeneralDelay
}
GetGeneralDelay() {
    global cGeneralDelay, iGeneralDelay
    GuiControlGet, iGeneralDelay,, cGeneralDelay
	return iGeneralDelay
}
; Swipe Speed
SetSwipeSpeed() {
    global cSwipeSpeed, iSwipeSpeed
    GuiControlGet, iSwipeSpeed,, cSwipeSpeed
}
GetSwipeSpeed() {
    global cSwipeSpeed, iSwipeSpeed
    GuiControlGet, iSwipeSpeed,, cSwipeSpeed
	return iSwipeSpeed
}
; Add Main Delay
SetAddMainDelay() {
    global cAddMainDelay, iAddMainDelay
    GuiControlGet, iAddMainDelay,, cAddMainDelay
}
GetAddMainDelay() {
    global cAddMainDelay, iAddMainDelay
    GuiControlGet, iAddMainDelay,, cAddMainDelay
	return iAddMainDelay
}
; Instance Start Delay
SetInstanceStartDelay() {
    global cInstanceStartDelay, iInstanceStartDelay
    GuiControlGet, iInstanceStartDelay,, cInstanceStartDelay
}
GetInstanceStartDelay() {
    global cInstanceStartDelay, iInstanceStartDelay
    GuiControlGet, iInstanceStartDelay,, cInstanceStartDelay
	return iInstanceStartDelay
}
;
; DISCORD #############################------------------------------------------------------
;
; Discord ID
SetDiscordID() {
    global cDiscordID, iDiscordID
    GuiControlGet, iDiscordID,, cDiscordID
}
GetDiscordID() {
    global cDiscordID, iDiscordID
    GuiControlGet, iDiscordID,, cDiscordID
	return iDiscordID
}
NormalizeDiscordUserID(sDiscordID) {
	if(sDiscordID = "ERROR") {
		return
	} else {
		return sDiscordID
	}
}
; Discord Webhook
SetDiscordWebhook() {
    global cDiscordWebhookURL, sDiscordWebhookURL
    GuiControlGet, sDiscordWebhookURL,, cDiscordWebhookURL
}
GetDiscordWebhook() {
    global cDiscordWebhookURL, sDiscordWebhookURL
    GuiControlGet, sDiscordWebhookURL,, cDiscordWebhookURL
	return sDiscordWebhookURL
}
NormalizeDiscordWebhookURL(sDiscordWebhookURL) {
	if(sDiscordWebhookURL = "ERROR") {
		return
	} else {
		return sDiscordWebhookURL
	}
}
; Discord txt file
OpenDiscordList() {
	sDiscordListFilePath := A_ScriptDir "\discord.txt"
	Run, %sDiscordListFilePath%
}
; Heartbeat Checkbox
ToggleHeartbeatCheckBox() {
	global cHeartBeatCheckbox, bHeartBeat, cHeartBeatID, cHeartBeatWebhookURL

    If (cHeartBeatCheckbox.status = 1) {
        GuiControl, Enable, cHeartBeatID
		GuiControl, Enable, cHeartBeatWebhookURL
		bHeartBeat := 1
    } else if (cHeartBeatCheckbox.status = 0) {
        GuiControl, Disable, cHeartBeatID
		GuiControl, Disable, cHeartBeatWebhookURL
		bHeartBeat := 0
    } else {
		; Skip
	}
}
GetHeartbeatCheckBox() {
    global bHeartBeat, cHeartBeatCheckbox
    bHeartBeat := cHeartBeatCheckbox.status
    return bHeartBeat
}
; Heartbeat ID
SetHeartbeatID() {
    global cHeartBeatID, iHeartBeatID
    GuiControlGet, iHeartBeatID,, cHeartBeatID
}
GetHeartbeatID() {
    global cHeartBeatID, iHeartBeatID
    GuiControlGet, iHeartBeatID,, cHeartBeatID
	return iHeartBeatID
}
NormalizeHeartBeatName(sHeartBeatName) {
	if(sHeartBeatName = "ERROR") {
		return
	} else {
		return sHeartBeatName
	}
}
; Heartbeat Webhook
SetHeartbeatWebhook() {
    global cHeartBeatWebhookURL, sHeartBeatWebhookURL
    GuiControlGet, sHeartBeatWebhookURL,, cHeartBeatWebhookURL
}
GetHeartbeatWebhook() {
    global cHeartBeatWebhookURL, sHeartBeatWebhookURL
    GuiControlGet, sHeartBeatWebhookURL,, cHeartBeatWebhookURL
	return sHeartBeatWebhookURL
}
NormalizeHeartBeatWebhookURL(sHeartBeatWebhookURL) {
	if(sHeartBeatWebhookURL = "ERROR") {
		return
	} else {
		return sHeartBeatWebhookURL
	}
}
;
; DISPLAYS #############################------------------------------------------------------
;
; Monitor List Drop Down
MonitorChanged() {
	global cMonitorList, iDisplayProfile

	; Read currently selected monitor from control, and temporarily store it [will be (1: 1920x1080) for example]
    GuiControlGet, sTempDisplayProfile,, cMonitorList

	; Update the display profile with the index number from the selected profile [returns "1" for example]
	iDisplayProfile := GetMonitorIndex(sTempDisplayProfile)
}
GetSelectedMonitor() {
    global cMonitorList, iDisplayProfile

	; Read currently selected monitor from control [will be (1: 1920x1080) for example]
    GuiControlGet, iDisplayProfile,, cMonitorList
	; Update the display profile with the index number from the selected profile [returns "1" for example]
    iDisplayProfile := GetMonitorIndex(iDisplayProfile)

    return iDisplayProfile
}
GetMonitorList() {
	; Loops through all monitors, retrieves their names and dimensions, and builds a MonitorOptions string formatted as:
	; MonitorNumber: (Width x Height) | MonitorNumber: (Width x Height) | ...
	; Example:	1: (1920x1080) | 2: (2650x1600)
	SysGet, MonitorCount, MonitorCount
	sMonitors := ""
	Loop, %MonitorCount%
	{
		SysGet, MonitorName, MonitorName, %A_Index%
		SysGet, Monitor, Monitor, %A_Index%
		sMonitors .= (A_Index > 1 ? "|" : "") "" A_Index ": (" MonitorRight - MonitorLeft "x" MonitorBottom - MonitorTop ")"
	}
	return sMonitors
}
GetMonitorIndex(sMonitors) {
	; This strips out everything after (including) the colon in the passed in string
	; Regex Explained: The ":" means matching a colon, ".*" matches any number of characters afterward, until "$" which means end of the line
	; Example: "1: 1920x1080" becomes "1"
	; This creates the index's for the drop down options to match
	return RegExReplace(sMonitors, ":.*$")
}
; Scale
InitializeScale() {
	global cScale100, cScale125, iScale
	if (iScale = 0)
		GuiControl,, cScale100, 1
	else
		GuiControl,, cScale125, 1
}
ScaleChanged() {
	global cScale100, iScale

    ; Get values stored in control, store them temporarily
    GuiControlGet, iScale100,, cScale100

    ; Check and update global status
	If (iScale100 = 1) {
		iScale = 0
	} else if (iScale100 = 0) {
		iScale = 1
	} else {
		; Skip
	}
}
GetScaleVal(sIniRead := 0) {
	global cScale100, cScale125, iScale

	; Direct read from ini file
	If (sIniRead = 1) {
		IniRead, iScale, Settings.ini, Displays, iScale
		return iScale
	}

	; Get values stored in control, store them temporarily
    GuiControlGet, iScale,, cScale100

    ; Check and update global status
	If (iScale = 0) {
		return 0
	} else if (iScale = 1) {
		return 1
	} else {
		MsgBox, Error: Scale not defined
	}

}
;
; MOO #############################------------------------------------------------------
;
; Menu Delete Account Checkbox
ToggleSkipMainCheckBox() {
	global cSkipMainCheckbox, bSkipAddingMain

    If (cSkipMainCheckbox.status = 1) {
        ; If Enabled
    } else {
        ; If Disabled
    }
}
GetSkipMainCheckBox() {
    global bSkipAddingMain, cSkipMainCheckbox
    bSkipAddingMain := cSkipMainCheckbox.status
    return bSkipAddingMain
}
; Fingerprint Mode Checkbox
ToggleFingerprintModeCheckBox() {
	global cFingerprintCheckbox, bFingerprintMode

    If (cFingerprintCheckbox.status = 1) {
        ; If Enabled
    } else {
        ; If Disabled
    }
}
GetFingerprintModeCheckBox() {
    global bFingerprintMode, cFingerprintCheckbox
    bFingerprintMode := cFingerprintCheckbox.status
    return bFingerprintMode
}
; Trade Mode Checkbox
ToggleTradeModeCheckBox() {
	global cTradeCheckbox, bTradeMode

    If (cTradeCheckbox.status = 1) {
        ; If Enabled
    } else {
        ; If Disabled
    }
}
GetTradeModeCheckBox() {
    global bTradeMode, cTradeCheckbox
    bTradeMode := cTradeCheckbox.status
    return bTradeMode
}
; Status Window Checkbox
ToggleStatusWindowCheckBox() {
	global cStatusWindowCheckbox, bShowStatusWindow

    If (cStatusWindowCheckbox.status = 1) {
        ; If Enabled
    } else {
        ; If Disabled
    }
}
GetStatusWindowCheckBox() {
    global bShowStatusWindow, cStatusWindowCheckbox
    bShowStatusWindow := cStatusWindowCheckbox.status
    return bShowStatusWindow
}
; Select Pack Per Instance Checkbox
ToggleSelectPackPerInstanceCheckBox() {
	global cPackPerInstanceCheckbox, bSelectPackPerInstance

    If (cPackPerInstanceCheckbox.status = 1) {
        ; If Enabled
    } else {
        ; If Disabled
    }
}
GetSelectPackPerInstanceCheckBox() {
    global bSelectPackPerInstance, cPackPerInstanceCheckbox
    bSelectPackPerInstance := cPackPerInstanceCheckbox.status
    return bSelectPackPerInstance
}
;
; ABOUT #############################------------------------------------------------------
;
; Link Buttons
OpenLink() {
	Run, https://buymeacoffee.com/aarturoo
}
OpenDiscord() {
	Run, https://discord.gg/C9Nyf7P4sT
}
OpenGithub() {
	Run, https://github.com/Arturo-1212/PTCGPB
}
OpenMoo() {
	Run, https://github.com/WolfThatMoos/PTCGPExtras
}
; License Skip Checkbox
ToggleLicenseSkipCheckBox() {
	global cSkipLicenseCheckbox, bSkipLicense

    If (cSkipLicenseCheckbox.status = 1) {
        ; If Enabled
    } else {
        ; If Disabled
    }
}
GetLicenseSkipCheckBox() {
    global bSkipLicense, cSkipLicenseCheckbox
    bSkipLicense := cSkipLicenseCheckbox.status
    return bSkipLicense
}
ShowLicenseDetails() {
	global bSkipLicense
	If (bSkipLicense = 1) {
		Progress, Off
		MsgBox, 64, The project is now licensed under CC BY-NC 4.0, The original intention of this project was not for it to be used for paid services even those disguised as 'donations.' I hope people respect my wishes and those of the community. `nThe project is now licensed under CC BY-NC 4.0, which allows you to use, modify, and share the software only for non-commercial purposes. Commercial use, including using the software to provide paid services or selling it (even if donations are involved), is not allowed under this license. The new license applies to this and all future releases.
	}
}
; Update Check
CheckForUpdates() {
	MsgBox, Greetings!`nThanks for your interest in this project, however it is now discontinued, and no maintenance or updates will be added.`n`nA new version of the bot written from scratch will be available in beta at a later date. If you're interested, visit my github.`nThanks!
}
;
; HELPERS #############################------------------------------------------------------
;
VerifyFiles() {
	; This doesn't do jack shit. It's here so that while the UI is loading, the user isn't
	; sitting there like...hello? Is it loading? *spams click opens it 10 more times*
	; The immediate feedback lets them chill and wait for it to load. Looks snazzy too.
}
AddImageTab(Options, Pages, Vertical := False) {
    static HwndList := {}, TabPairs := {}

    ; Define styles for active and inactive tabs | [Mode, StartColor, TargetColor, TextColor, Rounded, GuiColor, BorderColor, BorderWidth]
    ActiveTabStyle := [ [0, 0x80C6E9F4, , , 0, , 0x8046B8DA, 1]      ; normal
                      , [0, 0x8086D0E7, , , 0, , 0x8046B8DA, 1]      ; hover
                      , [0, 0x8046B8DA, , , 0, , 0x8046B8DA, 1]      ; pressed
                      , [0, 0x80F0F0F0, , , 0, , 0x8046B8DA, 1] ]

    InactiveTabStyle := [ [0, 0x80F0F0F0, , , , , 0xb0b0b0b0, 1]      ; normal
                        , [0, 0x80C6E6C6, , , , , 0xb0b0b0b0, 1]      ; hover
                        , [0, 0x8091CF91, , , , , 0xb0b0b0b0, 1]      ; pressed
                        , [0, 0x80F0F0F0, , , , , 0xb0b0b0b0, 1] ]

    ; Create a Hidden Tab control to keep track of the tab pages
    Gui, Add, Tab2, w0 h0 AltSubmit HwndTabHwnd, % Pages
    Gui, Tab

    ; Ensure correct formatting for pages
    if !InStr(Pages, "||")
        Pages := Trim(StrReplace(Pages, "|", "||",, 1), "|" )

    TabIndex := 1
	FirstActiveHwnd := ""
    Loop, Parse, Pages, |
    {
        if (A_LoopField = "")
            Continue

        ; Positioning logic to ensure stacking
		_Options := (A_Index = 1) ? Options " xp" : (Vertical ? "y+0" : "x+0")

		; Create Inactive Button (Default Visible)
        Gui, Add, Button, %_Options% HwndInactiveHwnd gAddImageTab_ChangeTab, % A_LoopField
		if (A_Index = 7) {
			Gui_StyleButton(InactiveHwnd, "Moo")
		} else {
			ImageButton.Create(InactiveHwnd, InactiveTabStyle*)
		}

        ; Get the position and size of the inactive button
        GuiControlGet, InactivePos, Pos, %InactiveHwnd%

        ; Create Active Button (Initially Hidden, excluding first tab) **at the same location**
        ActiveOptions := "x" InactivePosX " y" InactivePosY " w" InactivePosW " h" InactivePosH
		if (A_Index > 1)
            ActiveOptions .= " Hidden"
        Gui, Add, Button, %ActiveOptions% HwndActiveHwnd gAddImageTab_ChangeTab, % A_LoopField
        ImageButton.Create(ActiveHwnd, ActiveTabStyle*)

        ; Store button relationships in array format for AHK v1 compatibility
        HwndList[InactiveHwnd] := [TabIndex, TabHwnd, ActiveHwnd, InactiveHwnd]
        HwndList[ActiveHwnd] := [TabIndex, TabHwnd, ActiveHwnd, InactiveHwnd]

		; Track first active tab to hide its inactive version later
        if (A_Index = 1)
            FirstActiveHwnd := ActiveHwnd

        TabIndex++
    }

	; Ensure first tab starts active
	if (FirstActiveHwnd) {
		GuiControl, Hide, % HwndList[FirstActiveHwnd][4]  ; Hide first tab's inactive button
		GuiControl, Show, % FirstActiveHwnd  ; Show first tab's active button
	}

    Return

    AddImageTab_ChangeTab:
    GuiControlGet, focused_control, Focus
    GuiControlGet, focused_controlHwnd, Hwnd, %focused_control%

    ; Retrieve button pair (use array notation for AHK v1)
    TabIndex := HwndList[focused_controlHwnd][1]
    TabHwnd := HwndList[focused_controlHwnd][2]
    ActiveHwnd := HwndList[focused_controlHwnd][3]
    InactiveHwnd := HwndList[focused_controlHwnd][4]

    ; Reset all tabs to inactive first
    For EachHwnd, Info in HwndList
    {
        InactiveHwnd_Reset := Info[4]
        ActiveHwnd_Reset := Info[3]

        GuiControl, Show, %InactiveHwnd_Reset%
        GuiControl, Hide, %ActiveHwnd_Reset%
    }

    ; Activate the clicked tab
    GuiControl, Hide, %InactiveHwnd%
    GuiControl, Show, %ActiveHwnd%

    ; Switch to selected tab
    GuiControl, Choose, %TabHwnd%, % TabIndex

    Return
}
class CustomCheckbox {
	__New(status, hPic, hText, onChangeFunc := "") {
	   this.hPic := hPic
	   this.onChangeFunc := onChangeFunc
	   WinGetPos,,, W, H, ahk_id %hPic%
        (!W && W := H), (!H && H := W), (!(W && H) && (W := 16, H := 16))
        hBmChecked   := HBitmapFromBase64Image(GetImage("checked"), W, H)
        hBmUnchecked := HBitmapFromBase64Image(GetImage("unchecked"), W, H)
        this.OnClick := OnClick := ObjBindMethod(this, "_OnClickCheckbox", hBmChecked, hBmUnchecked)
        ; this._status := !status
		this._status := !!status  ; Ensure _status is always 0 or 1
        this.OnClick.Call()
        GuiControl, +g, %hPic%, % OnClick
        GuiControl, +g, %hText%, % OnClick
	}

	status[] {
		get {
		   return this._status
		}
		set {
		   if (this._status != !!value)
			  this.OnClick.Call()
		   return !!value
		}
	 }
	_OnClickCheckbox(hBitmap1, hBitmap0) {
	   this._status := !this._status
	   t := this._status
	   GuiControl,, % this.hPic, % "HBITMAP:*" . hBitmap%t%

	   if (this.onChangeFunc != "") {
			funcRef := Func(this.onChangeFunc) ; Get function reference
			if (IsFunc(funcRef)) {
				funcRef.Call()
			}
		}
	}
 }

 HBitmapFromBase64Image(base64, width, height) {
	size := CryptStringToBinary(base64, data)
	Return GetBitmapFromData(&data, size, width, height)
 }

 GetBitmapFromData(pData, size, width, height) {
	pIStream := DllCall("Shlwapi\SHCreateMemStream", "Ptr", pData, "UInt", size, "Ptr")
	GDIp := new GDIplus
	pBitmap := GDIp.CreateBitmapFromStream(pIStream)
	GDIp.GetImageDimensions(pBitmap, W, H)
	ObjRelease(pIStream)
	if !(width = W && height = H) {
	   pNewBitmap := Gdip.CreateBitmap(width, height)
	   G := Gdip.GraphicsFromImage(pNewBitmap)
	   Gdip.SetInterpolationMode(G, HighQualityBicubic := 7)
	   Gdip.DrawImage(G, pBitmap, 0, 0, width, height, 0, 0, W, H)
	   Gdip.DisposeImage(pBitmap), Gdip.DeleteGraphics(G)
	   pBitmap := pNewBitmap
	}
	hBitmap := GDIp.CreateHBITMAPFromBitmap(pBitmap)
	GDIp.DisposeImage(pBitmap)
	Return hBitmap
 }

 CryptStringToBinary(string, ByRef outData, formatName := "CRYPT_STRING_BASE64") {
	static formats := { CRYPT_STRING_BASE64: 0x1
					  , CRYPT_STRING_HEX:    0x4
					  , CRYPT_STRING_HEXRAW: 0xC }
	fmt := formats[formatName]
	chars := StrLen(string)
	if !DllCall("Crypt32\CryptStringToBinary", "Str", string, "UInt", chars, "UInt", fmt
											 , "Ptr", 0, "UIntP", bytes, "UIntP", 0, "UIntP", 0)
	   throw "CryptStringToBinary failed. LastError: " . A_LastError
	VarSetCapacity(outData, bytes)
	DllCall("Crypt32\CryptStringToBinary", "Str", string, "UInt", chars, "UInt", fmt
										 , "Str", outData, "UIntP", bytes, "UIntP", 0, "UIntP", 0)
	Return bytes
 }

 class GDIplus {
	__New() {
	   if !DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
		  DllCall("LoadLibrary", "Str", "gdiplus")
	   VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
	   DllCall("gdiplus\GdiplusStartup", "UPtrP", pToken, "Ptr", &si, "Ptr", 0)
	   this.token := pToken
	}
	__Delete()  {
	   DllCall("gdiplus\GdiplusShutdown", "Ptr", this.token)
	   if hModule := DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
		  DllCall("FreeLibrary", "Ptr", hModule)
	}
	GraphicsFromImage(pBitmap) {
	   DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "PtrP", pGraphics)
	   return pGraphics
	}
	CreateHBITMAPFromBitmap(pBitmap, Background=0xffffffff) {
	   DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "PtrP", hbm, "Int", Background)
	   return hbm
	}
	CreateBitmapFromStream(pIStream) {
	   DllCall("gdiplus\GdipCreateBitmapFromStream", "Ptr", pIStream, "PtrP", pBitmap)
	   Return pBitmap
	}
	CreateBitmap(Width, Height, Format=0x26200A) {
		DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", Width, "Int", Height, "Int", 0, "Int", Format, "Ptr", 0, "PtrP", pBitmap)
		Return pBitmap
	}
	GetImageDimensions(pBitmap, ByRef Width, ByRef Height) {
	   DllCall("gdiplus\GdipGetImageWidth", "Ptr", pBitmap, "UIntP", Width)
	   DllCall("gdiplus\GdipGetImageHeight", "Ptr", pBitmap, "UIntP", Height)
	}
	SetInterpolationMode(pGraphics, InterpolationMode) {
	   return DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", pGraphics, "Int", InterpolationMode)
	}
	DrawImage(pGraphics, pBitmap, dx, dy, dw, dh, sx, sy, sw, sh)  {
	   Return DllCall("gdiplus\GdipDrawImageRectRect", "Ptr", pGraphics, "Ptr", pBitmap
													 , "Float", dx, "Float", dy, "Float", dw, "Float", dh
													 , "Float", sx, "Float", sy, "Float", sw, "Float", sh
													 , "Int", 2, "Ptr", 0, "Ptr", 0, "Ptr", 0)
	}
	DeleteGraphics(pGraphics) {
	   return DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
	}
	DisposeImage(pBitmap)  {
	   return DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
	}
 }

 GetImage(name) {
	ImgChecked =
	(LTrim Join
	   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
	)

	ImgUnchecked =
	(LTrim Join
	   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
	)
	Return Img%name%
}
