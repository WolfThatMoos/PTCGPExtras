global needleDir := NeedleDIRCheck()
global pokedexFilePath := PokedexFileCheck()

; #############################################################################################
; PACK MANAGER | PACK OBJECT
; #############################################################################################
;
InitializePackManager() {
    global PackManager := {}

    ; Initialize packs
    PackManager["Charizard"] := CreatePack("Charizard", { "PackPrefix": "GAC",  "SetName": "Genetic Apex",         "SetCode": "A1" , "PackCardCount": 126, "PackCoords": [160, 407] })
    PackManager["MewTwo"]    := CreatePack("MewTwo",    { "PackPrefix": "GAM",  "SetName": "Genetic Apex",         "SetCode": "A1" , "PackCardCount": 125, "PackCoords": [200, 407] })
    PackManager["Pikachu"]   := CreatePack("Pikachu",   { "PackPrefix": "GAP",  "SetName": "Genetic Apex",         "SetCode": "A1" , "PackCardCount": 126, "PackCoords": [240, 407] })
    PackManager["Mew"]       := CreatePack("Mew",       { "PackPrefix": "MI",   "SetName": "Mythical Island",      "SetCode": "A1a", "PackCardCount": 86 , "PackCoords": [72, 407]  })
    PackManager["Dialga"]    := CreatePack("Dialga",    { "PackPrefix": "STSD", "SetName": "Space Time Smackdown", "SetCode": "A2" , "PackCardCount": 126, "PackCoords": [180, 272] })
    PackManager["Palkia"]    := CreatePack("Palkia",    { "PackPrefix": "STSP", "SetName": "Space Time Smackdown", "SetCode": "A2" , "PackCardCount": 126, "PackCoords": [221, 272] })
    PackManager["Arceus"]    := CreatePack("Arceus",    { "PackPrefix": "TLA",  "SetName": "Triumphant Light",     "SetCode": "A2a", "PackCardCount": 96 , "PackCoords": [72, 272]  })
}
; Function to create Pack objects
CreatePack(packName, packData) {
    pack := Object()
    pack.name := packName
    for key, value in packData
        pack[key] := value 

    ; Define methods
    pack.getCardCount  := Func("getCardCount").Bind(pack)
    pack.getPackCoords := Func("getPackCoords").Bind(pack)
    pack.getSetName    := Func("getSetName").Bind(pack)
    pack.getPackPrefix := Func("getPackPrefix").Bind(pack)
    pack.getSetCode    := Func("getSetCode").Bind(pack)

    return pack
}
; Methods for each Pack object
getCardCount(this) {
    return this.PackCardCount
}
getPackCoords(this) {
    return this.PackCoords
}
getSetName(this) {
    return this.SetName
}
getPackPrefix(this) {
    return this.PackPrefix
}
getSetCode(this) {
    return this.SetCode
}
; Methods for Pack Manager object
GetPackList(sReturnType := "Dropdown") {
	global PackManager

	switch sReturnType
	{
		case "Dropdown":
			sPacksList := ""
			for packName, _ in PackManager
				sPacksList .= packName "|"
			StringTrimRight, sPacksList, sPacksList, 1
			return sPacksList
		case "Array":
			packs := []
			for packName, _ in PackManager
				packs.Push(packName)
			return packs
	}
}
GetPackIndex(packName) {
    global PackManager
    index := 1
    for key, _ in PackManager {
        if (key = packName)
            return index
        index++
    }
    return -1  ; Not found
}
GetSetNameList() {
    global PackManager
    setNames := []
    for _, pack in PackManager {
        if !(pack.SetName in setNames)
            setNames.Push(pack.SetName)
    }
    return setNames
}
GetPackPrefixList() {
    global PackManager
    prefixes := []
    for _, pack in PackManager {
        prefixes.Push(pack.PackPrefix)
    }
    return prefixes
}
GetSetCodeList() {
    global PackManager
    setCodes := []
    for _, pack in PackManager {
        setCodes.Push(pack.SetCode)
    }
    return setCodes
}
GetPackCardCountList() {
    global PackManager
    cardCounts := []
    for _, pack in PackManager {
        cardCounts.Push(pack.PackCardCount)
    }
    return cardCounts
}

;#####################################################################################
; FUNCTIONS
;#####################################################################################
;
; CardInputBox()
; CompareBlocks()
; CreateBaseNeedle()
; CreatePokedex()
; ExtractNeedle()
; GetDefaultCardPoints()
; GetFileNameWithExtension()
; GetFileNameWithoutExtension()
; GetHWND()
; GetPackPoints(aPack)
; GetSearchBlock()
; IdentifyCards()
; IdentifyCardInSlot()
; isCardLoaded() <-- I can't bring myself to capitalize is. Sorry.
; LoadSettings()
; NeedleDIRCheck()
; PokedexFileCheck()
;
;#####################################################################################

