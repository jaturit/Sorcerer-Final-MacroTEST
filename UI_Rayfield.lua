-- [[ UI_Rayfield.lua - Rayfield UI shell ]]
-- Experimental replacement UI. Keeps the legacy UI available while controls are migrated.

local HttpService = _G._Services.HttpService
local Player = _G._Player
local FOLDER = _G._FOLDER
local CASINO_FOLDER = _G._CASINO_FOLDER
local SaveConfig = _G.SaveConfig
local LoadConfig = _G.LoadConfig
local SaveMapMacros = _G.SaveMapMacros
local GetCurrentMapName = _G.GetCurrentMapName
local RunMacroLogic = _G.RunMacroLogic
local RunCasinoMacroLogic = _G.RunCasinoMacroLogic
local StartCasinoDoorTracker = _G.StartCasinoDoorTracker
local StopCasinoDoorTracker = _G.StopCasinoDoorTracker
local ApplyLowPerformanceMode = _G.ApplyLowPerformanceMode
local SetLowPerformanceFPS = _G.SetLowPerformanceFPS
local UserAuth = _G._UserAuth

local LegacyLoadMainUI = _G.LoadMainUI
_G.LoadLegacyUI = LegacyLoadMainUI

local function safeSave()
    if SaveConfig then
        SaveConfig()
    end
end

local function listJsonFiles(folder)
    local files = { "None" }
    pcall(function()
        for _, file in pairs(listfiles(folder)) do
            local lower = file:lower()
            local isSystemFile =
                lower:find("user_auth")
                or lower:find("settings")
                or lower:find("std_auth")
                or lower:find("auth")
                or lower:find("config")
                or lower:find("_backup")
                or lower:find("map_macros")

            if file:sub(-5) == ".json" and not isSystemFile then
                local name = file:match("[^/\\]+$") or file
                name = name:gsub("%.json$", "")
                if name:sub(1, 1) ~= "_" and name:sub(1, 1) ~= "." then
                    table.insert(files, name)
                end
            end
        end
    end)
    return files
end

local function notify(Rayfield, title, content, duration)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = duration or 4,
        })
    end)
end

