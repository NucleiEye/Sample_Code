--// Variables
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:wait()
local keyToShow = Enum.KeyCode.M
local ui = plr.PlayerGui.Inventory
local menuOn = false
local menuDb = false
local guiTable = {}
local equipTable = {}
local magicNames = {
	Flame = {"BlazingPassion", "MagnificientFlame", "FlamingShot"},
	Wall = {"UltimateAegis", "Void", "AegisPummel"},
	FrostTusk = {"FrostBite", "IcicleCrash", "IceField"},
	Thunderbolt = {"ArmorOfThunderGod", "ElectricLunge", "ThunderTaze"}
}
local skills = {
	"BlazingPassion", "MagnificientFlame", "FlamingShot",
	"UltimateAegis", "Void", "AegisPummel",
	"FrostBite", "IcicleCrash", "IceField",
	"ArmorOfThunderGod", "ElectricLunge", "ThunderTaze"
}
local precedingConnections = {}
local alreadyEquipped = {}
local debounces = {
	Flame = false,
	Wall = false,
	frostTusk = false,
	Thunderbolt = false
}
local tableOfMagics = {"Flame", "Wall", "FrostTusk", "Thunderbolt"}
local skillFolderNames = {
	Flame = "FireSkills",
	Wall = "WallSkills",
	FrostTusk = "FrostTuskSkills",
	Thunderbolt = "ThunderboltSkills"
}

--// Modules
local main = require(game.ReplicatedStorage.Main)
local movement = require(main.moduleList.movement)
local generate = require(main.moduleList.toolGeneration)
local storage = require(main.moduleList.storageTools)
local keyBinds = require(main.moduleList.keybinds)
local descriptions = require(main.moduleList.moveDescs)

--// Empty/Initialize Table
keyBinds.equippedSkills[plr.Name] = {}

--// Services
local uis = game:GetService("UserInputService")
local tweenServices = game:GetService("TweenService")

--// Functions
--// On Button Clicks(General Functions)
local function transparencyTextBack(gui)
	for _, name in ipairs (gui) do
		name.Active = false
		name.ZIndex = -1
		local tween = tweenServices:Create(name, TweenInfo.new(0.8), {BackgroundTransparency = 1, TextTransparency = 1})
		tween:Play()
	end
end

--// Make Buttons/Text Labels Visible
local function visibilityTextBack(gui)
	for _, name in ipairs (gui) do
		name.Active = true
		name.ZIndex = 1
		local tween = tweenServices:Create(name, TweenInfo.new(0.8), {BackgroundTransparency = 0.55, TextTransparency = 0})
		tween:Play()
	end
end

--// Clone a given decal with a given color
local function decalClone(decal, color)
	local dec = game.ReplicatedStorage.Assets.UI.Inventory.Decals[decal]:Clone()
	dec.ImageColor3 = color
	dec.Parent = plr.PlayerGui.InventoryClone.Top.BackFrame.Info
	return dec
end

--// Handle Decal Label
local function decal(txt, color)
	local dec = decalClone(txt, color)
	dec.MouseEnter:Connect(function()
		local infusibleLabel = game.ReplicatedStorage.Assets.UI.Inventory.InfusibleLabel:Clone()
		infusibleLabel.Text = txt
		infusibleLabel.Parent = plr.PlayerGui.InventoryClone.Top
	end)
	dec.MouseLeave:Connect(function()
		local infusibleLabel = plr.PlayerGui.InventoryClone.Top.InfusibleLabel
		infusibleLabel:Destroy()
	end)
end

--// Decal Interactions
local decals = {
	MagnificientFlame = function()
		decal("Infusable", Color3.fromRGB(255, 98, 25))
	end,
	FlamingShot = function()
		decal("Infusable", Color3.fromRGB(255, 98, 25))
	end,
	IcicleCrash = function()
		decal("Infusable", Color3.fromRGB(11, 137, 255))
	end,
	--// Modes
	BlazingPassion = function()
		decal("Mode", Color3.fromRGB(255, 98, 25))
	end,
	FrostBite = function()
		decal("Mode", Color3.fromRGB(11, 137, 255))
	end,
	ArmorOfThunderGod = function()
		decal("Mode", Color3.fromRGB(133, 186, 255))
	end
}

