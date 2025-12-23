-- =================================================
-- VIM HUD: APP EXCLUSION EDITION
-- =================================================

-- 1. CLEANUP
if _G.modWatcher then _G.modWatcher:stop() end
if _G.keyWatcher then _G.keyWatcher:stop() end
if _G.appWatcher then _G.appWatcher:stop() end
if _G.interactionWatcher then _G.interactionWatcher:stop() end
if _G.hud then _G.hud:delete() end
if _G.keyBuffer then _G.keyBuffer:delete() end
if _G.prefPanel then _G.prefPanel:delete() end

local canvas = require("hs.canvas")
local eventtap = require("hs.eventtap")
local timer = require("hs.timer")
local hotkey = require("hs.hotkey")
local keycodes = require("hs.keycodes")
local styledtext = require("hs.styledtext")
local drawing = require("hs.drawing")
local window = require("hs.window")
local application = require("hs.application")

-- ================= CONFIGURATION =================

local isMasterEnabled = true
local isHudEnabled = true
local isBufferEnabled = true
local isActionInfoEnabled = true
local isAerospaceEnabled = false
local isEditMode = false

-- App Exclusion List (Bundle IDs)
local excludedApps = {
    ["com.apple.loginwindow"] = true,
    ["com.apple.ScreenSaver.Engine"] = true
}

local fontTitleSize = 32
local fontBodySize = 20
local hudPosIndex = 1
local customHudX, customHudY = 100, 100

local maxHudWidth = 700
local minHudWidth = 300
local hudPadding = 30
local hudBgColor = { red=0.1, green=0.1, blue=0.1, alpha=0.98 }
local hudStrokeColor = { white=1, alpha=0.1 }
local displayTime = 8.0

local colorTitle = { red=1, green=0.9, blue=0.4, alpha=1 }
local colorKey = { red=0.6, green=0.8, blue=1, alpha=1 }
local colorDesc = { white=0.9, alpha=1 }
local colorHeader = { white=0.6, alpha=1 }
local colorAccent = { red=1, green=0.4, blue=0.4, alpha=1 }
local colorInfo = { white=1, alpha=0.95 }
local colorDrag = { red=0.2, green=0.8, blue=0.2, alpha=0.9 }
local btnColorAction = {red=0.2, green=0.4, blue=0.8, alpha=1}
local btnColorExclude = {red=0.8, green=0.2, blue=0.2, alpha=1} -- Red for Exclude
local panelColor = { red=0.1, green=0.1, blue=0.1, alpha=0.98 }

local screen = hs.screen.mainScreen():frame()
local bufferMaxLen = 12
local bufferW, bufferH = 550, 85
local bufferX, bufferY = screen.w - bufferW - 30, screen.h - bufferH - 30
local bufferBgColor = { red=0.15, green=0.15, blue=0.15, alpha=0.95 }
local bufferTxtColor = { red=0.6, green=1, blue=0.6, alpha=1 }
local dimColor = { red=0.5, green=0.5, blue=0.5, alpha=1 }

-- Increased height for new App Selector
local prefW, prefH = 450, 750
local prefX, prefY = (screen.w - prefW) / 2, (screen.h - prefH) / 2
local btnColorOn = {red=0.2,green=0.6,blue=0.2,alpha=1}
local btnColorOff = {red=0.6,green=0.2,blue=0.2,alpha=1}

-- =================================================
-- DATA & HELPERS
-- =================================================
local VIM_STATE = { NORMAL="NORMAL", INSERT="INSERT", VISUAL="VISUAL", PENDING_CHANGE="PENDING_CHANGE" }
local currentState = VIM_STATE.NORMAL
local keyHistory = {}

-- Helper to check if current app is excluded
local function isCurrentAppDisabled()
    local win = window.focusedWindow()
    if not win then return false end
    local app = win:application()
    if not app then return false end
    return excludedApps[app:bundleID()] == true
end

local function getCurrentAppInfo()
    local win = window.focusedWindow()
    if not win then return "Unknown", "Unknown" end
    local app = win:application()
    if not app then return "Unknown", "Unknown" end
    return app:name(), app:bundleID()
end

local vimOps = { d="Delete", c="Change", y="Yank", v="Select", [">"]="Indent", ["<"]="Outdent", ["="]="Format" }
local vimContext = { i="Inside", a="Around" }
local vimObjects = {
    w="Word", W="WORD", p="Paragraph", s="Sentence", t="Tag",
    ["("]="Parens", [")"]="Parens", b="Parens",
    ["{"]="Braces", ["}"]="Braces", B="Braces",
    ["["]="Brackets", ["]"]="Brackets",
    ["<"]="Angle Brackets", [">"]="Angle Brackets",
    ["'"]="Quotes", ['"']="Double Quotes", ["`"]="Backticks"
}
local vimMotions = {
    h="Left", j="Down", k="Up", l="Right",
    w="Word", b="Back", e="End Word",
    ["0"]="Start Line", ["$"]="End Line", ["^"]="First Char",
    G="Bottom", H="Top Screen", M="Mid Screen", L="Bot Screen"
}
local argMotions = { f="Find", F="Find Back", t="Until", T="Until Back", r="Replace", m="Mark", ["`"]="Jump Mark", ["'"]="Jump Mark Line" }

