local trainer = {}

local canvas = require("hs.canvas")
local timer = require("hs.timer")
local constants = require("modules.constants")
local config = require("modules.config")
local ui = require("modules.ui")

local fs = require("hs.fs")
local json = require("hs.json")

local homeDir = os.getenv("HOME")
local saveDir = homeDir .. "/Documents/Vimualizer"
local statsFilePath = saveDir .. "/trainer_stats.json"
trainer.isActive = false
trainer.onboarding = false
trainer.difficulty = config.trainerDifficulty or 1
trainer.mistakeCount = 0
trainer.stats = { xp = 0, level = 1, streak = 0, totalCorrect = 0 }

local function ensureDirectoryExists()
    local attrs = fs.attributes(saveDir)
    if not attrs then fs.mkdir(saveDir) end
end

function trainer.save()
    ensureDirectoryExists()
    json.write(trainer.stats, statsFilePath, true, true)
end

function trainer.load()
    local loadedData = json.read(statsFilePath)
    if loadedData then
        for k, v in pairs(loadedData) do
            trainer.stats[k] = v
        end
    end
end

trainer.challenges = {
    -- DIFFICULTY 1: BEGINNER (Basics & Single Key Motions)
    { prompt = "Undo last action", target = "u", diff = 1, xp = 10 },
    { prompt = "Delete character under cursor", target = "x", diff = 1, xp = 10 },
    { prompt = "Insert text (Insert Mode)", target = "i", diff = 1, xp = 5 },
    { prompt = "Append text after cursor", target = "a", diff = 1, xp = 5 },
    { prompt = "Move down one line", target = "j", diff = 1, xp = 5 },
    { prompt = "Move up one line", target = "k", diff = 1, xp = 5 },
    { prompt = "Move left one char", target = "h", diff = 1, xp = 5 },
    { prompt = "Move right one char", target = "l", diff = 1, xp = 5 },
    { prompt = "Start of word", target = "w", diff = 1, xp = 10 },
    { prompt = "End of word", target = "e", diff = 1, xp = 10 },
    { prompt = "Start of line", target = "0", diff = 1, xp = 10 },
    { prompt = "End of line", target = "$", diff = 1, xp = 10 },
    { prompt = "Top of file", target = "gg", diff = 1, xp = 15 },
    { prompt = "Bottom of file", target = "G", diff = 1, xp = 15 },
    { prompt = "Paste after cursor", target = "p", diff = 1, xp = 10 },

    -- DIFFICULTY 2: INTERMEDIATE (Text Objects & Operators)
    { prompt = "Change inner word", target = "ciw", diff = 2, xp = 30 },
    { prompt = "Delete inner word", target = "diw", diff = 2, xp = 30 },
    { prompt = "Yank inside double quotes", target = "yi\"", diff = 2, xp = 40 },
    { prompt = "Change inside parentheses", target = "ci(", diff = 2, xp = 40 },
    { prompt = "Delete around paragraph", target = "dap", diff = 2, xp = 45 },
    { prompt = "Join current and next line", target = "J", diff = 2, xp = 20 },
    { prompt = "Jump to matching bracket", target = "%", diff = 2, xp = 25 },
    { prompt = "Find first non-blank char", target = "^", diff = 2, xp = 20 },
    { prompt = "Next paragraph", target = "}", diff = 2, xp = 15 },
    { prompt = "Previous paragraph", target = "{", diff = 2, xp = 15 },
    { prompt = "Redo last action", target = "^r", diff = 2, xp = 25 },
    { prompt = "Change to end of line", target = "C", diff = 2, xp = 25 },
    { prompt = "Delete to end of line", target = "D", diff = 2, xp = 25 },
    { prompt = "Select visual line", target = "V", diff = 2, xp = 20 },

    -- DIFFICULTY 3: ADVANCED (Counts & Efficiency)
    { prompt = "Delete 3 words", target = "3dw", diff = 3, xp = 50 },
    { prompt = "Yank 5 words", target = "y5w", diff = 3, xp = 60 },
    { prompt = "Delete 2 lines down", target = "d2j", diff = 3, xp = 50 },
    { prompt = "Change 3 words back", target = "c3b", diff = 3, xp = 70 },
    { prompt = "Delete inside HTML tags", target = "cit", diff = 3, xp = 80 },
    { prompt = "Jump to screen middle", target = "M", diff = 3, xp = 30 },
    { prompt = "Center screen cursor", target = "zz", diff = 3, xp = 20 },
    { prompt = "Scroll screen to top", target = "zt", diff = 3, xp = 20 },
    { prompt = "Uppercase inner word", target = "gUiw", diff = 3, xp = 60 },
    { prompt = "Delete until next comma", target = "dt,", diff = 3, xp = 70 },
    { prompt = "Change until next period", target = "ct.", diff = 3, xp = 70 },
}

function trainer.start()
    trainer.isActive = true
    trainer.onboarding = true
    trainer.inputBuffer = ""
    if _G.trainerCanvas then 
        _G.trainerCanvas:show() 
        ui.resetOpacity()
    end
    trainer.updateUI()
end

function trainer.beginGame()
    trainer.onboarding = false
    trainer.nextChallenge()
    hs.alert.show("⚡️ VIM SENSEI: BEGIN! ⚡️", 1)
