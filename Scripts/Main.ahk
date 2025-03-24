#Include %A_ScriptDir%\Include\Gdip_All.ahk
#Include %A_ScriptDir%\Include\Gdip_Imagesearch.ahk
#Include %A_ScriptDir%\Include\MooExtras.ahk
#SingleInstance on
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetBatchLines, -1
SetTitleMatchMode, 3
CoordMode, Pixel, Screen

; Allocate and hide the console window to reduce flashing
DllCall("AllocConsole")
WinHide % "ahk_id " DllCall("GetConsoleWindow", "ptr")

global winTitle, changeDate, failSafe, failSafeTime, StartSkipTime, failSafe, adbPort, scriptName, adbShell, adbPath, GPTest, StatusText, pauseToggle, deleteXML, packs, AddFriend, showStatus

deleteAccount := false
scriptName := StrReplace(A_ScriptName, ".ahk")
winTitle := scriptName
pauseToggle := false
showStatus := true

LoadSettingsFile()

global Variation, scaleParam, defaultLanguage
Variation := 20
scaleParam := 277
defaultLanguage := "Scale125"

adbPort := findAdbPorts(sMuMuInstallPath)

adbPath := sMuMuInstallPath . "\MuMuPlayerGlobal-12.0\shell\adb.exe"

if !FileExist(adbPath) ; if international mumu file path isn't found look for chinese domestic path
	adbPath := sMuMuInstallPath . "\MuMu Player 12\shell\adb.exe"

if !FileExist(adbPath)
	MsgBox Double check your folder path! It should be the one that contains the MuMuPlayer 12 folder! `nDefault is just C:\Program Files\Netease

if(!adbPort) {
	Msgbox, Invalid port... Check the common issues section in the readme/github guide.
	ExitApp
}

instanceSleep := scriptName * 1000
Sleep, %instanceSleep%

; Attempt to connect to ADB
ConnectAdb()

ArrangeWindows()
MaxRetries := 10
RetryCount := 0
Loop {
	try {
		WinGetPos, x, y, Width, Height, %winTitle%
		sleep, 2000
		;Winset, Alwaysontop, On, %winTitle%
		OwnerWND := WinExist(winTitle)
		x4 := x + 5
		y4 := y + 44

		Gui, New, +Owner%OwnerWND% -AlwaysOnTop +ToolWindow -Caption
		Gui, Default
		Gui, Margin, 4, 4  ; Set margin for the GUI
		Gui, Font, s5 cGray Norm Bold, Segoe UI  ; Normal font for input labels
		Gui, Add, Button, x0 y0 w30 h25 gReloadScript, Reload  (F5)
		Gui, Add, Button, x30 y0 w30 h25 gPauseScript, Pause (F6)
		Gui, Add, Button, x60 y0 w40 h25 gResumeScript, Resume (F6)
		Gui, Add, Button, x100 y0 w30 h25 gStopScript, Stop (F7)
		Gui, Add, Button, x130 y0 w40 h25 gShowStatusMessages, Status (F8)
		Gui, Show, NoActivate x%x4% y%y4% AutoSize
		break
	}
	catch {
		RetryCount++
		if (RetryCount >= MaxRetries) {
			CreateStatusMessage("Failed to create button gui.")
			break
		}
		Sleep, 1000
	}
	Sleep, %iGeneralDelay%
	CreateStatusMessage("Trying to create button gui...")
}

rerollTime := A_TickCount

initializeAdbShell()
restartGameInstance("Initializing bot...", false)
pToken := Gdip_Startup()

global bHeartBeat
if(bHeartBeat)
	IniWrite, 1, %A_ScriptDir%\..\HeartBeat.ini, HeartBeat, Main


; Start up ----------------------------------------------------------------------------------------------------------------------------

firstRun := true

; Click social icon until social hub is active tab
FindImageAndClick(120, 500, 155, 530, 10, "Social", 143, 518, 1000, 30)

Loop
{

	if(bHeartBeat)
		IniWrite, 1, %A_ScriptDir%\..\HeartBeat.ini, HeartBeat, Main

	; Click on Social icon until social hub is active tab
	FindImageAndClick(120, 500, 155, 530, , "Social", 143, 518, 1000, 30)

	; Click on Friends icon until add friend icon shows
	FindImageAndClick(226, 100, 270, 135, , "Add", 38, 460, 500)

	; Click on the approve tab button until it's selected
	FindImageAndClick(170, 450, 195, 480, , "Approve", 228, 464)

	; Deny all friend requests if there are any
	if(firstRun) {
		Sleep, 1000
		adbClick(205, 510)
		Sleep, 1000
		adbClick(210, 372)
		firstRun := false
	}

	done := false
	Loop 3 {
		Sleep, %iGeneralDelay%
		if(FindOrLoseImage(225, 195, 250, 215, , "Pending", 0)) {
			failSafe := A_TickCount
			failSafeTime := 0

			Loop {
				Sleep, %iGeneralDelay%
				clickButton := FindOrLoseImage(75, 340, 195, 530, 80, "Button", 0, failSafeTime) ;looking for ok button in case an invite is withdrawn

				if(FindOrLoseImage(123, 110, 162, 127, , "99", 0, failSafeTime)) {
					done := true
					break
				}else if(FindOrLoseImage(123, 110, 162, 127, , "991", 0, failSafeTime)) {
					done := true
					break
				}else if(FindOrLoseImage(123, 110, 162, 127, , "992", 0, failSafeTime)) {
					done := true
					break
				}else if(FindOrLoseImage(123, 110, 162, 127, , "993", 0, failSafeTime)) {
					done := true
					break
				}else if(FindOrLoseImage(80, 170, 120, 195, , "player", 0, failSafeTime)) {
					Sleep, %iGeneralDelay%
					adbClick(210, 210)
					Sleep, 1000
				} else if(FindOrLoseImage(225, 195, 250, 220, , "Pending", 0, failSafeTime)) {
					adbClick(245, 210)
				} else if(FindOrLoseImage(186, 496, 206, 518, , "Accept", 0, failSafeTime)) {
					done := true
					break
				} else if(clickButton) {
					StringSplit, pos, clickButton, `,  ; Split at ", "
					if (scaleParam = 287) {
						pos2 += 5
					}
					Sleep, 1000
					if(FindImageAndClick(190, 195, 215, 220, , "DeleteFriend", pos1, pos2, 4000)) {
						Sleep, %iGeneralDelay%
						adbClick(210, 210)
					}
				}
				failSafeTime := (A_TickCount - failSafe) // 1000
				CreateStatusMessage("Failsafe " . failSafeTime "/180 seconds")
			}
		}
		if(done || fullList)
			break
	}
}

