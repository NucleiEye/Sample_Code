--[[
    Note: To add new skills just add the button names to buttonTypes and if it is a ui you would click to see the skills for the
    magic then it is a magic; otherwise if it's a skill you equip then it's categorized as a skill
    The rest is handled by the script
-]]
--// Variables
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local menuDb, menuCd = false, 1.25
local menuOn = false
local plrGui = plr:WaitForChild("PlayerGui", 60)
local ui = plr.PlayerGui:WaitForChild("Inventory", 60)
local magics = char:WaitForChild("Magics", 60)
local equipRemote = game.ReplicatedStorage.Remotes.SkillEquipping
local precedingConnections = {}
local debounces = {
    Flame = false,
    Wall = false,
    FrostTusk = false,
    Thunderbolt = false
}
local buttonTypes = {
    --// Magics
    Flame               = "Magic",
    Wall                = "Magic",
    FrostTusk           = "Magic",
    Thunderbolt         = "Magic",

    --// Skills
    BlazingPassion      = "Skill",
    MagnificientFlame   = "Skill",
    FlamingShot         = "Skill",
    UltimateAegis       = "Skill",
    Void                = "Skill",
    AegisPummel         = "Skill",
    FrostBite           = "Skill",
    IcicleCrash         = "Skill",
    IceField            = "Skill",
    ArmorOfThunderGod   = "Skill",
    ElectricLunge       = "Skill",
    ThunderTaze         = "Skill",

    --// Back Button
    Back = "Back"
}
local interactionSignal, interactionConnection

--// Modules
local main = require(game.ReplicatedStorage.Main)
local keyBinds = require(main.moduleList.keybinds)
local descriptions = require(main.moduleList.moveDescs)
local signals = require(main.moduleList.signal)

--// Empty/Initialize Table
keyBinds.equippedSkills[plr.Name] = {}

--// Services
local tweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")

--// Find if there are already existing back frames and delete them if they exist
local function backFrameCheck(gui)
	for _, interface in ipairs (gui.Top:GetChildren()) do
		if interface.Name == "BackFrame" then
			interface:Destroy()
		end
	end
end