local simpleActions = {
    u="Undo", ["^r"]="Redo", x="Delete Char", s="Sub Char",
    i="Insert Mode", a="Append", o="Open Below",
    I="Insert Start", A="Append End", O="Open Above",
    p="Paste After", P="Paste Before",
    J="Join Lines", D="Delete to End", C="Change to End", Y="Yank Line",
    ["/"]="Search", ["?"]="Search Back", n="Next Match", N="Prev Match",
    [":"]="Command Line", ["%"]="Match Bracket", ["*"]="Find Word Under",
    ["~"]="Toggle Case", ["."]="Repeat Last",
    ["{"]="Prev Paragraph", ["}"]="Next Paragraph",
    ["⌥h"]="Focus Left", ["⌥j"]="Focus Down", ["⌥k"]="Focus Up", ["⌥l"]="Focus Right",
    ["⌥⇧h"]="Move Left", ["⌥⇧j"]="Move Down", ["⌥⇧k"]="Move Up", ["⌥⇧l"]="Move Right",
    ["⌥f"]="Toggle Float", ["⌥s"]="Layout Stack", ["⌥/"]="Vertical Split", ["⌥-"]="Horizontal Split",
    ["⌥tab"]="Next Workspace", ["⌥comma"]="Layout Tiles"
}

-- Smart Sequence Parser
local function getSequenceDescription()
    local len = #keyHistory
    if len == 0 then return "" end

    local k1 = keyHistory[len]
    local k2 = (len >= 2) and keyHistory[len-1] or nil
    local k3 = (len >= 3) and keyHistory[len-2] or nil

    -- A. Check 3-Key Sequences
    if k3 and k2 and k1 then
        if vimOps[k3] and vimContext[k2] then
            local objName = vimObjects[k1] or ("'" .. k1 .. "'")
            return vimOps[k3] .. " " .. vimContext[k2] .. " " .. objName
        end
        if vimOps[k3] and argMotions[k2] then
            return vimOps[k3] .. " " .. argMotions[k2] .. " '" .. k1 .. "'"
        end
    end

    -- B. Check 2-Key Sequences
    if k2 and k1 then
        if argMotions[k2] then return argMotions[k2] .. " '" .. k1 .. "'" end
        if vimOps[k2] and vimContext[k1] then return vimOps[k2] .. " " .. vimContext[k1] .. "..." end
        if vimOps[k2] and k2 == k1 then return vimOps[k2] .. " Line" end
        if vimOps[k2] then
            if vimMotions[k1] then return vimOps[k2] .. " " .. vimMotions[k1] end
            if k1 == "g" then return "" end
            if k1 == "G" then return vimOps[k2] .. " to Bottom" end
        end
        if k2 == "g" then
            if k1 == "g" then return "Go to Top" end
            if k1 == "e" then return "End Prev Word" end
            if k1 == "i" then return "Last Insert" end
            if k1 == "v" then return "Reselect" end
            if k1 == "d" then return "Go Definition" end
        end
        if k2 == "^w" then
            if k1 == "v" then return "Vert Split" end
            if k1 == "s" then return "Horiz Split" end
            if k1 == "c" then return "Close Window" end
            if k1 == "o" then return "Close Others" end
            if k1 == "=" then return "Equalize" end
            if k1 == "h" or k1=="j" or k1=="k" or k1=="l" then return "Window " .. k1:upper() end
        end
        if k2 == "z" then
            if k1 == "z" then return "Center View" end
            if k1 == "t" then return "Top View" end
            if k1 == "b" then return "Bottom View" end
            if k1 == "o" then return "Open Fold" end
            if k1 == "c" then return "Close Fold" end
            if k1 == "M" then return "Close All" end
            if k1 == "R" then return "Open All" end
        end
    end

    if k1 and vimOps[k1] then return vimOps[k1] .. "..." end
    local desc = simpleActions[k1] or vimMotions[k1]
    if not desc and #k1 > 1 and k1:sub(1,1) == "^" then desc = "Ctrl + " .. k1:sub(2) end
    return desc or ""
end

-- =================================================
-- MENUS
-- =================================================
local insertTriggers = { ["i"]=true, ["I"]=true, ["a"]=true, ["A"]=true, ["o"]=true, ["O"]=true, ["s"]=true, ["S"]=true, ["C"]=true }
local visualTriggers = { ["v"]=true, ["V"]=true, ["^v"]=true }

