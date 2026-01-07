-- =================================================
-- VIMUALIZER: REFACTORED MODULAR VERSION
-- =================================================

-- 1. CLEANUP EXISTING WATCHERS/CANVASES
if _G.modWatcher then _G.modWatcher:stop() end
if _G.keyWatcher then _G.keyWatcher:stop() end
if _G.appWatcher then _G.appWatcher:stop() end
if _G.hoverWatcher then _G.hoverWatcher:stop() end
if _G.interactionWatcher then _G.interactionWatcher:stop() end
if _G.hud then _G.hud:delete() end
if _G.keyBuffer then _G.keyBuffer:delete() end
if _G.prefPanel then _G.prefPanel:delete() end
if _G.exclPanel then _G.exclPanel:delete() end
if _G.tooltipCanvas then _G.tooltipCanvas:delete() end

-- 2. REQUIRE MODULES
local constants = require("modules.constants")
local config = require("modules.config")
local menus = require("modules.menus")
local ui = require("modules.ui")
local panels = require("modules.panels")
local vim_logic = require("modules.vim_logic")
local watchers = require("modules.watchers")

-- 3. INITIALIZATION
config.load()
ui.initCanvases()
panels.initPrefs()
watchers.init()

-- Set initial positions/fonts from config if they were loaded
_G.keyBuffer:frame({x=config.bufferX, y=config.bufferY, w=constants.bufferW, h=constants.bufferH})
_G.keyBuffer[3].textFont = config.fontCode
_G.keyBuffer[4].textFont = config.fontUI
_G.keyBuffer[2].textFont = config.fontUIBold

-- 4. GLOBAL HOTKEYS
hs.hotkey.bind({"cmd", "alt"}, "P", function()
    if _G.prefPanel:isShowing() then 
        _G.prefPanel:hide()
        _G.exclPanel:hide()
        config.isEditMode = false
        ui.updateDragHandles()
        vim_logic.resetToNormal()
    else 
        panels.updatePrefsVisuals()
        config.isEditMode = true
        _G.prefPanel:show()
        _G.keyBuffer:show()
        ui.presentHud("Preview", menus.previewMenu.text)
        ui.updateDragHandles()
    end
end)

-- 5. STARTUP
hs.alert.show("Vimualizer Refactored & Loaded")
ui.updateBufferGeometry()
vim_logic.updateStateDisplay()
if config.isBufferEnabled then _G.keyBuffer:show() end