; Function:     			CardInputBox
; Description:  		    Alerts user and prompts them with an interface to accept
;                           a user-input name for a specified card
;
; iCardSlot                 The card slot of the card needing to be identified/named
;
; return      				True if the card has loaded, false if cards are still being
;                           rendered
;
; notes					    My first attempt at anything GUI related. Don't hate lol          
;
CardInputBox(iCardSlot) {
    global winTitle
    hwnd := GetHWND()
    static CardName := ""

    ; Play a sound effect to alert the user that the input box is showing
    SoundPlay, %A_WinDir%\Media\notify.wav

    ; Capture screenshot of bot instance
    pInstanceSS := Gdip_BitmapFromHWND(hwnd)
    if !pInstanceSS {
        MsgBox, Error: Failed to screenshot instance %winTitle%!
        return
    } else {
        ; Gdip_SaveBitmapToFile(pInstanceSS, "C:\Users\Administrator\Downloads\PTCGPB\Playground\pInstanceSS.png")
    }

    ; pCardImage extraction coords
    aCardSlotCoords := [[20, 181, 76, 105], [103, 181, 76, 105], [186, 181, 76, 105], [61, 296, 76, 105], [146, 296, 76, 105]]
    iCardSlotStartX := aCardSlotCoords[iCardSlot][1]
    iCardSlotStartY := aCardSlotCoords[iCardSlot][2]
    iCardSlotEndX   := aCardSlotCoords[iCardSlot][3]
    iCardSlotEndY   := aCardSlotCoords[iCardSlot][4]

    ; Extract pCardImage from bot instance screenshot
    pCardImage := Gdip_CloneBitmapArea(pInstanceSS, iCardSlotStartX, iCardSlotStartY, iCardSlotEndX, iCardSlotEndY)
    if !pCardImage {
        MsgBox, Error: Failed to load the card image.
        ExitApp
    } else {
        ; Gdip_SaveBitmapToFile(pCardImage, "C:\Users\Administrator\Downloads\PTCGPB\Playground\pCardImage.png")
    }

    ; Dispose of the instance screenshot (we don't need it anymore)
    Gdip_DisposeImage(pInstanceSS)

    ; GUI Creation
    sGUITitle := "IdentifyCard: Instance " . winTitle . " - Card slot " . iCardSlot
    Gui, New, +AlwaysOnTop +HwndhMyGui
    Gui, Add, Picture, xm+16 ym+26 w180 h240 hwndhImg
    Gui, Font, S12 CDefault, Verdana
    Gui, Add, Text, xm+184 ym+64 w250 h30, Name of this card:
    Gui, Add, Edit, xm+184 ym+90 w250 vCardName
    Gui, Add, Button, Default xm+184 ym+160 w100 gSubmit, OK
    Gui, Add, Button, xm+300 ym+160 w100 gCancel, Cancel
    Gui, Show, w480 h260, %sGUITitle%

    ; Inject card image into GUI
    hdc := DllCall("GetDC", "Ptr", hImg, "Ptr") ; Get device context for the Picture control
    pGraphics := Gdip_GraphicsFromHDC(hdc) ; Create GDI+ Graphics object
    Gdip_DrawImage(pGraphics, pCardImage, 0, 0, 180, 240) ; Draw the image onto the GUI at (0,0)

    ; Release and cleanup
    DllCall("ReleaseDC", "Ptr", hImg, "Ptr", hdc)
    Gdip_DeleteGraphics(pGraphics)

    ; Wait for user input
    WinWaitClose, ahk_id %hMyGui%
    Gdip_DisposeImage(pCardImage)
    return CardName

    Submit:
        Gui, Submit, NoHide
        CardName := CardName  ; Store the input value
        Gui, Destroy
        Gdip_DisposeImage(pCardImage)
        return

    Cancel:
        CardName := ""  ; Clear value if canceled
        Gui, Destroy
        Gdip_DisposeImage(pCardImage)
        return
}

;#####################################################################################

; Function:     			CompareBlocks
; Description:  			Performs a triple check comparison of two pixel blocks to
;                           ensure they are identical. 
;                           Check 1: Same file size | dimensions
;                           Check 2: Lock Bits
;                           Check 3: Individual pixels
;
; pSearchBlock              Block of pixels from results screen of pack opening
;
; pNeedleBlock              Block of pixels from extracted needle
;
; return      				True if both blocks are identical, false if they are different
;
; notes						Locking/Unlocking might need delays depending on system.
;                           Needs testing.                         
;
CompareBlocks(pSearchBlock, pNeedleBlock) {
    w1 := Gdip_GetImageWidth(pSearchBlock), h1 := Gdip_GetImageHeight(pSearchBlock)
    w2 := Gdip_GetImageWidth(pNeedleBlock), h2 := Gdip_GetImageHeight(pNeedleBlock)

    ; Ensure both bitmaps have the same dimensions
    if (w1 != w2 || h1 != h2) {
        return false
    }

    ; Lock bits for both bitmaps. This dumps the pixel block into memory to directly access the raw pixel values (faster than looping Gdip_GetPixel())
    Stride1 := 0, Scan01 := 0, BitmapData1 := 0
    Stride2 := 0, Scan02 := 0, BitmapData2 := 0

    if (Gdip_LockBits(pSearchBlock, 0, 0, w1, h1, Stride1, Scan01, BitmapData1, 3, 0x26200a)) {
        return false
    }
    if (Gdip_LockBits(pNeedleBlock, 0, 0, w2, h2, Stride2, Scan02, BitmapData2, 3, 0x26200a)) {
        Gdip_UnlockBits(pSearchBlock, BitmapData1)
        return false
    }

    if (Stride1 != Stride2) {
        Gdip_UnlockBits(pSearchBlock, BitmapData1)
        Gdip_UnlockBits(pNeedleBlock, BitmapData2)
        return false
    }

    ; Loop through each pixel and compare ARGB values
    iPixelCount := 0
    Loop, % h1 {
        yOffset := (A_Index - 1) * Stride1
        Loop, % w1 {
            index := yOffset + (A_Index - 1) * 4  ; Each pixel is 4 bytes (ARGB)
            color1 := NumGet(Scan01 + index, 0, "UInt")
            color2 := NumGet(Scan02 + index, 0, "UInt")

            ; Check: If pixels don't match, return false
            a1 := (color1 >> 24) & 0xFF, r1 := (color1 >> 16) & 0xFF, g1 := (color1 >> 8) & 0xFF, b1 := color1 & 0xFF
            a2 := (color2 >> 24) & 0xFF, r2 := (color2 >> 16) & 0xFF, g2 := (color2 >> 8) & 0xFF, b2 := color2 & 0xFF

            if (Abs(r1 - r2) > 10 || Abs(g1 - g2) > 10 || Abs(b1 - b2) > 10) {
                iPixelCount++
                if (((iPixelCount / (w1 * h1)) * 100) > 15) {
                    Gdip_UnlockBits(pSearchBlock, BitmapData1)
                    Gdip_UnlockBits(pNeedleBlock, BitmapData2)
                    return false
                }
            }
        }
    }

    ; Clean up and return match
    Gdip_UnlockBits(pSearchBlock, BitmapData1)
    Gdip_UnlockBits(pNeedleBlock, BitmapData2)
    return true
}

;#####################################################################################

; Function:     			CreateBaseNeedle
; Description:  			Creates a blank needle image (100x3 pixels) to act as a 
;                           composite image, which will later hold the stitched individual
;                           needle blocks.
;
; needlePath                Full path derived from a card name, including it's extension
;
; return      				No return. Maybe will return filepath to base in the future?
;
; notes						needlePath is intended to be created and called by extractNeedle
;                           based on a given card name to serve as the base of the composite
;
;                           Currently only supports non-alpha .png bitmap files                        
;
CreateBaseNeedle(needlePath) {
    ; Create a blank 100x3 pixel image
    pBaseNeedle := Gdip_CreateBitmap(100, 3)

    ; Create a graphics object
    gBaseNeedle := Gdip_GraphicsFromImage(pBaseNeedle)

    ; Save as blank needle
    Gdip_SaveBitmapToFile(pBaseNeedle, needlePath)

    ; Cleanup
    Gdip_DeleteGraphics(gBaseNeedle)
    Gdip_DisposeImage(pBaseNeedle)
}

;#####################################################################################

; Function:     			CreatePokedex
; Description:  			Creates a csv file based on all card names loaded from the
;                           needle images in the needles directory.
;                           Uses GetDefaultCardPoints() to add default point values to
;                           specified cards
;
; return      				No return
;
; notes					    Deletes existing Pokedex.csv files on call                   
;
CreatePokedex() {
    global needleDir, pokedexFilePath
    needleFiles := []

    ; Loop through all .png files in the needle directory and store full paths
    Loop, %needleDir%*.png
        needleFiles.Push(A_LoopFileFullPath)  
    If (needleFiles.Length() < 1) {
        MsgBox, 0, Error - CreatePokedex, No needles found in the needles directory!
        needleFiles.Push("")
    }

    ; Delete any existing pokedex to avoid appending
    FileDelete, %pokedexFilePath%  

    ; Loop through each card, identify it's default rarities, and update the Pokedex
    for index, filePath in needleFiles {
        needleName := GetFileNameWithoutExtension(filePath)
        cardPoints := GetDefaultCardPoints(needleName)

        ; Update pokedex
        lineToWrite := (cardPoints != 0) ? needleName . "," . cardPoints : needleName
        FileAppend, %lineToWrite%`n, %pokedexFilePath%
    }
}

;#####################################################################################

; Function:     			ExtractNeedle
; Description:  			Captures specific coordinates corresponding to a card slot,
;                           injects the extracted image into a stored base image 
;                           (or creates one if it doesn’t exist), and saves the updated
;                           composite image.
;
; sCardName                 Name of the card, which becomes the needle file name
;
; iCardSlot                 Represents one of the five card slots in a pack pull
;
; return      				No return
;
; notes						aCardSlotCoords is a hand-picked set of coordinates to create a
;                           fingerprint of the card, based on what I found most unique in
;                           trials of test cards.                          
;
ExtractNeedle(sCardName, iCardSlot) {
    global winTitle, needleDir
    hwnd := GetHWND()
    aCardSlotCoords := [[29, 227], [112, 227], [195, 227], [69, 342], [154, 342]]

    ; Validate iCardSlot parameter
    if (iCardSlot < 1 || iCardSlot > 5) {
        MsgBox, Error - Invalid card number! Must be between 1 and 5.
        return
    }

    ; pNewNeedle extraction coords
    iCardSlotX := aCardSlotCoords[iCardSlot][1]
    iCardSlotY := aCardSlotCoords[iCardSlot][2]
    iNewNeedleWidth := 20
    iNewNeedleHeight := 3

    ; pNewNeedle injection coords
    iNewNeedleInjectionX := (iCardSlot - 1) * 20  ; Slot 1 → 0px, Slot 2 → 20px, etc.
    iNewNeedleInjectionY := 0

    ; Ensure the base needle image exists
    needlePath := needleDir . sCardName . ".png"
    if !FileExist(needlePath)
        CreateBaseNeedle(needlePath)
    
    ; Capture screenshot of bot instance
    pInstanceSS := Gdip_BitmapFromHWND(hwnd)
    if !pInstanceSS {
        MsgBox, Error: Failed to screenshot instance %winTitle%!
        return
    }

    ; Extract pNewNeedle from bot instance screenshot
    pNewNeedle := Gdip_CloneBitmapArea(pInstanceSS, iCardSlotX, iCardSlotY, iNewNeedleWidth, iNewNeedleHeight)

    ; Prep pCompositeNeedle for injection
    pCompositeNeedle := Gdip_CreateBitmapFromFile(needlePath)
    gCompositeNeedle := Gdip_GraphicsFromImage(pCompositeNeedle)
    
    ; Inject pNewNeedle into pCompositeNeedle
    gdip_DrawImage(gCompositeNeedle, pNewNeedle, iNewNeedleInjectionX, iNewNeedleInjectionY, iNewNeedleWidth, iNewNeedleHeight)

    ; Save the updated needle
    tempPath := needlePath . ".tmp.png" ; Temporary file first to bypass file lock
    Gdip_SaveBitmapToFile(pCompositeNeedle, tempPath)

    ; Cleanup before file operations
    Gdip_DeleteGraphics(gCompositeNeedle)
    Gdip_DisposeImage(pCompositeNeedle)
    Sleep, 100  ; Delay to allow file unlock

    ; Delete original image
    Loop, 5 {  ; Retry up to 5 times in case of file lock
        FileDelete, %needlePath%
        if !FileExist(needlePath)  ; Check if deletion was successful
            break
        Sleep, 50
    }

    ; Rename temp file to original
    Loop, 5 {
        FileMove, %tempPath%, %needlePath%
        if FileExist(needlePath)  ; Check if renaming was successful
            break
        Sleep, 50
    }

    ; Clean up
    gdip_disposeImage(pInstanceSS)
    gdip_disposeImage(pNewNeedle)
    Gdip_DisposeImage(pCompositeNeedle)
    Gdip_DeleteGraphics(gCompositeNeedle)
    return
}

;#####################################################################################

; Function:     			GetDefaultCardPoints
; Description:  			Uses extracted card rarity strings from needle names to
;                           create default desirable values
;
; sCardName                 Card name without an extension
;
; return      				Default pack points value representing a specific rarity
;
; notes					    CrownRare/Immsersive values should be updated to be in sync
;                           with the settings file for SkipCrownRares/Immsersives
;
;                           Maybe should be a switch/select case instead? Don't know this
;                           language well enough. Will look into this later  
;
;                           Order matters!            
;
GetDefaultCardPoints(sCardName) {
    if InStr(sCardName, "CrownRare") || InStr(sCardName, "Immersive") {
        return -99  ; CrownRare / Immsersive
    } else if InStr(sCardName, "_RR_") {
        return 2  ; 2 Star Rainbow 
    } else if InStr(sCardName, "_2Star") {
        return 2  ; 2 Star
    } else if InStr(sCardName, "EX") {
        return 1  ; EX
    } else if InStr(sCardName, "_1Star") {
        return 1  ; 1 Star
    } else {
        return 0  ; Normal / Everything else
    }
}

;#####################################################################################

; Function:     			GetFileNameWithExtension
; Description:  			Extracts the name of a file from a file path, with the
;                           extension
;
; fullPath                  Path to file
;
; return      				File name (with extension)
;
; notes						                         
;
GetFileNameWithExtension(fullPath) {
    SplitPath, fullPath, nameNoExt
    return nameNoExt
}

;#####################################################################################

; Function:     			GetFileNameWithoutExtension
; Description:  			Extracts the name of a file from a file path, with no
;                           extension
;
; fullPath                  Path to file
;
; return      				File name (no extension)
;
; notes						                         
;
GetFileNameWithoutExtension(fullPath) {
    SplitPath, fullPath, nameNoExt, , extension, nameOnly
    return nameOnly
}

;#####################################################################################
;
; Function:     			GetHWND
; Description:  			Fetches a unique handle to a bot instance to be sure
;                           commands are sent to the correct instance.
;
; return      				A hex representation of the PID, unique to the instance
;
; notes						                       
;
GetHWND() {
    global winTitle
    ; Capture hardware ID of bot instance
    hwnd := WinExist(winTitle)
    if !hwnd {
        MsgBox, Error: Unable to fetch the hardware ID of bot instance %winTitle%
        return
    } else {
        return hwnd
    }
}

;#####################################################################################

; Function:     			GetPackPoints
; Description:  			Calculates the total point value of a given pack by reading
;                           predefined point values from a CSV-based Pokedex.
;                           It maps card names to their respective point values, and sums
;                           the points for the cards present in the pack. 
; 
; aPack        				An array of card names returned by IdentifyCards()
;
; return      				Total pack points value of all 5 cards summed.
;
; notes						Values that are empty are considered 0.
;							
GetPackPoints(aPack) {
    global needleDir, pokedexFilePath

    ; Loop through the pokedex and map card points
    cardPoints := {}
    Loop, Read, %pokedexFilePath% 
    {
        ; Filter out empty lines and extra spaces
        line := Trim(A_LoopReadLine)
        if (line = "") {
            continue
        }

        ; Split each line into cardName and cardValue
        parts := StrSplit(line, ",")
        cardName := Trim(parts[1])
        cardValue := (parts.Length() > 1) ? Trim(parts[2]) : "0"
        if (cardValue = "") {
            cardValue := "0"
        }

        ; Store K/V in dictionary
        cardPoints[cardName] := cardValue
    }

    ; Loop through the dictionary, and if there's a matching key, get it's matching value, and update totalPoints
    totalPoints := 0
    for index, card in aPack {
        if cardPoints.HasKey(card) {
            totalPoints += cardPoints[card]
        }
    }

    return totalPoints
}

;#####################################################################################
;
; Function:     			GetSearchBlock
; Description:  		    Extracts a finger print from a screenshot of the 
;                           current bot instance on a pack opening results screen to
;                           compare with. Has error handling to ensure cards are fully
;                           rendered before comparing.
;
; iCardSlot                 The card slot to extract for comparison
;
; return      				Fingerprint of card in specified card slot
;
; notes					    Checks if the card has loaded 3 times, otherwise errors
;                           Delay between retries is 200ms          
;
GetSearchBlock(iCardSlot) {
    global winTitle
    hwnd := GetHWND()
    iNeedleCoords := [0, 0, 20, 3]
    aCardSlotCoords := [[29, 227], [112, 227], [195, 227], [69, 342], [154, 342]]
    retryCount := 0

    Loop
    {
        ; Capture screenshot of bot instance
        pInstanceSS := Gdip_BitmapFromHWND(hwnd)
        if !pInstanceSS {
            MsgBox, 0, Error - GetSearchBlock, Failed to get screenshot for instance %winTitle%!`nHWND: %hwnd%
            return
        }

        ; Extract card slot search block from instance screenshot
        aCurrentCardSlotCoords := aCardSlotCoords[iCardSlot]
        pSearchBlock := Gdip_CloneBitmapArea(pInstanceSS, aCurrentCardSlotCoords[1], aCurrentCardSlotCoords[2], iNeedleCoords[3], iNeedleCoords[4])

        ; Dispose of the instance screenshot (we don't need it anymore)
        Gdip_DisposeImage(pInstanceSS)

        ; Check if the card has loaded
        if isCardLoaded(pSearchBlock)
            return pSearchBlock  ; Valid block, return it

        ; Dispose of failed search block before retrying
        Gdip_DisposeImage(pSearchBlock)

        ; Error out if too many retries
        retryCount++
        if (retryCount >= 3) {
            MsgBox, Error: Could not capture a valid card image after 3 attempts.
            return
        }
        Sleep, 200  ; Small delay before retrying
    }
    
}

;#####################################################################################
;
; Function:     			IdentifyCards
; Description:  			Wrapper tool to identify the card names of each card slot
;
; return      				An array of strings containing the identified card name of
;                           each card slot
;
; notes						Values that are empty are considered 0.
;
IdentifyCards() {
    iTotalCardSlots := 5
    matchedCards := []

    ; Loop through each card slot, identifying each card and save the matched card's name
    Loop, %iTotalCardSlots% {
        matchedCards.Push(IdentifyCardInSlot(A_Index))
    }

    return matchedCards
}

;#####################################################################################
;
; Function:     			IdentifyCardInSlot
; Description:  			Wrapper tool to identify the card names of each card slot
;
; iCardSlot                 Represents one of the five card slots in a pack pull
;
; return      				A string representing the identified card name of a given
;                           card slot
;
; notes						iNeedleCoords is the startX and startY of the composite needle
;                           20 is the width, and 3 is the height (in pixels) of the needle
;
;                           aCardSlotCoords is a hand-picked set of coordinates to create a
;                           fingerprint of the card, based on what I found most unique in
;                           trials of test cards.
;
IdentifyCardInSlot(iCardSlot) {
    global winTitle, needleDir, bFingerPrintMode, sPackToOpen, PackManager, iDiscordID
    hwnd := GetHWND()
    iNeedleCoords := [0, 0, 20, 3]
    
    ; Get the pack prefix
    if !PackManager.HasKey(sPackToOpen) {
        MsgBox, 0, Error - IdentifyCardInSlot, Pack %sPackToOpen% not found in PackManager.
        return "Unknown"
    }
    sPackPrefix := PackManager[sPackToOpen].getPackPrefix()
    sBasePrefix := SubStr(sPackPrefix, 1, StrLen(sPackPrefix) - 1) ; Extract base set prefix (removes last letter if applicable)
    
    ; Load relevant needle images
    needleFiles := []
    Loop, %needleDir%*.png
    {
        fileName := A_LoopFileName
        if (SubStr(fileName, 1, StrLen(sPackPrefix)) = sPackPrefix) || (SubStr(fileName, 1, StrLen(sBasePrefix)) = sBasePrefix) {
            needleFiles.Push(A_LoopFileFullPath)
        }
    }
    
    iTotalNeedles := needleFiles.Length()
    If (iTotalNeedles < 1) {
        MsgBox, 0, Error - IdentifyCardInSlot, No relevant needle files found for pack "%sPackToOpen%"! `n Pack Prefix: %sPackPrefix% `n Base Prefix: %sBasePrefix%
        return "Unknown"
    }
    
    ; Load search block
    pSearchBlock := GetSearchBlock(iCardSlot)
    if !pSearchBlock {
        MsgBox, 0, Error - IdentifyCardInSlot, Failed to load pSearchBlock for card slot %iCardSlot%
        return "Unknown"
    }
    
    ; Loop through filtered needles and compare
    for index, needlePath in needleFiles {
        pCompositeNeedle := Gdip_CreateBitmapFromFile(needlePath)
        if !pCompositeNeedle {
            sNeedleName := GetFileNameWithoutExtension(needlePath)
            MsgBox, 0, Error - IdentifyCardInSlot, Failed to load pCompositeNeedle for %sNeedleName%
            continue
        }
        
        ; Extract needle block
        iNeedleCoords[1] := (iCardSlot - 1) * 20
        pNeedleBlock := Gdip_CloneBitmapArea(pCompositeNeedle, iNeedleCoords[1], iNeedleCoords[2], iNeedleCoords[3], iNeedleCoords[4])
        
        ; Compare blocks
        if CompareBlocks(pSearchBlock, pNeedleBlock) {
            Gdip_DisposeImage(pCompositeNeedle)
            Gdip_DisposeImage(pNeedleBlock)
            return GetFileNameWithoutExtension(needlePath)
        }
        Gdip_DisposeImage(pCompositeNeedle)
        Gdip_DisposeImage(pNeedleBlock)
    }
    
    ; No match found
    If (bFingerPrintMode = 1) {
        LogToDiscord("New card to identify!", , iDiscordID)
        sCardName := CardInputBox(iCardSlot)
        if (sCardName = "") {
            MsgBox, No card name entered. Skipping card %iCardSlot%.
            return "Unknown"
        }
        ExtractNeedle(sCardName, iCardSlot)
        return sCardName
    }
    
    return "Unknown"
}

;#####################################################################################
;
; Function:     			isCardLoaded
; Description:  		    Ensures cards are fully rendered by checking know pixel
;                           values of unloaded card zones
;
; pImage                    Finger print from bot instance screenshot to compare to
;                           known pre-loaded pixels
;
; return      				True if the card has loaded, false if cards are still being
;                           rendered
;
; notes					    I've had great success using this method to 
;                           ensure the cards rendered, but I did have one 
;                           case that I can't repeat where it failed. 
;                           Might need a new method?           
;
isCardLoaded(pImage) {
    firstPixel := Gdip_GetPixel(pImage, 0, 0)

    ; Loop through the rest of the pixels to check for any variation
    Loop, 20 {
        x := A_Index - 1
        Loop, 3 {
            y := A_Index - 1
            if (Gdip_GetPixel(pImage, x, y) != firstPixel) {
                ; MsgBox, It's a match, not all pixels are the same
                return true  ; Found variation, meaning the card has loaded
            }
        }
    }
    ; MsgBox, It's not a match, all pixels are the same
    return false  ; All pixels are the same, meaning the card hasn't loaded yet
}

;#####################################################################################
;
; Function:     			LoadSettingsFile
; Description:  			Checks if a settings exists, if it does, this reads in all
;                           the user defined values. If it doesn't, it loads defaults
;
; return      				None. All values declared and initialized as globals.
;
; notes						                       
;
LoadSettingsFile() {
	global iMainID, bRunMain, iTotalInstances, iTotalColumns, sMuMuInstallPath, bSpeedMod
	global iMinPackVal, iThresholdVal, sPackToOpen, iNumPacksToOpen, bThreshold, bOnePackMode, bInjectionMode, bMenuDelete
	global iGeneralDelay, iSwipeSpeed, iAddMainDelay, iInstanceStartDelay
	global iDiscordID, sDiscordWebhookURL, iHeartBeatID, sHeartBeatWebhookURL, bHeartBeat
	global iDisplayProfile, iScale
	global bSkipAddingMain, bFingerprintMode, bTradeMode, bShowStatusWindow, bSelectPackPerInstance
	global bSkipLicense

    global sSettingsFilePath
    sSettingsFilePath := A_ScriptDir . "\Settings.ini"

    If (!FileExist(sSettingsFilePath)) {
        SetWorkingDir .
        sSettingsFilePath := A_WorkingDir . "\Settings.ini"
        
        If (!FileExist(A_WorkingDir . "\Settings.ini")) {
            SetWorkingDir ..
            sSettingsFilePath := A_WorkingDir . "\Settings.ini"

            If (!FileExist(A_WorkingDir . "\Settings.ini")) {
                MsgBox, Error - LoadSettingsFile, Could not find settings.ini file.`nPlease make sure to run PTCGPB first.
                ExitApp
            }
        }
        SetWorkingDir %A_ScriptDir%
    }
    
	; Instances
    IniRead, iMainID, %sSettingsFilePath%, Instances, iMainID
    IniRead, bRunMain, %sSettingsFilePath%, Instances, bRunMain, 0
    IniRead, iTotalInstances, %sSettingsFilePath%, Instances, iTotalInstances, 1
    IniRead, iTotalColumns, %sSettingsFilePath%, Instances, iTotalColumns, 5
    IniRead, sMuMuInstallPath, %sSettingsFilePath%, Instances, cMuMuInstallPath, C:\Program Files\Netease
    IniRead, bSpeedMod, %sSettingsFilePath%, Instances, bSpeedMod, 0
	; Packs
    IniRead, iMinPackVal, %sSettingsFilePath%, Packs, iMinPackVal, 5
    IniRead, iThresholdVal, %sSettingsFilePath%, Packs, iThresholdVal, 1.2
    IniRead, sPackToOpen, %sSettingsFilePath%, Packs, sPackToOpen, Palkia
    IniRead, iNumPacksToOpen, %sSettingsFilePath%, Packs, iNumPacksToOpen, 14
    IniRead, bThreshold, %sSettingsFilePath%, Packs, bThreshold, 0
    IniRead, bOnePackMode, %sSettingsFilePath%, Packs, bOnePackMode, 1
    IniRead, bInjectionMode, %sSettingsFilePath%, Packs, bInjectionMode, 0
    IniRead, bMenuDelete, %sSettingsFilePath%, Packs, bMenuDelete, 0
	; Timings
    IniRead, iGeneralDelay, %sSettingsFilePath%, Timings, iGeneralDelay, 250
    IniRead, iSwipeSpeed, %sSettingsFilePath%, Timings, iSwipeSpeed, 350
    IniRead, iAddMainDelay, %sSettingsFilePath%, Timings, iAddMainDelay, 5
    IniRead, iInstanceStartDelay, %sSettingsFilePath%, Timings, iInstanceStartDelay, 10
	; Discord
    IniRead, iDiscordID, %sSettingsFilePath%, Discord, iDiscordID
    IniRead, sDiscordWebhookURL, %sSettingsFilePath%, Discord, sDiscordWebhookURL
    IniRead, iHeartBeatID, %sSettingsFilePath%, Discord, iHeartBeatID
    IniRead, sHeartBeatWebhookURL, %sSettingsFilePath%, Discord, sHeartBeatWebhookURL
    IniRead, bHeartBeat, %sSettingsFilePath%, Discord, bHeartBeat, 0
	; Displays
    IniRead, iDisplayProfile, %sSettingsFilePath%, Displays, iDisplayProfile, 1
    IniRead, iScale, %sSettingsFilePath%, Displays, iScale, 1
	; Moo
    IniRead, bSkipAddingMain, %sSettingsFilePath%, Moo, bSkipAddingMain, 0
    IniRead, bFingerprintMode, %sSettingsFilePath%, Moo, bFingerprintMode, 0
    IniRead, bTradeMode, %sSettingsFilePath%, Moo, bTradeMode, 0
    IniRead, bShowStatusWindow, %sSettingsFilePath%, Moo, bShowStatusWindow, 0
	IniRead, bSelectPackPerInstance, %sSettingsFilePath%, Moo, bSelectPackPerInstance, 0
	; About
	IniRead, bSkipLicense, %sSettingsFilePath%, About, bSkipLicense, 1
}

;#####################################################################################
;
; Function:     			NeedleDIRCheck
; Description:  			Checks if the needle directory exists, if it doesn't, it
;                           creates it.
;
; return      				Full file path to the Needles directory
;
; notes						                       
;
NeedleDIRCheck() {
    global needleDir

    needleDir := A_ScriptDir . "\Scripts\Pokedex\Needles\"

    If (!FileExist(needleDir)) {
        SetWorkingDir .
        needleDir := A_WorkingDir . "\Scripts\Pokedex\Needles\"
        
        If (!FileExist(needleDir)) {
            SetWorkingDir ..
            needleDir := A_WorkingDir . "\Scripts\Pokedex\Needles\"

            If (!FileExist(needleDir)) {
                MsgBox, Error - NeedleDIRCheck, Could not find the needles directory.`nPlease make sure it's located in Scripts --> Pokedex
                ExitApp
            }
        }
        SetWorkingDir %A_ScriptDir%
    }
    return %needleDir%
}

;#####################################################################################
;
; Function:     			PokedexFileCheck
; Description:  			Checks if the Pokedex.csv file exists, if it doesn't, it
;                           calls another function to create it.
;
; return      				Full path to the Pokedex.csv file
;
; notes						                       
;
PokedexFileCheck() {
    global pokedexFilePath

    pokedexFilePath := A_ScriptDir . "\Scripts\Pokedex\Pokedex.csv"

    If (!FileExist(pokedexFilePath)) {
        SetWorkingDir .
        pokedexFilePath := A_WorkingDir . "\Scripts\Pokedex\Pokedex.csv"
        
        If (!FileExist(pokedexFilePath)) {
            SetWorkingDir ..
            pokedexFilePath := A_WorkingDir . "\Scripts\Pokedex\Pokedex.csv"

            If (!FileExist(pokedexFilePath)) {
                MsgBox, Error - PokedexFileCheck, Could not find the Pokedex.`nPlease make sure it's located in Scripts --> Pokedex
                ExitApp
            }
        }
        SetWorkingDir %A_ScriptDir%
    }
    return %pokedexFilePath%
}

; ======================================================================================================================
; Namespace:         ImageButton
; Function:          Create images and assign them to pushbuttons.
; Tested with:       AHK 1.1.14.03 (A32/U32/U64)
; Tested on:         Win 7 (x64)
; Change history:    1.4.00.00/2014-06-07/just me - fixed bug for button caption = "0", "000", etc.
;                    1.3.00.00/2014-02-28/just me - added support for ARGB colors
;                    1.2.00.00/2014-02-23/just me - added borders
;                    1.1.00.00/2013-12-26/just me - added rounded and bicolored buttons       
;                    1.0.00.00/2013-12-21/just me - initial release
; How to use:
;     1. Create a push button (e.g. "Gui, Add, Button, vMyButton hwndHwndButton, Caption") using the 'Hwnd' option
;        to get its HWND.
;     2. Call ImageButton.Create() passing two parameters:
;        HWND        -  Button's HWND.
;        Options*    -  variadic array containing up to 6 option arrays (see below).
;        ---------------------------------------------------------------------------------------------------------------
;        The index of each option object determines the corresponding button state on which the bitmap will be shown.
;        MSDN defines 6 states (http://msdn.microsoft.com/en-us/windows/bb775975):
;           PBS_NORMAL    = 1
;	         PBS_HOT       = 2
;	         PBS_PRESSED   = 3
;	         PBS_DISABLED  = 4
;	         PBS_DEFAULTED = 5
;	         PBS_STYLUSHOT = 6 <- used only on tablet computers (that's false for Windows Vista and 7, see below)
;        If you don't want the button to be 'animated' on themed GUIs, just pass one option object with index 1.
;        On Windows Vista and 7 themed bottons are 'animated' using the images of states 5 and 6 after clicked.
;        ---------------------------------------------------------------------------------------------------------------
;        Each option array may contain the following values:
;           Index Value
;           1     Mode        mandatory:
;                             0  -  unicolored or bitmap
;                             1  -  vertical bicolored
;                             2  -  horizontal bicolored
;                             3  -  vertical gradient
;                             4  -  horizontal gradient
;                             5  -  vertical gradient using StartColor at both borders and TargetColor at the center
;                             6  -  horizontal gradient using StartColor at both borders and TargetColor at the center
;                             7  -  'raised' style
;           2     StartColor  mandatory for Option[1], higher indices will inherit the value of Option[1], if omitted:
;                             -  ARGB integer value (0xAARRGGBB) or HTML color name ("Red").
;                             -  Path of an image file or HBITMAP handle for mode 0.
;           3     TargetColor mandatory for Option[1] if Mode > 0, ignored if Mode = 0. Higher indcices will inherit
;                             the color of Option[1], if omitted:
;                             -  ARGB integer value (0xAARRGGBB) or HTML color name ("Red").
;           4     TextColor   optional, if omitted, the default text color will be used for Option[1], higher indices 
;                             will inherit the color of Option[1]:
;                             -  ARGB integer value (0xAARRGGBB) or HTML color name ("Red").
;                                Default: 0xFF000000 (black)
;           5     Rounded     optional:
;                             -  Radius of the rounded corners in pixel; the letters 'H' and 'W' may be specified
;                                also to use the half of the button's height or width respectively.
;                                Default: 0 - not rounded
;           6     GuiColor    optional, needed for rounded buttons if you've changed the GUI background color:
;                             -  RGB integer value (0xRRGGBB) or HTML color name ("Red").
;                                Default: AHK default GUI background color
;           7     BorderColor optional, ignored for modes 0 (bitmap) and 7, color of the border:
;                             -  RGB integer value (0xRRGGBB) or HTML color name ("Red").
;           8     BorderWidth optional, ignored for modes 0 (bitmap) and 7, width of the border in pixels:
;                             -  Default: 1
;        ---------------------------------------------------------------------------------------------------------------
;        If the the button has a caption it will be drawn above the bitmap.
; Credits:           THX tic     for GDIP.AHK     : http://www.autohotkey.com/forum/post-198949.html
;                    THX tkoi    for ILBUTTON.AHK : http://www.autohotkey.com/forum/topic40468.html
; ======================================================================================================================
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from the use of this software.
; ======================================================================================================================
; ======================================================================================================================
; CLASS ImageButton()
; ======================================================================================================================
Class ImageButton {
    ; ===================================================================================================================
    ; PUBLIC PROPERTIES =================================================================================================
    ; ===================================================================================================================
    Static DefGuiColor  := ""        ; default GUI color                             (read/write)
    Static DefTxtColor := "Black"    ; default caption color                         (read/write)
    Static LastError := ""           ; will contain the last error message, if any   (readonly)
    ; ===================================================================================================================
    ; PRIVATE PROPERTIES ================================================================================================
    ; ===================================================================================================================
    Static BitMaps := []
    Static GDIPDll := 0
    Static GDIPToken := 0
    Static MaxOptions := 8
    ; HTML colors
    Static HTML := {BLACK: 0x000000, GRAY: 0x808080, SILVER: 0xC0C0C0, WHITE: 0xFFFFFF, MAROON: 0x800000
                  , PURPLE: 0x800080, FUCHSIA: 0xFF00FF, RED: 0xFF0000, GREEN: 0x008000, OLIVE: 0x808000
                  , YELLOW: 0xFFFF00, LIME: 0x00FF00, NAVY: 0x000080, TEAL: 0x008080, AQUA: 0x00FFFF, BLUE: 0x0000FF}
    ; Initialize
    Static ClassInit := ImageButton.InitClass()
    ; ===================================================================================================================
    ; PRIVATE METHODS ===================================================================================================
    ; ===================================================================================================================
    __New(P*) {
       Return False
    }
    ; ===================================================================================================================
    InitClass() {
       ; ----------------------------------------------------------------------------------------------------------------
       ; Get AHK's default GUI background color
       GuiColor := DllCall("User32.dll\GetSysColor", "Int", 15, "UInt") ; COLOR_3DFACE is used by AHK as default
       This.DefGuiColor := ((GuiColor >> 16) & 0xFF) | (GuiColor & 0x00FF00) | ((GuiColor & 0xFF) << 16)
       Return True
    }
    ; ===================================================================================================================
    GdiplusStartup() {
       This.GDIPDll := This.GDIPToken := 0
       If (This.GDIPDll := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "Ptr")) {
          VarSetCapacity(SI, 24, 0)
          Numput(1, SI, 0, "Int")
          If !DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", GDIPToken, "Ptr", &SI, "Ptr", 0)
             This.GDIPToken := GDIPToken
          Else
             This.GdiplusShutdown()
       }
       Return This.GDIPToken
    }
    ; ===================================================================================================================
    GdiplusShutdown() {
       If This.GDIPToken
          DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", This.GDIPToken)
       If This.GDIPDll
          DllCall("Kernel32.dll\FreeLibrary", "Ptr", This.GDIPDll)
       This.GDIPDll := This.GDIPToken := 0
    }
    ; ===================================================================================================================
    FreeBitmaps() {
       For I, HBITMAP In This.BitMaps
          DllCall("Gdi32.dll\DeleteObject", "Ptr", HBITMAP)
       This.BitMaps := []
    }
    ; ===================================================================================================================
    GetARGB(RGB) {
       ARGB := This.HTML.HasKey(RGB) ? This.HTML[RGB] : RGB
       Return (ARGB & 0xFF000000) = 0 ? 0xFF000000 | ARGB : ARGB
    }
    ; ===================================================================================================================
    PathAddRectangle(Path, X, Y, W, H) {
       Return DllCall("Gdiplus.dll\GdipAddPathRectangle", "Ptr", Path, "Float", X, "Float", Y, "Float", W, "Float", H)
    }
    ; ===================================================================================================================
    PathAddRoundedRect(Path, X1, Y1, X2, Y2, R) {
       D := (R * 2), X2 -= D, Y2 -= D
       DllCall("Gdiplus.dll\GdipAddPathArc"
             , "Ptr", Path, "Float", X1, "Float", Y1, "Float", D, "Float", D, "Float", 180, "Float", 90)
       DllCall("Gdiplus.dll\GdipAddPathArc"
             , "Ptr", Path, "Float", X2, "Float", Y1, "Float", D, "Float", D, "Float", 270, "Float", 90)
       DllCall("Gdiplus.dll\GdipAddPathArc"
             , "Ptr", Path, "Float", X2, "Float", Y2, "Float", D, "Float", D, "Float", 0, "Float", 90)
       DllCall("Gdiplus.dll\GdipAddPathArc"
             , "Ptr", Path, "Float", X1, "Float", Y2, "Float", D, "Float", D, "Float", 90, "Float", 90)
       Return DllCall("Gdiplus.dll\GdipClosePathFigure", "Ptr", Path)
    }
    ; ===================================================================================================================
    SetRect(ByRef Rect, X1, Y1, X2, Y2) {
       VarSetCapacity(Rect, 16, 0)
       NumPut(X1, Rect, 0, "Int"), NumPut(Y1, Rect, 4, "Int")
       NumPut(X2, Rect, 8, "Int"), NumPut(Y2, Rect, 12, "Int")
       Return True
    }
    ; ===================================================================================================================
    SetRectF(ByRef Rect, X, Y, W, H) {
       VarSetCapacity(Rect, 16, 0)
       NumPut(X, Rect, 0, "Float"), NumPut(Y, Rect, 4, "Float")
       NumPut(W, Rect, 8, "Float"), NumPut(H, Rect, 12, "Float")
       Return True
    }
    ; ===================================================================================================================
    SetError(Msg) {
       This.FreeBitmaps()
       This.GdiplusShutdown()
       This.LastError := Msg
       Return False
    }
    ; ===================================================================================================================
    ; PUBLIC METHODS ====================================================================================================
    ; ===================================================================================================================
    Create(HWND, Options*) {
       ; Windows constants
       Static BCM_SETIMAGELIST := 0x1602
            , BS_CHECKBOX := 0x02, BS_RADIOBUTTON := 0x04, BS_GROUPBOX := 0x07, BS_AUTORADIOBUTTON := 0x09
            , BS_LEFT := 0x0100, BS_RIGHT := 0x0200, BS_CENTER := 0x0300, BS_TOP := 0x0400, BS_BOTTOM := 0x0800
            , BS_VCENTER := 0x0C00, BS_BITMAP := 0x0080
            , BUTTON_IMAGELIST_ALIGN_LEFT := 0, BUTTON_IMAGELIST_ALIGN_RIGHT := 1, BUTTON_IMAGELIST_ALIGN_CENTER := 4
            , ILC_COLOR32 := 0x20
            , OBJ_BITMAP := 7
            , RCBUTTONS := BS_CHECKBOX | BS_RADIOBUTTON | BS_AUTORADIOBUTTON
            , SA_LEFT := 0x00, SA_CENTER := 0x01, SA_RIGHT := 0x02
            , WM_GETFONT := 0x31
       ; ----------------------------------------------------------------------------------------------------------------
       This.LastError := ""
       ; ----------------------------------------------------------------------------------------------------------------
       ; Check HWND
       If !DllCall("User32.dll\IsWindow", "Ptr", HWND)
          Return This.SetError("Invalid parameter HWND!")
       ; ----------------------------------------------------------------------------------------------------------------
       ; Check Options
       If !(IsObject(Options)) || (Options.MinIndex() <> 1) || (Options.MaxIndex() > This.MaxOptions)
          Return This.SetError("Invalid parameter Options!")
       ; ----------------------------------------------------------------------------------------------------------------
       ; Get and check control's class and styles
       WinGetClass, BtnClass, ahk_id %HWND%
       ControlGet, BtnStyle, Style, , , ahk_id %HWND%
       If (BtnClass != "Button") || ((BtnStyle & 0xF ^ BS_GROUPBOX) = 0) || ((BtnStyle & RCBUTTONS) > 1)
          Return This.SetError("The control must be a pushbutton!")
       ; ----------------------------------------------------------------------------------------------------------------
       ; Load GdiPlus
       If !This.GdiplusStartup()
          Return This.SetError("GDIPlus could not be started!")
       ; ----------------------------------------------------------------------------------------------------------------
       ; Get the button's font
       GDIPFont := 0
       HFONT := DllCall("User32.dll\SendMessage", "Ptr", HWND, "UInt", WM_GETFONT, "Ptr", 0, "Ptr", 0, "Ptr")
       DC := DllCall("User32.dll\GetDC", "Ptr", HWND, "Ptr")
       DllCall("Gdi32.dll\SelectObject", "Ptr", DC, "Ptr", HFONT)
       DllCall("Gdiplus.dll\GdipCreateFontFromDC", "Ptr", DC, "PtrP", PFONT)
       DllCall("User32.dll\ReleaseDC", "Ptr", HWND, "Ptr", DC)
       If !(PFONT)
          Return This.SetError("Couldn't get button's font!")
       ; ----------------------------------------------------------------------------------------------------------------
       ; Get the button's rectangle
       VarSetCapacity(RECT, 16, 0)
       If !DllCall("User32.dll\GetWindowRect", "Ptr", HWND, "Ptr", &RECT)
          Return This.SetError("Couldn't get button's rectangle!")
       BtnW := NumGet(RECT,  8, "Int") - NumGet(RECT, 0, "Int")
       BtnH := NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int")
       ; ----------------------------------------------------------------------------------------------------------------
       ; Get the button's caption
       ControlGetText, BtnCaption, , ahk_id %HWND%
       If (ErrorLevel)
          Return This.SetError("Couldn't get button's caption!")
       ; ----------------------------------------------------------------------------------------------------------------
       ; Create the bitmap(s)
       This.BitMaps := []
       For Index, Option In Options {
          If !IsObject(Option)
             Continue
          BkgColor1 := BkgColor2 := TxtColor := Mode := Rounded := GuiColor := Image := ""
          ; Replace omitted options with the values of Options.1
          Loop, % This.MaxOptions {
             If (Option[A_Index] = "")
                Option[A_Index] := Options.1[A_Index]
          }
          ; -------------------------------------------------------------------------------------------------------------
          ; Check option values
          ; Mode
          Mode := SubStr(Option.1, 1 ,1)
          If !InStr("0123456789", Mode)
             Return This.SetError("Invalid value for Mode in Options[" . Index . "]!")
          ; StartColor & TargetColor
          If (Mode = 0)
          && (FileExist(Option.2) || (DllCall("Gdi32.dll\GetObjectType", "Ptr", Option.2, "UInt") = OBJ_BITMAP))
             Image := Option.2
          Else {
             If !(Option.2 + 0) && !This.HTML.HasKey(Option.2)
                Return This.SetError("Invalid value for StartColor in Options[" . Index . "]!")
             BkgColor1 := This.GetARGB(Option.2)
             If (Option.3 = "")
                Option.3 := Option.2
             If !(Option.3 + 0) && !This.HTML.HasKey(Option.3)
                Return This.SetError("Invalid value for TargetColor in Options[" . Index . "]!")
             BkgColor2 := This.GetARGB(Option.3)
          }
          ; TextColor
          If (Option.4 = "")
             Option.4 := This.DefTxtColor
          If !(Option.4 + 0) && !This.HTML.HasKey(Option.4)
             Return This.SetError("Invalid value for TxtColor in Options[" . Index . "]!")
          TxtColor := This.GetARGB(Option.4)
          ; Rounded
          Rounded := Option.5
          If (Rounded = "H")
             Rounded := BtnH * 0.5
          If (Rounded = "W")
             Rounded := BtnW * 0.5
          If !(Rounded + 0)
             Rounded := 0
          ; GuiColor
          If (Option.6 = "")
             Option.6 := This.DefGuiColor
          If !(Option.6 + 0) && !This.HTML.HasKey(Option.6)
             Return This.SetError("Invalid value for GuiColor in Options[" . Index . "]!")
          GuiColor := This.GetARGB(Option.6)
          ; BorderColor
          BorderColor := ""
          If (Option.7 <> "") {
             If !(Option.7 + 0) && !This.HTML.HasKey(Option.7)
                Return This.SetError("Invalid value for BorderColor in Options[" . Index . "]!")
             BorderColor := 0xFF000000 | This.GetARGB(Option.7) ; BorderColor must be always opaque
          }
          ; BorderWidth
          BorderWidth := Option.8 ? Option.8 : 1
          ; -------------------------------------------------------------------------------------------------------------
          ; Create a GDI+ bitmap
          DllCall("Gdiplus.dll\GdipCreateBitmapFromScan0", "Int", BtnW, "Int", BtnH, "Int", 0
                , "UInt", 0x26200A, "Ptr", 0, "PtrP", PBITMAP)
          ; Get the pointer to its graphics
          DllCall("Gdiplus.dll\GdipGetImageGraphicsContext", "Ptr", PBITMAP, "PtrP", PGRAPHICS)
          ; Quality settings
          DllCall("Gdiplus.dll\GdipSetSmoothingMode", "Ptr", PGRAPHICS, "UInt", 4)
          DllCall("Gdiplus.dll\GdipSetInterpolationMode", "Ptr", PGRAPHICS, "Int", 7)
          DllCall("Gdiplus.dll\GdipSetCompositingQuality", "Ptr", PGRAPHICS, "UInt", 4)
          DllCall("Gdiplus.dll\GdipSetRenderingOrigin", "Ptr", PGRAPHICS, "Int", 0, "Int", 0)
          DllCall("Gdiplus.dll\GdipSetPixelOffsetMode", "Ptr", PGRAPHICS, "UInt", 4)
          ; Clear the background
          DllCall("Gdiplus.dll\GdipGraphicsClear", "Ptr", PGRAPHICS, "UInt", GuiColor)
          ; Create the image
          If (Image = "") { ; Create a BitMap based on the specified colors
             PathX := PathY := 0, PathW := BtnW, PathH := BtnH
             ; Create a GraphicsPath
             DllCall("Gdiplus.dll\GdipCreatePath", "UInt", 0, "PtrP", PPATH)
             If (Rounded < 1) ; the path is a rectangular rectangle
                This.PathAddRectangle(PPATH, PathX, PathY, PathW, PathH)
             Else ; the path is a rounded rectangle
                This.PathAddRoundedRect(PPATH, PathX, PathY, PathW, PathH, Rounded)
             ; If BorderColor and BorderWidth are specified, 'draw' the border (not for Mode 7)
             If (BorderColor <> "") && (BorderWidth > 0) && (Mode <> 7) {
                ; Create a SolidBrush
                DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", BorderColor, "PtrP", PBRUSH)
                ; Fill the path
                DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
                ; Free the brush
                DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
                ; Reset the path
                DllCall("Gdiplus.dll\GdipResetPath", "Ptr", PPATH)
                ; Add a new 'inner' path
                PathX := PathY := BorderWidth, PathW -= BorderWidth, PathH -= BorderWidth, Rounded -= BorderWidth
                If (Rounded < 1) ; the path is a rectangular rectangle
                   This.PathAddRectangle(PPATH, PathX, PathY, PathW - PathX, PathH - PathY)
                Else ; the path is a rounded rectangle
                   This.PathAddRoundedRect(PPATH, PathX, PathY, PathW, PathH, Rounded)
                ; If a BorderColor has been drawn, BkgColors must be opaque
                BkgColor1 := 0xFF000000 | BkgColor1
                BkgColor2 := 0xFF000000 | BkgColor2               
             }
             PathW -= PathX
             PathH -= PathY
             If (Mode = 0) { ; the background is unicolored
                ; Create a SolidBrush
                DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", BkgColor1, "PtrP", PBRUSH)
                ; Fill the path
                DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
             }
             Else If (Mode = 1) || (Mode = 2) { ; the background is bicolored
                ; Create a LineGradientBrush
                This.SetRectF(RECTF, PathX, PathY, PathW, PathH)
                DllCall("Gdiplus.dll\GdipCreateLineBrushFromRect", "Ptr", &RECTF
                      , "UInt", BkgColor1, "UInt", BkgColor2, "Int", Mode & 1, "Int", 3, "PtrP", PBRUSH)
                DllCall("Gdiplus.dll\GdipSetLineGammaCorrection", "Ptr", PBRUSH, "Int", 1)
                ; Set up colors and positions
                This.SetRect(COLORS, BkgColor1, BkgColor1, BkgColor2, BkgColor2) ; sorry for function misuse
                This.SetRectF(POSITIONS, 0, 0.5, 0.5, 1) ; sorry for function misuse
                DllCall("Gdiplus.dll\GdipSetLinePresetBlend", "Ptr", PBRUSH
                      , "Ptr", &COLORS, "Ptr", &POSITIONS, "Int", 4)
                ; Fill the path
                DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
             }
             Else If (Mode >= 3) && (Mode <= 6) { ; the background is a gradient
                ; Determine the brush's width/height
                W := Mode = 6 ? PathW / 2 : PathW  ; horizontal
                H := Mode = 5 ? PathH / 2 : PathH  ; vertical
                ; Create a LineGradientBrush
                This.SetRectF(RECTF, PathX, PathY, W, H)
                DllCall("Gdiplus.dll\GdipCreateLineBrushFromRect", "Ptr", &RECTF
                      , "UInt", BkgColor1, "UInt", BkgColor2, "Int", Mode & 1, "Int", 3, "PtrP", PBRUSH)
                DllCall("Gdiplus.dll\GdipSetLineGammaCorrection", "Ptr", PBRUSH, "Int", 1)
                ; Fill the path
                DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
             }
             Else { ; raised mode
                DllCall("Gdiplus.dll\GdipCreatePathGradientFromPath", "Ptr", PPATH, "PtrP", PBRUSH)
                ; Set Gamma Correction
                DllCall("Gdiplus.dll\GdipSetPathGradientGammaCorrection", "Ptr", PBRUSH, "UInt", 1)
                ; Set surround and center colors
                VarSetCapacity(ColorArray, 4, 0)
                NumPut(BkgColor1, ColorArray, 0, "UInt")
                DllCall("Gdiplus.dll\GdipSetPathGradientSurroundColorsWithCount", "Ptr", PBRUSH, "Ptr", &ColorArray
                    , "IntP", 1)
                DllCall("Gdiplus.dll\GdipSetPathGradientCenterColor", "Ptr", PBRUSH, "UInt", BkgColor2)
                ; Set the FocusScales
                FS := (BtnH < BtnW ? BtnH : BtnW) / 3
                XScale := (BtnW - FS) / BtnW
                YScale := (BtnH - FS) / BtnH
                DllCall("Gdiplus.dll\GdipSetPathGradientFocusScales", "Ptr", PBRUSH, "Float", XScale, "Float", YScale)
                ; Fill the path
                DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
             }
             ; Free resources
             DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
             DllCall("Gdiplus.dll\GdipDeletePath", "Ptr", PPATH)
          } Else { ; Create a bitmap from HBITMAP or file
             If (Image + 0)
                DllCall("Gdiplus.dll\GdipCreateBitmapFromHBITMAP", "Ptr", Image, "Ptr", 0, "PtrP", PBM)
             Else
                DllCall("Gdiplus.dll\GdipCreateBitmapFromFile", "WStr", Image, "PtrP", PBM)
             ; Draw the bitmap
             DllCall("Gdiplus.dll\GdipDrawImageRectI", "Ptr", PGRAPHICS, "Ptr", PBM, "Int", 0, "Int", 0
                   , "Int", BtnW, "Int", BtnH)
             ; Free the bitmap
             DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", PBM)
          }
          ; -------------------------------------------------------------------------------------------------------------
          ; Draw the caption
          If (BtnCaption <> "") {
             ; Create a StringFormat object
             DllCall("Gdiplus.dll\GdipStringFormatGetGenericTypographic", "PtrP", HFORMAT)
             ; Text color
             DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", TxtColor, "PtrP", PBRUSH)
             ; Horizontal alignment
             HALIGN := (BtnStyle & BS_CENTER) = BS_CENTER ? SA_CENTER
                     : (BtnStyle & BS_CENTER) = BS_RIGHT  ? SA_RIGHT
                     : (BtnStyle & BS_CENTER) = BS_Left   ? SA_LEFT
                     : SA_CENTER
             DllCall("Gdiplus.dll\GdipSetStringFormatAlign", "Ptr", HFORMAT, "Int", HALIGN)
             ; Vertical alignment
             VALIGN := (BtnStyle & BS_VCENTER) = BS_TOP ? 0
                     : (BtnStyle & BS_VCENTER) = BS_BOTTOM ? 2
                     : 1
             DllCall("Gdiplus.dll\GdipSetStringFormatLineAlign", "Ptr", HFORMAT, "Int", VALIGN)
             ; Set render quality to system default
             DllCall("Gdiplus.dll\GdipSetTextRenderingHint", "Ptr", PGRAPHICS, "Int", 0)
             ; Set the text's rectangle
             VarSetCapacity(RECT, 16, 0)
             NumPut(BtnW, RECT,  8, "Float")
             NumPut(BtnH, RECT, 12, "Float")
             ; Draw the text
             DllCall("Gdiplus.dll\GdipDrawString", "Ptr", PGRAPHICS, "WStr", BtnCaption, "Int", -1
                   , "Ptr", PFONT, "Ptr", &RECT, "Ptr", HFORMAT, "Ptr", PBRUSH)
          }
          ; -------------------------------------------------------------------------------------------------------------
          ; Create a HBITMAP handle from the bitmap and add it to the array
          DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "Ptr", PBITMAP, "PtrP", HBITMAP, "UInt", 0X00FFFFFF)
          This.BitMaps[Index] := HBITMAP
          ; Free resources
          DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", PBITMAP)
          DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
          DllCall("Gdiplus.dll\GdipDeleteStringFormat", "Ptr", HFORMAT)
          DllCall("Gdiplus.dll\GdipDeleteGraphics", "Ptr", PGRAPHICS)
          ; Add the bitmap to the array
       }
       ; Now free the font object
       DllCall("Gdiplus.dll\GdipDeleteFont", "Ptr", PFONT)
       ; ----------------------------------------------------------------------------------------------------------------
       ; Create the ImageList
       HIL := DllCall("Comctl32.dll\ImageList_Create"
                    , "UInt", BtnW, "UInt", BtnH, "UInt", ILC_COLOR32, "Int", 6, "Int", 0, "Ptr")
       Loop, % (This.BitMaps.MaxIndex() > 1 ? 6 : 1) {
          HBITMAP := This.BitMaps.HasKey(A_Index) ? This.BitMaps[A_Index] : This.BitMaps.1
          DllCall("Comctl32.dll\ImageList_Add", "Ptr", HIL, "Ptr", HBITMAP, "Ptr", 0)
       }
       ; Create a BUTTON_IMAGELIST structure
       VarSetCapacity(BIL, 20 + A_PtrSize, 0)
       NumPut(HIL, BIL, 0, "Ptr")
       Numput(BUTTON_IMAGELIST_ALIGN_CENTER, BIL, A_PtrSize + 16, "UInt")
       ; Hide buttons's caption
       ControlSetText, , , ahk_id %HWND%
       Control, Style, +%BS_BITMAP%, , ahk_id %HWND%
       ; Assign the ImageList to the button
       SendMessage, %BCM_SETIMAGELIST%, 0, 0, , ahk_id %HWND%
       SendMessage, %BCM_SETIMAGELIST%, 0, % &BIL, , ahk_id %HWND%
       ; Free the bitmaps
       This.FreeBitmaps()
       ; ----------------------------------------------------------------------------------------------------------------
       ; All done successfully
       This.GdiplusShutdown()
       Return True
    }
    ; ===================================================================================================================
    ; Set the default GUI color
    SetGuiColor(GuiColor) {
       ; GuiColor     -  RGB integer value (0xRRGGBB) or HTML color name ("Red").
       If !(GuiColor + 0) && !This.HTML.HasKey(GuiColor)
          Return False
       This.DefGuiColor := (This.HTML.HasKey(GuiColor) ? This.HTML[GuiColor] : GuiColor) & 0xFFFFFF
       Return True
    }
    ; ===================================================================================================================
    ; Set the default text color
    SetTxtColor(TxtColor) {
       ; TxtColor     -  RGB integer value (0xRRGGBB) or HTML color name ("Red").
       If !(TxtColor + 0) && !This.HTML.HasKey(TxtColor)
          Return False
       This.DefTxtColor := (This.HTML.HasKey(TxtColor) ? This.HTML[TxtColor] : TxtColor) & 0xFFFFFF
       Return True
    }
 }