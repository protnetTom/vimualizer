local config = {}

local fs = require("hs.fs")
local json = require("hs.json")

config.isMasterEnabled = true
config.isHudEnabled = true
config.isBufferEnabled = true
config.isActionInfoEnabled = true
config.isAerospaceEnabled = false
config.isEscapeMenuEnabled = true
config.isMacroEnabled = true
config.isTooltipsEnabled = true
config.isEditMode = false
config.hudTextAlignment = "center"
config.isReactiveOpacityEnabled = true
config.idleOpacity = 0.2
config.idleTimeout = 3.0
config.fontTitleSize = 32
config.fontBodySize = 20
config.hudPosIndex = 1
config.customHudX, config.customHudY = 100, 100
config.bufferX, config.bufferY = 0, 0 -- To be set in init or loaded
config.fontUI = ".AppleSystemUIFont"
config.fontUIBold = ".AppleSystemUIFontBold"
config.fontCode = "Menlo"
config.trainerDifficulty = 1
config.excludedApps = {
    ["com.apple.loginwindow"] = true,
    ["com.apple.ScreenSaver.Engine"] = true
}
config.isSnippetsEnabled = true
config.hasCompletedOnboarding = false
config.snippets = {
    [";date"] = "{{date}}",
    [";time"] = "{{time}}",
     [";shrug"] = "¯\\_(ツ)_/¯",
    [";vml"] = "Vimualizer",
    [";lenny"] = "( ͡° ͜ʖ ͡°)",
    [";rocket"] = "🚀",
    [";fire"] = "🔥",
    [";check"] = "✅",
    [";todo"] = "TODO: ",
    [";fixme"] = "FIXME: ",
    [";rt"] = "→",
    [";lt"] = "←",
    [";up"] = "↑",
    [";dn"] = "↓",
    [";mail"] = "your.email@example.com"
}

local homeDir = os.getenv("HOME")
local saveDir = homeDir .. "/Documents/Vimualizer"
local settingsFilePath = saveDir .. "/settings.json"

local function ensureDirectoryExists()
    local attrs = fs.attributes(saveDir)
    if not attrs then fs.mkdir(saveDir) end
end

function config.save()
    ensureDirectoryExists()
    local cleanExclusions = {}
    for k, v in pairs(config.excludedApps) do if v == true then cleanExclusions[k] = true end end

    local settings = {
        isMasterEnabled = config.isMasterEnabled,
        isHudEnabled = config.isHudEnabled,
        isBufferEnabled = config.isBufferEnabled,
        isActionInfoEnabled = config.isActionInfoEnabled,
        isAerospaceEnabled = config.isAerospaceEnabled,
        isEscapeMenuEnabled = config.isEscapeMenuEnabled,
        isMacroEnabled = config.isMacroEnabled,
        isTooltipsEnabled = config.isTooltipsEnabled,
        hudTextAlignment = config.hudTextAlignment,
        excludedApps = cleanExclusions,
        fontTitleSize = config.fontTitleSize,
        fontBodySize = config.fontBodySize,
        hudPosIndex = config.hudPosIndex,
        customHudX = config.customHudX,
        customHudY = config.customHudY,
        bufferX = config.bufferX,
        bufferY = config.bufferY,
        fontCode = config.fontCode,
        fontUI = config.fontUI,
        fontUIBold = config.fontUIBold,
        isReactiveOpacityEnabled = config.isReactiveOpacityEnabled,
        trainerDifficulty = config.trainerDifficulty,
        isSnippetsEnabled = config.isSnippetsEnabled,
        hasCompletedOnboarding = config.hasCompletedOnboarding,
        snippets = config.snippets
    }
    json.write(settings, settingsFilePath, true, true)
end

function config.load()
    local settings = json.read(settingsFilePath)
    if settings then
        if settings.isMasterEnabled ~= nil then config.isMasterEnabled = settings.isMasterEnabled end
        if settings.isHudEnabled ~= nil then config.isHudEnabled = settings.isHudEnabled end
        if settings.isBufferEnabled ~= nil then config.isBufferEnabled = settings.isBufferEnabled end
        if settings.isActionInfoEnabled ~= nil then config.isActionInfoEnabled = settings.isActionInfoEnabled end
        if settings.isAerospaceEnabled ~= nil then config.isAerospaceEnabled = settings.isAerospaceEnabled end
        if settings.isEscapeMenuEnabled ~= nil then config.isEscapeMenuEnabled = settings.isEscapeMenuEnabled end
        if settings.isMacroEnabled ~= nil then config.isMacroEnabled = settings.isMacroEnabled end
        if settings.isTooltipsEnabled ~= nil then config.isTooltipsEnabled = settings.isTooltipsEnabled end
        if settings.hudTextAlignment ~= nil then config.hudTextAlignment = settings.hudTextAlignment end
        if settings.excludedApps then config.excludedApps = settings.excludedApps end
        if settings.fontTitleSize then config.fontTitleSize = tonumber(settings.fontTitleSize) end
        if settings.fontBodySize then config.fontBodySize = tonumber(settings.fontBodySize) end
        if settings.hudPosIndex then config.hudPosIndex = tonumber(settings.hudPosIndex) end
        if settings.customHudX then config.customHudX = tonumber(settings.customHudX) end
        if settings.customHudY then config.customHudY = tonumber(settings.customHudY) end
        if settings.bufferX then config.bufferX = tonumber(settings.bufferX) end
        if settings.bufferY then config.bufferY = tonumber(settings.bufferY) end
        if settings.fontCode then config.fontCode = settings.fontCode end
        if settings.fontUI then config.fontUI = settings.fontUI end
        if settings.fontUIBold then config.fontUIBold = settings.fontUIBold end
        if settings.isReactiveOpacityEnabled ~= nil then config.isReactiveOpacityEnabled = settings.isReactiveOpacityEnabled end
        if settings.trainerDifficulty then config.trainerDifficulty = tonumber(settings.trainerDifficulty) end
        if settings.isSnippetsEnabled ~= nil then config.isSnippetsEnabled = settings.isSnippetsEnabled end
        if settings.hasCompletedOnboarding ~= nil then config.hasCompletedOnboarding = settings.hasCompletedOnboarding end
        if settings.snippets then 
            for k, v in pairs(settings.snippets) do
                config.snippets[k] = v
            end
        end
    end
end

return config