local previewMenu = { title = "Visual Preview", text = "-- Section Header --\nkey : description text\ncmd : another command\n-- Another Section --\ntest : checking font size" }
local indexMenu = { title = "Vim Entry Points", text = "-- Operators --\nd : Delete Actions\nc : Change Actions\ny : Yank (Copy)\np : Paste\n-- Modes --\nv : Visual Char Mode\nV : Visual Line Mode\n^v : Visual Block Mode\n-- Navigation --\ng : Go / Extended\nz : Folds / View\nm : Marks\n/ : Search" }

local modifierMenus = {
    shift = { title = "Shift Held (Upper Case)", text = "-- Operators --\nD : Delete rest of line\nC : Change rest of line\nY : Yank line (yy)\n-- Insert --\nI : Insert at START\nA : Insert at END\nO : Insert line ABOVE\n-- Modes --\nV : Visual LINE Mode" },
    ctrl = { title = "Ctrl Held (Commands)", text = "-- Visual --\n^v : Visual BLOCK Mode\n-- Window --\n^w : Window Splits...\n-- Navigation --\n^d : Scroll Down\n^u : Scroll Up\n^o : Jump Back\n^i : Jump Forward" },
    alt = { title = "Aerospace (Option)", text = "-- Focus --\nh/j/k/l : Focus Window\n-- Move --\n⇧ + h/j/k/l : Move Window\n-- Layout --\n/ : Vertical Split\n- : Horizontal Split\ns : Layout Stack\nf : Toggle Floating\n, : Layout Tiles\n-- Workspaces --\n1-9 : Switch Workspace\n⇧ + 1-9 : Move to Workspace\nTab : Next Workspace" }
}

local triggers = {
    d = { title = "Delete (d...)", text = "-- Basics --\ndd : Entire line\nD : Rest of line (d$)\n-- Objects --\ndw : Next word\ndiw : Inner word\ndi\" : Inside quotes\ndi( : Inside parens\ndt{x} : Delete until {x}" },
    c = { title = "Change (c...)", text = "-- Basics --\ncc : Entire line\nC : Rest of line (c$)\ncw : Change word\n-- Objects --\nciw : Change inner word\nci\" : Change inside quotes\nci( : Change inside parens" },
    y = { title = "Yank/Copy (y...)", text = "-- Basics --\nyy : Entire line\ny$ : To end of line\np/P : Paste after/before\n-- Objects --\nyiw : Inner word\nyip : Inner paragraph" },
    v = { title = "Visual Char (v)", text = "v : Start selection\no : Swap cursor end\n-- Actions --\nd/y : Delete / Yank\n~ : Toggle Case\n>/< : Indent / Dedent" },
    V = { title = "Visual Line (Shift+v)", text = "V : Start Line Mode\nj/k : Extend selection\n} : Extend Paragraph\n= : Auto-indent\nJ : Join lines" },
    ["^v"] = { title = "Visual Block (Ctrl+v)", text = "^v : Start Block Mode\nI : Insert on ALL lines\nA : Append on ALL lines\nc : Change block\n$ : Extend to end" },
    g = { title = "Go / Extended (g...)", text = "-- Nav --\ngg : Top of file\nG : Bottom of file\ngi : Last insert spot\ngv : Reselect Visual\ngd : Go definition\n-- Format --\ngq : Format paragraph\ngu/gU : Lower/Upper case" },
    z = { title = "Folds & View (z...)", text = "-- Scroll --\nzz : Center screen\nzt/zb : Top/Bottom screen\n-- Folds --\nzo/zc : Open/Close fold\nza : Toggle fold\nzM/zR : Close/Open ALL" },
    m = { title = "Marks (m...)", text = "m{a-z} : Set local mark\nm{A-Z} : Set GLOBAL mark\n'{a-z} : Jump to mark line\n`{a-z} : Jump to mark pos" },
    ["^w"] = { title = "Window (Ctrl+w ...)", text = "-- Split --\nv/s : Vert/Horiz Split\n-- Move --\nh/j/k/l : Move Focus\nw : Cycle\n-- Actions --\nc : Close Window\n= : Equalize sizes" },
}

local function formatHudBody(rawText)
    local finalStyled = styledtext.new("")
    local baseStyle = { font={name=".AppleSystemUIFont", size=fontBodySize}, color=colorDesc, paragraphStyle={lineSpacing=8} }
    local keyStyle =  { font={name=".AppleSystemUIFontBold", size=fontBodySize}, color=colorKey }
    local headerStyle = { font={name=".AppleSystemUIFontBold", size=fontBodySize-2}, color=colorHeader }

    if not rawText or rawText == "" then return finalStyled end
    for line in rawText:gmatch("[^\r\n]+") do
        if line:match("^%-%-.*%-%-$") then
             finalStyled = finalStyled .. styledtext.new("\n" .. line .. "\n", headerStyle)
        elseif line:match(":") then
            local keyPart, descPart = line:match("^(.-)%s*:%s*(.*)$")
            finalStyled = finalStyled .. styledtext.new(keyPart, keyStyle) .. styledtext.new(" : ", baseStyle) .. styledtext.new(descPart .. "\n", baseStyle)
        else
             finalStyled = finalStyled .. styledtext.new(line .. "\n", baseStyle)
        end
    end
    return finalStyled
