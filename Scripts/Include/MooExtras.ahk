; MooExtras standard library v0.07 by Wolfeh 02/26/25

global bDEBUG := 1
global needleDir := NeedleDIRCheck()
global pokedexFilePath := PokedexFileCheck()

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

        ; Story K/V in dictionary
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
    global winTitle, needleDir, bDEBUG
    hwnd := GetHWND()
    needleFiles := []
    iNeedleCoords := [0, 0, 20, 3]

    ; Load needle images
    Loop, %needleDir%*.png
        needleFiles.Push(A_LoopFileFullPath)
    iTotalNeedles := needleFiles.Length()
    If (iTotalNeedles < 1) {
        MsgBox, 0, Error - IdentifyCardInSlot, No needle files found! `n Total Needle Files In %needleDIR%: %iTotalNeedles%
    }

    ; Load search block
    pSearchBlock := GetSearchBlock(iCardSlot)
    if !pSearchBlock {
        MsgBox, 0, Error - IdentifyCardInSlot, Failed to load pSearchBlock for card slot %iCardSlot%
        return
    } else {
        ; Gdip_SaveBitmapToFile(pSearchBlock, "C:\Users\Wolfeh\Downloads\pSearchBlock.png")
        ; MsgBox, Extracted pSearchBlock
    }
    
    ; Loop through each needle and compare vs current card slot
    for index, needlePath in needleFiles {
                
        ; Load the current composite needle
        pCompositeNeedle := Gdip_CreateBitmapFromFile(needlePath)
        if !pCompositeNeedle {
            sNeedleName := GetFileNameWithoutExtension(needlePath)
            MsgBox, 0, Error - IdentifyCardInSlot, Failed to load pCompositeNeedle for %sNeedleName%
            continue
        }
            
        ; Extract needle block from the composite needle
        iNeedleCoords[1] := (iCardSlot - 1) * 20
        pNeedleBlock := Gdip_CloneBitmapArea(pCompositeNeedle, iNeedleCoords[1], iNeedleCoords[2], iNeedleCoords[3], iNeedleCoords[4])
        ; sNeedleName := GetFileNameWithoutExtension(needlePath)
        ; Gdip_SaveBitmapToFile(pNeedleBlock, "C:\Users\Wolfeh\Downloads\Temp\" . sNeedleName . ".png")

        ; Compare search block with needle block
        if CompareBlocks(pSearchBlock, pNeedleBlock) {
            Gdip_DisposeImage(pCompositeNeedle)
            Gdip_DisposeImage(pNeedleBlock)
            return GetFileNameWithoutExtension(needlePath)
            break
        } else {
            Gdip_DisposeImage(pCompositeNeedle)
            Gdip_DisposeImage(pNeedleBlock)
        }
    }

    ; No matching card found, prompt or skip
    If (bDEBUG = 1) {
        ; If no matching needle found, then prompt user for card name
        sCardName := CardInputBox(iCardSlot)
        if (sCardName = "") {
            MsgBox, No card name entered. Skipping card %iCardSlot%.
            return "Unknown"
        }

        ; Extract the needle if Unknown, or update existing needle
        ExtractNeedle(sCardName, iCardSlot)

        ; Return newly added card
        return sCardName
    }

    MsgBox, 0, Warning - IdentifyCardInSlot, No matching card found for card slot %iCardSlot%
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
; Function:     			NeedleDIRCheck
; Description:  			Checks if the needle directory exists, if it doesn't, it
;                           creates it.
;
; return      				Full file path to the Needles directory
;
; notes						                       
;
NeedleDIRCheck() {
    needleDir := A_ScriptDir . "\Pokedex\Needles\"
    ; Ensure the Needles directory exists
    if !FileExist(needleDir) {
        FileCreateDir, %needleDir%
        Sleep, 100
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
    pokedexFilePath := A_ScriptDir . "\Pokedex\Pokedex.csv"
    if !FileExist(pokedexFilePath)
        CreatePokedex()
    return %pokedexFilePath%
}