return



























; Arrange Windows
ArrangeWindows() {
	global bRunMain, iTotalInstances, iTotalColumns, iScale, iDisplayProfile

	; Initialize values
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

FindOrLoseImage(X1, Y1, X2, Y2, searchVariation := "", imageName := "DEFAULT", EL := 1, safeTime := 0) {
	global winTitle, Variation, failSafe, defaultLanguage

	imagePath := A_ScriptDir . "\" . defaultLanguage . "\"
	confirmed := false

	if(searchVariation = "")
		searchVariation := Variation

	CreateStatusMessage(imageName)
	pBitmap := from_window(WinExist(winTitle))
	Path = %imagePath%%imageName%.png
	pNeedle := GetNeedle(Path)

	; 100% scale changes
	; if (scaleParam = 287) {
	; 	Y1 -= 8 ; offset, should be 44-36 i think?
	; 	Y2 -= 8
	; 	if (Y1 < 0) {
	; 		Y1 := 0
	; 	}
	; 	if (imageName = "Bulba") { ; too much to the left? idk how that happens
	; 		X1 := 200
	; 		Y1 := 220
	; 		X2 := 230
	; 		Y2 := 260
	; 	}
	; 	else if (imageName = "99") { ; 100% full of friend list
	; 		X1 := 60 ; Francais
	; 		Y1 := 103
	; 		X2 := 168 ; English
	; 		Y2 := 118
	; 	}
	; 	else if (imageName = "991") { ; 100% full of friend list
	; 		X1 := 60 ; Francais
	; 		Y1 := 103
	; 		X2 := 168 ; English
	; 		Y2 := 118
	; 	}
	; 	else if (imageName = "992") { ; 100% full of friend list
	; 		X1 := 60 ; Francais
	; 		Y1 := 103
	; 		X2 := 168 ; English
	; 		Y2 := 118
	; 	}
	; 	else if (imageName = "993") { ; 100% full of friend list
	; 		X1 := 60 ; Francais
	; 		Y1 := 103
	; 		X2 := 168 ; English
	; 		Y2 := 118
	; 	}
	; 	else if (imageName = "player") { ; 100% bot got deleted
	; 		X1 := 85
	; 		Y1 := 168
	; 		X2 := 120
	; 		Y2 := 181
	; 	}
	; }
	;bboxAndPause(X1, Y1, X2, Y2)

	; ImageSearch within the region
	vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, X1, Y1, X2, Y2, searchVariation)
	Gdip_DisposeImage(pBitmap)
	if(EL = 0)
		GDEL := 1
	else
		GDEL := 0
	if (!confirmed && vRet = GDEL && GDEL = 1) {
		confirmed := vPosXY
	} else if(!confirmed && vRet = GDEL && GDEL = 0) {
		confirmed := true
	}
	pBitmap := from_window(WinExist(winTitle))
	Path = %imagePath%App.png
	pNeedle := GetNeedle(Path)
	; ImageSearch within the region
	vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, 15, 155, 270, 420, searchVariation)
	Gdip_DisposeImage(pBitmap)
	if (vRet = 1) {
		CreateStatusMessage("At home page. Opening app..." )
		restartGameInstance("At the home page during: `n" imageName)
	}
	if(imageName = "Country" || imageName = "Social")
		FSTime := 90
	else
		FSTime := 180
	if (safeTime >= FSTime) {
		CreateStatusMessage("Instance " . scriptName . " has been `nstuck " . imageName . " for 90s. EL: " . EL . " sT: " . safeTime . " Killing it...")
		restartGameInstance("Instance " . scriptName . " has been stuck " . imageName)
		failSafe := A_TickCount
	}
	return confirmed
}