end

-- =================================================
-- UI SETUP
-- =================================================

_G.hud = canvas.new({x=0,y=0,w=100,h=100})
_G.hud[1] = { type="rectangle", action="fill", fillColor=hudBgColor, roundedRectRadii={xRadius=12,yRadius=12}, strokeColor=hudStrokeColor, strokeWidth=2 }
_G.hud[2] = { type="text", text="", frame={x=0,y=0,w=0,h=0} }
_G.hud[3] = { type="text", text="", frame={x=0,y=0,w=0,h=0} }
_G.hud[4] = { type="rectangle", action="skip", fillColor=colorDrag, roundedRectRadii={xRadius=12,yRadius=12}, frame={x=0,y=0,w="100%",h=30} }
_G.hud[5] = { type="text", action="skip", text="DRAG ME", textSize=11, textColor={white=1}, textAlignment="center", frame={x=0,y=9,w="100%",h=12} }

_G.keyBuffer = canvas.new({x=bufferX, y=bufferY, w=bufferW, h=bufferH})
_G.keyBuffer[1] = { type="rectangle", action="fill", fillColor=bufferBgColor, roundedRectRadii={xRadius=8,yRadius=8}, strokeColor={white=1,alpha=0.2}, strokeWidth=1 }
_G.keyBuffer[2] = { type="text", text="NORMAL", textColor=colorTitle, textSize=22, textAlignment="center", frame={x="0%",y="30%",w="25%",h="100%"} }
_G.keyBuffer[3] = { type="text", text="", textColor=bufferTxtColor, textSize=34, textAlignment="right", frame={x="25%",y="5%",w="70%",h="60%"} }
_G.keyBuffer[4] = { type="text", text="", textColor=colorInfo, textSize=15, textAlignment="right", frame={x="25%",y="60%",w="70%",h="30%"} }
_G.keyBuffer[5] = { type="rectangle", action="skip", fillColor=colorDrag, roundedRectRadii={xRadius=8,yRadius=8}, frame={x=0,y=0,w="100%",h=20} }
_G.keyBuffer[6] = { type="text", action="skip", text="DRAG ME", textSize=10, textColor={white=1}, textAlignment="center", frame={x=0,y=5,w="100%",h=10} }

local hudTimer = nil

local function updateBufferGeometry()
    if isActionInfoEnabled then
        _G.keyBuffer[3].frame = {x="25%", y="2%", w="70%", h="58%"}
        _G.keyBuffer[4].action = "stroke"
        _G.keyBuffer[4].frame = {x="25%", y="62%", w="70%", h="30%"}
    else
        _G.keyBuffer[3].frame = {x="25%", y="15%", w="70%", h="70%"}
        _G.keyBuffer[4].action = "skip"
    end
end

local function updateStateDisplay()
    local stateText, color = currentState, colorTitle
    if currentState == VIM_STATE.INSERT then color = {red=0.4, green=1, blue=0.4, alpha=1}
    elseif currentState == VIM_STATE.VISUAL then color = {red=1, green=0.6, blue=0.2, alpha=1}
    elseif currentState == VIM_STATE.PENDING_CHANGE then stateText = "PENDING"; color = colorAccent end
    _G.keyBuffer[2].text = stateText; _G.keyBuffer[2].textColor = color
end

local function addToBuffer(str, isPlaceholder)
    table.insert(keyHistory, str)
    if #keyHistory > bufferMaxLen then table.remove(keyHistory, 1) end
    _G.keyBuffer[3].text = table.concat(keyHistory, " "); _G.keyBuffer[3].textColor = isPlaceholder and dimColor or bufferTxtColor

    if isActionInfoEnabled and not isPlaceholder then
        local desc = getSequenceDescription()
        _G.keyBuffer[4].text = desc
    elseif isPlaceholder then
        _G.keyBuffer[4].text = ""
    end

    updateStateDisplay(); if isBufferEnabled then _G.keyBuffer:show() end
end

local function resetToNormal()
    currentState = VIM_STATE.NORMAL; keyHistory = {};
    _G.keyBuffer[3].text = ""; _G.keyBuffer[4].text = "";
    updateStateDisplay(); _G.hud:hide()
end