local function createRayfieldUI()
    LoadConfig()

    local ok, Rayfield = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)

    if not ok or not Rayfield then
        warn("[Rayfield UI] Failed to load Rayfield, opening legacy UI.")
        if LegacyLoadMainUI then
            LegacyLoadMainUI()
        end
        return
    end

    local Window = Rayfield:CreateWindow({
        Name = "Sorcerer Final Macro",
        LoadingTitle = "Sorcerer Final Macro",
        LoadingSubtitle = "Rayfield UI",
        Theme = "Default",
        ConfigurationSaving = {
            Enabled = false,
        },
        Discord = {
            Enabled = false,
        },
        KeySystem = false,
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
    })

    local Dashboard = Window:CreateTab("Dashboard")
    local Farm = Window:CreateTab("Good Farm")
    local Macro = Window:CreateTab("Macro")
    local AutoJoin = Window:CreateTab("Auto Join")
    local Casino = Window:CreateTab("Casino")
    local Story = Window:CreateTab("Story")
    local Event = Window:CreateTab("Event")
    local Settings = Window:CreateTab("Settings")

    Dashboard:CreateSection("Main Controls")

    Dashboard:CreateToggle({
        Name = "Auto Play Macro",
        CurrentValue = _G.AutoPlay,
        Flag = "RF_AutoPlay",
        Callback = function(value)
            _G._IsEventAutoPlay = false
            _G.AutoPlay = value
            if value then
                RunMacroLogic()
            else
                _G.MacroRunning = false
            end
            safeSave()
        end,
    })

    Dashboard:CreateToggle({
        Name = "Auto Replay",
        CurrentValue = _G.AutoReplay,
        Flag = "RF_AutoReplay",
        Callback = function(value)
            _G.AutoReplay = value
            safeSave()
        end,
    })

    Dashboard:CreateToggle({
        Name = "Auto Skip",
        CurrentValue = _G.AutoSkip,
        Flag = "RF_AutoSkip",
        Callback = function(value)
            _G.AutoSkip = value
            safeSave()
        end,
    })

    Dashboard:CreateToggle({
        Name = "Fast Vote Skip",
        CurrentValue = _G.FastSkip or false,
        Flag = "RF_FastSkip",
        Callback = function(value)
            _G.FastSkip = value
            safeSave()
        end,
    })

    Dashboard:CreateToggle({
        Name = "Lag Saver (White Screen + Low FPS)",
        CurrentValue = _G.LowPerformanceMode or false,
        Flag = "RF_LagSaver",
        Callback = function(value)
            _G.LowPerformanceMode = value
            if ApplyLowPerformanceMode then
                ApplyLowPerformanceMode(value)
            end
            safeSave()
        end,
    })

    Dashboard:CreateInput({
        Name = "Lag Saver FPS",
        CurrentValue = tostring(_G.LowPerformanceFPS or 15),
        PlaceholderText = "10 / 15 / 20",
        RemoveTextAfterFocusLost = false,
        Flag = "RF_LagSaverFPS",
        Callback = function(text)
            local fps = tonumber(text)
            if not fps then return end
            fps = math.clamp(math.floor(fps), 5, 60)
            _G.LowPerformanceFPS = fps
            if SetLowPerformanceFPS then
                SetLowPerformanceFPS(fps)
            end
            safeSave()
        end,
    })

    Dashboard:CreateButton({
        Name = "Exit To Lobby",
        Callback = function()
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ExitGame"):FireServer()
            end)
        end,
    })

    Dashboard:CreateButton({
        Name = "Open Legacy UI (all tools)",
        Callback = function()
            if LegacyLoadMainUI then
                LegacyLoadMainUI()
            end
        end,
    })

    Farm:CreateSection("Good Farm Queue")

    Farm:CreateToggle({
        Name = "Auto All Farm",
        CurrentValue = _G.AutoGoodFarm or false,
        Flag = "RF_AutoGoodFarm",
        Callback = function(value)
            _G.AutoGoodFarm = value
            if not value then
                _G.GoodFarmRoundsDone = 0
                _G.GoodFarmCurrentMode = 1
                if _G.SaveGoodFarmState then
                    _G.SaveGoodFarmState()
                end
            end
            safeSave()
        end,
    })

    Farm:CreateButton({
        Name = "Reset Good Farm Progress",
        Callback = function()
            _G.GoodFarmRoundsDone = 0
            _G.GoodFarmCurrentMode = 1
            if _G.SaveGoodFarmState then
                _G.SaveGoodFarmState()
            end
            safeSave()
            notify(Rayfield, "Good Farm", "Progress reset.")
        end,
    })

    for index, entry in ipairs(_G.GoodFarmQueue or {}) do
        local label = entry.Mode or ("Mode " .. tostring(index))
        Farm:CreateInput({
            Name = label .. " Rounds",
            CurrentValue = tostring(entry.Rounds or 0),
            PlaceholderText = "0 = disabled",
            RemoveTextAfterFocusLost = false,
            Flag = "RF_GF_Rounds_" .. tostring(index),
            Callback = function(text)
                local rounds = tonumber(text)
                if not rounds then return end
                entry.Rounds = math.max(0, math.floor(rounds))
                safeSave()
            end,
        })

        if label ~= "Event" and label ~= "Casino" then
            Farm:CreateInput({
                Name = label .. " Macro",
                CurrentValue = entry.MacroFile or "None",
                PlaceholderText = "macro file name",
                RemoveTextAfterFocusLost = false,
                Flag = "RF_GF_Macro_" .. tostring(index),
                Callback = function(text)
                    entry.MacroFile = (text ~= "" and text) or "None"
                    safeSave()
                end,
            })
        end
    end

    Macro:CreateSection("Macro Files")
    local macroDropdown
    macroDropdown = Macro:CreateDropdown({
        Name = "Selected Macro",
        Options = listJsonFiles(FOLDER),
        CurrentOption = { _G.SelectedFile or "None" },
        MultipleOptions = false,
        Flag = "RF_SelectedMacro",
        Callback = function(options)
            _G.SelectedFile = options[1] or "None"
            safeSave()
        end,
    })

    Macro:CreateButton({
        Name = "Refresh Macro List",
        Callback = function()
            if macroDropdown and macroDropdown.Refresh then
                macroDropdown:Refresh(listJsonFiles(FOLDER))
            end
        end,
    })

    Macro:CreateInput({
        Name = "New Macro File",
        CurrentValue = "",
        PlaceholderText = "file name",
        RemoveTextAfterFocusLost = false,
        Flag = "RF_NewMacroName",
        Callback = function(text)
            _G.FileName = text
        end,
    })

    Macro:CreateButton({
        Name = "Create Macro File",
        Callback = function()
            if _G.FileName and _G.FileName ~= "" then
                pcall(function()
                    writefile(FOLDER .. "/" .. _G.FileName .. ".json", "[]")
                end)
                notify(Rayfield, "Macro", "Created " .. _G.FileName)
            end
        end,
    })

    Macro:CreateButton({
        Name = "Delete Selected Macro",
        Callback = function()
            if _G.SelectedFile and _G.SelectedFile ~= "None" then
                pcall(function()
                    delfile(FOLDER .. "/" .. _G.SelectedFile .. ".json")
                end)
                _G.SelectedFile = "None"
                safeSave()
                notify(Rayfield, "Macro", "Deleted selected macro.")
            end
        end,
    })

    Macro:CreateToggle({
        Name = "Record Macro",
        CurrentValue = false,
        Flag = "RF_RecordMacro",
        Callback = function(value)
            if not _G._HookEnabled then
                warn("[Rayfield UI] Recording hook not available.")
                return
            end
            _G._IsRecording = value
            if value then
                _G._CurrentData = {}
                _G._PlacedTowers = {}
                notify(Rayfield, "Macro", "Recording started.")
            else
                if _G.SelectedFile and _G.SelectedFile ~= "None" then
                    local mapName = GetCurrentMapName and GetCurrentMapName() or nil
                    local saveData = {
                        MapName = mapName,
                        Actions = _G._CurrentData or {},
                    }
                    pcall(function()
                        writefile(FOLDER .. "/" .. _G.SelectedFile .. ".json", HttpService:JSONEncode(saveData))
                    end)
                    if mapName and _G._MapMacros and (not _G._MapMacros[mapName] or _G._MapMacros[mapName] == "") then
                        _G._MapMacros[mapName] = _G.SelectedFile
                        if SaveMapMacros then
                            SaveMapMacros()
                        end
                    end
                    notify(Rayfield, "Macro", "Recording saved.")
                end
            end
        end,
    })

    AutoJoin:CreateSection("Auto Join")
    AutoJoin:CreateToggle({
        Name = "Auto Join Casino",
        CurrentValue = _G.AutoJoinCasino,
        Flag = "RF_AutoJoinCasino",
        Callback = function(value)
            _G.AutoJoinCasino = value
            safeSave()
        end,
    })
    AutoJoin:CreateToggle({
        Name = "Auto Join Raid (Meguna)",
        CurrentValue = _G.AutoJoinRaid,
        Flag = "RF_AutoJoinRaid",
        Callback = function(value)
            _G.AutoJoinRaid = value
            safeSave()
        end,
    })
    AutoJoin:CreateToggle({
        Name = "Auto Join Raid (Gojo)",
        CurrentValue = _G.AutoJoinRaidGojo,
        Flag = "RF_AutoJoinRaidGojo",
        Callback = function(value)
            _G.AutoJoinRaidGojo = value
            safeSave()
        end,
    })
    AutoJoin:CreateToggle({
        Name = "Auto Rejoin Private Server",
        CurrentValue = _G.AutoRejoinPS,
        Flag = "RF_AutoRejoinPS",
        Callback = function(value)
            _G.AutoRejoinPS = value
            safeSave()
        end,
    })
    AutoJoin:CreateInput({
        Name = "Private Server Link",
        CurrentValue = _G.PrivateServerLink or "",
        PlaceholderText = "private server link",
        RemoveTextAfterFocusLost = false,
        Flag = "RF_PrivateServerLink",
        Callback = function(text)
            _G.PrivateServerLink = text
            safeSave()
        end,
    })

    Casino:CreateSection("Casino Macro")
    local casinoDropdown = Casino:CreateDropdown({
        Name = "Selected Casino Macro",
        Options = listJsonFiles(CASINO_FOLDER),
        CurrentOption = { _G.CasinoSelectedFile or "None" },
        MultipleOptions = false,
        Flag = "RF_CasinoMacro",
        Callback = function(options)
            _G.CasinoSelectedFile = options[1] or "None"
            safeSave()
        end,
    })
    Casino:CreateButton({
        Name = "Refresh Casino List",
        Callback = function()
            if casinoDropdown and casinoDropdown.Refresh then
                casinoDropdown:Refresh(listJsonFiles(CASINO_FOLDER))
            end
        end,
    })
    Casino:CreateToggle({
        Name = "Auto Play Casino Macro",
        CurrentValue = _G.AutoCasinoEnabled or false,
        Flag = "RF_CasinoAutoPlay",
        Callback = function(value)
            _G.AutoCasinoEnabled = value
            _G.AutoCasinoPlay = value
            safeSave()
            if value and RunCasinoMacroLogic then
                task.spawn(RunCasinoMacroLogic)
            end
        end,
    })
    Casino:CreateToggle({
        Name = "Record Casino Macro",
        CurrentValue = false,
        Flag = "RF_CasinoRecord",
        Callback = function(value)
            if not _G._HookEnabled then
                warn("[Rayfield UI] Recording hook not available.")
                return
            end
            _G._CasinoIsRecording = value
            if value then
                _G._CasinoCurrentData = {}
                _G._CasinoPlacedTowers = {}
                if StartCasinoDoorTracker then
                    StartCasinoDoorTracker()
                end
                notify(Rayfield, "Casino", "Recording started.")
            else
                if StopCasinoDoorTracker then
                    StopCasinoDoorTracker()
                end
                local fileToSave = _G.CasinoSelectedFile
                if fileToSave and fileToSave ~= "None" and fileToSave ~= "" then
                    pcall(function()
                        writefile(CASINO_FOLDER .. "/" .. fileToSave .. ".json", HttpService:JSONEncode(_G._CasinoCurrentData or {}))
                    end)
                end
                notify(Rayfield, "Casino", "Recording saved.")
            end
        end,
    })
    Casino:CreateDropdown({
        Name = "Next Spawn Type",
        Options = { "Defense", "Farm", "DefenseBoss", "KyoFarm" },
        CurrentOption = { _G._CasinoNextSpawnType or "Defense" },
        MultipleOptions = false,
        Flag = "RF_CasinoSpawnType",
        Callback = function(options)
            _G._CasinoNextSpawnType = options[1] or "Defense"
        end,
    })

    Story:CreateSection("Story")
    Story:CreateInput({
        Name = "Chapter",
        CurrentValue = tostring(_G.StoryChapter or 1),
        PlaceholderText = "1",
        RemoveTextAfterFocusLost = false,
        Flag = "RF_StoryChapter",
        Callback = function(text)
            local value = tonumber(text)
            if value then
                _G.StoryChapter = math.max(1, math.floor(value))
                safeSave()
            end
        end,
    })
    Story:CreateInput({
        Name = "Stage",
        CurrentValue = tostring(_G.StoryCurrentStage or 1),
        PlaceholderText = "1",
        RemoveTextAfterFocusLost = false,
        Flag = "RF_StoryStage",
        Callback = function(text)
            local value = tonumber(text)
            if value then
                _G.StoryCurrentStage = math.max(1, math.floor(value))
                safeSave()
            end
        end,
    })
    Story:CreateDropdown({
        Name = "Difficulty",
        Options = { "Normal", "Hellmode" },
        CurrentOption = { _G.StoryCurrentDifficulty or "Normal" },
        MultipleOptions = false,
        Flag = "RF_StoryDifficulty",
        Callback = function(options)
            _G.StoryCurrentDifficulty = options[1] or "Normal"
            safeSave()
        end,
    })
    Story:CreateToggle({
        Name = "Auto Play Story",
        CurrentValue = _G.AutoStory or false,
        Flag = "RF_AutoStory",
        Callback = function(value)
            _G.AutoStory = value
            if value then
                _G.StoryMacroMode = false
                _G.AutoJoinCasino = false
                _G.AutoCasinoPlay = false
                _G.AutoJoinRaid = false
                _G.AutoJoinRaidGojo = false
            end
            safeSave()
        end,
    })
    Story:CreateToggle({
        Name = "Play Macro Mode",
        CurrentValue = _G.StoryMacroMode or false,
        Flag = "RF_StoryMacroMode",
        Callback = function(value)
            _G.StoryMacroMode = value
            if value then
                _G.AutoStory = false
            end
            safeSave()
        end,
    })

    Event:CreateSection("Event")
    Event:CreateToggle({
        Name = "Auto Event",
        CurrentValue = _G.AutoEvent or false,
        Flag = "RF_AutoEvent",
        Callback = function(value)
            _G.AutoEvent = value
            safeSave()
        end,
    })
    Event:CreateToggle({
        Name = "Auto Play Event Macro",
        CurrentValue = _G.AutoEventMacro or false,
        Flag = "RF_EventMacro",
        Callback = function(value)
            _G.AutoEventMacro = value
            safeSave()
        end,
    })
    Event:CreateToggle({
        Name = "Auto Equip Event",
        CurrentValue = _G.AutoEventEquip or false,
        Flag = "RF_EventEquip",
        Callback = function(value)
            _G.AutoEventEquip = value
            safeSave()
        end,
    })
    Event:CreateDropdown({
        Name = "Card Choice",
        Options = { "Skip", "Card 1", "Card 2", "Card 3", "Smart" },
        CurrentOption = { "Skip" },
        MultipleOptions = false,
        Flag = "RF_EventCard",
        Callback = function(options)
            local selected = options[1] or "Skip"
            local map = {
                ["Skip"] = 0,
                ["Card 1"] = 1,
                ["Card 2"] = 2,
                ["Card 3"] = 3,
                ["Smart"] = -1,
            }
            _G.EventCardChoice = map[selected] or 0
            safeSave()
        end,
    })

    Settings:CreateSection("Settings")
    Settings:CreateInput({
        Name = "Discord Webhook",
        CurrentValue = _G.DiscordURL or "",
        PlaceholderText = "webhook url",
        RemoveTextAfterFocusLost = false,
        Flag = "RF_DiscordWebhook",
        Callback = function(text)
            _G.DiscordURL = text
            safeSave()
        end,
    })
    Settings:CreateButton({
        Name = "Test Webhook",
        Callback = function()
            if _G.SendWebhook then
                _G.SendWebhook("Test Message\nPlayer: " .. Player.Name)
            end
        end,
    })
    Settings:CreateButton({
        Name = "Logout Key",
        Callback = function()
            if UserAuth then
                UserAuth:Logout()
            end
            notify(Rayfield, "Key", "Logged out. Re-run script to login again.")
        end,
    })

    notify(Rayfield, "Rayfield UI", "Loaded. Legacy UI remains available.")
end

_G.LoadRayfieldUI = createRayfieldUI
_G.LoadMainUI = createRayfieldUI

print("[Module 9B/11] UI_Rayfield.lua loaded successfully")