FindImageAndClick(X1, Y1, X2, Y2, searchVariation := "", imageName := "DEFAULT", clickx := 0, clicky := 0, sleepTime := "", skip := false, safeTime := 0) {

	global winTitle, Variation, failSafe, confirmed, iGeneralDelay, defaultLanguage

	imagePath := A_ScriptDir . "\" defaultLanguage "\"

	if(searchVariation = "")
		searchVariation := Variation

	if (sleepTime = "")
		sleepTime := iGeneralDelay

	click := false
	if(clickx > 0 and clicky > 0)
		click := true
	x := 0
	y := 0
	StartSkipTime := A_TickCount

	confirmed := false

	; ; 100% scale changes
	; if (scaleParam = 287) {
	; 	Y1 -= 8 ; offset, should be 44-36 i think?
	; 	Y2 -= 8
	; 	if (Y1 < 0) {
	; 		Y1 := 0
	; 	}

	; 	if (imageName = "Platin") { ; can't do text so purple box
	; 		X1 := 141
	; 		Y1 := 189
	; 		X2 := 208
	; 		Y2 := 224
	; 	} else if (imageName = "Opening") { ; Opening click (to skip cards) can't click on the immersive skip with 239, 497
	; 		clickx := 250
	; 		clicky := 505
	; 	}
	; }

	if(click) {
		adbClick(clickx, clicky)
		clickTime := A_TickCount
	}
	CreateStatusMessage(imageName)

	Loop { ; Main loop
		Sleep, 10
		if(click) {
			ElapsedClickTime := A_TickCount - clickTime
			if(ElapsedClickTime > sleepTime) {
				adbClick(clickx, clicky)
				clickTime := A_TickCount
			}
		}

		if (confirmed) {
			continue
		}

		pBitmap := from_window(WinExist(winTitle))
		Path = %imagePath%%imageName%.png
		pNeedle := GetNeedle(Path)
		;bboxAndPause(X1, Y1, X2, Y2)
		; ImageSearch within the region
		vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, X1, Y1, X2, Y2, searchVariation)
		Gdip_DisposeImage(pBitmap)
		if (!confirmed && vRet = 1) {
			confirmed := vPosXY
		} else {
			if(skip < 45) {
				ElapsedTime := (A_TickCount - StartSkipTime) // 1000
				FSTime := 45
				if (ElapsedTime >= FSTime || safeTime >= FSTime) {
					CreateStatusMessage("Instance " . scriptName . " has been stuck for 90s. Killing it...")
					restartGameInstance("Instance " . scriptName . " has been stuck at " . imageName) ; change to reset the instance and delete data then reload script
					StartSkipTime := A_TickCount
					failSafe := A_TickCount
				}
			}
		}

		pBitmap := from_window(WinExist(winTitle))
		Path = %imagePath%Error1.png
		pNeedle := GetNeedle(Path)
		; ImageSearch within the region
		vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, 15, 155, 270, 420, searchVariation)
		Gdip_DisposeImage(pBitmap)
		if (vRet = 1) {
			CreateStatusMessage("Error message in " scriptName " Clicking retry..." )
			LogToFile("Error message in " scriptName " Clicking retry..." )
			adbClick(82, 389)
			Sleep, %iGeneralDelay%
			adbClick(139, 386)
			Sleep, 1000
		}
		pBitmap := from_window(WinExist(winTitle))
		Path = %imagePath%App.png
		pNeedle := GetNeedle(Path)
		; ImageSearch within the region
		vRet := Gdip_ImageSearch(pBitmap, pNeedle, vPosXY, 15, 155, 270, 420, searchVariation)
		Gdip_DisposeImage(pBitmap)
		if (vRet = 1) {
			CreateStatusMessage("At home page. Opening app..." )
			restartGameInstance("Found myself at the home page during: `n" imageName)
		}

		if(skip) {
			ElapsedTime := (A_TickCount - StartSkipTime) // 1000
			if (ElapsedTime >= skip) {
				return false
				ElapsedTime := ElapsedTime/2
				break
			}
		}
		if (confirmed) {
			break
		}

	}
	return confirmed
}