local function updateDragHandles()
    local action = isEditMode and "fill" or "skip"
    local textAction = isEditMode and "fill" or "skip"

    _G.hud[4].action = action
    _G.hud[5].action = textAction
    _G.hud[1].strokeColor = isEditMode and colorDrag or hudStrokeColor
    _G.keyBuffer[5].action = action
    _G.keyBuffer[6].action = textAction
    _G.keyBuffer[1].strokeColor = isEditMode and colorDrag or {white=1,alpha=0.2}

    local level = isEditMode and hs.canvas.windowLevels.floating or hs.canvas.windowLevels.overlay
    _G.hud:level(level)
    _G.keyBuffer:level(level)

    updateBufferGeometry()
end

-- =================================================
-- DYNAMIC RESIZING
-- =================================================
local function presentHud(title, rawBodyText, titleOverrideColor)
    local titleStyle = { font={name=".AppleSystemUIFontBold", size=fontTitleSize}, color=titleOverrideColor or colorTitle }
    local styledTitle = styledtext.new(title, titleStyle)
    local styledBody = formatHudBody(rawBodyText)
    local innerMaxW = maxHudWidth - (hudPadding * 2)
    local titleSize = drawing.getTextDrawingSize(styledTitle, {w=innerMaxW})
    local bodySize = {w=0, h=0}
    if rawBodyText and rawBodyText ~= "" then bodySize = drawing.getTextDrawingSize(styledBody, {w=innerMaxW}) end
    local contentW = math.max(titleSize.w, bodySize.w)
    local newW = math.max(minHudWidth, contentW + (hudPadding * 2))
    local titleH = titleSize.h
    local bodyH = bodySize.h
    local spacer = (bodyH > 0) and 15 or 0
    local newH = hudPadding + titleH + spacer + bodyH + hudPadding
    if isEditMode then newH = newH + 20 end

    local newX, newY = 150, 100
    if hudPosIndex == 1 then newX, newY = 150, (screen.h - newH) / 2 -- Left
    elseif hudPosIndex == 2 then newX, newY = screen.w - newW - 50, 50 -- Top Right
    elseif hudPosIndex == 3 then newX, newY = screen.w - newW - 50, screen.h - newH - 50 -- Bot Right
    elseif hudPosIndex == 4 then newX, newY = (screen.w - newW) / 2, (screen.h - newH) / 2 -- Center
    elseif hudPosIndex == 5 then newX, newY = customHudX, customHudY -- Custom
    end

    _G.hud:frame({x=newX, y=newY, w=newW, h=newH})
    local yOffset = isEditMode and 30 or hudPadding
    _G.hud[2].text = styledTitle
    _G.hud[2].frame = { x=hudPadding, y=yOffset, w=newW-(hudPadding*2), h=titleH }
    _G.hud[3].text = styledBody
    _G.hud[3].frame = { x=hudPadding, y=yOffset + titleH + spacer, w=newW-(hudPadding*2), h=bodyH }
    _G.hud[4].frame = {x=0,y=0,w=newW,h=30}
    _G.hud[5].frame = {x=0,y=9,w=newW,h=12}

    updateDragHandles()
    _G.hud:show()
end

-- =================================================
-- PREFERENCES GUI
-- =================================================
_G.prefPanel = canvas.new({x=prefX, y=prefY, w=prefW, h=prefH}):level(hs.canvas.windowLevels.floating)

