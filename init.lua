-- =================================================
-- VIMUALIZER: ROBUST SAVING & LOADING
-- =================================================

-- 1. CLEANUP
if _G.modWatcher then _G.modWatcher:stop() end
if _G.keyWatcher then _G.keyWatcher:stop() end
if _G.appWatcher then _G.appWatcher:stop() end
if _G.interactionWatcher then _G.interactionWatcher:stop() end
if _G.hud then _G.hud:delete() end
if _G.keyBuffer then _G.keyBuffer:delete() end
if _G.prefPanel then _G.prefPanel:delete() end
if _G.exclPanel then _G.exclPanel:delete() end

local canvas = require("hs.canvas")
local eventtap = require("hs.eventtap")
local timer = require("hs.timer")
local hotkey = require("hs.hotkey")
local keycodes = require("hs.keycodes")
local styledtext = require("hs.styledtext")
local drawing = require("hs.drawing")
local window = require("hs.window")
local application = require("hs.application")
local json = require("hs.json")
local alert = require("hs.alert")
local fs = require("hs.fs")

-- ================= CONFIGURATION =================

local isMasterEnabled = true
local isHudEnabled = true
local isBufferEnabled = true
local isActionInfoEnabled = true
local isAerospaceEnabled = false
local isEscapeMenuEnabled = true
local isMacroEnabled = true
local isEditMode = false

-- HUD Text Alignment ("left", "center", "right")
local hudTextAlignment = "center"

-- App Exclusion List (Bundle IDs)
local excludedApps = {
    ["com.apple.loginwindow"] = true,
    ["com.apple.ScreenSaver.Engine"] = true
}

-- Visual Settings
local fontTitleSize = 32
local fontBodySize = 20
local hudPosIndex = 1
local customHudX, customHudY = 100, 100

local maxHudWidth = 700
local minHudWidth = 350
local hudPadding = 30
local hudBgColor = { red=0.1, green=0.1, blue=0.1, alpha=0.98 }
local hudStrokeColor = { white=1, alpha=0.1 }
local displayTime = 8.0

-- Colors
local colorTitle = { red=1, green=0.9, blue=0.4, alpha=1 }
local colorKey = { red=0.6, green=0.8, blue=1, alpha=1 }
local colorDesc = { white=0.9, alpha=1 }
local colorHeader = { white=0.6, alpha=1 }
local colorAccent = { red=1, green=0.4, blue=0.4, alpha=1 }
local colorInfo = { white=1, alpha=0.95 }
local colorDrag = { red=0.2, green=0.8, blue=0.2, alpha=0.9 }
local btnColorAction = {red=0.2, green=0.4, blue=0.8, alpha=1}
local btnColorSave = {red=0.2, green=0.6, blue=0.2, alpha=1}
local btnColorExclude = {red=0.8, green=0.2, blue=0.2, alpha=1}
local panelColor = { red=0.1, green=0.1, blue=0.1, alpha=0.98 }
local btnColorOn = {red=0.2,green=0.6,blue=0.2,alpha=1}
local btnColorOff = {red=0.6,green=0.2,blue=0.2,alpha=1}
local colorRec = { red=1, green=0.2, blue=0.2, alpha=1 }

local screen = hs.screen.mainScreen():frame()

-- HUD / BUFFER Geometry
local bufferMaxLen = 12
local bufferW, bufferH = 550, 85
local bufferX, bufferY = screen.w - bufferW - 30, screen.h - bufferH - 30
local bufferBgColor = { red=0.15, green=0.15, blue=0.15, alpha=0.95 }
local bufferTxtColor = { red=0.6, green=1, blue=0.6, alpha=1 }

-- MAIN PREFS GEOMETRY
local prefW, prefH = 450, 850
local prefX, prefY = (screen.w - prefW) / 2, (screen.h - prefH) / 2

-- EXCLUSION LIST GEOMETRY
local exclW, exclH = 500, 600
local exclX, exclY = prefX + prefW + 20, prefY

-- =================================================
-- PERSISTENCE LOGIC
-- =================================================
local homeDir = os.getenv("HOME")
local saveDir = homeDir .. "/Documents/Vimualizer"
local settingsFilePath = saveDir .. "/settings.json"

local function ensureDirectoryExists()
    local attrs = fs.attributes(saveDir)
    if not attrs then fs.mkdir(saveDir) end
end