end

function trainer.stop()
    trainer.isActive = false
    if _G.trainerCanvas then _G.trainerCanvas:hide() end
    hs.alert.show("Vim Trainer: Session Paused", 1)
end

function trainer.cycleDifficulty()
    trainer.difficulty = trainer.difficulty + 1
    if trainer.difficulty > 3 then trainer.difficulty = 1 end
    config.trainerDifficulty = trainer.difficulty
    config.save()
    trainer.updateUI()
end

function trainer.nextChallenge()
    local available = {}
    for _, c in ipairs(trainer.challenges) do
        if c.diff == trainer.difficulty then table.insert(available, c) end
    end
    
    if #available == 0 then 
        trainer.currentChallenge = trainer.challenges[1]
    else
        local idx = math.random(1, #available)
        trainer.currentChallenge = available[idx]
    end
    
    trainer.inputBuffer = ""
    trainer.mistakeCount = 0
    trainer.startTime = os.clock()
    trainer.updateUI()
end

function trainer.processKey(key, keyName)
    if not trainer.isActive then return false end
    
    if trainer.onboarding then
        if keyName == "tab" then
            trainer.cycleDifficulty()
            return true
        end
        trainer.beginGame()
        return true
    end

    -- Support for Backspace
    if keyName == "delete" or keyName == "backspace" then
        if #trainer.inputBuffer > 0 then
            trainer.inputBuffer = trainer.inputBuffer:sub(1, -2)
            trainer.updateUI()
        end
        return true
    end

    -- Ignore modifier-only key events
    if #key == 0 then return false end

    trainer.inputBuffer = trainer.inputBuffer .. key
    
    if trainer.inputBuffer == trainer.currentChallenge.target then
        local duration = os.clock() - trainer.startTime
        local baseReward = trainer.currentChallenge.xp
        
        -- Speed & Perfection Bonus
        local speedBonus = (duration < 0.8) and 2 or 1
        local perfectionBonus = (trainer.mistakeCount == 0) and 1.5 or 1
        local reward = math.floor(baseReward * speedBonus * perfectionBonus)
        
        trainer.stats.xp = trainer.stats.xp + reward
        trainer.stats.streak = trainer.stats.streak + 1
        trainer.stats.totalCorrect = trainer.stats.totalCorrect + 1
        
        if trainer.stats.xp >= (trainer.stats.level * 150) then
            trainer.stats.level = trainer.stats.level + 1
            hs.alert.show("✨ LEVEL UP: Master Level " .. trainer.stats.level .. " ✨", 2)
        end
        
        trainer.save()
        local msg = string.format("Correct! +%d XP", reward)
        if speedBonus > 1 then msg = "⚡️ SPEEDY! " .. msg end
        hs.alert.show(msg, 0.8)
        
        trainer.nextChallenge()
        return true
    elseif trainer.currentChallenge.target:sub(1, #trainer.inputBuffer) ~= trainer.inputBuffer then
        -- This is a mistake, but we don't reset. We let them backspace to fix it.
        trainer.stats.streak = 0
        trainer.mistakeCount = trainer.mistakeCount + 1
        
        local alertTxt = "Mistake!"
        if trainer.mistakeCount >= 3 then alertTxt = "HINT REVEALED" end
        hs.alert.show(alertTxt, 0.3)
        
        trainer.updateUI()
        return true 
    end
    
    trainer.updateUI()
    return true
end

function trainer.updateUI()
    if not _G.trainerCanvas or not trainer.isActive then return end
    
    local c = _G.trainerCanvas
    
    local diffNames = {"BEGINNER", "INTERMEDIATE", "ADVANCED"}
    local currentDiff = diffNames[trainer.difficulty]

    if trainer.onboarding then
        c[2].text = "🥋 VIM SENSEI [" .. currentDiff .. "]"
        c[3].text = "Build muscle memory! Hit the keys as they appear.\n[TAB] to cycle difficulty. Any other key to START."
        c[4].text = ""
        c[5].text = "READY TO TRAIN?"
        c[5].textColor = {hex="#FFD60A"}
        c[6].text = "Current Level: " .. currentDiff
        return
    end

    local ch = trainer.currentChallenge
    c[2].text = "CHALLENGE (" .. currentDiff .. "):"
    c[3].text = ch.prompt
    
    -- Check if it's currently a mistake
    local isMistake = (trainer.currentChallenge.target:sub(1, #trainer.inputBuffer) ~= trainer.inputBuffer)

    -- Hint logic: only show target after 3 mistakes on layer 4
    if trainer.mistakeCount >= 3 then
        c[4].text = "HINT: " .. ch.target
    else
        c[4].text = ""
    end
    
    -- Buffer logic: show on layer 5
    c[5].text = (trainer.inputBuffer ~= "") and ("> " .. trainer.inputBuffer) or "Type precisely..."
    c[5].textColor = isMistake and {hex="#FF453A"} or {hex="#FFD60A"}
    
    -- Stats on layer 6
    c[6].text = string.format("Lvl %d | Streak: %d | XP: %d", trainer.stats.level, trainer.stats.streak, trainer.stats.xp)
end

trainer.load()

return trainer