restartGameInstance(reason, RL := true){
	global scriptName, adbShell, adbPath, adbPort
	initializeAdbShell()
	CreateStatusMessage("Restarting game reason: " reason)

	adbShell.StdIn.WriteLine("am force-stop jp.pokemon.pokemontcgp")
	;adbShell.StdIn.WriteLine("rm -rf /data/data/jp.pokemon.pokemontcgp/cache/*") ; clear cache
	Sleep, 3000
	adbShell.StdIn.WriteLine("am start -n jp.pokemon.pokemontcgp/com.unity3d.player.UnityPlayerActivity")

	Sleep, 3000
	if(RL) {
		LogToFile("Restarted game for instance " scriptName " Reason: " reason, "Restart.txt")
		LogToDiscord("Restarted game for instance " scriptName " Reason: " reason, , iDiscordID)
		Reload
	}
}

LogToFile(message, logFile := "") {
	global scriptName
	if(logFile = "") {
		return ;step logs no longer needed and i'm too lazy to go through the script and remove them atm...
		logFile := A_ScriptDir . "\..\Logs\Logs" . scriptName . ".txt"
	}
	else
		logFile := A_ScriptDir . "\..\Logs\" . logFile
	FormatTime, readableTime, %A_Now%, MMMM dd, yyyy HH:mm:ss
	FileAppend, % "[" readableTime "] " message "`n", %logFile%
}

CreateStatusMessage(Message, GuiName := "StatusMessage", X := 0, Y := 80) {
	global scriptName, winTitle, StatusText
	static hwnds := {}
	if(!showStatus)
		return
	try {
		; Check if GUI with this name already exists
		;GuiName := GuiName ; hoytdj Removed
		if !hwnds.HasKey(GuiName) {
			WinGetPos, xpos, ypos, Width, Height, %winTitle%
			X := X + xpos + 5
			Y := Y + ypos
			if(!X)
				X := 0
			if(!Y)
				Y := 0

			; Create a new GUI with the given name, position, and message
			Gui, %GuiName%:New, -AlwaysOnTop +ToolWindow -Caption
			Gui, %GuiName%:Margin, 2, 2  ; Set margin for the GUI
			Gui, %GuiName%:Font, s8  ; Set the font size to 8 (adjust as needed)
			Gui, %GuiName%:Add, Text, hwndhCtrl vStatusText,
			hwnds[GuiName] := hCtrl
			OwnerWND := WinExist(winTitle)
			Gui, %GuiName%:+Owner%OwnerWND% +LastFound
			DllCall("SetWindowPos", "Ptr", WinExist(), "Ptr", 1  ; HWND_BOTTOM
				, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13)  ; SWP_NOSIZE, SWP_NOMOVE, SWP_NOACTIVATE
			Gui, %GuiName%:Show, NoActivate x%X% y%Y% AutoSize
		}
		SetTextAndResize(hwnds[GuiName], Message)
		Gui, %GuiName%:Show, NoActivate AutoSize
	}
}

