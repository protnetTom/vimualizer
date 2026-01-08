local panels = {}

local canvas = require("hs.canvas")
local styledtext = require("hs.styledtext")
local application = require("hs.application")
local window = require("hs.window")

local constants = require("modules.constants")
local config = require("modules.config")

panels.sortedExclusions = {}
panels.sortedSnippets = {}

function panels.getCurrentAppInfo()
    local win = window.focusedWindow()
    if not win then return "Unknown", "Unknown" end
    local app = win:application()
    if not app then return "Unknown", "Unknown" end
    return app:name(), app:bundleID()
end

panels.currentTab = 1  -- 1=Features, 2=Appearance, 3=Advanced

function panels.initPrefs()
    -- Safeguard: Ensure all sequential indices are initialized
    for i=1,100 do _G.prefPanel[i] = { type="rectangle", action="skip", frame={x=0,y=0,w=0,h=0} } end

    -- Background
    _G.prefPanel[1] = { type="rectangle", frame={x=0,y=0,w="100%",h="100%"}, action="fill", fillColor=constants.panelColor, roundedRectRadii={xRadius=16, yRadius=16}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    
    -- Title
    _G.prefPanel[2] = { type="text", text="Vimualizer Settings", textColor=constants.colorTitle, textSize=24, textAlignment="center", frame={x=0,y="2%",w="100%",h="5%"} }

    -- TAB BUTTONS (Indices 3-8)
    local tabY = 8
    local tabW = 30
    local tabGap = 2
    
    -- Features Tab
    _G.prefPanel[3] = { type="rectangle", action="fill", frame={x="5%",y=tabY.."%",w=tabW.."%",h="4%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[4] = { type="text", text="Features", textAlignment="center", frame={x="5%",y=(tabY+0.8).."%",w=tabW.."%",h="4%"} }
    
    -- Appearance Tab
    _G.prefPanel[5] = { type="rectangle", action="fill", frame={x=(5+tabW+tabGap).."%",y=tabY.."%",w=tabW.."%",h="4%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[6] = { type="text", text="Appearance", textAlignment="center", frame={x=(5+tabW+tabGap).."%",y=(tabY+0.8).."%",w=tabW.."%",h="4%"} }
    
    -- Advanced Tab
    _G.prefPanel[7] = { type="rectangle", action="fill", frame={x=(5+(tabW+tabGap)*2).."%",y=tabY.."%",w=tabW.."%",h="4%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.prefPanel[8] = { type="text", text="Advanced", textAlignment="center", frame={x=(5+(tabW+tabGap)*2).."%",y=(tabY+0.8).."%",w=tabW.."%",h="4%"} }

    -- CONTENT AREA - Dynamic based on selected tab
    -- We'll use indices 10-50 for tab content (dynamically populated)
    
    -- FOOTER (Indices 90-99)
    local footerY = 95
    _G.prefPanel[90] = { type="rectangle", action="fill", fillColor=constants.btnColorSave, frame={x="5%",y=footerY.."%",w="22%",h="3%"}, roundedRectRadii={xRadius=4,yRadius=4} }
    _G.prefPanel[91] = { type="text", text="Save", textColor={white=1}, textSize=12, textAlignment="center", frame={x="5%",y=(footerY+0.4).."%",w="22%",h="3%"} }
    
    _G.prefPanel[92] = { type="rectangle", action="fill", fillColor=constants.btnColorAction, frame={x="29%",y=footerY.."%",w="22%",h="3%"}, roundedRectRadii={xRadius=4,yRadius=4} }
    _G.prefPanel[93] = { type="text", text="Analytics", textColor={white=1}, textSize=12, textAlignment="center", frame={x="29%",y=(footerY+0.4).."%",w="22%",h="3%"} }

    _G.prefPanel[94] = { type="rectangle", action="fill", fillColor={hex="#5856D6"}, frame={x="53%",y=footerY.."%",w="22%",h="3%"}, roundedRectRadii={xRadius=4,yRadius=4} }
    _G.prefPanel[95] = { type="text", text="Exclusions", textColor={white=1}, textSize=12, textAlignment="center", frame={x="53%",y=(footerY+0.4).."%",w="22%",h="3%"} }

    _G.prefPanel[96] = { type="rectangle", action="fill", fillColor={hex="#FF9500"}, frame={x="77%",y=footerY.."%",w="18%",h="3%"}, roundedRectRadii={xRadius=4,yRadius=4} }
    _G.prefPanel[97] = { type="text", text="Tour", textColor={white=1}, textSize=12, textAlignment="center", frame={x="77%",y=(footerY+0.4).."%",w="18%",h="3%"} }
end

function panels.updatePrefsVisuals()
    local function styleBtn(idx, enabled, txt)
        _G.prefPanel[idx].fillColor = (enabled and constants.btnColorOn or constants.btnColorOff)
        _G.prefPanel[idx].roundedRectRadii = {xRadius=6, yRadius=6}
        _G.prefPanel[idx+1].text = styledtext.new(txt, {font={name=config.fontUIBold, size=14}, color={white=1}, paragraphStyle={alignment="center"}})
    end
    local function styleActionBtn(idx)
        _G.prefPanel[idx].fillColor = constants.btnColorAction
        _G.prefPanel[idx].roundedRectRadii = {xRadius=6, yRadius=6}
    end

    -- Update tab button styles
    local activeTabColor = {hex="#0A84FF", alpha=0.8}
    local inactiveTabColor = {hex="#2C2C2E", alpha=0.9}
    
    _G.prefPanel[3].fillColor = (panels.currentTab == 1) and activeTabColor or inactiveTabColor
    _G.prefPanel[4].textColor = {white=(panels.currentTab == 1) and 1 or 0.6}
    _G.prefPanel[4].textFont = (panels.currentTab == 1) and config.fontUIBold or config.fontUI
    
    _G.prefPanel[5].fillColor = (panels.currentTab == 2) and activeTabColor or inactiveTabColor
    _G.prefPanel[6].textColor = {white=(panels.currentTab == 2) and 1 or 0.6}
    _G.prefPanel[6].textFont = (panels.currentTab == 2) and config.fontUIBold or config.fontUI
    
    _G.prefPanel[7].fillColor = (panels.currentTab == 3) and activeTabColor or inactiveTabColor
    _G.prefPanel[8].textColor = {white=(panels.currentTab == 3) and 1 or 0.6}
    _G.prefPanel[8].textFont = (panels.currentTab == 3) and config.fontUIBold or config.fontUI

    -- Clear content area (indices 10-89)
    for i=10,89 do
        _G.prefPanel[i] = { type="rectangle", action="skip", frame={x=0,y=0,w=0,h=0} }
    end

    -- Populate content based on current tab
    if panels.currentTab == 1 then
        -- FEATURES TAB
        local startY = 15
        local rowH = 5.5
        
        styleBtn(10, config.isMasterEnabled, "Enable Vimualizer: "..(config.isMasterEnabled and "ON" or "OFF"))
        _G.prefPanel[10].frame = {x="10%", y=startY.."%", w="80%", h=rowH.."%"}
        _G.prefPanel[11].frame = {x="10%", y=(startY+1.2).."%", w="80%", h=rowH.."%"}
        
        styleBtn(12, config.isHudEnabled, "Key Hints: "..(config.isHudEnabled and "ON" or "OFF"))
        _G.prefPanel[12].frame = {x="10%", y=(startY+rowH+1).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[13].frame = {x="10%", y=(startY+rowH+2.2).."%", w="80%", h=rowH.."%"}
        
        styleBtn(14, config.isBufferEnabled, "Keystroke Display: "..(config.isBufferEnabled and "ON" or "OFF"))
        _G.prefPanel[14].frame = {x="10%", y=(startY+(rowH+1)*2).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[15].frame = {x="10%", y=(startY+(rowH+1)*2+1.2).."%", w="80%", h=rowH.."%"}
        
        styleBtn(16, config.isActionInfoEnabled, "Action Explanations: "..(config.isActionInfoEnabled and "ON" or "OFF"))
        _G.prefPanel[16].frame = {x="10%", y=(startY+(rowH+1)*3).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[17].frame = {x="10%", y=(startY+(rowH+1)*3+1.2).."%", w="80%", h=rowH.."%"}
        
        styleBtn(18, config.isEscapeMenuEnabled, "Escape Menu: "..(config.isEscapeMenuEnabled and "ON" or "OFF"))
        _G.prefPanel[18].frame = {x="10%", y=(startY+(rowH+1)*4).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[19].frame = {x="10%", y=(startY+(rowH+1)*4+1.2).."%", w="80%", h=rowH.."%"}
        
        styleBtn(20, config.isMacroEnabled, "Macro Recording: "..(config.isMacroEnabled and "ON" or "OFF"))
        _G.prefPanel[20].frame = {x="10%", y=(startY+(rowH+1)*5).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[21].frame = {x="10%", y=(startY+(rowH+1)*5+1.2).."%", w="80%", h=rowH.."%"}
        
        styleBtn(22, config.isTooltipsEnabled, "Tooltips: "..(config.isTooltipsEnabled and "ON" or "OFF"))
        _G.prefPanel[22].frame = {x="10%", y=(startY+(rowH+1)*6).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[23].frame = {x="10%", y=(startY+(rowH+1)*6+1.2).."%", w="80%", h=rowH.."%"}

    elseif panels.currentTab == 2 then
        -- APPEARANCE TAB
        local startY = 15
        
        -- Position & Alignment
        local posNames = {"Left", "TopRight", "BotRight", "Center", "Custom"}
        styleActionBtn(10)
        _G.prefPanel[10].frame = {x="10%", y=startY.."%", w="38%", h="6%"}
        _G.prefPanel[11].text = styledtext.new("Position: "..posNames[config.hudPosIndex], {font={name=config.fontUIBold, size=13}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[11].frame = {x="10%", y=(startY+1.5).."%", w="38%", h="6%"}
        
        local alignLabel = "Align: " .. (config.hudTextAlignment:gsub("^%l", string.upper))
        styleActionBtn(12)
        _G.prefPanel[12].frame = {x="52%", y=startY.."%", w="38%", h="6%"}
        _G.prefPanel[13].text = styledtext.new(alignLabel, {font={name=config.fontUIBold, size=13}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[13].frame = {x="52%", y=(startY+1.5).."%", w="38%", h="6%"}
        
        -- Title Size
        local sizeY1 = 23
        styleActionBtn(14); styleActionBtn(16)
        _G.prefPanel[14].frame = {x="10%", y=sizeY1.."%", w="15%", h="5%"}
        _G.prefPanel[15].text = styledtext.new("-", {font={name=config.fontUIBold, size=20}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[15].frame = {x="10%", y=(sizeY1+0.8).."%", w="15%", h="5%"}
        _G.prefPanel[16].frame = {x="75%", y=sizeY1.."%", w="15%", h="5%"}
        _G.prefPanel[17].text = styledtext.new("+", {font={name=config.fontUIBold, size=20}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[17].frame = {x="75%", y=(sizeY1+0.8).."%", w="15%", h="5%"}
        _G.prefPanel[18].text = styledtext.new("Title Size: "..config.fontTitleSize, {font={name=config.fontUI, size=14}, color={white=0.9}, paragraphStyle={alignment="center"}})
        _G.prefPanel[18].frame = {x="25%", y=(sizeY1+1.2).."%", w="50%", h="5%"}
        
        -- Text Size
        local sizeY2 = 30
        styleActionBtn(20); styleActionBtn(22)
        _G.prefPanel[20].frame = {x="10%", y=sizeY2.."%", w="15%", h="5%"}
        _G.prefPanel[21].text = styledtext.new("-", {font={name=config.fontUIBold, size=20}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[21].frame = {x="10%", y=(sizeY2+0.8).."%", w="15%", h="5%"}
        _G.prefPanel[22].frame = {x="75%", y=sizeY2.."%", w="15%", h="5%"}
        _G.prefPanel[23].text = styledtext.new("+", {font={name=config.fontUIBold, size=20}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[23].frame = {x="75%", y=(sizeY2+0.8).."%", w="15%", h="5%"}
        _G.prefPanel[24].text = styledtext.new("Text Size: "..config.fontBodySize, {font={name=config.fontUI, size=14}, color={white=0.9}, paragraphStyle={alignment="center"}})
        _G.prefPanel[24].frame = {x="25%", y=(sizeY2+1.2).."%", w="50%", h="5%"}
        
        -- Ghost Mode
        local ghostY = 37
        styleBtn(26, config.isReactiveOpacityEnabled, "Ghost Mode: "..(config.isReactiveOpacityEnabled and "ON" or "OFF"))
        _G.prefPanel[26].frame = {x="10%", y=ghostY.."%", w="80%", h="5.5%"}
        _G.prefPanel[27].frame = {x="10%", y=(ghostY+1.2).."%", w="80%", h="5.5%"}
        
        -- Fonts
        local fontY = 45
        styleActionBtn(28)
        _G.prefPanel[28].frame = {x="10%", y=fontY.."%", w="38%", h="5%"}
        _G.prefPanel[29].text = styledtext.new("Main Font", {font={name=config.fontUIBold, size=12}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[29].frame = {x="10%", y=(fontY+1.2).."%", w="38%", h="5%"}
        
        styleActionBtn(30)
        _G.prefPanel[30].frame = {x="52%", y=fontY.."%", w="38%", h="5%"}
        _G.prefPanel[31].text = styledtext.new("Code Font", {font={name=config.fontUIBold, size=12}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[31].frame = {x="52%", y=(fontY+1.2).."%", w="38%", h="5%"}

    elseif panels.currentTab == 3 then
        -- ADVANCED TAB
        local startY = 15
        local rowH = 5.5
        
        local trainer = require("modules.trainer")
        styleBtn(10, trainer.isActive, "Trainer Mode: "..(trainer.isActive and "ON" or "OFF"))
        _G.prefPanel[10].frame = {x="10%", y=startY.."%", w="80%", h=rowH.."%"}
        _G.prefPanel[11].frame = {x="10%", y=(startY+1.2).."%", w="80%", h=rowH.."%"}
        
        styleBtn(12, config.isSnippetsEnabled, "Text Snippets: "..(config.isSnippetsEnabled and "ON" or "OFF"))
        _G.prefPanel[12].frame = {x="10%", y=(startY+rowH+1).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[13].frame = {x="10%", y=(startY+rowH+2.2).."%", w="80%", h=rowH.."%"}
        
        -- Manage Snippets Button
        styleActionBtn(14)
        _G.prefPanel[14].frame = {x="10%", y=(startY+(rowH+1)*2).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[15].text = styledtext.new("Manage Snippets (⚙︎)", {font={name=config.fontUIBold, size=13}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[15].frame = {x="10%", y=(startY+(rowH+1)*2+1.2).."%", w="80%", h=rowH.."%"}
        
        local aggressionLabels = {"Conservative", "Moderate", "Aggressive"}
        local aggressionLabel = aggressionLabels[config.easyMotionAggression] or "Moderate"
        styleBtn(16, config.isEasyMotionEnabled, "EasyMotion: "..(config.isEasyMotionEnabled and "ON" or "OFF").." ("..aggressionLabel..")")
        _G.prefPanel[16].frame = {x="10%", y=(startY+(rowH+1)*3).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[17].frame = {x="10%", y=(startY+(rowH+1)*3+1.2).."%", w="80%", h=rowH.."%"}
        
        styleBtn(18, config.isAerospaceEnabled, "Aerospace Mode: "..(config.isAerospaceEnabled and "ON" or "OFF"))
        _G.prefPanel[18].frame = {x="10%", y=(startY+(rowH+1)*4).."%", w="80%", h=rowH.."%"}
        _G.prefPanel[19].frame = {x="10%", y=(startY+(rowH+1)*4+1.2).."%", w="80%", h=rowH.."%"}
        
        -- Current App Exclusion
        local appY = startY + (rowH+1)*5 + 3
        _G.prefPanel[20].text = styledtext.new("CURRENT APP", {font={name=config.fontUIBold, size=11}, color=constants.colorHeader, paragraphStyle={alignment="center"}})
        _G.prefPanel[20].frame = {x="10%", y=appY.."%", w="80%", h="3%"}
        
        local appName, appID = panels.getCurrentAppInfo()
        local isExcluded = config.excludedApps[appID] == true
        _G.prefPanel[21].fillColor = {red=0.15, green=0.15, blue=0.15, alpha=1}
        _G.prefPanel[21].roundedRectRadii = {xRadius=4,yRadius=4}
        _G.prefPanel[21].frame = {x="10%", y=(appY+4).."%", w="55%", h="4%"}
        _G.prefPanel[22].text = styledtext.new(appName, {font={name=config.fontUI, size=11}, color={white=0.9}, paragraphStyle={alignment="center"}})
        _G.prefPanel[22].frame = {x="10%", y=(appY+4.8).."%", w="55%", h="4%"}
        
        _G.prefPanel[23].fillColor = isExcluded and constants.btnColorOff or constants.btnColorOn
        _G.prefPanel[23].roundedRectRadii = {xRadius=4,yRadius=4}
        _G.prefPanel[23].frame = {x="67%", y=(appY+4).."%", w="23%", h="4%"}
        _G.prefPanel[24].text = styledtext.new(isExcluded and "Include" or "Exclude", {font={name=config.fontUIBold, size=11}, color={white=1}, paragraphStyle={alignment="center"}})
        _G.prefPanel[24].frame = {x="67%", y=(appY+4.8).."%", w="23%", h="4%"}
    end
end

function panels.updateStatsPanel()
    local stats = require("modules.stats")
    
    -- Thoroughly clear the canvas
    local currentLen = #_G.statsPanel
    for i = currentLen, 1, -1 do _G.statsPanel[i] = nil end

    -- Background & Title
    _G.statsPanel[1] = { type="rectangle", action="fill", fillColor=constants.panelColor, roundedRectRadii={xRadius=16, yRadius=16}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    _G.statsPanel[2] = { type="text", text="Efficiency Analytics", textColor=constants.colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="2%",w="100%",h="8%"} }

    -- Summary Section
    local summaryY = 60
    _G.statsPanel[3] = { type="text", text="LIFETIME STATS", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="0%",y=summaryY,w="100%",h=20} }
    
    local keysTyped = tonumber(stats.data.totalKeysTyped) or 0
    local keysSaved = tonumber(stats.data.keysSaved) or 0
    local totalUsed = keysTyped + keysSaved
    local efficiency = (totalUsed > 0) and math.floor((keysSaved / totalUsed) * 100) or 0

    local statsTxt = string.format("Keystrokes Typed: %d\nKeystrokes Saved: %d\nVim Efficiency: %d%%", keysTyped, keysSaved, efficiency)
    _G.statsPanel[4] = { type="text", text=statsTxt, textColor={white=0.9}, textSize=18, textAlignment="center", frame={x="10%", y=summaryY + 30, w="80%", h=80} }

    _G.statsPanel[5] = { type="text", text="TOP COMMANDS", textColor=constants.colorHeader, textSize=12, textAlignment="center", frame={x="0%", y=summaryY + 120, w="100%", h=20} }
    
    -- Graph Section
    local top = stats.getTopCommands(12)
    local maxFreq = 1
    if top and top[1] and top[1].freq then maxFreq = top[1].freq end
    
    local idx = 6
    for i, item in ipairs(top) do
        local rowY = summaryY + 150 + ((i-1) * 35)
        local barW = math.floor((item.freq / maxFreq) * 300)
        local barX = 150
        
        _G.statsPanel[idx] = { type="text", text=tostring(item.cmd), textColor=constants.colorKey, textSize=15, textAlignment="right", frame={x=10, y=rowY, w=130, h=30}, textFont=config.fontCode }
        idx = idx + 1
        _G.statsPanel[idx] = { type="rectangle", action="fill", fillColor={hex="#0A84FF", alpha=0.3}, frame={x=barX, y=rowY+5, w=barW, h=20}, roundedRectRadii={xRadius=4,yRadius=4} }
        idx = idx + 1
        _G.statsPanel[idx] = { type="text", text=tostring(item.freq), textColor={white=0.7}, textSize=12, textAlignment="left", frame={x=barX + barW + 10, y=rowY+5, w=60, h=20} }
        idx = idx + 1
    end

    -- Footer
    _G.statsPanel[idx] = { type="rectangle", action="fill", fillColor=constants.btnColorAction, frame={x="30%", y="90%", w="40%", h="5%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    idx = idx + 1
    _G.statsPanel[idx] = { type="text", text="Close Results", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%", y="91.2%", w="40%", h="5%"} }
    
    _G.statsPanel:show()
end

function panels.updateExclusionPanel()
    for i = #_G.exclPanel, 1, -1 do _G.exclPanel[i] = nil end

    _G.exclPanel[1] = { type="rectangle", action="fill", fillColor=constants.panelColor, roundedRectRadii={xRadius=16, yRadius=16}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    _G.exclPanel[2] = { type="text", text="Excluded Apps", textColor=constants.colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="2%",w="100%",h="8%"} }

    panels.sortedExclusions = {}
    for id, _ in pairs(config.excludedApps) do table.insert(panels.sortedExclusions, id) end
    table.sort(panels.sortedExclusions)

    local rowH = 35
    local startY = 60

    for i, bundleId in ipairs(panels.sortedExclusions) do
        local yVal = startY + ((i-1) * (rowH + 5))
        _G.exclPanel[#_G.exclPanel+1] = { type="rectangle", action="fill", fillColor={red=0.2,green=0.2,blue=0.2,alpha=1}, frame={x="5%", y=yVal, w="80%", h=rowH}, roundedRectRadii={xRadius=4,yRadius=4} }
        _G.exclPanel[#_G.exclPanel+1] = { type="text", text=bundleId, textColor={white=0.9}, textSize=13, textAlignment="center", frame={x="7%", y=yVal+11, w="75%", h=rowH} }
        _G.exclPanel[#_G.exclPanel+1] = { type="rectangle", action="fill", fillColor=constants.btnColorExclude, frame={x="87%", y=yVal, w="8%", h=rowH}, roundedRectRadii={xRadius=4,yRadius=4} }
        _G.exclPanel[#_G.exclPanel+1] = { type="text", text="X", textColor={white=1}, textSize=14, textAlignment="center", frame={x="87%", y=yVal+10, w="8%", h=rowH} }
    end

    _G.exclPanel[#_G.exclPanel+1] = { type="rectangle", action="fill", fillColor=constants.btnColorAction, frame={x="30%", y="89%", w="40%", h="5%"}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.exclPanel[#_G.exclPanel+1] = { type="text", text="Close List", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%", y="90.2%", w="40%", h="5%"} }
end

function panels.updateSnipPanel()
    for i = #_G.snipPanel, 1, -1 do _G.snipPanel[i] = nil end

    _G.snipPanel[1] = { type="rectangle", action="fill", fillColor=constants.panelColor, roundedRectRadii={xRadius=16, yRadius=16}, strokeColor=constants.hudStrokeColor, strokeWidth=1, shadow=constants.shadowSpec }
    _G.snipPanel[2] = { type="text", text="Manage Snippets", textColor=constants.colorTitle, textSize=24, textAlignment="center", frame={x="0%",y="2%",w="100%",h="8%"} }

    panels.sortedSnippets = {}
    for trigger, expansion in pairs(config.snippets) do table.insert(panels.sortedSnippets, {t=trigger, e=expansion}) end
    table.sort(panels.sortedSnippets, function(a,b) return a.t < b.t end)

    local rowH = 26; local startY = 60
    for i, item in ipairs(panels.sortedSnippets) do
        local yVal = startY + ((i-1) * (rowH + 2))
        -- No break, snipH is 800 so we can fit many rows
        _G.snipPanel[#_G.snipPanel+1] = { type="rectangle", action="fill", fillColor={red=0.15,green=0.15,blue=0.15,alpha=1}, frame={x="4%", y=yVal, w="82%", h=rowH}, roundedRectRadii={xRadius=4,yRadius=4} }
        local displayStr = item.t .. " → " .. tostring(item.e)
        _G.snipPanel[#_G.snipPanel+1] = { type="text", text=displayStr, textColor={white=0.9}, textSize=10, textAlignment="left", frame={x="6%", y=yVal+7, w="78%", h=rowH}, textFont=config.fontUI }
        _G.snipPanel[#_G.snipPanel+1] = { type="rectangle", action="fill", fillColor=constants.btnColorExclude, frame={x="88%", y=yVal, w="8%", h=rowH}, roundedRectRadii={xRadius=4,yRadius=4} }
        _G.snipPanel[#_G.snipPanel+1] = { type="text", text="X", textColor={white=1}, textSize=12, textAlignment="center", frame={x="88%", y=yVal+6, w="8%", h=rowH} }
    end

    local btnY = 660
    _G.snipPanel[#_G.snipPanel+1] = { type="rectangle", action="fill", fillColor=constants.btnColorSave, frame={x="30%", y=btnY, w="40%", h=40}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.snipPanel[#_G.snipPanel+1] = { type="text", text="Add New (+)", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%", y=btnY+10, w="40%", h=40} }

    _G.snipPanel[#_G.snipPanel+1] = { type="rectangle", action="fill", fillColor=constants.btnColorAction, frame={x="30%", y=btnY+55, w="40%", h=40}, roundedRectRadii={xRadius=6,yRadius=6} }
    _G.snipPanel[#_G.snipPanel+1] = { type="text", text="Close Panel", textColor={white=1}, textSize=16, textAlignment="center", frame={x="30%", y=btnY+65, w="40%", h=40} }
end

function panels.getSettingsTarget(relX, relY)
    -- TAB BUTTONS (8% - 12%)
    if relY > 0.08 and relY < 0.12 then
        if relX > 0.05 and relX < 0.35 then return "tab_features"
        elseif relX > 0.37 and relX < 0.67 then return "tab_appearance"
        elseif relX > 0.69 and relX < 0.99 then return "tab_advanced" end
    end
    
    -- CONTENT AREA (15% - 90%) - Dynamic based on current tab
    if relY > 0.15 and relY < 0.90 then
        if panels.currentTab == 1 then
            -- FEATURES TAB
            local row = math.floor((relY - 0.15) / 0.065)
            if row == 0 then return "toggle_master"
            elseif row == 1 then return "toggle_hud"
            elseif row == 2 then return "toggle_buffer"
            elseif row == 3 then return "toggle_action"
            elseif row == 4 then return "toggle_entry"
            elseif row == 5 then return "toggle_macro"
            elseif row == 6 then return "toggle_tooltips" end
            
        elseif panels.currentTab == 2 then
            -- APPEARANCE TAB
            if relY > 0.15 and relY < 0.21 then
                if relX < 0.5 then return "btn_pos" else return "btn_align" end
            elseif relY > 0.23 and relY < 0.28 then
                if relX < 0.25 then return "btn_title_minus"
                elseif relX > 0.75 then return "btn_title_plus" end
            elseif relY > 0.30 and relY < 0.35 then
                if relX < 0.25 then return "btn_text_minus"
                elseif relX > 0.75 then return "btn_text_plus" end
            elseif relY > 0.37 and relY < 0.425 then
                return "toggle_ghost"
            elseif relY > 0.45 and relY < 0.50 then
                if relX < 0.5 then return "btn_font_ui" else return "btn_font_code" end
            end
            
        elseif panels.currentTab == 3 then
            -- ADVANCED TAB
            local row = math.floor((relY - 0.15) / 0.065)
            if row == 0 then return "toggle_trainer"
            elseif row == 1 then return "toggle_snippets"
            elseif row == 2 then return "btn_manage_snippets"
            elseif row == 3 then return "toggle_easymotion"
            elseif row == 4 then return "toggle_aerospace" end
            
            -- Current app exclusion (around 60%)
            if relY > 0.60 and relY < 0.68 then
                if relX > 0.67 then return "toggle_app" end
            end
        end
    end
    
    -- FOOTER (95%+)
    if relY > 0.95 then
        if relX < 0.27 then return "btn_save"
        elseif relX > 0.29 and relX < 0.51 then return "btn_analytics"
        elseif relX > 0.53 and relX < 0.75 then return "btn_exclusions"
        elseif relX > 0.77 then return "btn_tour" end
    end
    
    return nil
end

return panels
