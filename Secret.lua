local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local placeId = game.PlaceId
local currentJobId = game.JobId
local searching = false
local attempts = 0
local triedServers = {}

-- ✅ قائمة السكرتات والبرينروتات المطلوبة
local knownNames = {
    ["La Vacca Staturno Saturnita"] = true,
    ["Chimpanzini Spiderini"] = true,
    ["Los Tralaleritos"] = true,
    ["Las Tralaleritas"] = true,
    ["Graipuss Medussi"] = true,
    ["La Grande Combinasion"] = true,
    ["Nuclearo Dinossauro"] = true,
    ["Garama and Madundung"] = true,
    ["Tortuginni Dragonfruitini"] = true,
    ["Pot Hotspot"] = true,
    ["Las Vaquitas Saturnitas"] = true,
    ["Chicleteira Bicicleteira"] = true,
    ["Tralalero Tralala"] = true,
    ["Matteo"] = true,
    ["Gattatino Nyanino"] = true,
    ["Girafa Celestre"] = true,
    ["Coco Elefanto"] = true,
    ["Ballerino Lololo"] = true,
    ["Trenostruzzo Turbo 3000"] = true,
    ["Statutino Libertino"] = true,
    ["Odin Din Din Dun"] = true,
    ["Espresso Signora"] = true,
}

-- 💬 Discord Webhook
local webhookUrl = "https://discord.com/api/webhooks/1402399536391127093/1RrkegsAKunQqldzboAa7Lwvu6e1BosdMessoqamlbHcY0JN7s7wjEAumaUnyxCP4KFR"

local function sendWebhook(name)
    local data = {
        ["content"] = "🎯 تم العثور على Secret قوي: " .. name .. "\n🔗 [رابط السيرفر](https://www.roblox.com/games/" .. placeId .. "?jobId=" .. currentJobId .. ")",
        ["username"] = "Secret Notifier"
    }
    local body = HttpService:JSONEncode(data)
    pcall(function()
        HttpService:PostAsync(webhookUrl, body, Enum.HttpContentType.ApplicationJson)
    end)
end

-- ✨ ESP Function
local function createESP(part, text)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BrainrotESP"
    billboard.Size = UDim2.new(0, 150, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 4.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1000
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "💰 " .. text
    label.TextColor3 = Color3.fromRGB(255, 255, 0)
    label.Font = Enum.Font.FredokaOne
    label.TextScaled = true
    label.TextStrokeTransparency = 0.3
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextWrapped = true
    label.Parent = billboard
end

-- 🔍 Check for strongest secret and apply ESP
local function hasStrongSecret()
    local maxSecret = nil
    local maxRate = 0

    for _, base in pairs(workspace:GetChildren()) do
        if base:IsA("Model") and base.Name:lower():find("base") then
            for _, d in pairs(base:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text:match("[/%$]") then
                    local name = d.Text
                    if not knownNames[name] then continue end
                    local rateText = d.Text:match("%$(.-)/s")
                    if rateText then
                        local clean = rateText:gsub("[KMB]", {
                            ["K"] = "*1e3", ["M"] = "*1e6", ["B"] = "*1e9"
                        })
                        local rate = tonumber(loadstring("return " .. clean)())
                        if rate and rate > 250000 and rate > maxRate then
                            maxRate = rate
                            maxSecret = d
                        end
                    end
                end
            end
        end
    end

    if maxSecret then
        sendWebhook(maxSecret.Text)
        createESP(maxSecret, maxSecret.Text)
        return true
    end
    return false
end

-- 🔍 Apply ESP to all known models
local function scanAllForESP()
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and knownNames[model.Name] then
            if not model:FindFirstChild("BrainrotESP") then
                local part = model:FindFirstChildWhichIsA("BasePart")
                if part then
                    createESP(part, model.Name)
                end
            end
        end
    end
end

-- 🧱 GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "SecretGui"
gui.ResetOnSpawn = false

local function createLabel(name, text, position)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.Text = text
    lbl.Size = UDim2.new(0.3, 0, 0.05, 0)
    lbl.Position = position
    lbl.BackgroundTransparency = 0.3
    lbl.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextScaled = true
    lbl.Parent = gui
    return lbl
end

local function createButton(name, text, position, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = text
    btn.Size = UDim2.new(0.22, 0, 0.06, 0)
    btn.Position = position
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextScaled = true
    btn.Parent = gui
    return btn
end

local statusLabel = createLabel("StatusLabel", "الحالة: متوقف", UDim2.new(0.05, 0, 0.02, 0))
local attemptsLabel = createLabel("AttemptsLabel", "المحاولات: 0", UDim2.new(0.4, 0, 0.02, 0))
local startBtn = createButton("StartButton", "ابدأ البحث", UDim2.new(0.05, 0, 0.1, 0), Color3.fromRGB(0, 200, 0))
local stopBtn = createButton("StopButton", "أوقف البحث", UDim2.new(0.32, 0, 0.1, 0), Color3.fromRGB(200, 0, 0))

-- 🌐 Get servers
local function getServers()
    local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if success and result and result.data then
        return result.data
    else
        warn("⚠️ فشل في جلب السيرفرات.")
        return {}
    end
end

-- 🔁 Hopping logic
local function startHopping()
    searching = true
    attempts = 0
    triedServers = {}
    statusLabel.Text = "🔍 جاري البحث..."
    attemptsLabel.Text = "المحاولات: 0"

    while searching do
        if hasStrongSecret() then return end
        scanAllForESP()
        local servers = getServers()
        local hopped = false

        for _, server in ipairs(servers) do
            if not searching then return end
            if server.id ~= currentJobId and server.playing < server.maxPlayers and not triedServers[server.id] then
                triedServers[server.id] = true
                attempts += 1
                attemptsLabel.Text = "المحاولات: " .. attempts
                statusLabel.Text = "🚀 محاولة رقم "..attempts.." - القفز لسيرفر جديد..."
                wait(0.5)
                TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
                hopped = true
                break
            end
        end

        if not hopped then
            statusLabel.Text = "🔁 لا يوجد سيرفر مناسب. إعادة المحاولة..."
            wait(3)
        end
    end
end

-- 🟢 أزرار التحكم
startBtn.MouseButton1Click:Connect(function()
    if not searching then
        startHopping()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    searching = false
    statusLabel.Text = "⛔ تم إيقاف البحث."
end)

-- ✅ تشغيل ESP عند البدء
scanAllForESP()