local function saveSettings()
    ensureDirectoryExists()
    local cleanExclusions = {}
    for k, v in pairs(excludedApps) do if v == true then cleanExclusions[k] = true end end

    local settings = {
        isMasterEnabled = isMasterEnabled,
        isHudEnabled = isHudEnabled,
        isBufferEnabled = isBufferEnabled,
        isActionInfoEnabled = isActionInfoEnabled,
        isAerospaceEnabled = isAerospaceEnabled,
        isEscapeMenuEnabled = isEscapeMenuEnabled,
        isMacroEnabled = isMacroEnabled,
        hudTextAlignment = hudTextAlignment, -- SAVE ALIGNMENT
        excludedApps = cleanExclusions,
        fontTitleSize = fontTitleSize,
        fontBodySize = fontBodySize,
        hudPosIndex = hudPosIndex,
        customHudX = customHudX,
        customHudY = customHudY,
        bufferX = bufferX,
        bufferY = bufferY
    }
    json.write(settings, settingsFilePath, true, true)
end

local function loadSettings()
    local settings = json.read(settingsFilePath)
    if settings then
        if settings.isMasterEnabled ~= nil then isMasterEnabled = settings.isMasterEnabled end
        if settings.isHudEnabled ~= nil then isHudEnabled = settings.isHudEnabled end
        if settings.isBufferEnabled ~= nil then isBufferEnabled = settings.isBufferEnabled end
        if settings.isActionInfoEnabled ~= nil then isActionInfoEnabled = settings.isActionInfoEnabled end
        if settings.isAerospaceEnabled ~= nil then isAerospaceEnabled = settings.isAerospaceEnabled end
        if settings.isEscapeMenuEnabled ~= nil then isEscapeMenuEnabled = settings.isEscapeMenuEnabled end
        if settings.isMacroEnabled ~= nil then isMacroEnabled = settings.isMacroEnabled end
        if settings.hudTextAlignment ~= nil then hudTextAlignment = settings.hudTextAlignment end -- LOAD ALIGNMENT
        if settings.excludedApps then excludedApps = settings.excludedApps end
        if settings.fontTitleSize then fontTitleSize = tonumber(settings.fontTitleSize) end
        if settings.fontBodySize then fontBodySize = tonumber(settings.fontBodySize) end
        if settings.hudPosIndex then hudPosIndex = tonumber(settings.hudPosIndex) end
        if settings.customHudX then customHudX = tonumber(settings.customHudX) end
        if settings.customHudY then customHudY = tonumber(settings.customHudY) end
        if settings.bufferX then bufferX = tonumber(settings.bufferX) end
        if settings.bufferY then bufferY = tonumber(settings.bufferY) end
    end
end

loadSettings()

-- =================================================
-- DATA & HELPERS
-- =================================================
local VIM_STATE = { NORMAL="NORMAL", INSERT="INSERT", VISUAL="VISUAL", PENDING_CHANGE="PENDING_CHANGE" }
local currentState = VIM_STATE.NORMAL
local keyHistory = {}
local recordingRegister = nil
local pendingMacroStart = false

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

-- VIM DEFINITIONS
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

-- MENUS
local insertTriggers = { ["i"]=true, ["I"]=true, ["a"]=true, ["A"]=true, ["o"]=true, ["O"]=true, ["s"]=true, ["S"]=true, ["C"]=true }
local visualTriggers = { ["v"]=true, ["V"]=true, ["^v"]=true }

local indexMenu = { title = "Vim Entry Points", text = "-- Operators --\nd : Delete Actions\nc : Change Actions\ny : Yank (Copy)\np : Paste\n-- Modes --\nv : Visual Char Mode\nV : Visual Line Mode\n^v : Visual Block Mode\n-- Macros --\nq : Record Macro\n-- Navigation --\ng : Go / Extended\nz : Folds / View\nm : Marks\n/ : Search" }
local previewMenu = { title = "Visual Preview", text = "-- Section Header --\nkey : description text\ncmd : another command\n-- Another Section --\ntest : checking font size" }

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
    q = { title = "Macros (q)", text = "q{a-z} : Record to register\nq : Stop recording\n@{a-z} : Replay macro\n@@ : Replay last macro" },
    ["^w"] = { title = "Window (Ctrl+w ...)", text = "-- Split --\nv/s : Vert/Horiz Split\n-- Move --\nh/j/k/l : Move Focus\nw : Cycle\n-- Actions --\nc : Close Window\n= : Equalize sizes" },
}