;Modified from https://stackoverflow.com/a/49354127
SetTextAndResize(controlHwnd, newText) {
	dc := DllCall("GetDC", "Ptr", controlHwnd)

	; 0x31 = WM_GETFONT
	SendMessage 0x31,,,, ahk_id %controlHwnd%
	hFont := ErrorLevel
	oldFont := 0
	if (hFont != "FAIL")
		oldFont := DllCall("SelectObject", "Ptr", dc, "Ptr", hFont)

	VarSetCapacity(rect, 16, 0)
	; 0x440 = DT_CALCRECT | DT_EXPANDTABS
	h := DllCall("DrawText", "Ptr", dc, "Ptr", &newText, "Int", -1, "Ptr", &rect, "UInt", 0x440)
	; width = rect.right - rect.left
	w := NumGet(rect, 8, "Int") - NumGet(rect, 0, "Int")

	if oldFont
		DllCall("SelectObject", "Ptr", dc, "Ptr", oldFont)
	DllCall("ReleaseDC", "Ptr", controlHwnd, "Ptr", dc)

	GuiControl,, %controlHwnd%, %newText%
	GuiControl MoveDraw, %controlHwnd%, % "h" h*96/A_ScreenDPI + 2 " w" w*96/A_ScreenDPI + 2
}

adbClick(X, Y) {
	global adbShell, adbPath, adbPort
	initializeAdbShell()
	X := Round(X / 277 * 540)
	Y := Round((Y - 44) / 489 * 960)
	adbShell.StdIn.WriteLine("input tap " X " " Y)
}

ControlClick(X, Y) {
	global winTitle
	ControlClick, x%X% y%Y%, %winTitle%
}