local function equip(nam, parent, mag, num)
	if mag:FindFirstChild(nam) or keyBinds.equippedSkills[plr.Name][nam] ~= nil then
		plr.PlayerGui.Tools[keyBinds.equippedSkills[plr.Name][nam]].Skill.Text = "Empty"
		keyBinds.equippedSkills[plr.Name][parent.Name] = nil
		mag[nam]:Destroy()
	end
	local skill = game.ReplicatedStorage.Assets.Skills:FindFirstChild(nam):Clone() or nil
	skill.Parent = mag
	plr.PlayerGui.InventoryClone.Top.BackFrame:Destroy()
	game.ReplicatedStorage.Remotes.SkillEquipping:FireServer(parent.Name, num)
	keyBinds.equippedSkills[plr.Name][parent.Name] = num
	plr.PlayerGui.Tools[num].Skill.Text = parent.Text
	local clone = game.ReplicatedStorage.Assets.UI.Equipped:Clone()
	clone.Text = "Equipped: " .. parent.Text
	clone.TextTransparency = 1
	clone.Parent = plr.PlayerGui.Equipped
	local tween1 = tweenServices:Create(clone, TweenInfo.new(0.3), {TextTransparency = 0})
	tween1:Play()
	wait(1.3)
	local tween = tweenServices:Create(clone, TweenInfo.new(0.3), {TextTransparency = 1})
	tween:Play()
	tween.Completed:wait()
	tween:Destroy()
	tween1:Destroy()
	clone:Destroy()
end

--// Equip 1 clicked
local function equip1(skill)
	local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	local parent = gui.Top[string.gsub(skill, "%s", "")] or gui.Bottom[string.gsub(skill, "%s", "")]
	equip(parent.Name, parent, char:FindFirstChild("Magics")[parent.Value.Value], "One")
end

--// Equip 2 clicked
local function equip2(skill)
	local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	local parent = gui.Top[string.gsub(skill, "%s", "")] or gui.Bottom[string.gsub(skill, "%s", "")]
	equip(parent.Name, parent, char:FindFirstChild("Magics")[parent.Value.Value], "Two")
end

--// Equip 3 clicked
local function equip3(skill)
	local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	local parent = gui.Top[string.gsub(skill, "%s", "")] or gui.Bottom[string.gsub(skill, "%s", "")]
	equip(parent.Name, parent, char:FindFirstChild("Magics")[parent.Value.Value], "Three")
end

--// Equip 4 clicked
local function equip4(skill)
	local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	local parent = gui.Top[string.gsub(skill, "%s", "")] or gui.Bottom[string.gsub(skill, "%s", "")]
	equip(parent.Name, parent, char:FindFirstChild("Magics")[parent.Value.Value], "Four")
end

--// Equip 5 clicked
local function equip5(skill)
	local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	local parent = gui.Top[string.gsub(skill, "%s", "")] or gui.Bottom[string.gsub(skill, "%s", "")]
	equip(parent.Name, parent, char:FindFirstChild("Magics")[parent.Value.Value], "Five")
end

equipTable.Equip1 = equip1
equipTable.Equip2 = equip2
equipTable.Equip3 = equip3
equipTable.Equip4 = equip4
equipTable.Equip5 = equip5

--// Clone and place equip gui
local function cloneAndPlace(gui, parent, skill)
	local guiClone = game.ReplicatedStorage.Assets.UI.Inventory.BackFrame:Clone()
	guiClone.Parent = parent
	guiClone.Skill.Text = skill
	guiClone.Description.Text = descriptions[string.gsub(skill, "%s", "")] or "Description not Found"
	for _, name in pairs (guiClone:GetChildren()) do
		if name:IsA("TextButton") then
			name.MouseButton1Down:Connect(function()
				equipTable[name.Name](skill)
			end)
		end
	end
	if decals[string.gsub(skill, "%s", "")] then
		decals[string.gsub(skill, "%s", "")]()
	end
end

--// Clone Specific folder Children and place it within an area
local function cloneFolder(folder, parent)
	for _, button in ipairs (folder:GetChildren()) do
		local clone = button:Clone()
		clone.Parent = parent
	end
end

--// Check for other backframes and destroy them if they exist
local function findBackframes(gui)
	for _, ui in ipairs (gui:GetDescendants()) do
		if ui.Name == "BackFrame" and ui.Parent ~= gui and ui:IsA("Frame") then
			ui:Destroy()
		end
	end
end

