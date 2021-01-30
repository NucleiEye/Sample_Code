--// Variables
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:wait()
local dashCd, sprintCd = 1.5, .08
local dashDb, sprintDb = false, false
local lastPressed, signalSent = nil, false

--// Modules
local main = require(game.ReplicatedStorage.Main)
local functions = require(main.moduleList.functions)
local animLoader = require(main.moduleList.animationLoader)

--// Services
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

--// Functions
local dashing = {
	D = function()
		animLoader.returnAnims(game.ReplicatedStorage.Assets.Animations.Dashing.Right, char):Play()
		game.ReplicatedStorage.Remotes.Movement:FireServer("D")
	end,
	A = function()
		animLoader.returnAnims(game.ReplicatedStorage.Assets.Animations.Dashing.Left, char):Play()
		game.ReplicatedStorage.Remotes.Movement:FireServer("A")
	end,
	W = function()
		animLoader.returnAnims(game.ReplicatedStorage.Assets.Animations.Dashing.Front, char):Play()
		game.ReplicatedStorage.Remotes.Movement:FireServer("W")
	end,
	S = function()
		animLoader.returnAnims(game.ReplicatedStorage.Assets.Animations.Dashing.Back, char):Play()
		game.ReplicatedStorage.Remotes.Movement:FireServer("S")
	end
}

--// Input Began
uis.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end
	if input.KeyCode == Enum.KeyCode.Q and not dashDb and char.Values.punchCd.Value == false and char.Values.isBlocking.Value == false then
		char.Values.punchCd.Value = true
		dashDb = true
		for key, funct in pairs (dashing) do
			if uis:IsKeyDown(key) then
				dashing[key]()
				break
			end
		end
		wait(dashCd)
		dashDb = false
	end
	if input.KeyCode == Enum.KeyCode.W and lastPressed ~= nil and os.clock() - lastPressed < 0.2 and not sprintDb and char.Values.isBlocking.Value == false and char.Values.punchCd.Value == false then
		sprintDb = true
		signalSent = true
		game.ReplicatedStorage.Remotes.Movement:FireServer("Sprinting")
		while uis:IsKeyDown(Enum.KeyCode.W) or uis:IsKeyDown(Enum.KeyCode.A) or uis:IsKeyDown(Enum.KeyCode.D) do
			wait(0.05)
		end
		game.ReplicatedStorage.Remotes.Movement:FireServer("SprintingOff")
		wait(sprintCd)
		lastPressed = nil
		sprintDb = false
		signalSent = false
	end
end)

--// Input Ended
uis.InputEnded:Connect(function(input, isTyping)
	if isTyping then return end
	if input.KeyCode == Enum.KeyCode.W and lastPressed == nil and not sprintDb then
		sprintDb = true
		lastPressed = os.clock()
		sprintDb = false
		coroutine.wrap(function()
			wait(.2)
			if signalSent == false then lastPressed = nil end
		end)()
	end
end)

local dashEvents = {
	D = function(char)
		local fx = game.ReplicatedStorage.Assets.FX.ArmorOfThunderGodDash:Clone()
		fx.P1.CFrame = char.HumanoidRootPart.CFrame
		fx.P2.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(-8, 0, 0)
		fx.Parent = char
		for i = 0, 1, 0.018 do
			for _, beam in ipairs (fx.P1:GetChildren()) do
				if beam:IsA("Beam") then
					beam.Width0 = functions.lerp(beam.Width0, 0, i)
					beam.Width1 = functions.lerp(beam.Width1, 0, i)
				end
			end
			runService.RenderStepped:wait()
		end
		fx:Destroy()
	end,
	A = function(char)
		local fx = game.ReplicatedStorage.Assets.FX.ArmorOfThunderGodDash:Clone()
		fx.P1.CFrame = char.HumanoidRootPart.CFrame
		fx.P2.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(8, 0, 0)
		fx.Parent = char
		for i = 0, 1, 0.018 do
			for _, beam in ipairs (fx.P1:GetChildren()) do
				if beam:IsA("Beam") then
					beam.Width0 = functions.lerp(beam.Width0, 0, i)
					beam.Width1 = functions.lerp(beam.Width1, 0, i)
				end
			end
			runService.RenderStepped:wait()
		end
		fx:Destroy()
	end,
	S = function(char)
		local fx = game.ReplicatedStorage.Assets.FX.ArmorOfThunderGodDash:Clone()
		fx.P1.CFrame = char.HumanoidRootPart.CFrame
		fx.P2.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8)
		fx.Parent = char
		for i = 0, 1, 0.018 do
			for _, beam in ipairs (fx.P1:GetChildren()) do
				if beam:IsA("Beam") then
					beam.Width0 = functions.lerp(beam.Width0, 0, i)
					beam.Width1 = functions.lerp(beam.Width1, 0, i)
				end
			end
			runService.RenderStepped:wait()
		end
		fx:Destroy()
	end,
	W = function(char)
		local fx = game.ReplicatedStorage.Assets.FX.ArmorOfThunderGodDash:Clone()
		fx.P1.CFrame = char.HumanoidRootPart.CFrame
		fx.P2.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, 8)
		fx.Parent = char
		for i = 0, 1, 0.018 do
			for _, beam in ipairs (fx.P1:GetChildren()) do
				if beam:IsA("Beam") then
					beam.Width0 = functions.lerp(beam.Width0, 0, i)
					beam.Width1 = functions.lerp(beam.Width1, 0, i)
				end
			end
			runService.RenderStepped:wait()
		end
		fx:Destroy()
	end
}

--// On client event
game.ReplicatedStorage.Remotes.Movement.OnClientEvent:Connect(function(char, movementType)
	if dashEvents[movementType] then
		dashEvents[movementType](char)
	end
end)
