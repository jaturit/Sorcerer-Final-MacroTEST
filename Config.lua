-- [[ 📦 Config.lua - Services, Global Variables, Colors, Save/Load Config, Map-Macro Binding ]]
-- Module 1 of 12 | Sorcerer Final Macro - Modular Edition

-- ═══════════════════════════════════════════════════════
-- 🔧 SERVICES
-- ═══════════════════════════════════════════════════════

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")

local Request = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or function() return nil end

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local FOLDER = "Sorcerer_Final_Macro"
local CASINO_FOLDER = FOLDER.."/Casino_Macros"
local AUTH_FILE = FOLDER.."/user_auth.json"   -- คีย์ใช้ร่วมกันทุกจอ (ไม่แยก)

-- ═══════════════════════════════════════════════════════
-- 👤 PER-ACCOUNT CONFIG PROFILE
-- เปิดหลายจอด้วยตัวรันเดียวกัน → แต่ละไอดี (UserId) มีโฟลเดอร์คอนฟิกของตัวเอง
-- ไฟล์ macro ที่อัดไว้ยังใช้ร่วมกันที่ FOLDER เหมือนเดิม
-- ═══════════════════════════════════════════════════════
local PROFILES_FOLDER = FOLDER.."/Profiles"
local PROFILE_ID = tostring(Player.UserId)
local PROFILE_FOLDER = PROFILES_FOLDER.."/"..PROFILE_ID
local PROFILE_INFO_FILE = PROFILE_FOLDER.."/profile_info.json"

local CONFIG_FILE = PROFILE_FOLDER.."/settings.json"
local MAP_CONFIG_FILE = PROFILE_FOLDER.."/map_macros.json"
local GOODFARM_STATE_FILE = PROFILE_FOLDER.."/goodfarm_state.json"
local LAGSAVER_STATE_FILE = PROFILE_FOLDER.."/lag_saver_state.json"
local CULLING_POINTS_FILE = PROFILE_FOLDER.."/culling_points.txt"
local LAST_RESULT_FILE = PROFILE_FOLDER.."/last_run_result.json"
local DASHBOARD_FILE = PROFILE_FOLDER.."/dashboard.json"
local EVENT_COLONY_FILE = PROFILE_FOLDER.."/event_colony.txt"
local LAGSAVER_BACKGROUND_IMAGE = "rbxassetid://85556556528294"

-- ไฟล์ที่แยกตามไอดี (ชื่อไฟล์เดียวกับเวอร์ชันเก่าที่อยู่ใน FOLDER)
local PROFILE_FILE_NAMES = {
    "settings.json", "map_macros.json", "goodfarm_state.json", "lag_saver_state.json",
    "culling_points.txt", "last_run_result.json", "dashboard.json", "event_colony.txt",
    "story_towers.json",
}

pcall(function()
    if not isfolder(FOLDER) then makefolder(FOLDER) end
    if not isfolder(CASINO_FOLDER) then makefolder(CASINO_FOLDER) end
    if not isfolder(PROFILES_FOLDER) then makefolder(PROFILES_FOLDER) end
    if not isfolder(PROFILE_FOLDER) then makefolder(PROFILE_FOLDER) end
end)

-- ครั้งแรกที่ไอดีนี้ยังไม่มีไฟล์ของตัวเอง → คัดลอกจากไฟล์เก่า (ใช้ร่วมกัน) มาให้ จะได้ไม่เสียค่าที่ตั้งไว้
pcall(function()
    for _, name in ipairs(PROFILE_FILE_NAMES) do
        local legacyPath = FOLDER.."/"..name
        local profilePath = PROFILE_FOLDER.."/"..name
        if not isfile(profilePath) and isfile(legacyPath) then
            writefile(profilePath, readfile(legacyPath))
        end
    end
end)

-- บันทึกชื่อไอดีไว้ให้หน้า UI แสดงในรายการโปรไฟล์
pcall(function()
    writefile(PROFILE_INFO_FILE, HttpService:JSONEncode({
        UserId = Player.UserId,
        Name = Player.Name,
        DisplayName = Player.DisplayName,
        UpdatedAt = os.time(),
    }))
end)

-- Export Services ผ่าน _G เพื่อให้โมดูลอื่นใช้ได้
_G._Services = {
    HttpService = HttpService,
    Players = Players,
    ReplicatedStorage = ReplicatedStorage,
    UserInputService = UserInputService,
    TweenService = TweenService,
    RunService = RunService,
    Lighting = Lighting,
    ContentProvider = ContentProvider,
}
_G._Request = Request
_G._Player = Player
_G._PlayerGui = PlayerGui
_G._FOLDER = FOLDER
_G._CASINO_FOLDER = CASINO_FOLDER
_G._GOODFARM_STATE_FILE = GOODFARM_STATE_FILE
_G._AUTH_FILE = AUTH_FILE
_G._CONFIG_FILE = CONFIG_FILE
_G._MAP_CONFIG_FILE = MAP_CONFIG_FILE
_G._LAGSAVER_STATE_FILE = LAGSAVER_STATE_FILE
_G._CULLING_POINTS_FILE = CULLING_POINTS_FILE
_G._LAST_RESULT_FILE = LAST_RESULT_FILE
_G._DASHBOARD_FILE = DASHBOARD_FILE
_G._EVENT_COLONY_FILE = EVENT_COLONY_FILE
_G._PROFILES_FOLDER = PROFILES_FOLDER
_G._PROFILE_FOLDER = PROFILE_FOLDER
_G._PROFILE_ID = PROFILE_ID

-- ═══════════════════════════════════════════════════════
-- 🎯 GLOBAL VARIABLES
-- ═══════════════════════════════════════════════════════