--// Base Magic Cloner
local function baseElement(magic)
	local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	local mag = string.gsub(magic, "%s", "")
	cloneFolder(game.ReplicatedStorage.Assets.UI.Inventory[skillFolderNames[mag]], gui.Top)
	local back = game.ReplicatedStorage.Assets.UI.Inventory.Back:Clone()
	back.Parent = gui.Bottom
	local tween = tweenServices:Create(back, TweenInfo.new(0.8), {BackgroundTransparency = 0.55, TextTransparency = 0})
	local tableOfTransparency = {}
	for _, name in ipairs (tableOfMagics) do
		table.insert(tableOfTransparency, #tableOfTransparency + 1, gui.Top[name])
	end
	local tableOfVisibility = {}
	for name, moves in pairs (magicNames) do
		if name == mag then
			for _, skill in ipairs (moves) do
				table.insert(tableOfVisibility, #tableOfVisibility + 1, gui.Top[skill])
			end
		end
	end
	for db, _ in ipairs (debounces) do
		debounces[db] = true
	end
	tween:Play()
	transparencyTextBack(tableOfTransparency)
	visibilityTextBack(tableOfVisibility)
	game.ReplicatedStorage.Signals.CheckHit:Fire()
end

--// Skills Button Clicks
local function skillButtonClicks(skillName)
	local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	findBackframes(gui)
	--cloneAndPlace(gui, gui.Top[skillName])
	cloneAndPlace(gui, gui.Top, skillName)
end

--// Back Function
local function Back()
	local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	findBackframes(gui)
	local tableOfTransparency = {gui.Bottom.Back}
	for _, ui in ipairs (gui.Top:GetChildren()) do
		for _, skill in ipairs (skills) do
			if ui:IsA("TextButton") and tostring(ui) == skill then 
				table.insert(tableOfTransparency, #tableOfTransparency + 1, ui)
			end
		end
	end
	local tableOfVisibility = {}
	for _, name in ipairs (tableOfMagics) do
		table.insert(tableOfVisibility, #tableOfVisibility + 1, gui.Top[name])
	end
	for db, _ in ipairs (debounces) do
		debounces[db] = false
	end
	transparencyTextBack(tableOfTransparency)
	coroutine.wrap(function()
		wait(0.8)
		for _, ui in ipairs (tableOfTransparency) do
			ui:Destroy()
		end
	end)()
	visibilityTextBack(tableOfVisibility)
	game.ReplicatedStorage.Signals.CheckHit:Fire()
end

--// Add the functions to the table
for _, magic in ipairs (tableOfMagics) do
	guiTable[magic] = baseElement
end
for magic, skill in pairs (magicNames) do
	for _, move in ipairs (skill) do
		guiTable[move] = skillButtonClicks
	end
end
guiTable.Back = Back

--// Input Began
uis.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end
	if not isTyping and input.KeyCode == keyToShow and not menuDb then
		menuDb = true
		if not menuOn then
			local gui = ui:Clone()
			gui.Name = "InventoryClone"
			gui.Parent = plr.PlayerGui
			menuOn = true
			--game.ReplicatedStorage.Remotes.GUI.Inventory:FireServer("equip")
			--cutscene()
			local tweenTop = tweenServices:Create(gui.Top, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Position = UDim2.new(0.266, 0, 0.064, 0)})
			local tweenBottom = tweenServices:Create(gui.Bottom, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Position = UDim2.new(0.266, 0, 0.345, 0)})
			tweenTop:Play()
			tweenBottom:Play()

			--// Running Events; loop through descendants of ui
			--// if there are any text buttons then when that textbutton
			--// is clicked, then on click do whatever is assigned to that name
			game.ReplicatedStorage.Signals.CheckHit:Fire()
		elseif menuOn then
			menuOn = false
			local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
			local tweenTop = tweenServices:Create(gui.Top, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Position = UDim2.new(0.266, 0, -1, 0)})
			local tweenBottom = tweenServices:Create(gui.Bottom, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Position = UDim2.new(0.266, 0, 1, 0)})
			tweenTop:Play()
			tweenBottom:Play()
			tweenBottom.Completed:wait()
			gui:Destroy()
			debounces.Flame = false
			debounces.Wall = false
			game.ReplicatedStorage.Remotes.GUI.Inventory:FireServer("unequip")
			--char.Humanoid.WalkSpeed = 13
			--game.Lighting:FindFirstChild("Blur"):Destroy()
		end
		wait(2)
		menuDb = false
	end
end)

--// on binded event
game.ReplicatedStorage.Signals.CheckHit.Event:Connect(function()
	local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	for _, connection in ipairs (precedingConnections) do
		if type(connection) == "userdata" then
			connection:Disconnect()
		end
	end
	for _, ui in pairs (gui:GetDescendants()) do
		if ui:IsA("TextButton") and ui.Parent ~= "BackFrame" and ui.Parent:IsA("Frame") then
			local connection
			connection = ui.MouseButton1Down:Connect(function()
				for name, _ in pairs (debounces) do
					if ui.Name == name and debounces[name] == true then return end
				end
				guiTable[ui.Name](ui.Text)
			end)
			table.insert(precedingConnections, #precedingConnections + 1, connection)
		end
	end
end)
