local watchers = {}

local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")
local timer = require("hs.timer")
local alert = require("hs.alert")
local dialog = require("hs.dialog")
local window = require("hs.window")
local mouse = require("hs.mouse")
local canvas = require("hs.canvas")
local styledtext = require("hs.styledtext")
local drawing = require("hs.drawing")

local constants = require("modules.constants")
local config = require("modules.config")
local menus = require("modules.menus")
local ui = require("modules.ui")
local panels = require("modules.panels")
local vim_logic = require("modules.vim_logic")

local dragTarget = nil
local dragOffset = {x=0, y=0}

function watchers.init()
    _G.hoverWatcher = eventtap.new({eventtap.event.types.mouseMoved}, function(e)
        if not config.isTooltipsEnabled or not _G.prefPanel or not _G.prefPanel:isShowing() then 
            if _G.tooltipCanvas:isShowing() then _G.tooltipCanvas:hide() end
            return false 
        end

        local p = e:location()
        local f = _G.prefPanel:frame()
        
        if p.x >= f.x and p.x <= (f.x + f.w) and p.y >= f.y and p.y <= (f.y + f.h) then
            local relY = (p.y - f.y) / f.h
            local relX = (p.x - f.x) / f.w
            local target = panels.getSettingsTarget(relX, relY)
            
            if target and menus.tooltips[target] then
                local txt = menus.tooltips[target]
                local cardW = 180
                local padding = 10
                
                local styled = styledtext.new(txt, {font={name=".AppleSystemUIFont", size=13}, color={white=1}, paragraphStyle={alignment="center"}})
                local textSize = drawing.getTextDrawingSize(styled, {w=cardW-(padding*2)})
                local totalH = textSize.h + (padding*2)
                
                _G.tooltipCanvas:frame({x=p.x+20, y=p.y+20, w=cardW, h=totalH})
                _G.tooltipCanvas[2].text = styled
                _G.tooltipCanvas[2].frame = {x=padding, y=padding, w=cardW-(padding*2), h=textSize.h}
                
                _G.tooltipCanvas:show()
                mouse.cursor(hs.mouse.cursorTypes.pointingHand)
                return false
            end
        end
        _G.tooltipCanvas:hide()
        mouse.cursor(hs.mouse.cursorTypes.arrow)
        return false
    end):start()

    _G.interactionWatcher = eventtap.new({ eventtap.event.types.leftMouseDown, eventtap.event.types.leftMouseDragged, eventtap.event.types.leftMouseUp }, function(e)
        if not config.isEditMode then return false end
        local p = e:location(); local type = e:getType()

        if type == eventtap.event.types.leftMouseDown then
            local f = _G.prefPanel:frame()
            if _G.prefPanel:isShowing() and p.x >= f.x and p.x <= (f.x + f.w) and p.y >= f.y and p.y <= (f.y + f.h) then
                local relY = (p.y - f.y) / f.h; local relX = (p.x - f.x) / f.w; local changed = false
                local target = panels.getSettingsTarget(relX, relY)

                if target == "toggle_master" then config.isMasterEnabled = not config.isMasterEnabled; changed=true
                elseif target == "toggle_hud" then config.isHudEnabled = not config.isHudEnabled; changed=true
                elseif target == "toggle_buffer" then config.isBufferEnabled = not config.isBufferEnabled; if not config.isBufferEnabled then _G.keyBuffer:hide() else _G.keyBuffer:show() end; changed=true
                elseif target == "toggle_action" then config.isActionInfoEnabled = not config.isActionInfoEnabled; ui.updateBufferGeometry(); changed=true
                elseif target == "toggle_entry" then config.isEscapeMenuEnabled = not config.isEscapeMenuEnabled; changed=true
                elseif target == "toggle_macro" then config.isMacroEnabled = not config.isMacroEnabled; changed=true
                elseif target == "toggle_aerospace" then config.isAerospaceEnabled = not config.isAerospaceEnabled; changed=true
                elseif target == "toggle_tooltips" then config.isTooltipsEnabled = not config.isTooltipsEnabled; changed=true; _G.tooltipCanvas:hide()
                
                elseif target == "btn_pos" then
                    config.hudPosIndex = config.hudPosIndex + 1; if config.hudPosIndex > 5 then config.hudPosIndex = 1 end
                    changed=true
                elseif target == "btn_align" then
                    if config.hudTextAlignment == "left" then config.hudTextAlignment = "center"
                    elseif config.hudTextAlignment == "center" then config.hudTextAlignment = "right"
                    else config.hudTextAlignment = "left" end
                    ui.presentHud("Alignment: " .. config.hudTextAlignment, menus.previewMenu.text)
                    changed=true
                    
                elseif target == "btn_title_minus" then config.fontTitleSize=math.max(10, config.fontTitleSize-2); changed=true; config.save(); ui.presentHud("Title Size: "..config.fontTitleSize, menus.previewMenu.text)
                elseif target == "btn_title_plus" then config.fontTitleSize=math.min(60, config.fontTitleSize+2); changed=true; config.save(); ui.presentHud("Title Size: "..config.fontTitleSize, menus.previewMenu.text)
                elseif target == "btn_text_minus" then config.fontBodySize=math.max(8, config.fontBodySize-1); changed=true; config.save(); ui.presentHud("Text Size: "..config.fontBodySize, menus.previewMenu.text)
                elseif target == "btn_text_plus" then config.fontBodySize=math.min(40, config.fontBodySize+1); changed=true; config.save(); ui.presentHud("Text Size: "..config.fontBodySize, menus.previewMenu.text)
                
                elseif target == "toggle_ghost" then config.isReactiveOpacityEnabled = not config.isReactiveOpacityEnabled; changed=true; if not config.isReactiveOpacityEnabled then ui.resetOpacity() end

                elseif target == "btn_font_ui" then
                    local btn, newFont = dialog.textPrompt("Set Main Font", "Enter font name (e.g. Helvetica, Inter):", config.fontUI, "OK", "Cancel")
                    if btn == "OK" and newFont and newFont ~= "" then
                        config.fontUI = newFont; config.fontUIBold = newFont .. " Bold"
                        _G.keyBuffer[4].textFont = config.fontUI
                        _G.keyBuffer[2].textFont = config.fontUIBold
                        changed = true; config.save()
                        ui.presentHud("Main Font Updated", "New Main Font: " .. newFont .. "\n\n" .. menus.previewMenu.text)
                    end
                elseif target == "btn_font_code" then
                    local btn, newFont = dialog.textPrompt("Set Code Font", "Enter font name (e.g. Menlo, Monaco):", config.fontCode, "OK", "Cancel")
                    if btn == "OK" and newFont and newFont ~= "" then
                        config.fontCode = newFont
                        _G.keyBuffer[3].textFont = config.fontCode
                        changed = true; config.save()
                        ui.presentHud("Code Font Updated", "New Code Font: " .. newFont .. "\n\n" .. menus.previewMenu.text)
                    end

                elseif target == "toggle_app" then
                    local _, appID = panels.getCurrentAppInfo()
                    if config.excludedApps[appID] then 
                        config.excludedApps[appID] = nil; 
                        if config.isBufferEnabled then _G.keyBuffer:show() end
                    else 
                        config.excludedApps[appID] = true; 
                        _G.keyBuffer:hide(); _G.hud:hide() 
                    end
                    changed=true; if _G.exclPanel:isShowing() then panels.updateExclusionPanel() end
                    
                elseif target == "btn_save" then config.save(); alert.show("Vimualizer Settings Saved", 1)
                elseif target == "btn_analytics" then panels.updateStatsPanel(); _G.statsPanel:show()
                elseif target == "btn_exclusions" then panels.updateExclusionPanel(); _G.exclPanel:show()
                end

                if changed then config.save(); timer.doAfter(0, function() panels.updatePrefsVisuals() end) end
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
                    if relX > 0.85 and panels.sortedExclusions[rowIndex] then
                        config.excludedApps[panels.sortedExclusions[rowIndex]] = nil
                        config.save(); panels.updateExclusionPanel(); panels.updatePrefsVisuals()
                    end
                end
                return true
            end

            local sF = _G.statsPanel:frame()
            if _G.statsPanel:isShowing() and p.x >= sF.x and p.x <= (sF.x + sF.w) and p.y >= sF.y and p.y <= (sF.y + sF.h) then
                local relY = (p.y - sF.y) / sF.h
                if relY > 0.90 then _G.statsPanel:hide() end
                return true
            end

            local hF = _G.hud:frame()
            if _G.hud:isShowing() and p.x >= hF.x and p.x <= (hF.x + hF.w) and p.y >= hF.y and p.y <= (hF.y + hF.h) then
                dragTarget="hud"; dragOffset={x=p.x-hF.x, y=p.y-hF.y}; config.hudPosIndex=5; panels.updatePrefsVisuals(); return true
            end
            local bF = _G.keyBuffer:frame()
            if _G.keyBuffer:isShowing() and p.x >= bF.x and p.x <= (bF.x + bF.w) and p.y >= bF.y and p.y <= (bF.y + bF.h) then
                dragTarget="buffer"; dragOffset={x=p.x-bF.x, y=p.y-bF.y}; return true
            end
            _G.prefPanel:hide(); _G.exclPanel:hide(); _G.hud:hide(); config.isEditMode=false; ui.updateDragHandles(); vim_logic.resetToNormal(); return false
        elseif type == eventtap.event.types.leftMouseDragged then
            if dragTarget == "hud" then
                local newX, newY = p.x - dragOffset.x, p.y - dragOffset.y
                _G.hud:frame({x=newX, y=newY, w=_G.hud:frame().w, h=_G.hud:frame().h}); config.customHudX, config.customHudY = newX, newY; return true
            elseif dragTarget == "buffer" then
                local newX, newY = p.x - dragOffset.x, p.y - dragOffset.y
                _G.keyBuffer:frame({x=newX, y=newY, w=_G.keyBuffer:frame().w, h=_G.keyBuffer:frame().h}); config.bufferX, config.bufferY = newX, newY; return true
            end
        elseif type == eventtap.event.types.leftMouseUp then
            if dragTarget then config.save() end; dragTarget = nil
        end
        return false
    end):start()

    _G.appWatcher = hs.application.watcher.new(function(appName, eventType, app)
        if eventType == hs.application.watcher.activated then
            local bundleID = app:bundleID()
            if config.excludedApps[bundleID] then _G.hud:hide(); _G.keyBuffer:hide()
            else if config.isBufferEnabled then _G.keyBuffer:show() end end
            if _G.prefPanel:isShowing() then panels.updatePrefsVisuals() end
            ui.resetOpacity()
        end
    end):start()

    _G.modWatcher = eventtap.new({eventtap.event.types.flagsChanged}, function(e)
        ui.resetOpacity()
        local _, bundleID = panels.getCurrentAppInfo()
        if not config.isMasterEnabled or config.isEditMode or vim_logic.currentState == constants.VIM_STATE.INSERT or config.excludedApps[bundleID] then return false end

        if config.isHudEnabled then
            local flags = e:getFlags()
            if flags.alt and config.isAerospaceEnabled then 
                ui.presentHud(menus.modifierMenus.alt.title, menus.modifierMenus.alt.text, constants.colorAccent); 
            elseif flags.shift then 
                ui.presentHud(menus.modifierMenus.shift.title, menus.modifierMenus.shift.text, constants.colorAccent); 
            elseif flags.ctrl then 
                ui.presentHud(menus.modifierMenus.ctrl.title, menus.modifierMenus.ctrl.text, constants.colorAccent); 
            else
                if _G.hud:isShowing() then
                    local currentTitle = _G.hud[2].text:getString()
                    if currentTitle == menus.modifierMenus.shift.title or currentTitle == menus.modifierMenus.ctrl.title or currentTitle == menus.modifierMenus.alt.title then _G.hud:hide() end
                end
            end
        end
        return false
    end):start()

    _G.keyWatcher = eventtap.new({eventtap.event.types.keyDown}, function(e)
        ui.resetOpacity()
        local flags = e:getFlags(); local keyCode = e:getKeyCode(); local keyName = keycodes.map[keyCode]

        local _, bundleID = panels.getCurrentAppInfo()

        if keyName == "escape" or (flags.ctrl and keyName == "[") then
            if _G.exclPanel:isShowing() then _G.exclPanel:hide(); return true end
            if _G.statsPanel:isShowing() then _G.statsPanel:hide(); return true end
            if _G.prefPanel:isShowing() then _G.prefPanel:hide(); config.isEditMode=false; ui.updateDragHandles(); vim_logic.resetToNormal(); return true end
            if _G.hud:isShowing() or #vim_logic.keyHistory > 0 then vim_logic.resetToNormal(); return false end
            if config.isHudEnabled and config.isEscapeMenuEnabled and not config.isEditMode and not config.excludedApps[bundleID] then 
                ui.presentHud(menus.indexMenu.title, menus.indexMenu.text, constants.colorTitle); return false 
            end
            return false
        end

        if not config.isMasterEnabled or config.isEditMode or config.excludedApps[bundleID] then return false end
        local char = e:getCharacters()

        if config.isAerospaceEnabled and flags.alt then
             local cleanKey = keyName; if flags.shift then cleanKey = "⇧"..cleanKey end
             vim_logic.addToBuffer("⌥"..cleanKey); return false
        end

        if vim_logic.currentState == constants.VIM_STATE.INSERT then return false end
        local bufferChar = char; if keyName=="space" then bufferChar="␣" elseif keyName=="return" then bufferChar="↵" elseif keyName=="backspace" then bufferChar="⌫" elseif flags.ctrl then bufferChar="^"..(keyName or "?") end

        if config.isMacroEnabled then
            if vim_logic.recordingRegister and bufferChar == "q" then vim_logic.recordingRegister = nil; vim_logic.addToBuffer("q (Stop)"); return false end
            if vim_logic.pendingMacroStart then vim_logic.pendingMacroStart = false; if bufferChar then vim_logic.recordingRegister = bufferChar; vim_logic.addToBuffer(bufferChar); vim_logic.updateStateDisplay() end; return false end
            if vim_logic.currentState == constants.VIM_STATE.NORMAL and bufferChar == "q" and not vim_logic.recordingRegister then vim_logic.pendingMacroStart = true; vim_logic.addToBuffer("q"); if config.isHudEnabled then ui.presentHud(menus.triggers.q.title, menus.triggers.q.text, constants.colorAccent) end; return false end
        end

        if constants.insertTriggers[bufferChar] then vim_logic.currentState = constants.VIM_STATE.INSERT; vim_logic.addToBuffer(bufferChar); return false end
        if bufferChar == "c" and vim_logic.currentState == constants.VIM_STATE.NORMAL then vim_logic.currentState = constants.VIM_STATE.PENDING_CHANGE; vim_logic.addToBuffer("c"); if config.isHudEnabled then ui.presentHud(menus.triggers.c.title, menus.triggers.c.text, constants.colorAccent) end; return false end
        if vim_logic.currentState == constants.VIM_STATE.PENDING_CHANGE then vim_logic.currentState = constants.VIM_STATE.INSERT; vim_logic.addToBuffer(bufferChar); _G.hud:hide(); return false end
        if constants.visualTriggers[bufferChar] then vim_logic.currentState = constants.VIM_STATE.VISUAL; vim_logic.addToBuffer(bufferChar); if config.isHudEnabled then local vMenu = menus.triggers[bufferChar] or menus.triggers.v; ui.presentHud(vMenu.title, vMenu.text, constants.colorTitle) end; return false end

        if vim_logic.currentState == constants.VIM_STATE.NORMAL or vim_logic.currentState == constants.VIM_STATE.VISUAL then
            if bufferChar and #bufferChar > 0 and #bufferChar < 5 then vim_logic.addToBuffer(bufferChar) end
            if config.isHudEnabled then
                local lookup = bufferChar; if flags.ctrl and keyName then lookup = "^"..keyName end
                if menus.triggers[lookup] then ui.presentHud(menus.triggers[lookup].title, menus.triggers[lookup].text); if ui.hudTimer then ui.hudTimer:stop() end; ui.hudTimer = timer.doAfter(constants.displayTime, function() _G.hud:hide() end) end
            end
        end
        return false
    end):start()
end

return watchers
