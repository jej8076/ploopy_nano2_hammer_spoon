#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_InitialWorkingDir

; ------------------------------------------------------------------
; [설정 상수] 감도가 너무 빠르면 SENSITIVITY 숫자를 더 키우세요 (예: 40)
; ------------------------------------------------------------------
global SENSITIVITY := 30  
global WARP_DISTANCE := 50
global scrollMode := false
global fixedX := 0, fixedY := 0
global accumulatedX := 0, accumulatedY := 0

; ------------------------------------------------------------------
; 1. 기본 키 매핑 (F13, 마우스, Caps, Ctrl-BS 등)
; ------------------------------------------------------------------

#LButton::Click "Right"           ; Win + 좌클릭을 우클릭으로
^BackSpace::Send "{Delete}"       ; Ctrl + BS를 Delete로
^Esc::Send "#{Tab}"               ; Ctrl + Esc를 작업 보기로
^+v::Send("#v")			 ; Ctrl + Shift + V (^ + shift + v) 를 누르면 Win + V (# + v) 실행
^+z::Send("^y")			; Ctrl + Shift + Z 를 누르면 Ctrl + Y (Redo) 실행

; 1. Ctrl + 방향키 -> Home / End 로 변경
^Left::Send("{Home}")
^Right::Send("{End}")

; 2. Alt + 방향키 -> 단어 단위 이동 (기존 Ctrl + 방향키 기능)
!Left::Send("^{Left}")
!Right::Send("^{Right}")

; 3. (옵션) Ctrl + Shift + 방향키 -> 줄 전체 선택 (Home/End 선택)
^+Left::Send("+{Home}")
^+Right::Send("+{End}")

; 4. (옵션) Alt + Shift + 방향키 -> 단어 단위 선택 (기존 Ctrl + Shift + 방향키 기능) 
!+Left::Send("^+{Left}")
!+Right::Send("^+{Right}")

; 5. Ctrl + Shift + W 를 누르면 Alt + F4 (창 닫기/프로그램 종료) 실행
^+w::Send("!{F4}")

; ------------------------------------------------------------------
; 2. Vim Style Escape (한글 상태면 영어로 전환 후 Esc)
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
; 3. F18 Drag Scroll Mode (버그 수정 및 감도 최적화)
; ------------------------------------------------------------------

F18:: {
    global scrollMode, fixedX, fixedY, accumulatedX, accumulatedY
    
    ; 에러 발생 지점 수정: if문 뒤에 중괄호를 붙이거나 명확하게 줄바꿈
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
    global scrollMode, fixedX, fixedY, accumulatedX, accumulatedY, SENSITIVITY, WARP_DISTANCE
    
    if (!scrollMode) {
        return
    }

    MouseGetPos(&currX, &currY)
    
    ; 1. 현재 마우스의 실제 이동량 계산
    dx := currX - fixedX
    dy := currY - fixedY

    ; 2. 이동량을 누적 (움직이지 않으면 0이 더해짐)
    accumulatedX += dx
    accumulatedY += dy

    ; 3. 누적된 값이 민감도(SENSITIVITY)를 넘었을 때만 스크롤 발생
    ; Abs()를 사용하여 양수/음수 모두 체크
    if (Abs(accumulatedY) >= SENSITIVITY) {
        ; 정수 단위로 스크롤 횟수 계산
        scrollStepsY := Integer(accumulatedY / SENSITIVITY)
        
        if (scrollStepsY != 0) {
            dirY := (scrollStepsY > 0) ? "Down" : "Up"
            ; 스크롤 신호를 1단위씩 끊어서 정확히 보냄
            Click("Wheel" . dirY . " " . Abs(scrollStepsY))
            
            ; 4. 중요: 사용한 양만큼 '정확히' 차감하여 남은 이동량만 보존
            accumulatedY -= (scrollStepsY * SENSITIVITY)
        }
    }

    if (Abs(accumulatedX) >= SENSITIVITY) {
        scrollStepsX := Integer(accumulatedX / SENSITIVITY)
        
        if (scrollStepsX != 0) {
            dirX := (scrollStepsX > 0) ? "Right" : "Left"
            Click("Wheel" . dirX . " " . Abs(scrollStepsX))
            accumulatedX -= (scrollStepsX * SENSITIVITY)
        }
    }

    ; 5. 커서 워핑 (중심점을 다시 fixedX, fixedY로 강제 고정)
    ; 미세하게 움직여도 중심점으로 되돌려야 다음 tick에서 정확한 dx, dy가 계산됨
    MouseMove(fixedX, fixedY, 0)
}

TrayTip "AutoHotkey 통합 설정 로드 완료", "모든 기능이 정상 작동 중입니다."