local function initPrefs()
    _G.prefPanel[1] = { type="rectangle", action="fill", fillColor=panelColor, roundedRectRadii={xRadius=12, yRadius=12}, strokeColor=hudStrokeColor, strokeWidth=2 }
    _G.prefPanel[2] = { type="text", text="Vim HUD Config", textColor=colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="3%",w="100%",h="8%"} }

    for i=0,5 do
        local yPos = 11 + (i * 9)
        _G.prefPanel[3 + (i*2)] = { type="rectangle", action="fill", frame={x="10%",y=yPos.."%",w="80%",h="7%"} }
        _G.prefPanel[4 + (i*2)] = { type="text", frame={x="10%",y=(yPos+1.5).."%",w="80%",h="7%"} }
    end

    local yStart = 68
    -- Title Size
    _G.prefPanel[15] = { type="rectangle", action="fill", frame={x="10%",y=yStart.."%",w="20%",h="8%"} }
    _G.prefPanel[16] = { type="text", text="-", textColor={white=1}, textSize=20, textAlignment="center", frame={x="10%",y=(yStart+0.5).."%",w="20%",h="8%"} }
    _G.prefPanel[17] = { type="rectangle", action="fill", frame={x="70%",y=yStart.."%",w="20%",h="8%"} }
    _G.prefPanel[18] = { type="text", text="+", textColor={white=1}, textSize=20, textAlignment="center", frame={x="70%",y=(yStart+0.5).."%",w="20%",h="8%"} }
    _G.prefPanel[19] = { type="text", text="Title Size", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%",y=(yStart+1).."%",w="40%",h="8%"} }

    yStart = 78
    -- Text Size
    _G.prefPanel[20] = { type="rectangle", action="fill", frame={x="10%",y=yStart.."%",w="20%",h="8%"} }
    _G.prefPanel[21] = { type="text", text="-", textColor={white=1}, textSize=20, textAlignment="center", frame={x="10%",y=(yStart+0.5).."%",w="20%",h="8%"} }
    _G.prefPanel[22] = { type="rectangle", action="fill", frame={x="70%",y=yStart.."%",w="20%",h="8%"} }
    _G.prefPanel[23] = { type="text", text="+", textColor={white=1}, textSize=20, textAlignment="center", frame={x="70%",y=(yStart+0.5).."%",w="20%",h="8%"} }
    _G.prefPanel[24] = { type="text", text="Text Size", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%",y=(yStart+1).."%",w="40%",h="8%"} }

    -- App Exclusion Section (Row 9, approx 88%)
    _G.prefPanel[25] = { type="rectangle", action="fill", frame={x="10%",y="88%",w="55%",h="8%"} } -- App Name BG
    _G.prefPanel[26] = { type="text", text="App Name", textColor={white=1}, textSize=14, textAlignment="center", frame={x="10%",y="88.5%",w="55%",h="8%"} }
    _G.prefPanel[27] = { type="rectangle", action="fill", frame={x="67%",y="88%",w="23%",h="8%"} } -- Toggle Button BG
    _G.prefPanel[28] = { type="text", text="Toggle", textColor={white=1}, textSize=14, textAlignment="center", frame={x="67%",y="88.5%",w="23%",h="8%"} }

    _G.prefPanel[29] = { type="text", text="[ Drag Green Handles to Move ]", textColor={white=0.5}, textSize=12, textAlignment="center", frame={x="0%",y="96%",w="100%",h="4%"} }
end

local function updatePrefsVisuals()
    local function styleBtn(idx, enabled, txt)
        _G.prefPanel[idx].fillColor = (enabled and btnColorOn or btnColorOff)
        _G.prefPanel[idx].roundedRectRadii = {xRadius=6, yRadius=6}
        _G.prefPanel[idx+1].text = styledtext.new(txt, {font={name=".AppleSystemUIFontBold", size=16}, color={white=1}, paragraphStyle={alignment="center"}})
    end

    styleBtn(3, isHudEnabled, "Suggestions: "..(isHudEnabled and "ON" or "OFF"))
    styleBtn(5, isBufferEnabled, "Key Buffer: "..(isBufferEnabled and "ON" or "OFF"))
    styleBtn(7, isActionInfoEnabled, "Action Info: "..(isActionInfoEnabled and "ON" or "OFF"))
    styleBtn(9, isAerospaceEnabled, "Aerospace Info: "..(isAerospaceEnabled and "ON" or "OFF"))
    styleBtn(11, isMasterEnabled, "Master Power: "..(isMasterEnabled and "ON" or "OFF"))

    local posNames = {"Left (150px)", "Top Right", "Bot Right", "True Center", "Custom"}
    _G.prefPanel[13].fillColor = btnColorAction; _G.prefPanel[13].roundedRectRadii = {xRadius=6,yRadius=6}
    _G.prefPanel[14].text = styledtext.new("Pos: "..posNames[hudPosIndex], {font={name=".AppleSystemUIFontBold", size=16}, color={white=1}, paragraphStyle={alignment="center"}})

    local function styleSmallBtn(idx) _G.prefPanel[idx].fillColor = btnColorAction; _G.prefPanel[idx].roundedRectRadii={xRadius=6,yRadius=6} end
    styleSmallBtn(15); styleSmallBtn(17); styleSmallBtn(20); styleSmallBtn(22)
    _G.prefPanel[19].text = "Title Size: " .. fontTitleSize
    _G.prefPanel[24].text = "Text Size: " .. fontBodySize

    -- Update App Exclusion Row
    local appName, appID = getCurrentAppInfo()
    local isExcluded = excludedApps[appID] == true

    _G.prefPanel[25].fillColor = {red=0.15, green=0.15, blue=0.15, alpha=1} -- Dark grey for text box
    _G.prefPanel[25].roundedRectRadii = {xRadius=6, yRadius=6}
    _G.prefPanel[26].text = styledtext.new("App: " .. appName, {font={name=".AppleSystemUIFont", size=14}, color={white=0.9}, paragraphStyle={alignment="left"}})

    _G.prefPanel[27].fillColor = isExcluded and btnColorOff or btnColorOn -- Red if excluded (to remove), Green if included (to add)
    _G.prefPanel[27].roundedRectRadii = {xRadius=6, yRadius=6}
    local btnText = isExcluded and "Include" or "Exclude"
    _G.prefPanel[28].text = styledtext.new(btnText, {font={name=".AppleSystemUIFontBold", size=14}, color={white=1}, paragraphStyle={alignment="center"}})
end

initPrefs(); updatePrefsVisuals()

-- =================================================
-- INTERACTION WATCHER
-- =================================================
local dragTarget = nil
local dragOffset = {x=0, y=0}

_G.interactionWatcher = eventtap.new({ eventtap.event.types.leftMouseDown, eventtap.event.types.leftMouseDragged, eventtap.event.types.leftMouseUp }, function(e)
    if not isEditMode then return false end
    local type = e:getType(); local p = e:location()

    if type == eventtap.event.types.leftMouseDown then
        local f = _G.prefPanel:frame()
        if p.x >= f.x and p.x <= (f.x + f.w) and p.y >= f.y and p.y <= (f.y + f.h) then
            local relY = (p.y - f.y) / f.h
            local relX = (p.x - f.x) / f.w
            local changed = false

            if relY > 0.11 and relY < 0.18 then isHudEnabled = not isHudEnabled; if not isHudEnabled then _G.hud:hide() else presentHud("Preview", previewMenu.text) end; changed=true
            elseif relY > 0.20 and relY < 0.27 then isBufferEnabled = not isBufferEnabled; if not isBufferEnabled then _G.keyBuffer:hide() else _G.keyBuffer:show() end; changed=true
            elseif relY > 0.29 and relY < 0.36 then isActionInfoEnabled = not isActionInfoEnabled; updateBufferGeometry(); changed=true
            elseif relY > 0.38 and relY < 0.45 then isAerospaceEnabled = not isAerospaceEnabled; changed=true
            elseif relY > 0.47 and relY < 0.54 then isMasterEnabled = not isMasterEnabled; if not isMasterEnabled then _G.hud:hide(); _G.keyBuffer:hide() end; changed=true
            elseif relY > 0.56 and relY < 0.63 then hudPosIndex = hudPosIndex + 1; if hudPosIndex > 5 then hudPosIndex = 1 end; presentHud("Preview Position", previewMenu.text); changed=true
            elseif relY > 0.68 and relY < 0.76 then
                if relX < 0.3 then fontTitleSize = math.max(12, fontTitleSize - 2); changed=true
                elseif relX > 0.7 then fontTitleSize = math.min(60, fontTitleSize + 2); changed=true end
                if changed then presentHud("Preview Title Size", previewMenu.text) end
            elseif relY > 0.78 and relY < 0.86 then
                if relX < 0.3 then fontBodySize = math.max(10, fontBodySize - 1); changed=true
                elseif relX > 0.7 then fontBodySize = math.min(30, fontBodySize + 1); changed=true end
                if changed then presentHud("Preview Text Size", previewMenu.text) end

            -- App Exclusion Toggle (88% - 96%)
            elseif relY > 0.88 and relY < 0.96 and relX > 0.67 then
                local _, appID = getCurrentAppInfo()
                if excludedApps[appID] then excludedApps[appID] = nil else excludedApps[appID] = true end
                changed = true
            end

            if changed then timer.doAfter(0, function() updatePrefsVisuals() end) end
            return true
        end

        local hF = _G.hud:frame()
        if _G.hud:isShowing() and p.x >= hF.x and p.x <= (hF.x + hF.w) and p.y >= hF.y and p.y <= (hF.y + hF.h) then
            dragTarget = "hud"; dragOffset = {x = p.x - hF.x, y = p.y - hF.y}; hudPosIndex = 5; updatePrefsVisuals(); return true
        end

        local bF = _G.keyBuffer:frame()
        if _G.keyBuffer:isShowing() and p.x >= bF.x and p.x <= (bF.x + bF.w) and p.y >= bF.y and p.y <= (bF.y + bF.h) then
            dragTarget = "buffer"; dragOffset = {x = p.x - bF.x, y = p.y - bF.y}; return true
        end

        _G.prefPanel:hide(); _G.hud:hide(); isEditMode=false; updateDragHandles(); resetToNormal(); return false

    elseif type == eventtap.event.types.leftMouseDragged then
        if dragTarget == "hud" then
            local newX, newY = p.x - dragOffset.x, p.y - dragOffset.y
            _G.hud:frame({x=newX, y=newY, w=_G.hud:frame().w, h=_G.hud:frame().h})
            customHudX, customHudY = newX, newY; return true
        elseif dragTarget == "buffer" then
            local newX, newY = p.x - dragOffset.x, p.y - dragOffset.y
            _G.keyBuffer:frame({x=newX, y=newY, w=_G.keyBuffer:frame().w, h=_G.keyBuffer:frame().h})
            bufferX, bufferY = newX, newY; return true
        end
    elseif type == eventtap.event.types.leftMouseUp then dragTarget = nil end
    return false
end):start()

hotkey.bind({"cmd", "alt"}, "P", function()
    if _G.prefPanel:isShowing() then _G.prefPanel:hide(); isEditMode = false; updateDragHandles(); resetToNormal()
    else updatePrefsVisuals(); isEditMode = true; _G.prefPanel:show(); _G.keyBuffer:show(); presentHud("Drag Me", previewMenu.text); updateDragHandles() end
end)

-- =================================================
-- MAIN WATCHERS
-- =================================================
_G.appWatcher = hs.application.watcher.new(function(appName, eventType, app)
    if eventType == hs.application.watcher.activated then
        if excludedApps[app:bundleID()] then
            _G.hud:hide()
            _G.keyBuffer:hide()
        else
            if isBufferEnabled then _G.keyBuffer:show() end
        end
        if _G.prefPanel:isShowing() then updatePrefsVisuals() end -- Update toggle button text
    end
end):start()

_G.modWatcher = eventtap.new({eventtap.event.types.flagsChanged}, function(e)
    if not isMasterEnabled or isEditMode or currentState == VIM_STATE.INSERT or isCurrentAppDisabled() then return false end
    local flags = e:getFlags()

    if flags.alt and isAerospaceEnabled then
        presentHud(modifierMenus.alt.title, modifierMenus.alt.text, colorAccent)
        if hudTimer then hudTimer:stop() end
    elseif flags.shift then
        presentHud(modifierMenus.shift.title, modifierMenus.shift.text, colorAccent)
        if hudTimer then hudTimer:stop() end
    elseif flags.ctrl then
        presentHud(modifierMenus.ctrl.title, modifierMenus.ctrl.text, colorAccent)
        if hudTimer then hudTimer:stop() end
    else
        if _G.hud:isShowing() then
            local currentTitle = _G.hud[2].text:getString()
            if currentTitle == modifierMenus.shift.title or currentTitle == modifierMenus.ctrl.title or currentTitle == modifierMenus.alt.title then
                _G.hud:hide()
            end
        end
    end
    return false
end):start()

_G.keyWatcher = eventtap.new({eventtap.event.types.keyDown}, function(e)
    local flags = e:getFlags(); local keyCode = e:getKeyCode(); local keyName = keycodes.map[keyCode]

    -- 1. GLOBAL ESCAPE HANDLER
    if keyName == "escape" or (flags.ctrl and keyName == "[") then
        if _G.prefPanel:isShowing() then
            _G.prefPanel:hide(); isEditMode=false; updateDragHandles(); resetToNormal()
            return true
        end
        if _G.hud:isShowing() then resetToNormal(); return true end
        if isHudEnabled and not isEditMode and not isCurrentAppDisabled() then
            resetToNormal(); presentHud(indexMenu.title, indexMenu.text, colorTitle); return true
        end
        return false
    end

    if not isMasterEnabled or isEditMode or isCurrentAppDisabled() then return false end
    local char = e:getCharacters()

    if isAerospaceEnabled and flags.alt then
         local cleanKey = keyName
         if flags.shift then cleanKey = "⇧"..cleanKey end
         local displayStr = "⌥"..cleanKey
         addToBuffer(displayStr)
         return false
    end

    if currentState == VIM_STATE.INSERT then return false end
    local bufferChar = char; if keyName=="space" then bufferChar="␣" elseif keyName=="return" then bufferChar="↵" elseif keyName=="backspace" then bufferChar="⌫" elseif flags.ctrl then bufferChar="^"..(keyName or "?") end

    if insertTriggers[bufferChar] then currentState = VIM_STATE.INSERT; addToBuffer(bufferChar); return false end
    if bufferChar == "c" and currentState == VIM_STATE.NORMAL then currentState = VIM_STATE.PENDING_CHANGE; addToBuffer("c"); if isHudEnabled then presentHud(triggers.c.title, triggers.c.text, colorAccent) end; return false end
    if currentState == VIM_STATE.PENDING_CHANGE then currentState = VIM_STATE.INSERT; addToBuffer(bufferChar); _G.hud:hide(); return false end
    if visualTriggers[bufferChar] then currentState = VIM_STATE.VISUAL; addToBuffer(bufferChar); if isHudEnabled then local vMenu = triggers[bufferChar] or triggers.v; presentHud(vMenu.title, vMenu.text, colorTitle) end; return false end

    if currentState == VIM_STATE.NORMAL or currentState == VIM_STATE.VISUAL then
        if bufferChar and #bufferChar > 0 and #bufferChar < 5 then addToBuffer(bufferChar) end
        if isHudEnabled then
            local lookup = bufferChar; if flags.ctrl and keyName then lookup = "^"..keyName end
            if triggers[lookup] then presentHud(triggers[lookup].title, triggers[lookup].text); if hudTimer then hudTimer:stop() end; hudTimer = timer.doAfter(displayTime, function() _G.hud:hide() end) end
        end
    end
    return false
end):start()

hs.alert.show("Vim HUD: App Exclusion Ready")
updateBufferGeometry(); updateStateDisplay(); if isBufferEnabled then _G.keyBuffer:show() end