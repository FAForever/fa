#NoEnv
#SingleInstance Force
#MaxThreadsPerHotkey 1
SendMode Input
SetWorkingDir %A_ScriptDir%
SetMouseDelay, -1
CoordMode, Mouse, Screen

; F8: repeat right-clicks without moving the cursor.
; Shift+F8: hold Shift while repeating right-clicks, queueing FAF orders.
; F9: stop a currently running repeat.

F8::RepeatOrderClicks(false)
+F8::RepeatOrderClicks(true)

F9::
    cancelRepeats := true
    ToolTip, Repeated clicks cancelled.
    SetTimer, ClearToolTip, -1000
return

RepeatOrderClicks(queueOrders) {
    global cancelRepeats

    InputBox, clickCount, FAF order repeat, Number of orders to issue:, , 300, 140, , , , , 100
    if ErrorLevel
        return

    if !RegExMatch(clickCount, "^\d+$") || (clickCount < 1) {
        MsgBox, 48, FAF order repeat, Enter a whole number greater than zero.
        return
    }

    InputBox, delayMs, FAF order repeat, Delay between orders in milliseconds:, , 360, 140, , , , , 60
    if ErrorLevel
        return

    if !RegExMatch(delayMs, "^\d+$") {
        MsgBox, 48, FAF order repeat, Enter a non-negative whole-number delay.
        return
    }

    cancelRepeats := false
    ToolTip, Issuing %clickCount% right-click order(s) in 4 seconds.`nReturn focus to FAF now. Press F9 to cancel.
    Sleep, 4000

    if (queueOrders)
        SendInput, {Shift down}

    Loop, %clickCount% {
        if (cancelRepeats)
            break

        Click, Right
        Sleep, %delayMs%
    }

    if (queueOrders)
        SendInput, {Shift up}

    ToolTip
}

ClearToolTip:
    ToolTip
return
