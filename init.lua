-- key mapping for vim
-- Convert input soruce as English and sends 'escape' if inputSource is not English.
-- Sends 'escape' if inputSource is English.
-- key bindding reference --> https://www.hammerspoon.org/docs/hs.hotkey.html
local inputEnglish = "com.apple.keylayout.ABC"
local esc_bind

function convert_to_eng_with_esc()
	local inputSource = hs.keycodes.currentSourceID()
	if not (inputSource == inputEnglish) then
		hs.eventtap.keyStroke({}, 'right')
		hs.keycodes.currentSourceID(inputEnglish)
	end
	esc_bind:disable()
	hs.eventtap.keyStroke({}, 'escape')
	esc_bind:enable()
end

esc_bind = hs.hotkey.new({}, 'escape', convert_to_eng_with_esc):enable()

-- F18 Drag Scroll Mode (v9 - 커서 제한적 고정)
local scrollMode = false
local fixedPos = nil  -- 시작 위치 (일정 거리 벗어나면 돌아올 위치)
local lastPos = nil   -- 이전 위치 (움직임 계산용)
local scrollTimer = nil
local accumulatedY = 0
local accumulatedX = 0
local WARP_DISTANCE = 50  -- 이 거리 이상 벗어나면 커서 되돌림

local function startScrollMode()
    if scrollMode then return end

    scrollMode = true
    fixedPos = hs.mouse.absolutePosition()
    lastPos = fixedPos
    accumulatedY = 0
    accumulatedX = 0

    scrollTimer = hs.timer.doEvery(0.01, function()
        if scrollMode and lastPos then
            local currentPos = hs.mouse.absolutePosition()
            local dx = currentPos.x - lastPos.x
            local dy = currentPos.y - lastPos.y

            accumulatedY = accumulatedY + dy
            accumulatedX = accumulatedX + dx

            local scrollY = math.floor(accumulatedY / 5)
            local scrollX = math.floor(accumulatedX / 5)

            if scrollY ~= 0 or scrollX ~= 0 then
                hs.eventtap.scrollWheel({scrollX, scrollY}, {}, "line")
                accumulatedY = accumulatedY - (scrollY * 5)
                accumulatedX = accumulatedX - (scrollX * 5)
            end

            -- 시작 위치에서 일정 거리 이상 벗어나면 되돌림
            local distFromFixed = math.sqrt((currentPos.x - fixedPos.x)^2 + (currentPos.y - fixedPos.y)^2)
            if distFromFixed > WARP_DISTANCE then
                hs.mouse.absolutePosition(fixedPos)
                lastPos = fixedPos
            else
                lastPos = currentPos
            end
        end
    end)
end

local function stopScrollMode()
    if not scrollMode then return end

    scrollMode = false
    fixedPos = nil
    lastPos = nil
    accumulatedY = 0
    accumulatedX = 0

    if scrollTimer then
        scrollTimer:stop()
        scrollTimer = nil
    end
end

-- F18 hotkey: pressedFn, releasedFn, repeatFn
hs.hotkey.bind({}, "f18", startScrollMode, stopScrollMode, nil)

hs.alert.show("Hammerspoon v9 ON")