_G.SelectedFile = "None"
_G.FileName = ""
_G.AutoReplay = false
_G.AutoSkip = false
_G.AutoPlay = false
_G.AutoUpgrade = false
_G.AutoUpgradeRunning = false
_G.CasinoMacroRunning = false
_G.DiscordURL = ""
_G.AutoJoinCasino = false
_G.AutoToLobby = false
_G.AutoJoinRaid = false
_G.AutoJoinRaidGojo = false
_G.AutoJoinGauntlet = false
_G.AutoCasinoPlay = false
_G.AutoCasinoEnabled = false  -- ผู้ใช้ต้องการ auto (ไม่ reset ตอน macro จบ)
_G.CasinoSelectedFile = "None"
_G.LowPerformanceMode = false
_G.LowPerformanceFPS = 15
_G.CyberpunkUI = true
_G.UIBackgroundImage = "rbxassetid://90298702993965"
_G.UIBackgroundTransparency = 0.52
_G.LagSaverBackgroundImage = LAGSAVER_BACKGROUND_IMAGE

-- Justice Sorcerer
_G.AutoQTE = false
_G.AutoDomain = false

-- Auto Story
_G.AutoStory = false
_G.StoryGameEnded = false
_G.StoryMacroMode = false
_G.StoryFriendsOnly = false
_G.StoryChapter = 1
_G.StoryCurrentStage = 1
_G.StoryCurrentDifficulty = "Normal"
_G.StoryPendingResult = nil -- persisted before ExitGame, consumed after the new lobby session loads

-- Good Farm (Auto All Farm)
_G.AutoGoodFarm = false
_G.GoodFarmCurrentMode = 1
_G.GoodFarmRoundsDone = 0
_G.GoodFarmQueue = {
    { Mode = "Event",       Rounds = 0, MacroFile = "None" },
    { Mode = "RaidMeguna",  Rounds = 0, MacroFile = "None" },
    { Mode = "RaidGojo",    Rounds = 0, MacroFile = "None" },
    { Mode = "InfiniteNew", Rounds = 0, MacroFile = "None" },
    { Mode = "Casino",      Rounds = 0, MacroFile = "None" },
    { Mode = "StoryHell15", Rounds = 0, MacroFile = "None" },
}

-- Story Tower Registration (4 slots)
_G.StorySetupMode = nil  -- nil = off, "Damage1"/"Damage2"/"Farm1"/"Farm2" = waiting for tower place
_G.StoryTowers = {
    Damage1 = { ID = nil, TowerName = nil, Count = 1 },
    Damage2 = { ID = nil, TowerName = nil, Count = 0 },
    Farm1   = { ID = nil, TowerName = nil, Count = 2 },
    Farm2   = { ID = nil, TowerName = nil, Count = 0 },
}
local STORY_TOWER_FILE = PROFILE_FOLDER.."/story_towers.json"
_G._STORY_TOWER_FILE = STORY_TOWER_FILE

local function SaveStoryTowers()
    pcall(function()
        local data = {}
        for k, v in pairs(_G.StoryTowers) do
            data[k] = { ID = v.ID, TowerName = v.TowerName, Count = v.Count }
        end
        writefile(STORY_TOWER_FILE, HttpService:JSONEncode(data))
    end)
end

local function LoadStoryTowers()
    pcall(function()
        if isfile(STORY_TOWER_FILE) then
            local data = HttpService:JSONDecode(readfile(STORY_TOWER_FILE))
            for k, v in pairs(data) do
                if _G.StoryTowers[k] then
                    _G.StoryTowers[k].ID = v.ID
                    _G.StoryTowers[k].TowerName = v.TowerName
                    _G.StoryTowers[k].Count = v.Count or 0
                end
            end
        end
    end)
end

_G.SaveStoryTowers = SaveStoryTowers
_G.LoadStoryTowers = LoadStoryTowers

local CasinoNextSpawnType = "Defense" -- "Farm" หรือ "Defense"

local IsRecording = false
local CurrentData = {}
local PlacedTowers = {}

-- Export shared local state ผ่าน _G
_G._CasinoNextSpawnType = CasinoNextSpawnType
_G._IsRecording = IsRecording
_G._CurrentData = CurrentData
_G._PlacedTowers = PlacedTowers

-- ═══════════════════════════════════════════════════════
-- 🎨 NEON RED COLOR SCHEME
-- ═══════════════════════════════════════════════════════

local Colors = {
    NeonRed = Color3.fromRGB(255, 20, 60),
    DarkRed = Color3.fromRGB(180, 0, 30),
    Black = Color3.fromRGB(10, 10, 15),
    DarkGray = Color3.fromRGB(20, 20, 25),
    MediumGray = Color3.fromRGB(30, 30, 35),
    LightGray = Color3.fromRGB(200, 200, 200),
    White = Color3.fromRGB(255, 255, 255),
    RedGlow = Color3.fromRGB(255, 50, 80),
    Green = Color3.fromRGB(0, 255, 100),
    Yellow = Color3.fromRGB(255, 200, 0),
    Orange = Color3.fromRGB(255, 150, 0),
}
_G._Colors = Colors

-- Low FPS / low graphics mode for long farm sessions.
local performanceState = {
    originals = setmetatable({}, { __mode = "k" }),
    connection = nil,
    originalFPSCap = nil,
    screenCover = nil,
}

local function ClampNumber(value, minValue, maxValue)
    value = tonumber(value) or minValue
    value = math.floor(value)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function SaveOriginal(instance, property)
    local ok, current = pcall(function()
        return instance[property]
    end)
    if not ok then return end
    local props = performanceState.originals[instance]
    if not props then
        props = {}
        performanceState.originals[instance] = props
    end
    if props[property] == nil then
        props[property] = current
    end
end

local function SetOptimizedProperty(instance, property, value)
    pcall(function()
        SaveOriginal(instance, property)
        instance[property] = value
    end)
