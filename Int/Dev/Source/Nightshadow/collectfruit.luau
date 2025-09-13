local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.ResetOnSpawn = false
screenGui.Name = "MidnightHubStatus"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 240, 0, 95)
mainFrame.Position = UDim2.new(0.5, -120, 0, 20)
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.5
mainFrame.BorderSizePixel = 0

local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 10)

local hubTitle = Instance.new("TextLabel", mainFrame)
hubTitle.Size = UDim2.new(1, 0, 0, 25)
hubTitle.Position = UDim2.new(0.5, 0, 0, 5)
hubTitle.AnchorPoint = Vector2.new(0.5, 0)
hubTitle.BackgroundTransparency = 1
hubTitle.Text = "Midnight Hub"
hubTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
hubTitle.Font = Enum.Font.GothamBold
hubTitle.TextSize = 20

local statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0.5, 0, 0, 35)
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Inicializando..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14

local subStatusLabel = Instance.new("TextLabel", mainFrame)
subStatusLabel.Size = UDim2.new(1, 0, 0, 20)
subStatusLabel.Position = UDim2.new(0.5, 0, 0, 60)
subStatusLabel.AnchorPoint = Vector2.new(0.5, 0)
subStatusLabel.BackgroundTransparency = 1
subStatusLabel.Text = ""
subStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
subStatusLabel.Font = Enum.Font.Gotham
subStatusLabel.TextSize = 12

local function updateStatus(mainText, subText)
    statusLabel.Text = mainText
    subStatusLabel.Text = subText or ""
end

local Marines = function() ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam","Marines") end
local Pirates = function() ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam","Pirates") end

local lastAction = tick()
local serverJoinTime = tick()
local function markAction()
    lastAction = tick()
end

local function checkForFriends()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and LocalPlayer:IsFriendsWith(player.UserId) then
            return true
        end
    end
    return false
end

local function tryStoreFruit(tool)
    local remote = tool:FindFirstChild("EatRemote",true)
    if remote and remote.Parent then
        local fruitName = remote.Parent:GetAttribute("OriginalName")
        if fruitName then
            local success, result = pcall(function()
                return ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitName, tool)
            end)
            if success and result ~= "Already" then
                updateStatus("Fruta armazenada", fruitName)
                markAction()
                return true
            end
        end
    end
    return false
end

local function storeInventoryFruits()
    local stored = false
    for _,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            if tryStoreFruit(tool) then
                stored = true
            end
        end
    end
    return stored
end

local function safeRequest(url)
    local req = syn and syn.request or http_request or request or (http and http.request)
    if req then
        local ok, res = pcall(function()
            return req({Url = url, Method = "GET"})
        end)
        if ok and res then
            local body = res.Body or res.body
            return body
        end
    else
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and res then
            return res
        end
    end
    return nil
end

local function Hop()
    updateStatus("Trocando servidor", "")
    local targetPlaceId = 4442272183
    
    pcall(function()
        TeleportService:Teleport(targetPlaceId, LocalPlayer)
    end)
end

local function esp(obj)
    if not obj:FindFirstChild("Highlight") then
        local hl = Instance.new("Highlight",obj)
        hl.FillColor = Color3.fromRGB(255,0,0)
        hl.OutlineColor = Color3.fromRGB(255,0,0)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0
    end
end

local function rotate(obj)
    if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
        if not obj:FindFirstChild("Rotating") then
            local flag = Instance.new("BoolValue",obj)
            flag.Name = "Rotating"
            RunService.Heartbeat:Connect(function()
                if obj and obj.Parent and obj:FindFirstChild("Handle") then
                    obj.Handle.CFrame = obj.Handle.CFrame * CFrame.Angles(0,math.rad(2.5),0)
                end
            end)
        end
    end
end

local function waitForTeam()
    updateStatus("Verificando equipe...","")
    while not LocalPlayer.Team do
        updateStatus("Selecionando equipe...","")
        if math.random(1,2) == 1 then Marines() else Pirates() end
        task.wait(2)
    end
    updateStatus("Equipe selecionada:",LocalPlayer.Team.Name)
end

local function collectFruit(obj)
    updateStatus("Coletando fruta",obj.Name)
    esp(obj)
    rotate(obj)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Handle") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = obj.Handle.CFrame + Vector3.new(0,5,0)
    end
    task.wait(0.3)
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Handle") then
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart,obj.Handle,0)
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart,obj.Handle,1)
        end
    end)
    task.wait(0.3)
    if not tryStoreFruit(obj) then
        Hop()
    else
        markAction()
    end
    return true
end

local function collectBerry(bush)
    for attr,_ in pairs(bush:GetAttributes()) do
        local berryPart = bush.Parent:FindFirstChild(attr)
        if berryPart and berryPart:IsA("BasePart") then
            updateStatus("Coletando berry",attr)
            esp(berryPart)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = berryPart.CFrame + Vector3.new(0,1,0)
            end
            for i=1,3 do
                task.wait(0.2)
                VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
            end
            markAction()
            return true
        end
    end
end

local boughtThisServer = false
local function buyRandomFruit()
    if boughtThisServer then return false end
    boughtThisServer = true
    updateStatus("Comprando fruta aleatória","")
    local success, result = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin","Buy")
    end)
    if success and result then
        updateStatus("Fruta comprada",tostring(result))
        markAction()
        return true
    else
        updateStatus("Não foi possível comprar","")
        return false
    end
end

local function mainLoop()
    while task.wait(1) do
        if checkForFriends() then
            updateStatus("Amigo encontrado", "Trocando servidor")
            Hop()
            return
        end
        
        if tick() - serverJoinTime > 15 then
            updateStatus("Tempo limite", "Trocando servidor")
            Hop()
            return
        end
        
        if tick() - lastAction > 45 then
            updateStatus("Timeout", "Trocando de servidor")
            Hop()
            return
        end
        
        if buyRandomFruit() then continue end
        local foundFruit = false
        for _,obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj:FindFirstChild("Handle") and obj.Name:lower():find("fruit") then
                collectFruit(obj)
                foundFruit = true
                break
            end
        end
        if foundFruit then continue end
        local foundBerry = false
        local bushes = CollectionService:GetTagged("BerryBush")
        for _,bush in ipairs(bushes) do
            if collectBerry(bush) then
                foundBerry = true
                break
            end
        end
        if foundBerry then continue end
        if storeInventoryFruits() then
            markAction()
            continue
        end
        updateStatus("Nada encontrado","Trocando de servidor")
        task.wait(1)
        Hop()
        return
    end
end

task.spawn(function()
    updateStatus("Iniciando...","")
    task.wait(2)
    serverJoinTime = tick()
    waitForTeam()
    mainLoop()
end)