RandomUsername() {
	FileRead, content, %A_ScriptDir%\..\usernames.txt

	values := StrSplit(content, "`r`n") ; Use `n if the file uses Unix line endings

	; Get a random index from the array
	Random, randomIndex, 1, values.MaxIndex()

	; Return the random value
	return values[randomIndex]
}

adbInput(name) {
	global adbShell, adbPath, adbPort
	initializeAdbShell()
	adbShell.StdIn.WriteLine("input text " . name )
}

adbSwipeUp() {
	global adbShell, adbPath, adbPort
	initializeAdbShell()
	adbShell.StdIn.WriteLine("input swipe 309 816 309 355 60")
	;adbShell.StdIn.WriteLine("input swipe 309 816 309 555 30")
	Sleep, 150
}

adbSwipe() {
	global adbShell, setSpeed, iSwipeSpeed, adbPath, adbPort
	initializeAdbShell()
	X1 := 35
	Y1 := 327
	X2 := 267
	Y2 := 327
	X1 := Round(X1 / 277 * 535)
	Y1 := Round((Y1 - 44) / 489 * 960)
	X2 := Round(X2 / 44 * 535)
	Y2 := Round((Y2 - 44) / 489 * 960)
	if(setSpeed = 1) {
		adbShell.StdIn.WriteLine("input swipe " . X1 . " " . Y1 . " " . X2 . " " . Y2 . " " . iSwipeSpeed)
		sleepDuration := iSwipeSpeed * 1.2
		Sleep, %sleepDuration%
	}
	else if(setSpeed = 2) {
		adbShell.StdIn.WriteLine("input swipe " . X1 . " " . Y1 . " " . X2 . " " . Y2 . " " . iSwipeSpeed)
		sleepDuration := iSwipeSpeed * 1.2
		Sleep, %sleepDuration%
	}
	else {
		adbShell.StdIn.WriteLine("input swipe " . X1 . " " . Y1 . " " . X2 . " " . Y2 . " " . iSwipeSpeed)
		sleepDuration := iSwipeSpeed * 1.2
		Sleep, %sleepDuration%
	}
}

Screenshot(filename := "Valid") {
	global adbShell, adbPath, packs
	SetWorkingDir %A_ScriptDir%  ; Ensures the working directory is the script's directory

	; Define folder and file paths
	screenshotsDir := A_ScriptDir "\..\Screenshots"
	if !FileExist(screenshotsDir)
		FileCreateDir, %screenshotsDir%

	; File path for saving the screenshot locally
	screenshotFile := screenshotsDir "\" . A_Now . "_" . winTitle . "_" . filename . "_" . packs . "_packs.png"

	pBitmap := from_window(WinExist(winTitle))
	Gdip_SaveBitmapToFile(pBitmap, screenshotFile)

	return screenshotFile
}

LogToDiscord(message, screenshotFile := "", ping := false, xmlFile := "") {
	global iDiscordID, sDiscordWebhookURL
	if (sDiscordWebhookURL != "") {
		MaxRetries := 10
		RetryCount := 0
		Loop {
			try {
				; Prepare the message data
				if (ping && iDiscordID != "") {
					data := "{""content"": ""<@" iDiscordID "> " message """}"
				} else {
					data := "{""content"": """ message """}"
				}

				; Create the HTTP request object
				whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
				whr.Open("POST", sDiscordWebhookURL, false)
				whr.SetRequestHeader("Content-Type", "application/json")
				whr.Send(data)

				; If an image file is provided, send it
				if (screenshotFile != "") {
					; Check if the file exists
					if (FileExist(screenshotFile)) {
						; Send the image using curl
						RunWait, curl -k -F "file=@%screenshotFile%" %sDiscordWebhookURL%,, Hide
					}
				}
				if (xmlFile != "") {
					; Check if the file exists
					if (FileExist(xmlFile)) {
						; Send the image using curl
						RunWait, curl -k -F "file=@%xmlFile%" %sDiscordWebhookURL%,, Hide
					}
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
			sleep, 250
		}
	}
}
; Pause Script
PauseScript:
	CreateStatusMessage("Pausing...")
	Pause, On
return

; Resume Script
ResumeScript:
	CreateStatusMessage("Resuming...")
	Pause, Off
	StartSkipTime := A_TickCount ;reset stuck timers
	failSafe := A_TickCount
return

; Stop Script
StopScript:
	CreateStatusMessage("Stopping script...")
ExitApp
return

ShowStatusMessages:
	ToggleStatusMessages()
return

ReloadScript:
	Reload
return

TestScript:
	ToggleTestScript()
return

ToggleTestScript() {
	global GPTest
	if(!GPTest) {
		CreateStatusMessage("In GP Test Mode")
		GPTest := true
	}
	else {
		CreateStatusMessage("Exiting GP Test Mode")
		;Winset, Alwaysontop, On, %winTitle%
		GPTest := false
	}
}

FriendAdded() {
	global AddFriend
	AddFriend++
}

from_window(ByRef image) {
	; Thanks tic - https://www.autohotkey.com/boards/viewtopic.php?t=6517

	; Get the handle to the window.
	image := (hwnd := WinExist(image)) ? hwnd : image

	; Restore the window if minimized! Must be visible for capture.
	if DllCall("IsIconic", "ptr", image)
		DllCall("ShowWindow", "ptr", image, "int", 4)

	; Get the width and height of the client window.
	VarSetCapacity(Rect, 16) ; sizeof(RECT) = 16
	DllCall("GetClientRect", "ptr", image, "ptr", &Rect)
		, width  := NumGet(Rect, 8, "int")
		, height := NumGet(Rect, 12, "int")

	; struct BITMAPINFOHEADER - https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapinfoheader
	hdc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
	VarSetCapacity(bi, 40, 0)                ; sizeof(bi) = 40
		, NumPut(       40, bi,  0,   "uint") ; Size
		, NumPut(    width, bi,  4,   "uint") ; Width
		, NumPut(  -height, bi,  8,    "int") ; Height - Negative so (0, 0) is top-left.
		, NumPut(        1, bi, 12, "ushort") ; Planes
		, NumPut(       32, bi, 14, "ushort") ; BitCount / BitsPerPixel
		, NumPut(        0, bi, 16,   "uint") ; Compression = BI_RGB
		, NumPut(        3, bi, 20,   "uint") ; Quality setting (3 = low quality, no anti-aliasing)
	hbm := DllCall("CreateDIBSection", "ptr", hdc, "ptr", &bi, "uint", 0, "ptr*", pBits:=0, "ptr", 0, "uint", 0, "ptr")
	obm := DllCall("SelectObject", "ptr", hdc, "ptr", hbm, "ptr")

	; Print the window onto the hBitmap using an undocumented flag. https://stackoverflow.com/a/40042587
	DllCall("PrintWindow", "ptr", image, "ptr", hdc, "uint", 0x3) ; PW_CLIENTONLY | PW_RENDERFULLCONTENT
	; Additional info on how this is implemented: https://www.reddit.com/r/windows/comments/8ffr56/altprintscreen/

	; Convert the hBitmap to a Bitmap using a built in function as there is no transparency.
	DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", pBitmap:=0)

	; Cleanup the hBitmap and device contexts.
	DllCall("SelectObject", "ptr", hdc, "ptr", obm)
	DllCall("DeleteObject", "ptr", hbm)
	DllCall("DeleteDC",	 "ptr", hdc)

	return pBitmap
}

~+F5::Reload
~+F6::Pause
~+F7::ExitApp
~+F8::ToggleStatusMessages()

ToggleStatusMessages() {
	if(showStatus)
		showStatus := False
	else
		showStatus := True
}

bboxAndPause(X1, Y1, X2, Y2, doPause := False) {
	BoxWidth := X2-X1
	BoxHeight := Y2-Y1
	; Create a GUI
	Gui, BoundingBox:+AlwaysOnTop +ToolWindow -Caption +E0x20
	Gui, BoundingBox:Color, 123456
	Gui, BoundingBox:+LastFound  ; Make the GUI window the last found window for use by the line below. (straght from documentation)
	WinSet, TransColor, 123456 ; Makes that specific color transparent in the gui

	; Create the borders and show
	Gui, BoundingBox:Add, Progress, x0 y0 w%BoxWidth% h2 BackgroundRed
	Gui, BoundingBox:Add, Progress, x0 y0 w2 h%BoxHeight% BackgroundRed
	Gui, BoundingBox:Add, Progress, x%BoxWidth% y0 w2 h%BoxHeight% BackgroundRed
	Gui, BoundingBox:Add, Progress, x0 y%BoxHeight% w%BoxWidth% h2 BackgroundRed
	Gui, BoundingBox:Show, x%X1% y%Y1% NoActivate
	Sleep, 100

	if (doPause) {
		Pause
	}

	if GetKeyState("F4", "P") {
		Pause
	}

	Gui, BoundingBox:Destroy
}

; Function to initialize ADB Shell
initializeAdbShell() {
	global adbShell, adbPath, adbPort
	RetryCount := 0
	MaxRetries := 10
	BackoffTime := 1000  ; Initial backoff time in milliseconds

	Loop {
		try {
			if (!adbShell) {
				; Validate adbPath and adbPort
				if (!FileExist(adbPath)) {
					throw "ADB path is invalid."
				}
				if (adbPort < 0 || adbPort > 65535)
					throw "ADB port is invalid."

				adbShell := ComObjCreate("WScript.Shell").Exec(adbPath . " -s 127.0.0.1:" . adbPort . " shell")

				adbShell.StdIn.WriteLine("su")
			} else if (adbShell.Status != 0) {
				Sleep, BackoffTime
				BackoffTime += 1000 ; Increase the backoff time
			} else {
				break
			}
		} catch e {
			RetryCount++
			if (RetryCount > MaxRetries) {
				CreateStatusMessage("Failed to connect to shell: " . e.message)
				LogToFile("Failed to connect to shell: " . e.message)
				Pause
			}
		}
		Sleep, BackoffTime
	}
}

ConnectAdb() {
	global adbPath, adbPort, StatusText
	MaxRetries := 5
	RetryCount := 0
	connected := false
	ip := "127.0.0.1:" . adbPort ; Specify the connection IP:port

	CreateStatusMessage("Connecting to ADB...")

	Loop %MaxRetries% {
		; Attempt to connect using CmdRet
		connectionResult := CmdRet(adbPath . " connect " . ip)

		; Check for successful connection in the output
		if InStr(connectionResult, "connected to " . ip) {
			connected := true
			CreateStatusMessage("ADB connected successfully.")
			return true
		} else {
			RetryCount++
			CreateStatusMessage("ADB connection failed. Retrying (" . RetryCount . "/" . MaxRetries . ").")
			Sleep, 2000
		}
	}

	if !connected {
		CreateStatusMessage("Failed to connect to ADB after multiple retries. Please check your emulator and port settings.")
		Reload
	}
}

CmdRet(sCmd, callBackFuncObj := "", encoding := "") {
	static HANDLE_FLAG_INHERIT := 0x00000001, flags := HANDLE_FLAG_INHERIT
		, STARTF_USESTDHANDLES := 0x100, CREATE_NO_WINDOW := 0x08000000

   (encoding = "" && encoding := "cp" . DllCall("GetOEMCP", "UInt"))
   DllCall("CreatePipe", "PtrP", hPipeRead, "PtrP", hPipeWrite, "Ptr", 0, "UInt", 0)
   DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", flags, "UInt", HANDLE_FLAG_INHERIT)

   VarSetCapacity(STARTUPINFO , siSize :=    A_PtrSize*4 + 4*8 + A_PtrSize*5, 0)
   NumPut(siSize              , STARTUPINFO)
   NumPut(STARTF_USESTDHANDLES, STARTUPINFO, A_PtrSize*4 + 4*7)
   NumPut(hPipeWrite          , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*3)
   NumPut(hPipeWrite          , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*4)

   VarSetCapacity(PROCESS_INFORMATION, A_PtrSize*2 + 4*2, 0)

   if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW
                              , "Ptr", 0, "Ptr", 0, "Ptr", &STARTUPINFO, "Ptr", &PROCESS_INFORMATION)
   {
      DllCall("CloseHandle", "Ptr", hPipeRead)
      DllCall("CloseHandle", "Ptr", hPipeWrite)
      throw "CreateProcess is failed"
   }
   DllCall("CloseHandle", "Ptr", hPipeWrite)
   VarSetCapacity(sTemp, 4096), nSize := 0
   while DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", &sTemp, "UInt", 4096, "UIntP", nSize, "UInt", 0) {
      sOutput .= stdOut := StrGet(&sTemp, nSize, encoding)
      ( callBackFuncObj && callBackFuncObj.Call(stdOut) )
   }
   DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION))
   DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize))
   DllCall("CloseHandle", "Ptr", hPipeRead)
   Return sOutput
}

GetNeedle(Path) {
	static NeedleBitmaps := Object()
	if (NeedleBitmaps.HasKey(Path)) {
		return NeedleBitmaps[Path]
	} else {
		pNeedle := Gdip_CreateBitmapFromFile(Path)
		NeedleBitmaps[Path] := pNeedle
		return pNeedle
	}
}

findAdbPorts(baseFolder := "C:\Program Files\Netease") {
	global adbPorts, winTitle, scriptName
	; Initialize variables
	adbPorts := 0  ; Create an empty associative array for adbPorts
	mumuFolder = %baseFolder%\MuMuPlayerGlobal-12.0\vms\*
	if !FileExist(mumuFolder)
		mumuFolder = %baseFolder%\MuMu Player 12\vms\*

	if !FileExist(mumuFolder){
		MsgBox, 16, , Double check your folder path! It should be the one that contains the MuMuPlayer 12 folder! `nDefault is just C:\Program Files\Netease
		ExitApp
	}
	; Loop through all directories in the base folder
	Loop, Files, %mumuFolder%, D  ; D flag to include directories only
	{
		folder := A_LoopFileFullPath
		configFolder := folder "\configs"  ; The config folder inside each directory

		; Check if config folder exists
		IfExist, %configFolder%
		{
			; Define paths to vm_config.json and extra_config.json
			vmConfigFile := configFolder "\vm_config.json"
			extraConfigFile := configFolder "\extra_config.json"

			; Check if vm_config.json exists and read adb host port
			IfExist, %vmConfigFile%
			{
				FileRead, vmConfigContent, %vmConfigFile%
				; Parse the JSON for adb host port
				RegExMatch(vmConfigContent, """host_port"":\s*""(\d+)""", adbHostPort)
				adbPort := adbHostPort1  ; Capture the adb host port value
			}

			; Check if extra_config.json exists and read playerName
			IfExist, %extraConfigFile%
			{
				FileRead, extraConfigContent, %extraConfigFile%
				; Parse the JSON for playerName
				RegExMatch(extraConfigContent, """playerName"":\s*""(.*?)""", playerName)
				if(playerName1 = scriptName) {
					return adbPort
				}
			}
		}
	}
}

MonthToDays(year, month) {
    static DaysInMonths := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days := 0
    Loop, % month - 1 {
        days += DaysInMonths[A_Index]
    }
    if (month > 2 && IsLeapYear(year))
        days += 1
    return days
}

IsLeapYear(year) {
    return (Mod(year, 4) = 0 && Mod(year, 100) != 0) || Mod(year, 400) = 0
}

; ^e::
; msgbox ss
; pToken := Gdip_Startup()
; Screenshot()
; return
