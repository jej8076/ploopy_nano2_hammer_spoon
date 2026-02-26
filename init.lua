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

-- F18 Drag Scroll Mode (v7 - hs.hotkey 사용)
local scrollMode = false
local lastPos = nil
local scrollTimer = nil
local accumulatedY = 0
local accumulatedX = 0

local function startScrollMode()
    if scrollMode then return end

    scrollMode = true
    lastPos = hs.mouse.absolutePosition()
    accumulatedY = 0
    accumulatedX = 0
    hs.alert.show("SCROLL ON")

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

            lastPos = currentPos
        end
    end)
end

local function stopScrollMode()
    if not scrollMode then return end

    scrollMode = false
    lastPos = nil
    accumulatedY = 0
    accumulatedX = 0
    hs.alert.show("SCROLL OFF")

    if scrollTimer then
        scrollTimer:stop()
        scrollTimer = nil
    end
end

-- F18 hotkey: pressedFn, releasedFn, repeatFn
hs.hotkey.bind({}, "f18", startScrollMode, stopScrollMode, nil)

hs.alert.show("Hammerspoon v7 ON")
