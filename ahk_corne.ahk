#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_InitialWorkingDir

; ------------------------------------------------------------------
; [설정 상수]
; ------------------------------------------------------------------
global SENSITIVITY := 30
global scrollMode := false
global fixedX := 0, fixedY := 0
global accumulatedX := 0, accumulatedY := 0

; ------------------------------------------------------------------
; 1. 맥북 스타일 및 기본 매핑 (Cmd 위치의 Alt 활용)
; ------------------------------------------------------------------

; [저장/복사/붙여넣기/전체선택]
!s::Send "^s"
!c::Send "^c"
!v::Send "^v"
!x::Send "^x"
!a::Send "^a"
!w::Send "^w"
!z::Send "^z"
!q::Send "!{F4}"

; [줄 이동] Alt + 방향키 -> Home / End
!Left::Send("{Home}")
!Right::Send("{End}")
!+Left::Send("+{Home}")
!+Right::Send("+{End}")

; [뒤로가기/앞으로가기] 맥북 스타일 Ctrl + [ / ]
^[::Send "!{Left}"
^]::Send "!{Right}"

; [마우스] Ctrl + 좌클릭 -> 우클릭
^LButton::Click "Right"

; [기타 편의]
^BackSpace::Send "{Delete}"  ; Ctrl + BS -> Delete
^+v::Send("#v")              ; Ctrl + Shift + V -> 클립보드 기록(Win+V)
^+z::Send("^y")              ; Ctrl + Shift + Z -> Redo(Ctrl+Y)
^+w::Send("!{F4}")           ; Ctrl + Shift + W -> 창 닫기(Alt+F4)

; [시스템 단축키 비활성화]
#1::return
#2::return

; ------------------------------------------------------------------
; 2. 윈도우 시스템 기능 보존 (창 정렬 간섭 방지)
; ------------------------------------------------------------------
; Win + 방향키(창 정렬)가 오토핫키 매핑에 가로채지지 않도록 명시적으로 허용
~#Left::return
~#Right::return
~#Up::return
~#Down::return

; ------------------------------------------------------------------
; 3. Vim Style Escape (한영 자동 전환)
; ------------------------------------------------------------------
$Esc:: {
    if (IME_GET() != 0) {
        Send "{vk15}" ; 한글이면 한/영 전환
    }
    Send "{Esc}"
}

IME_GET(WinTitle:="A") {
    try {
        hwnd := WinExist(WinTitle)
        if (hwnd) {
            ptrSize := A_PtrSize
            stGTI := Buffer(4 * 4 + ptrSize * 6, 0)
            NumPut("UInt", stGTI.Size, stGTI, 0)
            DllCall("GetGUIThreadInfo", "Uint", 0, "Ptr", stGTI)
            hwnd := NumGet(stGTI, 8 + ptrSize, "Ptr")
            return DllCall("SendMessage", "Ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd), "UInt", 0x0283, "Ptr", 0x0005, "Ptr", 0)
        }
    }
    return 0
}

; ------------------------------------------------------------------
; 4. F18 Drag Scroll Mode (감도 최적화)
; ------------------------------------------------------------------
F18:: {
    global scrollMode, fixedX, fixedY, accumulatedX, accumulatedY
    if (scrollMode) {
        return
    }
    scrollMode := true
    MouseGetPos(&fixedX, &fixedY)
    accumulatedX := 0
    accumulatedY := 0
    SetTimer(ScrollTick, 10)
}

F18 up:: {
    global scrollMode
    scrollMode := false
    SetTimer(ScrollTick, 0)
}

ScrollTick() {
    global scrollMode, fixedX, fixedY, accumulatedX, accumulatedY, SENSITIVITY
    if (!scrollMode) {
	return
    }
    MouseGetPos(&currX, &currY)
    accumulatedX += (currX - fixedX)
    accumulatedY += (currY - fixedY)

    if (Abs(accumulatedY) >= SENSITIVITY) {
        scrollStepsY := Integer(accumulatedY / SENSITIVITY)
        dirY := (scrollStepsY > 0) ? "Down" : "Up"
        Click("Wheel" . dirY . " " . Abs(scrollStepsY))
        accumulatedY -= (scrollStepsY * SENSITIVITY)
    }
    if (Abs(accumulatedX) >= SENSITIVITY) {
        scrollStepsX := Integer(accumulatedX / SENSITIVITY)
        dirX := (scrollStepsX > 0) ? "Right" : "Left"
        Click("Wheel" . dirX . " " . Abs(scrollStepsX))
        accumulatedX -= (scrollStepsX * SENSITIVITY)
    }
    MouseMove(fixedX, fixedY, 0)
}

TrayTip "AutoHotkey 통합 설정 로드 완료", "맥북 스타일 및 드래그 스크롤 기능 활성화"
