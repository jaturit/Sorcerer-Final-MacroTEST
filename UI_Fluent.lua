-- [[ UI_Fluent.lua - Fluent Plus UI shell + legacy fallback ]]
-- Module 10 of 11 | Sorcerer Final Macro - Modular Edition

local HttpService = _G._Services.HttpService
local Player = _G._Player
local FOLDER = _G._FOLDER
local CASINO_FOLDER = _G._CASINO_FOLDER
local SaveConfig = _G.SaveConfig
local LoadConfig = _G.LoadConfig
local SaveMapMacros = _G.SaveMapMacros
local LoadMapMacros = _G.LoadMapMacros
local MapMacros = _G._MapMacros
local GetCurrentMapName = _G.GetCurrentMapName
local RunMacroLogic = _G.RunMacroLogic
local RunCasinoMacroLogic = _G.RunCasinoMacroLogic
local StartCasinoDoorTracker = _G.StartCasinoDoorTracker
local StopCasinoDoorTracker = _G.StopCasinoDoorTracker
local RejoinVIPServer = _G.RejoinVIPServer
local ApplyLowPerformanceMode = _G.ApplyLowPerformanceMode
local SetLowPerformanceFPS = _G.SetLowPerformanceFPS
local UserAuth = _G._UserAuth
local HookEnabled = _G._HookEnabled

local LegacyLoadMainUI = _G.LoadMainUI
_G.LoadLegacyUI = LegacyLoadMainUI

local FLUENT_URL = "https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"