local function getSequenceDescription()
    local len = #keyHistory
    if len == 0 then return "" end
    local k1 = keyHistory[len]
    local k2 = (len >= 2) and keyHistory[len-1] or nil
    local k3 = (len >= 3) and keyHistory[len-2] or nil

    if k3 and k2 and k1 then
        if vimOps[k3] and vimContext[k2] then
            local objName = vimObjects[k1] or ("'" .. k1 .. "'")
            return vimOps[k3] .. " " .. vimContext[k2] .. " " .. objName
        end
    end
    if k2 and k1 then
        if argMotions[k2] then return argMotions[k2] .. " '" .. k1 .. "'" end
        if vimOps[k2] and vimContext[k1] then return vimOps[k2] .. " " .. vimContext[k1] .. "..." end
        if vimOps[k2] and k2 == k1 then return vimOps[k2] .. " Line" end
    end
    if k1 and vimOps[k1] then return vimOps[k1] .. "..." end
    local desc = simpleActions[k1] or vimMotions[k1]
    if not desc and #k1 > 1 and k1:sub(1,1) == "^" then desc = "Ctrl + " .. k1:sub(2) end
    return desc or ""
end

-- FORMAT HUD TEXT: DYNAMIC ALIGNMENT
local function formatHudBody(rawText)
    local finalStyled = styledtext.new("")
    -- Use global hudTextAlignment variable
    local baseStyle = { font={name=".AppleSystemUIFont", size=fontBodySize}, color=colorDesc, paragraphStyle={lineSpacing=6, alignment=hudTextAlignment} }
    local keyStyle =  { font={name=".AppleSystemUIFontBold", size=fontBodySize}, color=colorKey, paragraphStyle={lineSpacing=6, alignment=hudTextAlignment} }
    local headerStyle = { font={name=".AppleSystemUIFontBold", size=fontBodySize-2}, color=colorHeader, paragraphStyle={lineSpacing=6, alignment=hudTextAlignment} }

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
-- UI INITIALIZATION
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
        _G.keyBuffer[4].action = "stroke"; _G.keyBuffer[4].frame = {x="25%", y="62%", w="70%", h="30%"}
    else
        _G.keyBuffer[3].frame = {x="25%", y="15%", w="70%", h="70%"}
        _G.keyBuffer[4].action = "skip"
    end
end

local function updateStateDisplay()
    local stateText, color = currentState, colorTitle
    if recordingRegister then stateText = "REC @" .. recordingRegister; color = colorRec
    elseif currentState == VIM_STATE.INSERT then color = {red=0.4, green=1, blue=0.4, alpha=1}
    elseif currentState == VIM_STATE.VISUAL then color = {red=1, green=0.6, blue=0.2, alpha=1}
    elseif currentState == VIM_STATE.PENDING_CHANGE then stateText = "PENDING"; color = colorAccent end
    _G.keyBuffer[2].text = stateText; _G.keyBuffer[2].textColor = color
end

local function addToBuffer(str)
    table.insert(keyHistory, str)
    if #keyHistory > bufferMaxLen then table.remove(keyHistory, 1) end
    _G.keyBuffer[3].text = table.concat(keyHistory, " ")
    if isActionInfoEnabled then _G.keyBuffer[4].text = getSequenceDescription() end
    updateStateDisplay(); if isBufferEnabled then _G.keyBuffer:show() end
end

local function resetToNormal()
    currentState = VIM_STATE.NORMAL; pendingMacroStart = false; keyHistory = {};
    _G.keyBuffer[3].text = ""; _G.keyBuffer[4].text = "";
    updateStateDisplay(); _G.hud:hide()
end

local function updateDragHandles()
    local action = isEditMode and "fill" or "skip"
    _G.hud[4].action = action; _G.hud[5].action = action; _G.hud[1].strokeColor = isEditMode and colorDrag or hudStrokeColor
    _G.keyBuffer[5].action = action; _G.keyBuffer[6].action = action; _G.keyBuffer[1].strokeColor = isEditMode and colorDrag or {white=1,alpha=0.2}
    local level = isEditMode and hs.canvas.windowLevels.floating or hs.canvas.windowLevels.overlay
    _G.hud:level(level); _G.keyBuffer:level(level)
    updateBufferGeometry()
end

local function presentHud(title, rawBodyText, titleOverrideColor)
    -- Use global hudTextAlignment variable
    local styledTitle = styledtext.new(title, { font={name=".AppleSystemUIFontBold", size=fontTitleSize}, color=titleOverrideColor or colorTitle, paragraphStyle={alignment=hudTextAlignment} })
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
    if hudPosIndex == 1 then newX, newY = 150, (screen.h - newH) / 2
    elseif hudPosIndex == 2 then newX, newY = screen.w - newW - 50, 50
    elseif hudPosIndex == 3 then newX, newY = screen.w - newW - 50, screen.h - newH - 50
    elseif hudPosIndex == 4 then newX, newY = (screen.w - newW) / 2, (screen.h - newH) / 2
    elseif hudPosIndex == 5 then newX, newY = customHudX, customHudY end

    _G.hud:frame({x=newX, y=newY, w=newW, h=newH})
    _G.hud[2].text = styledTitle; _G.hud[2].frame = {x=hudPadding,y=hudPadding,w=newW-(hudPadding*2),h=titleH};
    _G.hud[3].text = styledBody; _G.hud[3].frame = {x=hudPadding,y=hudPadding+titleH+spacer,w=newW-(hudPadding*2),h=bodyH};
    updateDragHandles()
    _G.hud:show()
