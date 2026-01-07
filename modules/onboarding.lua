local onboarding = {}

local canvas = require("hs.canvas")
local eventtap = require("hs.eventtap")
local config = require("modules.config")
local constants = require("modules.constants")

onboarding.currentStep = 1
onboarding.isActive = false

local steps = {
    {
        title = "Welcome to Vimualizer ✨",
        body = "Vimualizer turns your Vim motions into a real-time visual experience on macOS.\n\nLet's get you set up in less than 60 seconds.",
        image = "👋"
    },
    {
        title = "The HUD & Key Buffer 🖥️",
        body = "Watch your keystrokes appear as human-readable actions. The HUD explains what you're doing, while the Buffer tracks your active mode (Normal, Insert, Visual).",
        image = "⌨️"
    },
    {
        title = "Vim Sensei 🥋",
        body = "Sharpen your muscle memory with our built-in trainer. Experience progressive challenges to master advanced text objects and operators.",
        image = "🧠"
    },
    {
        title = "Ghost Mode 👻",
        body = "Distraction-free focus. Your UI will automatically fade when you're not typing, and snap back to full visibility the moment you hit a key.",
        image = "💨"
    },
    {
        title = "Total Control ⚙️",
        body = "Reposition windows, change fonts, and toggle features using the Control Panel.\n\nShortcut: [ Cmd + Opt + P ]",
        image = "🛠️"
    },
    {
        title = "You're Ready! 🚀",
        body = "Vimualizer is now active and listening.\n\nTap Finish to start your journey.",
        image = "🏁"
    }
}

function onboarding.init()
    if _G.onboardingCanvas then _G.onboardingCanvas:delete() end

    local w, h = 500, 400
    local screen = hs.screen.mainScreen():frame()
    
    _G.onboardingCanvas = canvas.new({
        x = (screen.w - w) / 2,
        y = (screen.h - h) / 2,
        w = w,
        h = h
    }):level(hs.canvas.windowLevels.overlay)

    -- Background
    _G.onboardingCanvas[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = { hex = "#1c1c1e", alpha = 0.98 },
        roundedRectRadii = { xRadius = 20, yRadius = 20 },
        strokeColor = { white = 1, alpha = 0.2 },
        strokeWidth = 1,
        shadow = { blurRadius = 30, color = { alpha = 0.5, white = 0 }, offset = { h = 15, w = 0 } }
    }

    -- Emoji/Icon Area
    _G.onboardingCanvas[2] = {
        type = "text",
        text = "",
        textSize = 80,
        textAlignment = "center",
        frame = { x = 0, y = 40, w = "100%", h = 100 }
    }

    -- Title
    _G.onboardingCanvas[3] = {
        type = "text",
        text = "",
        textColor = { white = 1 },
        textSize = 28,
        textFont = config.fontUIBold or ".AppleSystemUIFontBold",
        textAlignment = "center",
        frame = { x = 40, y = 160, w = w - 80, h = 40 }
    }

    -- Body
    _G.onboardingCanvas[4] = {
        type = "text",
        text = "",
        textColor = { white = 0.7 },
        textSize = 18,
        textFont = config.fontUI or ".AppleSystemUIFont",
        textAlignment = "center",
        frame = { x = 50, y = 210, w = w - 100, h = 100 }
    }

    -- Progress Dots
    _G.onboardingCanvas[5] = {
        type = "text",
        text = "",
        textColor = { white = 0.3 },
        textSize = 12,
        textAlignment = "center",
        frame = { x = 0, y = 310, w = "100%", h = 20 }
    }

    -- Next Button Background
    _G.onboardingCanvas[6] = {
        type = "rectangle",
        action = "fill",
        fillColor = { hex = "#0A84FF" },
        roundedRectRadii = { xRadius = 10, yRadius = 10 },
        frame = { x = (w - 140) / 2, y = 340, w = 140, h = 40 }
    }

    -- Next Button Text
    _G.onboardingCanvas[7] = {
        type = "text",
        text = "Next",
        textColor = { white = 1 },
        textSize = 16,
        textFont = config.fontUIBold or ".AppleSystemUIFontBold",
        textAlignment = "center",
        frame = { x = (w - 140) / 2, y = 349, w = 140, h = 22 }
    }
end

function onboarding.updateUI()
    local step = steps[onboarding.currentStep]
    _G.onboardingCanvas[2].text = step.image
    _G.onboardingCanvas[3].text = step.title
    _G.onboardingCanvas[4].text = step.body

    local dots = ""
    for i = 1, #steps do
        dots = dots .. (i == onboarding.currentStep and "● " or "○ ")
    end
    _G.onboardingCanvas[5].text = dots

    if onboarding.currentStep == #steps then
        _G.onboardingCanvas[6].fillColor = { hex = "#30D158" }
        _G.onboardingCanvas[7].text = "Finish"
    else
        _G.onboardingCanvas[6].fillColor = { hex = "#0A84FF" }
        _G.onboardingCanvas[7].text = "Next"
    end
end

function onboarding.start()
    if onboarding.isActive then return end
    onboarding.isActive = true
    onboarding.currentStep = 1
    onboarding.init()
    onboarding.updateUI()
    _G.onboardingCanvas:show()
    
    -- Interaction watcher helper
    onboarding.tap = eventtap.new({ eventtap.event.types.leftMouseDown, eventtap.event.types.keyDown }, function(e)
        if not onboarding.isActive then return false end
        
        local type = e:getType()
        if type == eventtap.event.types.leftMouseDown then
            local p = e:location()
            local f = _G.onboardingCanvas:frame()
            if p.x >= f.x and p.x <= (f.x + f.w) and p.y >= f.y and p.y <= (f.y + f.h) then
                -- Check if button area
                local relX = p.x - f.x
                local relY = p.y - f.y
                local btnF = _G.onboardingCanvas[6].frame
                if relX >= btnF.x and relX <= (btnF.x + btnF.w) and relY >= btnF.y and relY <= (btnF.y + btnF.h) then
                    onboarding.next()
                    return true
                end
                return true
            end
        elseif type == eventtap.event.types.keyDown then
            local keyName = hs.keycodes.map[e:getKeyCode()]
            if keyName == "return" or keyName == "space" then
                onboarding.next()
                return true
            elseif keyName == "escape" then
                onboarding.stop()
                return true
            end
        end
        return false
    end):start()
end

function onboarding.next()
    if onboarding.currentStep < #steps then
        onboarding.currentStep = onboarding.currentStep + 1
        onboarding.updateUI()
    else
        onboarding.stop()
    end
end

function onboarding.stop()
    onboarding.isActive = false
    if onboarding.tap then onboarding.tap:stop() end
    if _G.onboardingCanvas then _G.onboardingCanvas:hide() end
    config.hasCompletedOnboarding = true
    config.save()
    if config.isBufferEnabled then _G.keyBuffer:show() end
    hs.alert.show("Onboarding Complete! Welcome to Vimualizer.", 2)
end

return onboarding
