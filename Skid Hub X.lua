
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

-- FPS Counter Setup
local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "FPSCounter"
fpsGui.ResetOnSpawn = false
fpsGui.IgnoreGuiInset = true
fpsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
fpsGui.Parent = PlayerGui

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPSLabel"
fpsLabel.Size = UDim2.new(0, 100, 0, 25)
fpsLabel.Position = UDim2.new(1, -110, 0, 10) -- Top-right corner
fpsLabel.BackgroundTransparency = 1
fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fpsLabel.TextStrokeTransparency = 0.5
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Font = Enum.Font.SourceSansBold
fpsLabel.TextSize = 20
fpsLabel.Text = "FPS: ..."
fpsLabel.Parent = fpsGui

-- FPS Update Loop
task.spawn(function()
	local lastTime = tick()
	local frames = 0
	while true do
		frames += 1
		local now = tick()
		if now - lastTime >= 1 then
			fpsLabel.Text = "FPS: " .. frames
			frames = 0
			lastTime = now
		end
		task.wait()
	end
end)

local ShecklesCount = Leaderstats.Sheckles
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

local Window = Fluent:CreateWindow({
    Title = "Skid Hub X",
    SubTitle = "by theshortestofthemall",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local SeedStock = {}
local OwnedSeeds = {}
local HarvestIgnores = {
	Normal = false,
	Gold = false,
	Rainbow = false
}
local function GetFarm(PlayerName: string): Folder?
	local Farms = GetFarms()
	for _, Farm in next, Farms do
		local Owner = GetFarmOwner(Farm)
		if Owner == PlayerName then
			return Farm
		end
	end
    return
end

local IsSelling = false
local function SellInventory()
	local Character = LocalPlayer.Character
	local Previous = Character:GetPivot()
	local PreviousSheckles = ShecklesCount.Value

	--// Prevent conflict
	if IsSelling then return end
	IsSelling = true

	Character:PivotTo(CFrame.new(62, 4, -26))
	while wait() do
		if ShecklesCount.Value ~= PreviousSheckles then break end
		GameEvents.Sell_Inventory:FireServer()
	end
	Character:PivotTo(Previous)

	wait(0.2)
	IsSelling = false
end
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "Home" }),
    AutoHarvest = Window:AddTab({ Title = "Auto-Harvest", Icon = "leaf" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

do
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    local BuySeedStock = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock")
    local BuyGearStock = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyGearStock")

    -- UI toggle function
    local function toggleGui(name)
        local ui = PlayerGui:FindFirstChild(name)
        if ui and ui:IsA("ScreenGui") then
            ui.Enabled = not ui.Enabled
            Fluent:Notify({
                Title = name,
                Content = "Now " .. (ui.Enabled and "Visible" or "Hidden"),
                Duration = 4
            })
        else
            Fluent:Notify({
                Title = "Error",
                Content = name .. " not found.",
                Duration = 4
            })
        end
    end

    -- Toggle buttons for UIs
    Tabs.Main:AddButton({
        Title = "Toggle HoneyEventShop_UI",
        Description = "Show or hide Honey Shop",
        Callback = function()
            toggleGui("HoneyEventShop_UI")
        end
    })

-- Event1 items
local Event1 = {
    "Nectarine",
    "Flower Seed Pack",
    "Honey Walkway",
    "Bee Chair",
    "Honey Sprinkler",
    "Honey Torch",
    "Bee Egg",
    "Bee Crate",
    "Pollen Radar",
    "Nectar Staff",
    "Nectarshade",
    "Lavender",
    "Hive Fruit",
    "Honey Comb"
}

local selectedEventItems = {}

local EventDropdown = Tabs.Main:AddDropdown("EventDropdown", {
    Title = "Select Event Items to Auto-Buy",
    Description = "Auto-buys continuously",
    Values = Event1,
    Multi = true,
    Default = {},
})

EventDropdown:OnChanged(function(selection)
    selectedEventItems = selection
end)

local AutoBuyEventToggle = Tabs.Main:AddToggle("AutoBuyEventItems", {
    Title = "Auto Buy Event Items",
    Description = "Repeat buys selected Event items",
    Default = false,
})

AutoBuyEventToggle:OnChanged(function(enabled)
    if enabled then
        task.spawn(function()
            while Options.AutoBuyEventItems.Value do
                for itemName, isSelected in pairs(selectedEventItems) do
                    if isSelected then
                        game:GetService("ReplicatedStorage").GameEvents.BuyEventShopItem:FireServer(itemName)
                        task.wait(0.05)
                    end
                end
                task.wait(1)
            end
        end)
    end
end)

    Tabs.Main:AddButton({
        Title = "Toggle Seed Shop",
        Description = "Show or hide Seed Shop",
        Callback = function()
            toggleGui("Seed_Shop")
        end
    })

    Tabs.Main:AddButton({
        Title = "Toggle Gear Shop",
        Description = "Show or hide Gear Shop",
        Callback = function()
            toggleGui("Gear_Shop")
        end
    })

    -- Seed list
    local Seeds = {
        "Cherry Blossom", "Daffodil", "Coconut", "Lumira", "Crocus", "Easter Egg", "Traveler's Fruit", "Apple",
        "Dandelion", "Cocovine", "Red Lollipop", "Succulent", "Rosy Delight", "Cranberry", "Loquat", "Dragon Pepper",
        "Moon Blossom", "Pineapple", "Blood Banana", "Crimson Vine", "Pear", "Nectar Thorn", "Bell Pepper", "Pepper",
        "Cacao", "Lotus", "Lime", "Orange Tulip", "Cursed Fruit", "Carrot", "Mango", "Green Apple", "Elephant Ears",
        "Lavender", "Hive Fruit", "Parasol Flower", "Moonglow", "Feijoa", "Avocado", "Mint", "Noble Flower",
        "Tomato", "Ice Cream Bean", "Nightshade", "Lemon", "Sugar Apple", "Wild Carrot", "Bee Balm", "Starfruit",
        "Bendboo", "Violet Corn", "Passionfruit", "Papaya", "Corn", "Blueberry", "Candy Blossom", "Purple Dahlia",
        "Nectarine", "Strawberry", "Bamboo", "Sunflower", "Pink Lily", "Banana", "Rose", "Peach", "Lilac", "Foxglove",
        "Mushroom", "Moon Mango", "Beanstalk", "Cantaloupe", "Candy Sunflower", "Ember Lily", "Suncoil", "Glowshroom",
        "Venus Fly Trap", "Eggplant", "Durian", "Soul Fruit", "Prickly Pear", "Cauliflower", "Honeysuckle",
        "Raspberry", "Dragon Fruit", "Moon Melon", "Moonflower", "Chocolate Carrot", "Watermelon", "Celestiberry",
        "Cactus", "Grape", "Nectarshade", "Pumpkin", "Kiwi", "Manuka Flower"
    }

    local selectedSeeds = {}

    local SeedDropdown = Tabs.Main:AddDropdown("SeedDropdown", {
        Title = "Select Seeds to Auto-Buy",
        Description = "Multi-select supported",
        Values = Seeds,
        Multi = true,
        Default = {},
    })

    SeedDropdown:OnChanged(function(selection)
        selectedSeeds = selection
    end)

    local AutoBuyToggle = Tabs.Main:AddToggle("AutoBuySeeds", {
        Title = "Auto Buy Selected Seeds",
        Description = "Buys selected seeds",
        Default = false,
    })

    AutoBuyToggle:OnChanged(function(enabled)
        if enabled then
            Fluent:Notify({
                Title = "Auto Buyer",
                Content = "Auto-buy started.",
                Duration = 4,
            })

            task.spawn(function()
                while Options.AutoBuySeeds.Value do
                    for seedName, isSelected in pairs(selectedSeeds) do
                        if isSelected then
                            for i = 1, 30 do
                                BuySeedStock:FireServer(seedName)
                                task.wait(0.05)
                            end
                        end
                    end
                    task.wait(5)
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Buyer",
                Content = "Auto-buy stopped.",
                Duration = 4,
            })
        end
    end)

    -- Gear list
    local Gears = {
        "Sweet Soaker Sprinkler",
        "Trowel",
        "Stalk Sprout Sprinkler",
        "Friendship Pot",
        "Harvest Tool",
        "Flower Froster Sprinkler",
        "Favorite Tool",
        "Reclaimer",
        "Lightning Rod",
        "Godly Sprinkler",
        "Advanced Sprinkler",
        "Clearing Spray",
        "Master Sprinkler",
        "Berry Blusher Sprinkler",
        "Spice Spritzer Sprinkler",
        "Tropical Mist Sprinkler",
        "Tanning Mirror",
        "Mutation Spray Choco",
        "Recall Wrench",
        "Watering Can",
        "Mutation Spray Shocked",
        "Mutation Spray Pollinated",
        "Basic Sprinkler"
    }

    local selectedGears = {}

    local GearDropdown = Tabs.Main:AddDropdown("GearDropdown", {
        Title = "Select Gears to Auto-Buy",
        Description = "Multi-select supported",
        Values = Gears,
        Multi = true,
        Default = {},
    })

    GearDropdown:OnChanged(function(selection)
        selectedGears = selection
    end)

    local AutoBuyGearToggle = Tabs.Main:AddToggle("AutoBuyGears", {
        Title = "Auto Buy Selected Gears",
        Description = "Buys selected gears",
        Default = false,
    })

    AutoBuyGearToggle:OnChanged(function(enabled)
        if enabled then
            task.spawn(function()
                while Options.AutoBuyGears.Value do
                    for gearName, isSelected in pairs(selectedGears) do
                        if isSelected then
                            for i = 1, 30 do
                                BuyGearStock:FireServer(gearName)
                                task.wait(0.05)
                            end
                        end
                    end
                    task.wait(5)
                end
            end)
        end
    end)
end

local AutoSellToggle = Tabs.Main:AddToggle("AutoSellToggle", {
    Title = "Auto Sell Inventory",
    Default = false
})

coroutine.wrap(function()
    while task.wait(1) do
        if AutoSellToggle.Value then
            SellInventory()
        end
    end
end)()

local function AutoSellCheck()
    local CropCount = #GetInvCrops()

    if not AutoSell.Value then return end
    if CropCount < SellThreshold.Value then return end

    SellInventory()
end

local AutoSummerHarvestThread

local AutoSummerHarvestToggle = Tabs.AutoHarvest:AddToggle("AutoSummerHarvest", {
    Title = "Auto Submit Summer Harvest",
    Description = "Auto Submits Plants Every 60Sec",
    Default = false,
    Callback = function(enabled)
        if enabled then
            AutoSummerHarvestThread = task.spawn(function()
                while Options.AutoSummerHarvest.Value do
                    local remote = ReplicatedStorage:WaitForChild("GameEvents"):FindFirstChild("SummerHarvestRemoteEvent")
                    if remote then
                        pcall(function()
                            remote:FireServer("SubmitAllPlants")
                        end)
                    end
                    task.wait(60)
                end
            end)
        else
            if AutoSummerHarvestThread then
                task.cancel(AutoSummerHarvestThread)
                AutoSummerHarvestThread = nil
            end
        end
    end
})

-- Auto Buy All 3 Pet Eggs (Slot 1–3)
local AutoBuyPetEggsToggle = Tabs.AutoHarvest:AddToggle("AutoBuyPetEggs", {
    Title = "Auto Buy All Pet Eggs",
    Description = "",
    Default = false,
})

task.spawn(function()
    while task.wait(60) do
        if Options.AutoBuyPetEggs.Value then
            for slot = 1, 3 do
                pcall(function()
                    ReplicatedStorage.GameEvents.BuyPetEgg:FireServer(slot)
                    task.wait(0.3)
                end)
            end
        end
    end
end)

local AutoHarvestToggle = Tabs.AutoHarvest:AddToggle("AutoHarvest", {
    Title = "Auto Collect Plants",
    Description = "",
    Default = false
})

-- Functional logic for AutoWalk and AutoHarvest
local function GetMyFarm()
	for _, farm in pairs(workspace.Farm:GetChildren()) do
		local owner = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data") and farm.Important.Data:FindFirstChild("Owner")
		if owner and owner.Value == LocalPlayer.Name then
			return farm
		end
	end
end

local function GetRandomFarmPoint()
	local farm = GetMyFarm()
	if not farm then return Vector3.new(0, 0, 0) end
	local plantLocations = farm.Important:FindFirstChild("Plant_Locations")
	if not plantLocations then return Vector3.new(0, 0, 0) end

	local parts = plantLocations:GetChildren()
	if #parts == 0 then return Vector3.new(0, 0, 0) end

	local part = parts[math.random(1, #parts)]
	local pos, size = part.Position, part.Size
	return Vector3.new(
		math.random(math.floor(pos.X - size.X / 2), math.floor(pos.X + size.X / 2)),
		4,
		math.random(math.floor(pos.Z - size.Z / 2), math.floor(pos.Z + size.Z / 2))
	)
end

local function GetHarvestablePlants()
    local character = LocalPlayer.Character
    if not character then return {} end

    local root = GetMyFarm()
    if not root then return {} end

    local plantFolder = root.Important:FindFirstChild("Plants_Physical")
    if not plantFolder then return {} end

    local pos = character:GetPivot().Position
    local plants = {}

    for _, model in pairs(plantFolder:GetDescendants()) do
        if model:IsA("ProximityPrompt") and model.Enabled then
            local parent = model.Parent

            table.insert(plants, parent.Parent)
        end
    end

    return plants
end

local function HarvestPlants()
    for _, prompt in ipairs(GetHarvestablePlants()) do
        pcall(function()
            ReplicatedStorage.ByteNetReliable:FireServer(buffer.fromstring("\001\001\000\001"), { prompt })
        end)
    end
end

local function AutoWalkToPlant()
	if IsSelling then return end
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local plants = GetHarvestablePlants()
	local doRandom = #plants == 0 or math.random(1, 3) == 2

	if Options.AllowRandomAutoWalk.Value and doRandom then
		humanoid:MoveTo(GetRandomFarmPoint())
	else
		for _, prompt in ipairs(plants) do
			local part = prompt.Parent
			if part and part:IsA("BasePart") then
				humanoid:MoveTo(part.Position)
			end
		end
	end
end

-- Auto loops
task.spawn(function()
	while task.wait(1) do
		if Options.AutoWalk.Value then
			AutoWalkToPlant()
		end
	end
end)

task.spawn(function()
	while task.wait(0.3) do
		if Options.AutoHarvest.Value then
			HarvestPlants()
		end
	end
end)


SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