end

-- =================================================
-- PREFERENCES PANELS (MAIN & EXCLUSION)
-- =================================================
_G.prefPanel = canvas.new({x=prefX, y=prefY, w=prefW, h=prefH}):level(hs.canvas.windowLevels.floating)
_G.exclPanel = canvas.new({x=exclX, y=exclY, w=exclW, h=exclH}):level(hs.canvas.windowLevels.floating)

local sortedExclusions = {}

-- 1. INIT MAIN PREFS (Added Alignment Button)
local function initPrefs()
    _G.prefPanel[1] = { type="rectangle", action="fill", fillColor=panelColor, roundedRectRadii={xRadius=12, yRadius=12}, strokeColor=hudStrokeColor, strokeWidth=2 }
    _G.prefPanel[2] = { type="text", text="Vimualizer Config", textColor=colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="3%",w="100%",h="8%"} }

    -- 7 Full Width Buttons
    for i=0,6 do
        local yPos = 10 + (i * 7)
        _G.prefPanel[3 + (i*2)] = { type="rectangle", action="fill", frame={x="10%",y=yPos.."%",w="80%",h="6%"} }
        _G.prefPanel[4 + (i*2)] = { type="text", textAlignment="center", frame={x="10%",y=(yPos+1.5).."%",w="80%",h="6%"} }
    end

    -- Split Row for Position / Alignment
    local splitY = 10 + (7 * 7) -- ~59%
    -- Left: Position (Index 17, 18)
    _G.prefPanel[17] = { type="rectangle", action="fill", frame={x="10%",y=splitY.."%",w="38%",h="6%"} }
    _G.prefPanel[18] = { type="text", textAlignment="center", frame={x="10%",y=(splitY+1.5).."%",w="38%",h="6%"} }
    -- Right: Alignment (Index 19, 20)
    _G.prefPanel[19] = { type="rectangle", action="fill", frame={x="52%",y=splitY.."%",w="38%",h="6%"} }
    _G.prefPanel[20] = { type="text", textAlignment="center", frame={x="52%",y=(splitY+1.5).."%",w="38%",h="6%"} }

    local yStart = 68
    -- Size Controls (Title) - Indices shifted +2 due to extra button pair
    _G.prefPanel[21] = { type="rectangle", action="fill", frame={x="10%",y=yStart.."%",w="20%",h="6%"} }
    _G.prefPanel[22] = { type="text", text="-", textColor={white=1}, textSize=20, textAlignment="center", frame={x="10%",y=(yStart+0.5).."%",w="20%",h="6%"} }
    _G.prefPanel[23] = { type="rectangle", action="fill", frame={x="70%",y=yStart.."%",w="20%",h="6%"} }
    _G.prefPanel[24] = { type="text", text="+", textColor={white=1}, textSize=20, textAlignment="center", frame={x="70%",y=(yStart+0.5).."%",w="20%",h="6%"} }
    _G.prefPanel[25] = { type="text", text="Title Size", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%",y=(yStart+1).."%",w="40%",h="6%"} }

    yStart = 76
    -- Size Controls (Text)
    _G.prefPanel[26] = { type="rectangle", action="fill", frame={x="10%",y=yStart.."%",w="20%",h="6%"} }
    _G.prefPanel[27] = { type="text", text="-", textColor={white=1}, textSize=20, textAlignment="center", frame={x="10%",y=(yStart+0.5).."%",w="20%",h="6%"} }
    _G.prefPanel[28] = { type="rectangle", action="fill", frame={x="70%",y=yStart.."%",w="20%",h="6%"} }
    _G.prefPanel[29] = { type="text", text="+", textColor={white=1}, textSize=20, textAlignment="center", frame={x="70%",y=(yStart+0.5).."%",w="20%",h="6%"} }
    _G.prefPanel[30] = { type="text", text="Text Size", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%",y=(yStart+1).."%",w="40%",h="6%"} }

    -- App Exclusion
    local yApp = 85
    _G.prefPanel[31] = { type="rectangle", action="fill", frame={x="10%",y=yApp.."%",w="55%",h="6%"} }
    _G.prefPanel[32] = { type="text", text="App Name", textColor={white=1}, textSize=14, textAlignment="center", frame={x="10%",y=(yApp+0.5).."%",w="55%",h="6%"} }
    _G.prefPanel[33] = { type="rectangle", action="fill", frame={x="67%",y=yApp.."%",w="23%",h="6%"} }
    _G.prefPanel[34] = { type="text", text="Toggle", textColor={white=1}, textSize=14, textAlignment="center", frame={x="67%",y=(yApp+0.5).."%",w="23%",h="6%"} }

    -- Bottom Buttons
    local yBtn = 93
    _G.prefPanel[35] = { type="rectangle", action="fill", fillColor=btnColorSave, frame={x="10%",y=yBtn.."%",w="35%",h="5%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[36] = { type="text", text="Save", textColor={white=1}, textSize=15, textAlignment="center", frame={x="10%",y=(yBtn+0.5).."%",w="35%",h="5%"} }

    _G.prefPanel[37] = { type="rectangle", action="fill", fillColor=btnColorAction, frame={x="50%",y=yBtn.."%",w="40%",h="5%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[38] = { type="text", text="Exclusions >>", textColor={white=1}, textSize=15, textAlignment="center", frame={x="50%",y=(yBtn+0.5).."%",w="40%",h="5%"} }
end

local function updatePrefsVisuals()
    local function styleBtn(idx, enabled, txt)
        _G.prefPanel[idx].fillColor = (enabled and btnColorOn or btnColorOff)
        _G.prefPanel[idx].roundedRectRadii = {xRadius=6, yRadius=6}
        _G.prefPanel[idx+1].text = styledtext.new(txt, {font={name=".AppleSystemUIFontBold", size=16}, color={white=1}, paragraphStyle={alignment="center"}})
    end

    styleBtn(3, isMasterEnabled, "Master Power: "..(isMasterEnabled and "ON" or "OFF"))
    styleBtn(5, isHudEnabled, "Suggestions: "..(isHudEnabled and "ON" or "OFF"))
    styleBtn(7, isBufferEnabled, "Key Buffer: "..(isBufferEnabled and "ON" or "OFF"))
    styleBtn(9, isActionInfoEnabled, "Action Info: "..(isActionInfoEnabled and "ON" or "OFF"))
    styleBtn(11, isEscapeMenuEnabled, "Entry Menu: "..(isEscapeMenuEnabled and "ON" or "OFF"))
    styleBtn(13, isMacroEnabled, "Macro Rec: "..(isMacroEnabled and "ON" or "OFF"))
    styleBtn(15, isAerospaceEnabled, "Aerospace Info: "..(isAerospaceEnabled and "ON" or "OFF"))

    -- Position Button (Left)
    local posNames = {"Left", "TopRight", "BotRight", "Center", "Custom"}
    _G.prefPanel[17].fillColor = btnColorAction; _G.prefPanel[17].roundedRectRadii = {xRadius=6,yRadius=6}
    _G.prefPanel[18].text = styledtext.new("Pos: "..posNames[hudPosIndex], {font={name=".AppleSystemUIFontBold", size=16}, color={white=1}, paragraphStyle={alignment="center"}})

    -- Alignment Button (Right)
    local alignLabel = "Align: " .. (hudTextAlignment:gsub("^%l", string.upper))
    _G.prefPanel[19].fillColor = btnColorAction; _G.prefPanel[19].roundedRectRadii = {xRadius=6,yRadius=6}
    _G.prefPanel[20].text = styledtext.new(alignLabel, {font={name=".AppleSystemUIFontBold", size=16}, color={white=1}, paragraphStyle={alignment="center"}})

    local function styleSmallBtn(idx) _G.prefPanel[idx].fillColor = btnColorAction; _G.prefPanel[idx].roundedRectRadii={xRadius=6,yRadius=6} end
    styleSmallBtn(21); styleSmallBtn(23); styleSmallBtn(26); styleSmallBtn(28)
    _G.prefPanel[25].text = "Title Size: " .. fontTitleSize
    _G.prefPanel[30].text = "Text Size: " .. fontBodySize

    local appName, appID = getCurrentAppInfo()
    local isExcluded = excludedApps[appID] == true
    _G.prefPanel[31].fillColor = {red=0.15, green=0.15, blue=0.15, alpha=1}; _G.prefPanel[31].roundedRectRadii = {xRadius=6,yRadius=6}
    _G.prefPanel[32].text = styledtext.new("App: "..appName, {font={name=".AppleSystemUIFont", size=14}, color={white=0.9}, paragraphStyle={alignment="center"}})
    _G.prefPanel[33].fillColor = isExcluded and btnColorOff or btnColorOn; _G.prefPanel[33].roundedRectRadii = {xRadius=6,yRadius=6}
    _G.prefPanel[34].text = styledtext.new(isExcluded and "Include" or "Exclude", {font={name=".AppleSystemUIFontBold", size=14}, color={white=1}, paragraphStyle={alignment="center"}})
end

-- 2. EXCLUSION LIST PANEL
local function updateExclusionPanel()
    while #_G.exclPanel > 0 do _G.exclPanel[#_G.exclPanel] = nil end

    _G.exclPanel[1] = { type="rectangle", action="fill", fillColor=panelColor, roundedRectRadii={xRadius=12, yRadius=12}, strokeColor=hudStrokeColor, strokeWidth=2 }
    _G.exclPanel[2] = { type="text", text="Excluded Apps", textColor=colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="2%",w="100%",h="8%"} }

    sortedExclusions = {}
    for id, _ in pairs(excludedApps) do table.insert(sortedExclusions, id) end
    table.sort(sortedExclusions)

    local rowH = 35
    local startY = 60

    for i, bundleId in ipairs(sortedExclusions) do
        local yVal = startY + ((i-1) * (rowH + 5))
        _G.exclPanel[#_G.exclPanel+1] = { type="rectangle", action="fill", fillColor={red=0.2,green=0.2,blue=0.2,alpha=1}, frame={x="5%", y=yVal, w="80%", h=rowH}, roundedRectRadii={xRadius=4,yRadius=4} }
        _G.exclPanel[#_G.exclPanel+1] = { type="text", text=bundleId, textColor={white=0.9}, textSize=13, textAlignment="center", frame={x="7%", y=yVal+7, w="75%", h=rowH} }
        _G.exclPanel[#_G.exclPanel+1] = { type="rectangle", action="fill", fillColor=btnColorExclude, frame={x="87%", y=yVal, w="8%", h=rowH}, roundedRectRadii={xRadius=4,yRadius=4} }
        _G.exclPanel[#_G.exclPanel+1] = { type="text", text="X", textColor={white=1}, textSize=14, textAlignment="center", frame={x="87%", y=yVal+6, w="8%", h=rowH} }
    end

    _G.exclPanel[#_G.exclPanel+1] = { type="rectangle", action="fill", fillColor=btnColorAction, frame={x="30%", y="90%", w="40%", h="7%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.exclPanel[#_G.exclPanel+1] = { type="text", text="Close List", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%", y="91.5%", w="40%", h="7%"} }
end

initPrefs(); updatePrefsVisuals()

-- =================================================
-- INTERACTION WATCHER (Adjusted for Split Row)
-- =================================================
local dragTarget = nil
local dragOffset = {x=0, y=0}

_G.interactionWatcher = eventtap.new({ eventtap.event.types.leftMouseDown, eventtap.event.types.leftMouseDragged, eventtap.event.types.leftMouseUp }, function(e)
    if not isEditMode then return false end
    local p = e:location(); local type = e:getType()

    if type == eventtap.event.types.leftMouseDown then
        local f = _G.prefPanel:frame()
        if _G.prefPanel:isShowing() and p.x >= f.x and p.x <= (f.x + f.w) and p.y >= f.y and p.y <= (f.y + f.h) then
            local relY = (p.y - f.y) / f.h; local relX = (p.x - f.x) / f.w; local changed = false

            -- 1. Master Power (10% - 16%)
            if relY > 0.10 and relY < 0.16 then isMasterEnabled = not isMasterEnabled; changed=true
            -- 2. Suggestions (17% - 23%)
            elseif relY > 0.17 and relY < 0.23 then isHudEnabled = not isHudEnabled; changed=true
            -- 3. Key Buffer (24% - 30%)
            elseif relY > 0.24 and relY < 0.30 then isBufferEnabled = not isBufferEnabled; if not isBufferEnabled then _G.keyBuffer:hide() else _G.keyBuffer:show() end; changed=true
            -- 4. Action Info (31% - 37%)
            elseif relY > 0.31 and relY < 0.37 then isActionInfoEnabled = not isActionInfoEnabled; updateBufferGeometry(); changed=true
            -- 5. Entry Menu (38% - 44%)
            elseif relY > 0.38 and relY < 0.44 then isEscapeMenuEnabled = not isEscapeMenuEnabled; changed=true
            -- 6. Macro Rec (45% - 51%)
            elseif relY > 0.45 and relY < 0.51 then isMacroEnabled = not isMacroEnabled; changed=true
            -- 7. Aerospace (52% - 58%)
            elseif relY > 0.52 and relY < 0.58 then isAerospaceEnabled = not isAerospaceEnabled; changed=true

            -- 8. Position OR Alignment (59% - 65%)
            elseif relY > 0.59 and relY < 0.65 then
                if relX < 0.5 then
                    -- Position Clicked
                    hudPosIndex = hudPosIndex + 1; if hudPosIndex > 5 then hudPosIndex = 1 end
                else
                    -- Alignment Clicked
                    if hudTextAlignment == "left" then hudTextAlignment = "center"
                    elseif hudTextAlignment == "center" then hudTextAlignment = "right"
                    else hudTextAlignment = "left" end
                    presentHud("Alignment: " .. hudTextAlignment, previewMenu.text)
                end
                changed=true

            -- Sizing Controls (Start ~68%)
            elseif relY > 0.68 and relY < 0.74 then
                if relX < 0.3 then fontTitleSize=math.max(10, fontTitleSize-2) else fontTitleSize=math.min(60, fontTitleSize+2) end
                changed=true; saveSettings(); presentHud("Title Size: "..fontTitleSize, previewMenu.text)
            elseif relY > 0.76 and relY < 0.82 then
                if relX < 0.3 then fontBodySize=math.max(8, fontBodySize-1) else fontBodySize=math.min(40, fontBodySize+1) end
                changed=true; saveSettings(); presentHud("Text Size: "..fontBodySize, previewMenu.text)

            -- App Toggle (Start ~85%)
            elseif relY > 0.85 and relY < 0.91 and relX > 0.67 then
                local _, appID = getCurrentAppInfo()
                if excludedApps[appID] then excludedApps[appID] = nil; if isBufferEnabled then _G.keyBuffer:show() end
                else excludedApps[appID] = true; _G.keyBuffer:hide(); _G.hud:hide() end
                changed=true; if _G.exclPanel:isShowing() then updateExclusionPanel() end

            -- Bottom Buttons (Start ~93%)
            elseif relY > 0.93 then
                if relX < 0.45 then saveSettings(); alert.show("Vimualizer Settings Saved", 1)
                elseif relX > 0.50 then updateExclusionPanel(); _G.exclPanel:show() end
            end

            if changed then saveSettings(); timer.doAfter(0, function() updatePrefsVisuals() end) end
            return true
        end

        local eF = _G.exclPanel:frame()
        if _G.exclPanel:isShowing() and p.x >= eF.x and p.x <= (eF.x + eF.w) and p.y >= eF.y and p.y <= (eF.y + eF.h) then
            local relY = (p.y - eF.y) / eF.h
            if relY > 0.90 then _G.exclPanel:hide(); return true end
            local rowH = 40; local listStartY = eF.y + 60; local relativeClickY = p.y - listStartY
            if relativeClickY > 0 then
                local rowIndex = math.floor(relativeClickY / rowH) + 1
                local relX = (p.x - eF.x) / eF.w
                if relX > 0.85 and sortedExclusions[rowIndex] then
                    excludedApps[sortedExclusions[rowIndex]] = nil
                    saveSettings(); updateExclusionPanel(); updatePrefsVisuals()
                end
            end
            return true
        end

        local hF = _G.hud:frame()
        if _G.hud:isShowing() and p.x >= hF.x and p.x <= (hF.x + hF.w) and p.y >= hF.y and p.y <= (hF.y + hF.h) then
            dragTarget="hud"; dragOffset={x=p.x-hF.x, y=p.y-hF.y}; hudPosIndex=5; updatePrefsVisuals(); return true
        end
        local bF = _G.keyBuffer:frame()
        if _G.keyBuffer:isShowing() and p.x >= bF.x and p.x <= (bF.x + bF.w) and p.y >= bF.y and p.y <= (bF.y + bF.h) then
            dragTarget="buffer"; dragOffset={x=p.x-bF.x, y=p.y-bF.y}; return true
        end
        _G.prefPanel:hide(); _G.exclPanel:hide(); _G.hud:hide(); isEditMode=false; updateDragHandles(); resetToNormal(); return false
    elseif type == eventtap.event.types.leftMouseDragged then
        if dragTarget == "hud" then
            local newX, newY = p.x - dragOffset.x, p.y - dragOffset.y
            _G.hud:frame({x=newX, y=newY, w=_G.hud:frame().w, h=_G.hud:frame().h}); customHudX, customHudY = newX, newY; return true
        elseif dragTarget == "buffer" then
            local newX, newY = p.x - dragOffset.x, p.y - dragOffset.y
            _G.keyBuffer:frame({x=newX, y=newY, w=_G.keyBuffer:frame().w, h=_G.keyBuffer:frame().h}); bufferX, bufferY = newX, newY; return true
        end
    elseif type == eventtap.event.types.leftMouseUp then
        if dragTarget then saveSettings() end; dragTarget = nil
    end
    return false
end):start()

hotkey.bind({"cmd", "alt"}, "P", function()
    if _G.prefPanel:isShowing() then _G.prefPanel:hide(); _G.exclPanel:hide(); isEditMode = false; updateDragHandles(); resetToNormal()
    else updatePrefsVisuals(); isEditMode = true; _G.prefPanel:show(); _G.keyBuffer:show(); presentHud("Preview", previewMenu.text); updateDragHandles() end
end)

-- =================================================
-- MAIN LOGIC
-- =================================================
_G.appWatcher = hs.application.watcher.new(function(appName, eventType, app)
    if eventType == hs.application.watcher.activated then
        if excludedApps[app:bundleID()] then _G.hud:hide(); _G.keyBuffer:hide()
        else if isBufferEnabled then _G.keyBuffer:show() end end
        if _G.prefPanel:isShowing() then updatePrefsVisuals() end
    end
end):start()

_G.modWatcher = eventtap.new({eventtap.event.types.flagsChanged}, function(e)
    if not isMasterEnabled or isEditMode or currentState == VIM_STATE.INSERT or isCurrentAppDisabled() then return false end
    local flags = e:getFlags()
    if flags.alt and isAerospaceEnabled then presentHud(modifierMenus.alt.title, modifierMenus.alt.text, colorAccent); if hudTimer then hudTimer:stop() end
    elseif flags.shift then presentHud(modifierMenus.shift.title, modifierMenus.shift.text, colorAccent); if hudTimer then hudTimer:stop() end
    elseif flags.ctrl then presentHud(modifierMenus.ctrl.title, modifierMenus.ctrl.text, colorAccent); if hudTimer then hudTimer:stop() end
    else
        if _G.hud:isShowing() then
            local currentTitle = _G.hud[2].text:getString()
            if currentTitle == modifierMenus.shift.title or currentTitle == modifierMenus.ctrl.title or currentTitle == modifierMenus.alt.title then _G.hud:hide() end
        end
    end
    return false
end):start()

_G.keyWatcher = eventtap.new({eventtap.event.types.keyDown}, function(e)
    local flags = e:getFlags(); local keyCode = e:getKeyCode(); local keyName = keycodes.map[keyCode]

    if keyName == "escape" or (flags.ctrl and keyName == "[") then
        if _G.exclPanel:isShowing() then _G.exclPanel:hide(); return true end
        if _G.prefPanel:isShowing() then _G.prefPanel:hide(); isEditMode=false; updateDragHandles(); resetToNormal(); return true end
        if _G.hud:isShowing() or #keyHistory > 0 then resetToNormal(); return false end
        if isHudEnabled and isEscapeMenuEnabled and not isEditMode and not isCurrentAppDisabled() then presentHud(indexMenu.title, indexMenu.text, colorTitle); return false end
        return false
    end

    if not isMasterEnabled or isEditMode or isCurrentAppDisabled() then return false end
    local char = e:getCharacters()

    if isAerospaceEnabled and flags.alt then
         local cleanKey = keyName; if flags.shift then cleanKey = "⇧"..cleanKey end
         addToBuffer("⌥"..cleanKey); return false
    end

    if currentState == VIM_STATE.INSERT then return false end
    local bufferChar = char; if keyName=="space" then bufferChar="␣" elseif keyName=="return" then bufferChar="↵" elseif keyName=="backspace" then bufferChar="⌫" elseif flags.ctrl then bufferChar="^"..(keyName or "?") end

    if isMacroEnabled then
        if recordingRegister and bufferChar == "q" then recordingRegister = nil; addToBuffer("q (Stop)"); return false end
        if pendingMacroStart then pendingMacroStart = false; if bufferChar then recordingRegister = bufferChar; addToBuffer(bufferChar); updateStateDisplay() end; return false end
        if currentState == VIM_STATE.NORMAL and bufferChar == "q" and not recordingRegister then pendingMacroStart = true; addToBuffer("q"); if isHudEnabled then presentHud(triggers.q.title, triggers.q.text, colorAccent) end; return false end
    end

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

hs.alert.show("Vimualizer Loaded")
updateBufferGeometry(); updateStateDisplay(); if isBufferEnabled then _G.keyBuffer:show() end