--// Take a table and make its elements transparent
local function transparencyTween(objects, mode)
    --// Variables
    local tweens = {}
    local cleanUpConnection

    --// If the mode is to make the elements transparent then make them transparent; otherwise make the elements have properties given
    for _, obj in ipairs (objects) do
	local backTransparency, textTransparency = 0, 0 --// background transparency and text transparency to tween to
	obj.ZIndex = ( mode == "Transparency" and -1 ) or 1
	backTransparency = ( mode == "Transparency" and 1 ) or 0.55
	textTransparency = ( mode == "Transparency" and 1 ) or 0
	local tween = tweenService:Create(obj, TweenInfo.new(0.8), {BackgroundTransparency = backTransparency, TextTransparency = textTransparency})
        tween:Play()
        tweens[#tweens + 1] = tween
    end

    --// Tween Cleanup
    local cleanUp = signals.New()
    cleanUpConnection = cleanUp:Connect(function ()
        for _, tween in ipairs (tweens) do
            tween:Destroy()
        end
        cleanUpConnection:Disconnect()
        cleanUp:Destroy()
        cleanUpConnection = nil
        cleanUp = nil
    end)
end

--// Interactions for buttons classified as 'Magic' or 'Skill'
local interactions = {
    Magic = function (interface) --// when player interacts with a button classified as Magic
        --// Variables
        local button = interface.Name
        local gui = plrGui:FindFirstChild("InventoryClone")
        local tableOfTransparency, tableOfVisibility = {}, {}
        local folder = game.ReplicatedStorage.Assets.UI.Inventory[button .. "Skills"]:GetChildren()

        --// Make Current buttons on the gui uninteractable
        for db, _ in pairs (debounces) do
            debounces[db] = true
        end

        --// Clone respective skill button folder and parent the buttons to the top frame of the gui
        for _, skillButton in ipairs (folder) do
            local buttonClone = skillButton:Clone()
            buttonClone.Parent = gui.Top
        end

        --// Clone Back Button
        local back = game.ReplicatedStorage.Assets.UI.Inventory.Back:Clone()
	    back.Parent = gui.Bottom

        --// Insert ui to respective tables based off the category they fall in
        for name, category in pairs (buttonTypes) do
	    local chooseTable = ( category == "Magic" and tableOfTransparency ) or tableOfVisibility
	    chooseTable[#chooseTable + 1] = ( gui.Top:FindFirstChild(name) and gui.Top[name] ) or ( gui.Bottom:FindFirstChild(name) and gui.Bottom[name] )
        end

        --// Tween Properties of Table of Transparency
	transparencyTween(tableOfTransparency, "Transparency")

        --// Tween Properties of Table of Table of Visibility
        transparencyTween(tableOfVisibility)

        --// Fire Signal to check for interaction with those buttons
        if interactionSignal then interactionSignal:Fire() end
    end,
    Skill = function (interface) --// when player interacts with a button classified as Skill
        --// Variables
        local gui = plrGui:FindFirstChild("InventoryClone")
        local button = interface.Name
        local correspondance = {
            Equip1 = "One",
            Equip2 = "Two",
            Equip3 = "Three",
            Equip4 = "Four",
            Equip5 = "Five"
        }

        --// Check For Backframes and delete any existing ones
        backFrameCheck(gui)

        --// Clone Backframe for current skill
        local backframe = game.ReplicatedStorage.Assets.UI.Inventory.BackFrame:Clone()
        backframe.Parent = gui.Top

        --// Backframe skill's text becomes the skill and the description becomes the associated description to the skill
	    backframe.Skill.Text = interface.Text
        backframe.Description.Text = ( descriptions[button] ) or ( "Description not Found" )

        --// On button pressed equip the skill
        for _, component in ipairs (backframe:GetChildren()) do
            if component:IsA("TextButton") then
                component.MouseButton1Down:Connect(function ()
                    --// Variables
                    local equipTo = correspondance[component.Name]

					--// Check if other skills are equipped to the same spot
					for skill, keybind in pairs (keyBinds.equippedSkills[plr.Name]) do
						if keybind == equipTo and skill then
							for _, magicScript in pairs (magics:GetChildren()) do
								if magicScript:FindFirstChild(skill) then
                                    magicScript[skill]:Destroy()
                                    break
                                end
                            end
                        end
                    end

                    --// "Equip" the skill
                    local skill = game.ReplicatedStorage.Assets.Skills:FindFirstChild(button):Clone()
	                skill.Parent = magics[interface.Value.Value]
					keyBinds.equippedSkills[plr.Name][button] = equipTo
	                plrGui.Tools[equipTo].Skill.Text = interface.Text
                    equipRemote:FireServer(button, equipTo)

					--// Destroy the back frame
					backframe:Destroy()

                    --// Give feedback through equipped text
                    local clone = game.ReplicatedStorage.Assets.UI.Equipped:Clone()
                    clone.Text = "Equipped: " .. interface.Text
                    clone.TextTransparency = 1
                    clone.Parent = plrGui.Equipped
                    local tween1 = tweenService:Create(clone, TweenInfo.new(0.3), {TextTransparency = 0})
                    tween1:Play()
                    wait(1.3)
                    local tween = tweenService:Create(clone, TweenInfo.new(0.3), {TextTransparency = 1})
					tween:Play()

					--// Clean up tweens/objects
                    tween.Completed:wait()
                    tween:Destroy()
                    tween1:Destroy()
					clone:Destroy()
                end)
            end
        end
    end,
    Back = function () --// when player interacts with the Back Button
        --// Variables
        local gui = plrGui:FindFirstChild("InventoryClone")
        local tableOfTransparency, tableOfVisibility = {}, {}

        --// Check for backframes and delete any existing ones
        backFrameCheck(gui)

        --// Add elements to tables based off of the category they fall in
        for name, category in pairs (buttonTypes) do
            if category == "Magic" then --// If it falls under the category of Magic then it'll be added to tableOfVisibility
                tableOfVisibility[#tableOfVisibility + 1] = ( gui.Top:FindFirstChild(name) and gui.Top[name] ) or ( gui.Bottom:FindFirstChild(name) and gui.Bottom[name] )
            else --// If it doesn't fall under the category of Magic then it'll be added to tableOfTransparency
                tableOfTransparency[#tableOfTransparency + 1] = ( gui.Top:FindFirstChild(name) and gui.Top[name] ) or ( gui.Bottom:FindFirstChild(name) and gui.Bottom[name] )
            end
        end

        --// Tween Properies of table of transparency and destroy the elements within it
        transparencyTween(tableOfTransparency, "Transparency")
        for _, obj in ipairs (tableOfTransparency) do
            obj:Destroy()
        end

        --// Tween Properties of table of visibility
        transparencyTween(tableOfVisibility)

        --// Toggle the button debounces so that the magic buttons are interactable again
        for db, _ in pairs (debounces) do
            debounces[db] = false
        end
    end
}

--// Check for Button Interaction/Signal Function and perform a function based off of the category the button falls in
local function buttonInteractionCheck()
    local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
	for _, connection in ipairs (precedingConnections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	for _, interface in ipairs (gui:GetDescendants()) do
		if interface:IsA("TextButton") and interface.Parent ~= "BackFrame" and interface.Parent:IsA("Frame") then
            local connection
			connection = interface.MouseButton1Down:Connect(function()
				for db, _ in pairs (debounces) do
                    if interface.Name == db and debounces[db] then return end
				end
                if buttonTypes[interface.Name] then
                    interactions[buttonTypes[interface.Name]](interface)
                end
			end)
            precedingConnections[#precedingConnections + 1] = connection
		end
	end
end

--// User Input Began
uis.InputBegan:Connect(function (input, isTyping)
    if isTyping then return end
    if input.KeyCode == Enum.KeyCode.M and not menuDb then
        menuDb = true
        if menuOn then --// If the menu is already on then turn menu off and remove the menu ui
            menuOn = not menuOn
            for db, _ in pairs (debounces) do
                debounces[db] = false
            end
			local gui = plr.PlayerGui:FindFirstChild("InventoryClone")
			local tweenTop = tweenService:Create(gui.Top, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Position = UDim2.new(0.266, 0, -1, 0)})
			local tweenBottom = tweenService:Create(gui.Bottom, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Position = UDim2.new(0.266, 0, 1, 0)})
			tweenTop:Play()
			tweenBottom:Play()
            tweenBottom.Completed:wait()
            --// Clean up
            gui:Destroy()
            interactionConnection:Disconnect()
            interactionSignal:Destroy()
            interactionConnection = nil
            interactionSignal = nil
        else --// If the menu isn't on then it's obviously off; clone the equipping inventory ui and check for button interaction
            menuOn = true
            local gui = ui:Clone()
            gui.Name = "InventoryClone"
            gui.Parent = plr.PlayerGui
            local tweenTop = tweenService:Create(gui.Top, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Position = UDim2.new(0.266, 0, 0.064, 0)})
			local tweenBottom = tweenService:Create(gui.Bottom, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Position = UDim2.new(0.266, 0, 0.345, 0)})
			tweenTop:Play()
            tweenBottom:Play()
            local buttonInteraction = signals.New()
            interactionSignal = buttonInteraction
            interactionConnection = buttonInteraction:Connect(buttonInteractionCheck)
            buttonInteraction:Fire()
        end
        wait(menuCd)
        menuDb = false
    end
end)

--// Remote fired to client to update equipped skills client based for datastore
game.ReplicatedStorage.Remotes.SkillEquipping.OnClientEvent:Connect(function(parent, num)
	keyBinds.equippedSkills[plr.Name][parent] = num
end)