end

local function GetFPSCapper()
    return setfpscap or set_fps_cap or (syn and syn.setfpscap)
end

local function SetFPSCap(value)
    local capper = GetFPSCapper()
    if type(capper) == "function" then
        pcall(capper, value)
        return true
    end
    return false
end

local function ApplyQualityLevel()
    pcall(function()
        UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

local function OptimizeInstance(instance)
    if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
        or instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then
        SetOptimizedProperty(instance, "Enabled", false)
    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        SetOptimizedProperty(instance, "Transparency", 1)
    elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
        SetOptimizedProperty(instance, "Enabled", false)
    elseif instance:IsA("PostEffect") then
        SetOptimizedProperty(instance, "Enabled", false)
    elseif instance:IsA("BasePart") then
        SetOptimizedProperty(instance, "CastShadow", false)
        SetOptimizedProperty(instance, "Reflectance", 0)
    end
end

local function RestoreOptimizedProperties()
    for instance, props in pairs(performanceState.originals) do
        if instance and instance.Parent then
            for property, value in pairs(props) do
                pcall(function()
                    instance[property] = value
                end)
            end
        end
    end
    performanceState.originals = setmetatable({}, { __mode = "k" })
end

local ApplyLowPerformanceMode

local function SaveLagSaverState()
    pcall(function()
        writefile(LAGSAVER_STATE_FILE, HttpService:JSONEncode({
            Enabled = _G.LowPerformanceMode and true or false,
            FPS = ClampNumber(_G.LowPerformanceFPS or 15, 5, 60),
            UpdatedAt = os.time()
        }))
    end)
end

local function LoadLagSaverState()
    local state = nil
    pcall(function()
        if isfile and isfile(LAGSAVER_STATE_FILE) then
            state = HttpService:JSONDecode(readfile(LAGSAVER_STATE_FILE))
        end
    end)
    return state
end

local function DestroyScreenCover()
    if performanceState.screenCover then
        pcall(function()
            performanceState.screenCover:Destroy()
        end)
        performanceState.screenCover = nil
    end
end

local function NormalizeImageId(value)
    value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" or value == "0" then return "" end
    if value:match("^%d+$") then
        return "rbxassetid://" .. value
    end
    return value
end

local function GetAssetThumbnailId(value)
    value = tostring(value or "")
    local id = value:match("rbxassetid://(%d+)") or value:match("id=(%d+)") or value:match("^(%d+)$")
    if not id then return "" end
    return "rbxthumb://type=Asset&id=" .. id .. "&w=720&h=720"
end

local function GetLagSaverStatusText()
    if _G.AutoGoodFarm then
        local status = nil
        pcall(function()
            status = _G._GoodFarmStatusLabel and _G._GoodFarmStatusLabel.Text
        end)
        return status or "Good Farm is running"
    end
    if _G.AutoCasinoPlay or _G.AutoCasinoEnabled then
        return "Casino macro is running"
    end
    if _G.AutoStory then
        return "Auto Story is running"
    end
    if _G.StoryMacroMode then
        return "Story macro mode is running"
    end
    if _G.AutoEvent or _G.AutoEventMacro then
        return "Event automation is running"
    end
    if _G.MacroRunning or _G.AutoPlay then
        return "Macro is running"
    end
    return _G.LagSaverStatus or "Waiting for automation"
end

local function GetLagSaverDashboardText()
    local text = ""
    pcall(function()
        if _G.GetDashboardText then
            text = _G.GetDashboardText()
        end
    end)
    if text == "" then
        text = "Dashboard data will appear after the first cache update"
    end
    return text
end

local function GetCullingPointsText()
    local points = nil
    pcall(function()
        local cg = PlayerGui:FindFirstChild("CullingGames")
        if cg then
            local tp = cg:FindFirstChild("Teleport")
            if tp and tp.Visible then
                for _, v in pairs(tp:GetChildren()) do
                    if v:IsA("TextLabel") and v.Text and v.Text ~= "" then
                        local pts = v.Text:match("Culling Points:%s*(%d+)") or v.Text:match("^(%d+)$")
                        if pts then
                            points = pts
                            if writefile then
                                writefile(CULLING_POINTS_FILE, pts)
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
    if not points then
        pcall(function()
            if isfile and isfile(CULLING_POINTS_FILE) then
                points = readfile(CULLING_POINTS_FILE)
            end
        end)
    end
    return points or "---"
end

local function GetLagSaverResultText()
    local result = _G.LastGameResult
    if type(result) == "table" and result.Text and result.Text ~= "" then
        return result.Text
    end
    pcall(function()
        if isfile and isfile(LAST_RESULT_FILE) then
            local data = HttpService:JSONDecode(readfile(LAST_RESULT_FILE))
            if type(data) == "table" and data.Text and data.Text ~= "" then
                result = data
            end
        end
    end)
    if type(result) == "table" and result.Text and result.Text ~= "" then
        _G.LastGameResult = result
        return result.Text
    end
    return "No completed run yet"
end

local function ShowScreenCover()
    DestroyScreenCover()

    local gui = Instance.new("ScreenGui")
    gui.Name = "LagSaverWhiteScreen"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483647
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local cover = Instance.new("Frame", gui)
    cover.Name = "LagSaverStatusCover"
    cover.Size = UDim2.new(1, 0, 1, 0)
    cover.Position = UDim2.new(0, 0, 0, 0)
    cover.BackgroundColor3 = Color3.fromRGB(3, 5, 10)
    cover.BorderSizePixel = 0
    cover.ZIndex = 10000

    local backgroundImage = Instance.new("ImageLabel", cover)
    backgroundImage.Name = "LagSaverBackgroundImage"
    backgroundImage.AnchorPoint = Vector2.new(0.5, 0.5)
    backgroundImage.Size = UDim2.new(1, 0, 1, 0)
    backgroundImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    backgroundImage.BackgroundTransparency = 1
    backgroundImage.Image = NormalizeImageId(_G.LagSaverBackgroundImage or LAGSAVER_BACKGROUND_IMAGE)
    backgroundImage.ImageTransparency = 0.16
    backgroundImage.ScaleType = Enum.ScaleType.Crop
    backgroundImage.Visible = backgroundImage.Image ~= ""
    backgroundImage.ZIndex = 10000
    pcall(function()
        backgroundImage.ResampleMode = Enum.ResamplerMode.Default
    end)

    local backgroundDim = Instance.new("Frame", cover)
    backgroundDim.Name = "LagSaverBackgroundDim"
    backgroundDim.Size = UDim2.new(1, 0, 1, 0)
    backgroundDim.BackgroundColor3 = Color3.fromRGB(3, 5, 10)
    backgroundDim.BackgroundTransparency = 0.5
    backgroundDim.BorderSizePixel = 0
    backgroundDim.ZIndex = 10001

    local topLine = Instance.new("Frame", cover)
    topLine.Size = UDim2.new(1, 0, 0, 3)
    topLine.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    topLine.BorderSizePixel = 0
    topLine.ZIndex = 10001

    local title = Instance.new("TextLabel", cover)
    title.Size = UDim2.new(1, -240, 0, 34)
    title.Position = UDim2.new(0, 34, 0, 14)
    title.BackgroundTransparency = 1
    title.Text = "LAG SAVER // BOT STATUS"
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 10003
    local titleGlow = Instance.new("UIStroke", title)
    titleGlow.Color = Color3.fromRGB(0, 180, 255)
    titleGlow.Thickness = 1
    titleGlow.Transparency = 0.25

    local subtitle = Instance.new("TextLabel", cover)
    subtitle.Size = UDim2.new(1, -70, 0, 20)
    subtitle.Position = UDim2.new(0, 34, 0, 44)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Rendering is covered. Macro logic continues in the background."
    subtitle.TextColor3 = Color3.fromRGB(190, 210, 220)
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 12
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 10003

    local panel = Instance.new("Frame", cover)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Size = UDim2.new(0.78, 0, 0.86, 0)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
    panel.BackgroundTransparency = 0.34
    panel.BorderSizePixel = 0
    panel.ZIndex = 10002
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
    local panelSize = Instance.new("UISizeConstraint", panel)
    panelSize.MinSize = Vector2.new(460, 360)
    panelSize.MaxSize = Vector2.new(860, 470)
    local panelStroke = Instance.new("UIStroke", panel)
    panelStroke.Color = Color3.fromRGB(0, 255, 255)
    panelStroke.Thickness = 2
    panelStroke.Transparency = 0.2
    title.Parent = panel
    subtitle.Parent = panel

    local accent = Instance.new("Frame", panel)
    accent.Size = UDim2.new(0, 5, 1, -28)
    accent.Position = UDim2.new(0, 18, 0, 14)
    accent.BackgroundColor3 = Color3.fromRGB(255, 235, 59)
    accent.BorderSizePixel = 0
    accent.ZIndex = 10002

    local statusLabel = Instance.new("TextLabel", panel)
    statusLabel.Size = UDim2.new(1, -60, 0, 30)
    statusLabel.Position = UDim2.new(0, 34, 0, 76)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 18
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.ZIndex = 10002

    local macroLabel = Instance.new("TextLabel", panel)
    macroLabel.Size = UDim2.new(1, -60, 0, 24)
    macroLabel.Position = UDim2.new(0, 34, 0, 110)
    macroLabel.BackgroundTransparency = 1
    macroLabel.TextColor3 = Color3.fromRGB(235, 245, 255)
    macroLabel.Font = Enum.Font.GothamMedium
    macroLabel.TextSize = 13
    macroLabel.TextXAlignment = Enum.TextXAlignment.Left
    macroLabel.ZIndex = 10002

    local waveLabel = Instance.new("TextLabel", panel)
    waveLabel.Size = UDim2.new(1, -60, 0, 24)
    waveLabel.Position = UDim2.new(0, 34, 0, 136)
    waveLabel.BackgroundTransparency = 1
    waveLabel.TextColor3 = Color3.fromRGB(255, 235, 59)
    waveLabel.Font = Enum.Font.GothamMedium
    waveLabel.TextSize = 13
    waveLabel.TextXAlignment = Enum.TextXAlignment.Left
    waveLabel.ZIndex = 10002

    local cullingLabel = Instance.new("TextLabel", panel)
    cullingLabel.Size = UDim2.new(1, -60, 0, 24)
    cullingLabel.Position = UDim2.new(0, 34, 0, 162)
    cullingLabel.BackgroundTransparency = 1
    cullingLabel.TextColor3 = Color3.fromRGB(255, 208, 64)
    cullingLabel.Font = Enum.Font.GothamBold
    cullingLabel.TextSize = 13
    cullingLabel.TextXAlignment = Enum.TextXAlignment.Left
    cullingLabel.ZIndex = 10002

    local dashboardTitle = Instance.new("TextLabel", panel)
    dashboardTitle.Size = UDim2.new(1, -60, 0, 22)
    dashboardTitle.Position = UDim2.new(0, 34, 0, 194)
    dashboardTitle.BackgroundTransparency = 1
    dashboardTitle.Text = "DASHBOARD CACHE"
    dashboardTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
    dashboardTitle.Font = Enum.Font.GothamBold
    dashboardTitle.TextSize = 12
    dashboardTitle.TextXAlignment = Enum.TextXAlignment.Left
    dashboardTitle.ZIndex = 10002

    local dashboardLabel = Instance.new("TextLabel", panel)
    dashboardLabel.Size = UDim2.new(1, -60, 0, 44)
    dashboardLabel.Position = UDim2.new(0, 34, 0, 218)
    dashboardLabel.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
    dashboardLabel.BackgroundTransparency = 0.24
    dashboardLabel.TextColor3 = Color3.fromRGB(230, 240, 245)
    dashboardLabel.Font = Enum.Font.Gotham
    dashboardLabel.TextSize = 12
    dashboardLabel.TextWrapped = true
    dashboardLabel.TextXAlignment = Enum.TextXAlignment.Left
    dashboardLabel.TextYAlignment = Enum.TextYAlignment.Center
    dashboardLabel.ZIndex = 10002
    Instance.new("UICorner", dashboardLabel).CornerRadius = UDim.new(0, 6)
    local dashboardPad = Instance.new("UIPadding", dashboardLabel)
    dashboardPad.PaddingLeft = UDim.new(0, 10)
    dashboardPad.PaddingRight = UDim.new(0, 10)

    local resultTitle = Instance.new("TextLabel", panel)
    resultTitle.Size = UDim2.new(1, -60, 0, 22)
    resultTitle.Position = UDim2.new(0, 34, 0, 274)
    resultTitle.BackgroundTransparency = 1
    resultTitle.Text = "LAST RUN RESULT"
    resultTitle.TextColor3 = Color3.fromRGB(255, 20, 92)
    resultTitle.Font = Enum.Font.GothamBold
    resultTitle.TextSize = 12
    resultTitle.TextXAlignment = Enum.TextXAlignment.Left
    resultTitle.ZIndex = 10002

    local resultLabel = Instance.new("TextLabel", panel)
    resultLabel.Size = UDim2.new(1, -60, 1, -326)
    resultLabel.Position = UDim2.new(0, 34, 0, 298)
    resultLabel.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
    resultLabel.BackgroundTransparency = 0.24
    resultLabel.TextColor3 = Color3.fromRGB(230, 240, 245)
    resultLabel.Font = Enum.Font.Gotham
    resultLabel.TextSize = 11
    resultLabel.TextWrapped = true
    resultLabel.TextXAlignment = Enum.TextXAlignment.Left
    resultLabel.TextYAlignment = Enum.TextYAlignment.Top
    resultLabel.ZIndex = 10002
    Instance.new("UICorner", resultLabel).CornerRadius = UDim.new(0, 6)
    local resultPad = Instance.new("UIPadding", resultLabel)
    resultPad.PaddingTop = UDim.new(0, 8)
    resultPad.PaddingLeft = UDim.new(0, 10)
    resultPad.PaddingRight = UDim.new(0, 10)

    local offButton = Instance.new("TextButton", panel)
    offButton.Name = "DisableLagSaver"
    offButton.Size = UDim2.new(0, 180, 0, 34)
    offButton.Position = UDim2.new(1, -200, 0, 18)
    offButton.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
    offButton.Text = "EXIT"
    offButton.TextColor3 = Color3.fromRGB(0, 255, 255)
    offButton.Font = Enum.Font.GothamBold
    offButton.TextSize = 12
    offButton.ZIndex = 10003
    Instance.new("UICorner", offButton).CornerRadius = UDim.new(0, 8)
    local offStroke = Instance.new("UIStroke", offButton)
    offStroke.Color = Color3.fromRGB(0, 255, 255)
    offStroke.Thickness = 1.5
    offStroke.Transparency = 0.25

    offButton.MouseButton1Click:Connect(function()
        ApplyLowPerformanceMode(false)
        if _G.SetLagSaverToggle then
            _G.SetLagSaverToggle(false)
        end
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end)

    pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if not gui.Parent then
        gui.Parent = PlayerGui
    end

    performanceState.screenCover = gui

    task.spawn(function()
        if not backgroundImage.Image or backgroundImage.Image == "" then return end
        pcall(function()
            ContentProvider:PreloadAsync({backgroundImage})
        end)
        task.wait(1.25)
        local loaded = false
        pcall(function()
            loaded = backgroundImage.IsLoaded
        end)
        if not loaded and backgroundImage and backgroundImage.Parent then
            local fallbackImage = GetAssetThumbnailId(backgroundImage.Image)
            if fallbackImage ~= "" and fallbackImage ~= backgroundImage.Image then
                backgroundImage.Image = fallbackImage
                pcall(function()
                    ContentProvider:PreloadAsync({backgroundImage})
                end)
            end
            task.wait(0.75)
            loaded = false
            pcall(function()
                loaded = backgroundImage.IsLoaded
            end)
            if not loaded and backgroundImage and backgroundImage.Parent then
                local uiBackground = NormalizeImageId(_G.UIBackgroundImage or "")
                if uiBackground ~= "" and uiBackground ~= backgroundImage.Image then
                    backgroundImage.Image = uiBackground
                    backgroundImage.Visible = true
                    pcall(function()
                        ContentProvider:PreloadAsync({backgroundImage})
                    end)
                end
            end
        end
    end)

    task.spawn(function()
        while performanceState.screenCover == gui and gui.Parent do
            statusLabel.Text = "STATUS: " .. GetLagSaverStatusText()
            macroLabel.Text = "MACRO: " .. tostring(_G.SelectedFile or "None") .. "   |   CASINO: " .. tostring(_G.CasinoSelectedFile or "None")
            waveLabel.Text = "WAVE: " .. tostring(_G._CurrentWave or 0) .. "   |   FPS CAP: " .. tostring(_G.LowPerformanceFPS or 15)
            cullingLabel.Text = "CULLING POINTS: " .. GetCullingPointsText()
            dashboardLabel.Text = GetLagSaverDashboardText()
            resultLabel.Text = GetLagSaverResultText()
            task.wait(1)
        end
    end)
end

function ApplyLowPerformanceMode(enabled)
    _G.LowPerformanceMode = enabled and true or false
    _G.LowPerformanceFPS = ClampNumber(_G.LowPerformanceFPS, 5, 60)
    SaveLagSaverState()

    if _G.LowPerformanceMode then
        if performanceState.originalFPSCap == nil then
            pcall(function()
                if type(getfpscap) == "function" then
                    performanceState.originalFPSCap = getfpscap()
                end
            end)
        end

        SetFPSCap(_G.LowPerformanceFPS)
        ApplyQualityLevel()

        SetOptimizedProperty(Lighting, "GlobalShadows", false)
        SetOptimizedProperty(Lighting, "EnvironmentDiffuseScale", 0)
        SetOptimizedProperty(Lighting, "EnvironmentSpecularScale", 0)
        SetOptimizedProperty(Lighting, "FogEnd", 100000)

        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            SetOptimizedProperty(terrain, "WaterWaveSize", 0)
            SetOptimizedProperty(terrain, "WaterWaveSpeed", 0)
            SetOptimizedProperty(terrain, "WaterReflectance", 0)
            SetOptimizedProperty(terrain, "WaterTransparency", 1)
            SetOptimizedProperty(terrain, "Decoration", false)
        end

        for _, instance in ipairs(game:GetDescendants()) do
            OptimizeInstance(instance)
        end

        if performanceState.connection then
            performanceState.connection:Disconnect()
        end
        performanceState.connection = game.DescendantAdded:Connect(function(instance)
            if _G.LowPerformanceMode then
                task.defer(OptimizeInstance, instance)
            end
        end)

        ShowScreenCover()
        print("[Lag Saver] Enabled at " .. tostring(_G.LowPerformanceFPS) .. " FPS")
    else
        if performanceState.connection then
            performanceState.connection:Disconnect()
            performanceState.connection = nil
        end

        DestroyScreenCover()
        RestoreOptimizedProperties()
        SetFPSCap(performanceState.originalFPSCap or 60)
        print("[Lag Saver] Disabled")
    end
end

_G.ApplyLowPerformanceMode = ApplyLowPerformanceMode
_G.SetLowPerformanceFPS = function(value)
    _G.LowPerformanceFPS = ClampNumber(value, 5, 60)
    SaveLagSaverState()
    if _G.LowPerformanceMode then
        ApplyLowPerformanceMode(true)
    end
end

-- ═══════════════════════════════════════════════════════
-- 💾 DATA ENCODE / DECODE
-- ═══════════════════════════════════════════════════════

function DeepEncode(args)
    local t = {}
    for i, v in pairs(args) do
        if typeof(v) == "CFrame" then 
            t[i] = {Type = "CFrame", Value = {v:GetComponents()}}
        elseif typeof(v) == "Vector3" then 
            t[i] = {Type = "Vector3", Value = {v.X, v.Y, v.Z}}
        elseif typeof(v) == "Instance" then
            t[i] = {Type = "Instance", Value = v:GetFullName()}
        else 
            t[i] = v 
        end
    end
    return t
end

function DeepDecode(args)
    local t = {}
    for i, v in pairs(args) do
        if type(v) == "table" and v.Type == "CFrame" then 
            t[i] = CFrame.new(unpack(v.Value))
        elseif type(v) == "table" and v.Type == "Vector3" then 
            t[i] = Vector3.new(unpack(v.Value))
        elseif type(v) == "table" and v.Type == "Instance" then
            -- resolve Instance path กลับ เช่น "Workspace.Towers.BowSorcererAwk"
            local obj = nil
            pcall(function()
                local parts = v.Value:split(".")
                obj = game
                for pi = 1, #parts do
                    obj = obj:FindFirstChild(parts[pi]) or obj:WaitForChild(parts[pi], 3)
                    if not obj then break end
                end
            end)
            t[i] = obj
        else 
            t[i] = v 
        end
    end
    return t
end

_G.DeepEncode = DeepEncode
_G.DeepDecode = DeepDecode

-- ═══════════════════════════════════════════════════════
-- 💾 SAVE / LOAD CONFIG
-- ═══════════════════════════════════════════════════════

local function SaveConfig()
    pcall(function()
        local autoPlayVal = _G.AutoPlay
        if _G._IsEventAutoPlay then 
            autoPlayVal = false 
        end
        local cfg = {
            AutoReplay = _G.AutoReplay,
            AutoSkip = _G.AutoSkip,
            AutoPlay = autoPlayVal,
            AutoUpgrade = _G.AutoUpgrade,
            SelectedFile = _G.SelectedFile,
            DiscordURL = _G.DiscordURL,
            AutoJoinCasino = _G.AutoJoinCasino,
            AutoToLobby = _G.AutoToLobby,
            AutoJoinRaid = _G.AutoJoinRaid,
            AutoJoinRaidGojo = _G.AutoJoinRaidGojo,
            AutoJoinGauntlet = _G.AutoJoinGauntlet,
            AutoCasinoPlay = _G.AutoCasinoPlay,
            AutoCasinoEnabled = _G.AutoCasinoEnabled,
            CasinoSelectedFile = _G.CasinoSelectedFile,
            StoryChapter = _G.StoryChapter,
            StoryCurrentStage = _G.StoryCurrentStage,
            StoryCurrentDifficulty = _G.StoryCurrentDifficulty,
            StoryPendingResult = _G.StoryPendingResult,
            AutoStory = _G.AutoStory,
            StoryMacroMode = _G.StoryMacroMode,
            StoryFriendsOnly = _G.StoryFriendsOnly,
            AutoSellEnabled = _G.AutoSellEnabled,
            AutoSellWave = _G.AutoSellWave,
            FastSkip = _G.FastSkip,
            AutoEvent = _G.AutoEvent,
            AutoEventMacro = _G.AutoEventMacro,
            AutoEventEquip = _G.AutoEventEquip,
            EventCardChoice = _G.EventCardChoice,
            EventSelectedFile = _G.EventSelectedFile,
            EventColonyMacros = _G.EventColonyMacros,
            EventCardBlacklist = _G.EventCardBlacklist,
            SmartCardOrder = _G.SmartCardOrder,
            AutoGoodFarm = _G.AutoGoodFarm,
            GoodFarmQueue = _G.GoodFarmQueue,
            GoodFarmCurrentMode = _G.GoodFarmCurrentMode,
            GoodFarmRoundsDone = _G.GoodFarmRoundsDone,
            LowPerformanceMode = _G.LowPerformanceMode,
            LowPerformanceFPS = _G.LowPerformanceFPS,
            CyberpunkUI = _G.CyberpunkUI,
            UIBackgroundImage = _G.UIBackgroundImage,
            UIBackgroundTransparency = _G.UIBackgroundTransparency,
            AutoQTE = _G.AutoQTE,
            AutoDomain = _G.AutoDomain
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
    end)
end

local function LoadConfig()
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            _G.AutoReplay = data.AutoReplay or false
            _G.AutoSkip = data.AutoSkip or false
            _G.AutoPlay = data.AutoPlay or false
            _G.AutoUpgrade = data.AutoUpgrade or false
            _G.SelectedFile = data.SelectedFile or "None"
            _G.DiscordURL = data.DiscordURL or ""
            _G.AutoJoinCasino = data.AutoJoinCasino or false
            _G.AutoToLobby = data.AutoToLobby or false
            _G.AutoJoinRaid = data.AutoJoinRaid or false
            _G.AutoJoinRaidGojo = data.AutoJoinRaidGojo or false
            _G.AutoJoinGauntlet = data.AutoJoinGauntlet or false
            _G.AutoCasinoPlay = data.AutoCasinoPlay or false
            _G.AutoCasinoEnabled = data.AutoCasinoEnabled or false
            _G.CasinoSelectedFile = data.CasinoSelectedFile or "None"
            CasinoSelectedFile = _G.CasinoSelectedFile
            _G.StoryChapter = data.StoryChapter or 1
            _G.StoryCurrentStage = data.StoryCurrentStage or 1
            _G.StoryCurrentDifficulty = data.StoryCurrentDifficulty or "Normal"
            _G.StoryPendingResult = data.StoryPendingResult
            _G.AutoStory = data.AutoStory or false
            _G.StoryMacroMode = data.StoryMacroMode or false
            _G.StoryFriendsOnly = data.StoryFriendsOnly or false
            _G.AutoSellEnabled = data.AutoSellEnabled or false
            _G.AutoSellWave = data.AutoSellWave or 0
            _G.FastSkip = data.FastSkip or false
            _G.AutoEvent = data.AutoEvent or false
            _G.AutoEventMacro = data.AutoEventMacro or false
            _G.AutoEventEquip = data.AutoEventEquip or false
            _G.EventCardChoice = data.EventCardChoice or 0
            _G.EventSelectedFile = data.EventSelectedFile or "None"
            _G.EventColonyMacros = data.EventColonyMacros or {}
            _G.EventCardBlacklist = data.EventCardBlacklist or {}
            _G.SmartCardOrder = data.SmartCardOrder or "easy"
            _G.AutoGoodFarm = data.AutoGoodFarm or false
            _G.GoodFarmRoundsDone = data.GoodFarmRoundsDone or 0
            _G.LowPerformanceMode = data.LowPerformanceMode or false
            _G.LowPerformanceFPS = ClampNumber(data.LowPerformanceFPS or 15, 5, 60)
            _G.CyberpunkUI = data.CyberpunkUI
            if _G.CyberpunkUI == nil then _G.CyberpunkUI = true end
            _G.UIBackgroundImage = "rbxassetid://90298702993965"
            _G.UIBackgroundTransparency = ClampNumber(data.UIBackgroundTransparency or 0.52, 0.35, 1)
            _G.AutoQTE = data.AutoQTE or false
            _G.AutoDomain = data.AutoDomain or false
            if data.GoodFarmQueue then
                _G.GoodFarmQueue = data.GoodFarmQueue
                -- เช็ค mode ที่ขาดแล้วเติมให้อัตโนมัติ (กรณี config เก่าไม่มี mode ใหม่)
                local defaultModes = {"Event","RaidMeguna","RaidGojo","InfiniteNew","Casino","StoryHell15"}
                for _, modeName in ipairs(defaultModes) do
                    local found = false
                    for _, q in ipairs(_G.GoodFarmQueue) do
                        if q.Mode == modeName then found = true; break end
                    end
                    if not found then
                        table.insert(_G.GoodFarmQueue, { Mode = modeName, Rounds = 0, MacroFile = "None" })
                    end
                end
            end
            _G.GoodFarmCurrentMode = data.GoodFarmCurrentMode or 1
        end

        local lagState = LoadLagSaverState()
        if type(lagState) == "table" then
            if lagState.Enabled ~= nil then
                _G.LowPerformanceMode = lagState.Enabled and true or false
            end
            if lagState.FPS then
                _G.LowPerformanceFPS = ClampNumber(lagState.FPS, 5, 60)
            end
        end

        if _G.LowPerformanceMode then
            ApplyLowPerformanceMode(true)
        end
    end)
end

_G.SaveConfig = SaveConfig
_G.LoadConfig = LoadConfig
_G.SaveLagSaverState = SaveLagSaverState
_G.LoadLagSaverState = LoadLagSaverState

-- ═══════════════════════════════════════════════════════
-- 🗺️ MAP-MACRO BINDING SYSTEM
-- ═══════════════════════════════════════════════════════

local function GetCurrentMapName()
    local mapFolder = workspace:FindFirstChild("Map")
    local prefix = ""
    pcall(function()
        local pGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
        local cg = pGui and pGui:FindFirstChild("CullingGames")
        if cg and (cg.Enabled or (cg:FindFirstChild("Modifiers") and cg.Modifiers.Visible)) then
            prefix = "[Event] "
        end
    end)
    if mapFolder then
        local children = mapFolder:GetChildren()
        if #children > 0 then
            return prefix .. children[1].Name
        end
    end
    return nil
end

local MapMacros = {} -- { ["JujutsuHigh"] = "macro_filename", ... }

local function SaveMapMacros()
    pcall(function()
        writefile(MAP_CONFIG_FILE, HttpService:JSONEncode(MapMacros))
    end)
end

local function LoadMapMacros()
    pcall(function()
        if isfile(MAP_CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(MAP_CONFIG_FILE))
            if type(data) == "table" then
                -- แก้ในตารางเดิม เพื่อให้ _G._MapMacros / โมดูลอื่นที่ถืออ้างอิงไว้เห็นค่าใหม่
                for k in pairs(MapMacros) do MapMacros[k] = nil end
                for k, v in pairs(data) do MapMacros[k] = v end
            end
        end
    end)
end

local function AutoSelectMacroForMap(mapName)
    if not mapName then return end
    local macroName = MapMacros[mapName]
    if macroName and macroName ~= "" then
        _G.SelectedFile = macroName
        SaveConfig()
        print("🗺️ Auto Select: Map [" .. mapName .. "] → Macro [" .. macroName .. "]")
        return true
    end
    return false
end

_G.GetCurrentMapName = GetCurrentMapName
_G._MapMacros = MapMacros
_G.SaveMapMacros = SaveMapMacros
_G.LoadMapMacros = LoadMapMacros
_G.AutoSelectMacroForMap = AutoSelectMacroForMap

-- ═══════════════════════════════════════════════════════
-- 👤 CONFIG PROFILE API (ใช้ในหน้า Main)
-- ═══════════════════════════════════════════════════════

-- คืนรายการโปรไฟล์ทั้งหมด: { {Id="123", Name="abc", DisplayName="ABC", IsMe=true}, ... }
local function ListConfigProfiles()
    local list = {}
    pcall(function()
        if not isfolder(PROFILES_FOLDER) then return end
        for _, path in ipairs(listfiles(PROFILES_FOLDER)) do
            local id = tostring(path):match("[^/\\]+$")
            if id and isfolder(PROFILES_FOLDER.."/"..id) then
                local entry = { Id = id, Name = id, DisplayName = id, IsMe = (id == PROFILE_ID) }
                pcall(function()
                    local infoPath = PROFILES_FOLDER.."/"..id.."/profile_info.json"
                    if isfile(infoPath) then
                        local info = HttpService:JSONDecode(readfile(infoPath))
                        entry.Name = tostring(info.Name or id)
                        entry.DisplayName = tostring(info.DisplayName or entry.Name)
                    end
                end)
                table.insert(list, entry)
            end
        end
    end)
    table.sort(list, function(a, b)
        if a.IsMe ~= b.IsMe then return a.IsMe end
        return a.Name:lower() < b.Name:lower()
    end)
    return list
end

-- โหลดคอนฟิกของไอดีนี้จากไฟล์อีกครั้ง
local function ReloadMyConfig()
    LoadConfig()
    LoadStoryTowers()
    LoadMapMacros()
    return true
end

-- คัดลอกคอนฟิกจากไอดีอื่นมาเป็นของไอดีนี้ แล้วใช้งานทันที
-- (ไม่คัดลอกความคืบหน้า เช่น Good Farm รอบที่ทำไปแล้ว / ผลรอบล่าสุด / Lag Saver ของจอนั้น)
local function LoadConfigFromProfile(sourceId)
    sourceId = tostring(sourceId or "")
    if sourceId == "" then return false, "ยังไม่ได้เลือกโปรไฟล์" end
    if sourceId == PROFILE_ID then
        ReloadMyConfig()
        return true, "โหลดคอนฟิกของไอดีนี้ใหม่แล้ว"
    end
    local srcFolder = PROFILES_FOLDER.."/"..sourceId
    local srcSettings = srcFolder.."/settings.json"
    local ok, err = pcall(function()
        if not isfile(srcSettings) then error("โปรไฟล์นี้ยังไม่มี settings.json") end
        local data = HttpService:JSONDecode(readfile(srcSettings))
        if type(data) ~= "table" then error("ไฟล์คอนฟิกเสีย") end
        data.StoryPendingResult = nil
        data.GoodFarmCurrentMode = 1
        data.GoodFarmRoundsDone = 0
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
        for _, name in ipairs({ "map_macros.json", "story_towers.json" }) do
            local src = srcFolder.."/"..name
            if isfile(src) then
                writefile(PROFILE_FOLDER.."/"..name, readfile(src))
            end
        end
    end)
    if not ok then
        return false, tostring(err):gsub("^.-:%d+: ", "")
    end
    ReloadMyConfig()
    return true, "คัดลอกคอนฟิกจากไอดี " .. sourceId .. " แล้ว"
end

_G.ListConfigProfiles = ListConfigProfiles
_G.ReloadMyConfig = ReloadMyConfig
_G.LoadConfigFromProfile = LoadConfigFromProfile

-- ═══════════════════════════════════════════════════════
-- 🚀 INIT: Load saved data
-- ═══════════════════════════════════════════════════════

LoadConfig()
LoadStoryTowers()
LoadMapMacros()

print("👤 Config profile: " .. Player.Name .. " (" .. PROFILE_ID .. ") → " .. PROFILE_FOLDER)
print("✅ [Module 1/12] Config.lua loaded successfully")
