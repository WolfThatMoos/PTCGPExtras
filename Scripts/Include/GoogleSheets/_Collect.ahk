#Include %A_ScriptDir%\GoogleSheets.ahk
#SingleInstance on

Gui, Add, Text,, Card:
Gui, Add, Edit, vCardInput w200,
Gui, Add, Text,, Slot:
Gui, Add, DropDownList, vSlotInput w200, 1|2|3|4|5
Gui, Add, Button, gCheckClick w200, Store

Gui, Show,, Collect Fingerprint
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
            result := markNeedleCollected(cardValue, slotValue, needleCollected)

            if (result)
                MsgBox % "Card " . cardValue . " added to spreadsheet and slot " . slotValue . " marked as collected."
            else
                MsgBox % "Hmm... Something has gone wrong."
        case 0:
            result := markNeedleCollected(cardValue, slotValue, needleCollected)

            if (result)
                MsgBox % "Slot " . slotValue . " marked as collected for card " . cardValue . "."
            else
                MsgBox % "Hmm... Something has gone wrong."
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
