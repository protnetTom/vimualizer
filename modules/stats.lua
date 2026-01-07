local stats = {}

local fs = require("hs.fs")
local json = require("hs.json")
local timer = require("hs.timer")

local homeDir = os.getenv("HOME")
local saveDir = homeDir .. "/Documents/Vimualizer"
local statsFilePath = saveDir .. "/stats.json"

stats.data = {
    commandFrequency = {},
    totalKeysTyped = 0,
    keysSaved = 0,
    startTime = os.time(),
    lastSave = os.time()
}

local function ensureDirectoryExists()
    local attrs = fs.attributes(saveDir)
    if not attrs then fs.mkdir(saveDir) end
end

function stats.save()
    ensureDirectoryExists()
    json.write(stats.data, statsFilePath, true, true)
    stats.data.lastSave = os.time()
end

function stats.load()
    local loadedData = json.read(statsFilePath)
    if loadedData then
        -- Merge or replace
        for k, v in pairs(loadedData) do
            stats.data[k] = v
        end
    end
end

function stats.recordCommand(cmd)
    if not cmd or cmd == "" then return end
    stats.data.commandFrequency[cmd] = (stats.data.commandFrequency[cmd] or 0) + 1
    stats.data.totalKeysTyped = stats.data.totalKeysTyped + #cmd
    
    -- Auto-save occasionally
    if os.time() - stats.data.lastSave > 300 then
        stats.save()
    end
end

function stats.recordKeysSaved(count)
    stats.data.keysSaved = stats.data.keysSaved + count
end

function stats.getTopCommands(limit)
    local sorted = {}
    for cmd, freq in pairs(stats.data.commandFrequency) do
        table.insert(sorted, {cmd = cmd, freq = freq})
    end
    table.sort(sorted, function(a, b) return a.freq > b.freq end)
    
    local results = {}
    for i = 1, math.min(limit or 10, #sorted) do
        table.insert(results, sorted[i])
    end
    return results
end

-- Initialize on load
stats.load()

return stats