local function safeCall(label, fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("[Fluent UI] " .. label .. ": " .. tostring(err))
    end
    return ok
end

local function save()
    if SaveConfig then
        SaveConfig()
    end
end

local function notify(Fluent, title, content)
    if Fluent then
        safeCall("notify", function()
            Fluent:Notify({
                Title = title,
                Content = content,
                Duration = 4
            })
        end)
    else
        print("[Fluent UI] " .. title .. " - " .. content)
    end
end

local function cleanName(text)
    text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    text = text:gsub("%.json$", "")
    text = text:gsub("[/\\:]", "_")
    return text
end

local function fileBase(path)
    local name = tostring(path):match("[^/\\]+$") or tostring(path)
    return name:gsub("%.json$", "")
end

local function isSystemJson(path)
    local lower = tostring(path):lower()
    return lower:find("user_auth")
        or lower:find("settings")
        or lower:find("std_auth")
        or lower:find("auth")
        or lower:find("config")
        or lower:find("_backup")
        or lower:find("map_macros")
        or lower:find("story_towers")
        or lower:find("card_blacklist")
        or lower:find("dashboard_cache")
        or lower:find("event_colony")
end

local function listJsonFiles(folder)
    local files = { "None" }
    safeCall("list files", function()
        if not listfiles then return end
        for _, path in pairs(listfiles(folder)) do
            if tostring(path):sub(-5) == ".json" and not isSystemJson(path) then
                local name = fileBase(path)
                if name ~= "" and name:sub(1, 1) ~= "_" and name:sub(1, 1) ~= "." then
                    table.insert(files, name)
                end
            end
        end
    end)
    table.sort(files, function(a, b)
        if a == "None" then return true end
        if b == "None" then return false end
        return a:lower() < b:lower()
    end)
    return files
end

local function ensureEventFolder()
    local folder = FOLDER .. "/event"
    safeCall("make event folder", function()
        if makefolder and not isfolder(folder) then
            makefolder(folder)
        end
    end)
    return folder
end

local function listEventFiles()
    return listJsonFiles(ensureEventFolder())
end

local function createFile(folder, name)
    name = cleanName(name)
    if name == "" or name == "None" then return false end
    safeCall("create file", function()
        writefile(folder .. "/" .. name .. ".json", "[]")
    end)
    return true
end

local function deleteFile(folder, name)
    name = cleanName(name)
    if name == "" or name == "None" then return false end
    safeCall("delete file", function()
        local path = folder .. "/" .. name .. ".json"
        if isfile(path) then
            delfile(path)
        end
    end)
    return true
end

local function setToggleVisual(toggle, value)
    if not toggle then return end
    safeCall("set toggle visual", function()
        if toggle.SetValue then
            toggle:SetValue(value)
        elseif toggle.Set then
            toggle:Set(value)
        end
    end)
end

local function refreshDropdown(dropdown, values)
    if not dropdown then return end
    safeCall("refresh dropdown", function()
        if dropdown.SetValues then
            dropdown:SetValues(values)
        elseif dropdown.Refresh then
            dropdown:Refresh(values)
        end
    end)
end

local function addButton(section, title, description, icon, callback)
    return section:AddButton({
        Title = title,
        Description = description,
        Icon = icon,
        Callback = function()
            safeCall(title, callback)
        end
    })
end

local function addToggle(section, key, title, description, default, icon, callback)
    return section:AddToggle(key, {
        Title = title,
        Description = description,
        Default = default and true or false,
        Icon = icon,
        Callback = function(value)
            safeCall(title, function()
                callback(value)
            end)
        end
    })
end

local function addInput(section, key, title, placeholder, default, numeric, callback)
    return section:AddInput(key, {
        Title = title,
        Default = tostring(default or ""),
        Placeholder = placeholder or "",
        Numeric = numeric and true or false,
        Finished = false,
        Callback = function(value)
            safeCall(title, function()
                callback(value)
            end)
        end
    })
end

local function addDropdown(section, key, title, values, default, callback)
    return section:AddDropdown(key, {
        Title = title,
        Values = values,
        Default = default or values[1],
        Multi = false,
        AllowNull = false,
        Search = true,
        Callback = function(value)
            safeCall(title, function()
                callback(value)
            end)
        end
    })
end

local function setAutoPlay(value)
    _G._IsEventAutoPlay = false
    _G.AutoPlay = value and true or false
    if _G.AutoPlay then
        task.spawn(function()
            RunMacroLogic()
        end)
    else
        _G.MacroRunning = false
    end
    save()
end

local function setLagSaver(value)
    _G.LowPerformanceMode = value and true or false
    if ApplyLowPerformanceMode then
        ApplyLowPerformanceMode(_G.LowPerformanceMode)
    end
    save()
end

local function startCasinoLoop()
    task.spawn(function()
        while _G.AutoCasinoEnabled do
            local file = _G.CasinoSelectedFile or "None"
            if file == "None" or file == "" then
                _G.AutoCasinoEnabled = false
                _G.AutoCasinoPlay = false
                break
            end
            _G.AutoCasinoPlay = true
            RunCasinoMacroLogic()
            _G.AutoCasinoPlay = false
            if _G.AutoCasinoEnabled then
                task.wait(5)
            end
        end
        save()
    end)
end

local function createFluentUI()
    LoadConfig()
    LoadMapMacros()
    if _G.LoadStoryTowers then
        _G.LoadStoryTowers()
    end

    local Fluent, SaveManager, InterfaceManager
    local loaded = safeCall("load Fluent Plus", function()
        Fluent, SaveManager, InterfaceManager = loadstring(game:HttpGet(FLUENT_URL))()
    end)

    if not loaded or not Fluent then
        warn("[Fluent UI] Fluent Plus failed to load, opening legacy UI.")
        if LegacyLoadMainUI then
            LegacyLoadMainUI()
        end
        return
    end

    safeCall("manager setup", function()
        if SaveManager then
            SaveManager:SetLibrary(Fluent)
            SaveManager:SetFolder("SorcererFinalMacro/Fluent")
            SaveManager:IgnoreThemeSettings()
        end
        if InterfaceManager then
            InterfaceManager:SetLibrary(Fluent)
            InterfaceManager:SetFolder("SorcererFinalMacro/Interface")
        end
    end)

    local Window = Fluent:CreateWindow({
        Title = "Sorcerer Final Macro",
        SubTitle = "Fluent Plus UI",
        TitleIcon = "sparkles",
        Size = UDim2.fromOffset(700, 540),
        TabWidth = 170,
        Acrylic = true,
        Theme = "Dark",
        Search = true,
        MinimizeKey = Enum.KeyCode.LeftControl,
        UserInfo = true,
        UserInfoTitle = Player.Name,
        UserInfoSubtitle = "Macro Ready",
        UserInfoTop = false
    })

    local Tabs = {
        Dashboard = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" }),
        GoodFarm = Window:AddTab({ Title = "Good Farm", Icon = "sprout" }),
        Macro = Window:AddTab({ Title = "Macro", Icon = "folder-open" }),
        AutoJoin = Window:AddTab({ Title = "Auto Join", Icon = "log-in" }),
        Casino = Window:AddTab({ Title = "Casino", Icon = "dice-5" }),
        Story = Window:AddTab({ Title = "Story", Icon = "book-open" }),
        Event = Window:AddTab({ Title = "Event", Icon = "tickets" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

    -- Dashboard
    local quick = Tabs.Dashboard:AddSection("Quick Controls", "zap")
    local autoPlayToggle = addToggle(quick, "AutoPlayMacro", "Auto Play Macro", "Run selected macro in the current map.", _G.AutoPlay, "play", setAutoPlay)
    _G.SetDashboardAutoPlay = function(value)
        setToggleVisual(autoPlayToggle, value)
        _G.AutoPlay = value and true or false
    end

    addToggle(quick, "AutoReplay", "Auto Replay", "Replay after a run ends.", _G.AutoReplay, "repeat", function(value)
        _G.AutoReplay = value
        save()
    end)
    addToggle(quick, "AutoSkip", "Auto Skip", "Vote skip automatically.", _G.AutoSkip, "fast-forward", function(value)
        _G.AutoSkip = value
        save()
    end)
    addToggle(quick, "FastSkip", "Fast Vote Skip", "Spam vote skip faster while enabled.", _G.FastSkip, "skip-forward", function(value)
        _G.FastSkip = value
        save()
    end)

    local lagToggle = addToggle(quick, "LagSaver", "Lag Saver", "White screen + low FPS for farming.", _G.LowPerformanceMode, "monitor-off", setLagSaver)
    _G.SetLagSaverToggle = function(value)
        setToggleVisual(lagToggle, value)
        _G.LowPerformanceMode = value and true or false
    end

    addInput(quick, "LagSaverFPS", "Lag Saver FPS", "15", _G.LowPerformanceFPS or 15, true, function(value)
        local fps = tonumber(value)
        if not fps then return end
        fps = math.clamp(fps, 5, 60)
        _G.LowPerformanceFPS = fps
        if SetLowPerformanceFPS then
            SetLowPerformanceFPS(fps)
        end
        save()
    end)

    local info = Tabs.Dashboard:AddSection("Status", "activity")
    info:AddParagraph({
        Title = "Selected",
        Content = "Macro: " .. tostring(_G.SelectedFile or "None") .. "\nCasino: " .. tostring(_G.CasinoSelectedFile or "None") .. "\nGood Farm: " .. tostring(_G.GoodFarmRoundsDone or 0) .. " rounds done"
    })
    addButton(info, "Open Legacy UI", "Open the original full UI with every advanced tool.", "panels-top-left", function()
        if LegacyLoadMainUI then
            LegacyLoadMainUI()
        end
    end)
    addButton(info, "Rejoin Private Server", "Use the saved private server link now.", "refresh-cw", function()
        if RejoinVIPServer then
            RejoinVIPServer()
        end
    end)

    -- Good Farm
    local farm = Tabs.GoodFarm:AddSection("Queue", "list-ordered")
    addToggle(farm, "AutoGoodFarm", "Auto All Farm", "Run enabled queue modes in order.", _G.AutoGoodFarm, "sprout", function(value)
        _G.AutoGoodFarm = value
        if not value then
            _G.GoodFarmRoundsDone = 0
            _G.GoodFarmCurrentMode = 1
        end
        save()
        if _G.SaveGoodFarmState then
            _G.SaveGoodFarmState()
        end
    end)
    addButton(farm, "Reset Good Farm Progress", "Set current mode and rounds back to the beginning.", "rotate-ccw", function()
        _G.GoodFarmRoundsDone = 0
        _G.GoodFarmCurrentMode = 1
        save()
        if _G.SaveGoodFarmState then
            _G.SaveGoodFarmState()
        end
    end)

    for index, item in ipairs(_G.GoodFarmQueue or {}) do
        local mode = tostring(item.Mode or ("Mode" .. index))
        local section = Tabs.GoodFarm:AddSection(mode, "circle")
        addInput(section, "GFRounds" .. mode, "Rounds", "0", item.Rounds or 0, true, function(value)
            item.Rounds = math.max(0, tonumber(value) or 0)
            save()
        end)
        addInput(section, "GFMacro" .. mode, "Macro File", "None", item.MacroFile or "None", false, function(value)
            item.MacroFile = cleanName(value)
            if item.MacroFile == "" then
                item.MacroFile = "None"
            end
            save()
        end)
    end

    -- Macro
    local macroFiles = listJsonFiles(FOLDER)
    local macroFileName = ""
    local macro = Tabs.Macro:AddSection("Macro Files", "folder")
    local macroDropdown = addDropdown(macro, "SelectedMacro", "Selected Macro", macroFiles, _G.SelectedFile or "None", function(value)
        _G.SelectedFile = value
        save()
    end)
    addInput(macro, "NewMacroName", "New File Name", "farm_1", "", false, function(value)
        macroFileName = value
    end)
    addButton(macro, "Create Macro File", "Create an empty macro file.", "file-plus", function()
        if createFile(FOLDER, macroFileName) then
            _G.SelectedFile = cleanName(macroFileName)
            refreshDropdown(macroDropdown, listJsonFiles(FOLDER))
            save()
        end
    end)
    addButton(macro, "Delete Selected Macro", "Delete the currently selected macro file.", "trash-2", function()
        if deleteFile(FOLDER, _G.SelectedFile) then
            _G.SelectedFile = "None"
            refreshDropdown(macroDropdown, listJsonFiles(FOLDER))
            save()
        end
    end)
    addButton(macro, "Refresh Macro List", "Reload macro files from disk.", "refresh-cw", function()
        refreshDropdown(macroDropdown, listJsonFiles(FOLDER))
    end)

    local record = Tabs.Macro:AddSection("Recorder", "radio")
    local currentData = {}
    local placedTowers = {}
    addToggle(record, "RecordMacro", "Record Macro", "Record tower actions into the selected macro file.", false, "circle-dot", function(value)
        if not HookEnabled then
            warn("[Fluent UI] Recording hook is not available.")
            return
        end
        _G._IsRecording = value
        if value then
            currentData = {}
            placedTowers = {}
            _G._CurrentData = currentData
            _G._PlacedTowers = placedTowers
        else
            if _G.SelectedFile and _G.SelectedFile ~= "None" then
                local mapName = GetCurrentMapName and GetCurrentMapName() or nil
                local data = {
                    MapName = mapName,
                    Actions = _G._CurrentData or currentData
                }
                safeCall("save macro recording", function()
                    writefile(FOLDER .. "/" .. _G.SelectedFile .. ".json", HttpService:JSONEncode(data))
                end)
                if mapName and (not MapMacros[mapName] or MapMacros[mapName] == "") then
                    MapMacros[mapName] = _G.SelectedFile
                    SaveMapMacros()
                end
            end
        end
    end)

    addButton(record, "Bind Current Map", "Bind the current map to selected macro.", "map-pin", function()
        local mapName = GetCurrentMapName and GetCurrentMapName() or nil
        if mapName and _G.SelectedFile and _G.SelectedFile ~= "None" then
            MapMacros[mapName] = _G.SelectedFile
            SaveMapMacros()
        end
    end)

    -- Auto Join
    local autoJoin = Tabs.AutoJoin:AddSection("Auto Join", "log-in")
    addToggle(autoJoin, "AutoJoinCasino", "Auto Join Casino", "Join Casino automatically from lobby.", _G.AutoJoinCasino, "dice-5", function(value)
        _G.AutoJoinCasino = value
        save()
    end)
    addToggle(autoJoin, "AutoJoinRaidMeguna", "Auto Join Raid (Meguna)", "Join Meguna raid automatically.", _G.AutoJoinRaid, "swords", function(value)
        _G.AutoJoinRaid = value
        save()
    end)
    addToggle(autoJoin, "AutoJoinRaidGojo", "Auto Join Raid (Gojo)", "Join Gojo raid automatically.", _G.AutoJoinRaidGojo, "sparkles", function(value)
        _G.AutoJoinRaidGojo = value
        save()
    end)
    addToggle(autoJoin, "AutoToLobby", "Auto To Lobby", "Go back to lobby after a run ends.", _G.AutoToLobby, "door-open", function(value)
        _G.AutoToLobby = value
        save()
    end)
    addToggle(autoJoin, "AutoRejoinPS", "Auto Rejoin Private Server", "Use private server link after teleport errors.", _G.AutoRejoinPS, "refresh-cw", function(value)
        _G.AutoRejoinPS = value
        save()
    end)
    addInput(autoJoin, "PrivateServerLink", "Private Server Link", "https://www.roblox.com/games/...", _G.PrivateServerLink or "", false, function(value)
        _G.PrivateServerLink = value
        save()
    end)

    -- Casino
    local casinoFiles = listJsonFiles(CASINO_FOLDER)
    local casinoFileName = ""
    local casino = Tabs.Casino:AddSection("Casino Macro", "dice-5")
    local casinoDropdown = addDropdown(casino, "CasinoSelectedFile", "Selected Casino Macro", casinoFiles, _G.CasinoSelectedFile or "None", function(value)
        _G.CasinoSelectedFile = value
        save()
    end)
    addToggle(casino, "AutoCasinoEnabled", "Auto Play Casino Macro", "Loop the selected casino macro.", _G.AutoCasinoEnabled, "play", function(value)
        _G.AutoCasinoEnabled = value
        _G.AutoCasinoPlay = value
        save()
        if value then
            startCasinoLoop()
        end
    end)
    addDropdown(casino, "CasinoSpawnType", "Next Spawn Type", { "Defense", "Farm", "DefenseBoss", "KyoFarm" }, _G._CasinoNextSpawnType or "Defense", function(value)
        _G._CasinoNextSpawnType = value
    end)
    addInput(casino, "NewCasinoName", "New Casino File", "casino_1", "", false, function(value)
        casinoFileName = value
    end)
    addButton(casino, "Create Casino File", "Create an empty casino macro file.", "file-plus", function()
        if createFile(CASINO_FOLDER, casinoFileName) then
            _G.CasinoSelectedFile = cleanName(casinoFileName)
            refreshDropdown(casinoDropdown, listJsonFiles(CASINO_FOLDER))
            save()
        end
    end)
    addButton(casino, "Delete Selected Casino File", "Delete the selected casino macro.", "trash-2", function()
        if deleteFile(CASINO_FOLDER, _G.CasinoSelectedFile) then
            _G.CasinoSelectedFile = "None"
            refreshDropdown(casinoDropdown, listJsonFiles(CASINO_FOLDER))
            save()
        end
    end)
    addButton(casino, "Refresh Casino List", "Reload casino macro files from disk.", "refresh-cw", function()
        refreshDropdown(casinoDropdown, listJsonFiles(CASINO_FOLDER))
    end)

    local casinoRecord = Tabs.Casino:AddSection("Casino Recorder", "radio")
    addToggle(casinoRecord, "RecordCasino", "Record Casino Macro", "Record casino tower actions into selected file.", false, "circle-dot", function(value)
        if not HookEnabled then
            warn("[Fluent UI] Recording hook is not available.")
            return
        end
        if (_G.CasinoSelectedFile or "None") == "None" then
            warn("[Fluent UI] Select casino macro file first.")
            return
        end
        _G._CasinoIsRecording = value
        if value then
            _G._CasinoCurrentData = {}
            _G._CasinoPlacedTowers = {}
            if StartCasinoDoorTracker then
                StartCasinoDoorTracker()
            end
        else
            if StopCasinoDoorTracker then
                StopCasinoDoorTracker()
            end
            safeCall("save casino recording", function()
                writefile(CASINO_FOLDER .. "/" .. _G.CasinoSelectedFile .. ".json", HttpService:JSONEncode(_G._CasinoCurrentData or {}))
            end)
        end
    end)

    -- Story
    local story = Tabs.Story:AddSection("Story Auto", "book-open")
    addInput(story, "StoryChapter", "Chapter", "1", _G.StoryChapter or 1, true, function(value)
        _G.StoryChapter = math.max(1, tonumber(value) or 1)
        save()
    end)
    addInput(story, "StoryStage", "Stage", "1", _G.StoryCurrentStage or 1, true, function(value)
        _G.StoryCurrentStage = math.max(1, tonumber(value) or 1)
        save()
    end)
    addDropdown(story, "StoryDifficulty", "Difficulty", { "Normal", "Hard", "Hell" }, _G.StoryCurrentDifficulty or "Normal", function(value)
        _G.StoryCurrentDifficulty = value
        save()
    end)
    addToggle(story, "AutoStory", "Auto Play Story", "Join and play story stages automatically.", _G.AutoStory, "play", function(value)
        _G.AutoStory = value
        if value then
            _G.StoryMacroMode = false
            _G.AutoCasinoPlay = false
            _G.AutoJoinRaid = false
            _G.AutoJoinRaidGojo = false
        end
        save()
    end)
    addToggle(story, "StoryMacroMode", "Play Macro Mode", "Use the selected macro file for story.", _G.StoryMacroMode, "folder-play", function(value)
        _G.StoryMacroMode = value
        if value then
            _G.AutoStory = false
            _G.AutoPlay = true
        end
        save()
    end)
    addToggle(story, "StoryFriendsOnly", "Friends Only", "Use friends-only elevators where supported.", _G.StoryFriendsOnly, "users", function(value)
        _G.StoryFriendsOnly = value
        save()
    end)

    -- Event
    local event = Tabs.Event:AddSection("Event Control", "tickets")
    local eventToggle = addToggle(event, "AutoEvent", "Auto Event", "Join event and run event automation.", _G.AutoEvent, "tickets", function(value)
        _G.AutoEvent = value
        save()
    end)
    _G.SetEventToggle = function(value)
        setToggleVisual(eventToggle, value)
        _G.AutoEvent = value and true or false
    end

    local eventMacroToggle = addToggle(event, "AutoEventMacro", "Auto Play Event Macro", "Play event macro after card select.", _G.AutoEventMacro, "play", function(value)
        _G.AutoEventMacro = value
        save()
    end)
    _G.SetEventMacroToggle = function(value)
        setToggleVisual(eventMacroToggle, value)
        _G.AutoEventMacro = value and true or false
    end

    local eventEquipToggle = addToggle(event, "AutoEventEquip", "Auto Equip Event", "Equip towers from event macro.", _G.AutoEventEquip, "wrench", function(value)
        _G.AutoEventEquip = value
        save()
    end)
    _G.SetEventEquipToggle = function(value)
        setToggleVisual(eventEquipToggle, value)
        _G.AutoEventEquip = value and true or false
    end

    local cardMap = {
        ["Skip"] = 0,
        ["Card 1"] = 1,
        ["Card 2"] = 2,
        ["Card 3"] = 3,
        ["Smart"] = -1
    }
    local currentCard = "Skip"
    for name, id in pairs(cardMap) do
        if id == (_G.EventCardChoice or 0) then
            currentCard = name
        end
    end
    addDropdown(event, "EventCardChoice", "Card Choice", { "Skip", "Card 1", "Card 2", "Card 3", "Smart" }, currentCard, function(value)
        _G.EventCardChoice = cardMap[value] or 0
        save()
    end)

    local eventFiles = listEventFiles()
    local eventFileName = ""
    local eventFile = Tabs.Event:AddSection("Event Macro Files", "folder")
    local eventDropdown = addDropdown(eventFile, "EventSelectedFile", "Selected Event Macro", eventFiles, _G.EventSelectedFile or "None", function(value)
        _G.EventSelectedFile = value
        save()
    end)
    addInput(eventFile, "NewEventMacroName", "New Event File", "event_1", "", false, function(value)
        eventFileName = value
    end)
    addButton(eventFile, "Create Event File", "Create an empty event macro file.", "file-plus", function()
        local folder = ensureEventFolder()
        if createFile(folder, eventFileName) then
            _G.EventSelectedFile = cleanName(eventFileName)
            refreshDropdown(eventDropdown, listEventFiles())
            save()
        end
    end)
    addButton(eventFile, "Refresh Event List", "Reload event macro files from disk.", "refresh-cw", function()
        refreshDropdown(eventDropdown, listEventFiles())
    end)

    -- Settings
    local settings = Tabs.Settings:AddSection("Notifications", "bell")
    addInput(settings, "DiscordWebhook", "Discord Webhook", "https://discord.com/api/webhooks/...", _G.DiscordURL or "", false, function(value)
        _G.DiscordURL = value
        save()
    end)
    addButton(settings, "Test Webhook", "Send a small test message.", "send", function()
        if _G.SendWebhook then
            _G.SendWebhook("Test Message\nPlayer: " .. Player.Name)
        end
    end)

    local account = Tabs.Settings:AddSection("Account", "key-round")
    addButton(account, "Logout Key", "Clear saved license and show login again next run.", "log-out", function()
        if UserAuth then
            UserAuth:Logout()
            notify(Fluent, "Logged out", "Your saved key has been cleared.")
        end
    end)

    safeCall("settings sections", function()
        if InterfaceManager then
            InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        end
        if SaveManager then
            SaveManager:BuildConfigSection(Tabs.Settings)
        end
    end)

    Window:SelectTab(1)
    notify(Fluent, "Fluent Plus", "Sorcerer Final Macro UI loaded.")
end

_G.LoadFluentUI = createFluentUI
_G.LoadMainUI = createFluentUI

print("[Module 10/11] UI_Fluent.lua loaded successfully")
