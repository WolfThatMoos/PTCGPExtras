#Include %A_ScriptDir%\GoogleSheets.ahk
#SingleInstance on

Gui, Add, Text,, Card:
Gui, Add, Edit, vCardInput w200,
Gui, Add, Text,, Slot:
Gui, Add, DropDownList, vSlotInput w200, 1|2|3|4|5
Gui, Add, Button, gCheckClick w200, Check

Gui, Show,, Fingerprint Check
Return

CheckClick:
    Gui, Submit, NoHide

    cardValue := CardInput
    slotValue := SlotInput

    if (!cardValue || !slotValue) {
        MsgBox % "Enter a card name and select a slot number."
        Return
    }

    needleCollected := isNeedleCollected(cardValue, slotValue)

    switch needleCollected {
        case -1:
            MsgBox % "No fingerprints for card " . cardValue . " have been collected yet."
        case 0:
            MsgBox % "Slot " . slotValue . " fingerprint for " . cardValue . " has not been collected."
        case 1:
            MsgBox % "Slot " . slotValue . " fingerprint for " . cardValue . " has already been collected."
        default:
            MsgBox % "Hmm... Not sure. Probably an error?"
    }
Return

GuiClose:
    Gui, Destroy
    ExitApp
Return
