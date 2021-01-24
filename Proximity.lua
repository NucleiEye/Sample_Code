
--// Modules
local signal = require(script.Parent.Signals) -- Require signal module

--// Proximity Prompt Class
local customProximityPrompt = {}
customProximityPrompt.__index = customProximityPrompt

--// Create a new proximity prompt
function customProximityPrompt.New(player, parent)
    local self = setmetatable({}, customProximityPrompt)

    --// Prompt Properties
    self.Parent = parent  -- Requires a valid instance parent/base part to parent to
    self.Keybind = Enum.KeyCode.F -- Enum keycode for the keybind you want to bind for interaction || default -> F
    self.displayText = "F" -- Only for default gui
    self.MouseInteraction = nil -- For mouse interaction give this value an enum for mouse button 1 or 2
    self.Range = 15 -- Range of prompt visibility/interaction || default -> 15
    self.plr = player -- Player
    self.createGui = false -- True -> Default Gui || False -> Give your own billboard gui
    self.gui = nil -- Billboard gui if the player wants to give a custom gui
    self.interactionCooldown = 2.5 -- Cooldown between allowance for interaction with prompt || default -> 2.5

    --// Prompt Utils
    self.__signal = signal.New() -- Create a signal for handling interacted
    self.__OutsideSignal = signal.New() -- Signal for handling when player leaves range of prompt
    self.__EnterSignal = signal.New() -- Signal for handling when player enters range of prompt
    self.__InteractionEnded = signal.New() -- Signal for end of interaction/pressing of the button
    self.__inRange = false -- Variable for checking if character is in range of the prompt
    self.__uisConnection = nil -- connection for user input service
    self.signals = {self.__signal, self.__OutsideSignal, self.__EnterSignal, self.__InteractionEnded}
    self.db = false

    --// Background Checks
    self:RangeCheck()
    self:InteractionCheck()

    return self
end

--// Create Gui for the prompt
function customProximityPrompt:GuiCreation()
    if self.createGui then
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(5, 0, 5, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = self.Range + 5
        billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 5, 0)
        billboard.Parent = self.Parent
        local centralText = Instance.new("TextLabel")
        centralText.Text = self.displayText
        centralText.TextScaled = true
        centralText.Size = UDim2.new(0.5, 0, 0.5, 0)
        centralText.Parent = billboard
        self.gui = billboard
    else
        if self.gui ~= nil and not self.gui:IsA("BillboardGui") then warn("Must have a valid gui for the prompt.") return end
        local billboard = self.gui:Clone()
        billboard.Parent = self.Parent
        billboard.Enabled = true
        billboard.Adornee = self.Parent
        billboard.MaxDistance = self.Range + 5
        self.gui = billboard
    end
end

--// Handle interaction for that proximity prompt
function customProximityPrompt:Interacted(funct, args)
    if type(funct) ~= "function" then warn("Interaction for proximity prompts must be given a function") return end
    local functionArgs = args ~= nil and table.unpack(args) or nil
    self.__signal:Connect(function ()
        funct(functionArgs)
    end)
end

--// Handle what occurs when interaction ends
function customProximityPrompt:InteractionEnded(funct, args)
    if type(funct) ~= "function" then warn("Interaction for proximity prompts must be given a function") return end
    local functionArgs = args ~= nil and table.unpack(args) or nil
    self.__InteractionEnded:Connect(function ()
        funct(functionArgs)
    end)
end

--// When you come out of the range of the proximity prompt
function customProximityPrompt:RangeLeaving(funct, args)
    if type(funct) ~= "function" then warn("Interaction for proximity prompts must be given a function") return end
    local functionArgs = args ~= nil and table.unpack(args) or nil
    self.__OutsideSignal:Connect(function ()
        funct(functionArgs)
        self.gui.Enabled = false
    end)
end

--// When you enter the range of the proximity prompt
function customProximityPrompt:RangeEntering(funct, args)
    if type(funct) ~= "function" then warn("Interaction for proximity prompts must be given a function") return end
    local functionArgs = args ~= nil and table.unpack(args) or nil
    self.__EnterSignal:Connect(function ()
        self.gui.Enabled = true
        funct(functionArgs)
    end)
end

--// Constantly check if a player is close enough to the prompt, if the player is then fire signals as needed
function customProximityPrompt:RangeCheck()
    local rangeCheck = signal.New()
    local rangeConnection
    rangeConnection = rangeCheck:Connect(function()
        while self do
            if (self.Parent.Position - self.plr.Character.HumanoidRootPart.Position).Magnitude <= self.Range and not self.__inRange then
                self.__inRange = true
                self.__EnterSignal:Fire() -- fire signal that player is entering the range of prompt
            end
            if (self.Parent.Position - self.plr.Character.HumanoidRootPart.Position).Magnitude > self.Range and self.__inRange then
                self.__inRange = false
                self.__OutsideSignal:Fire() -- fire signal that player is leaving the range of prompt
            end
            wait(0.25)
         end
        rangeConnection:Disconnect()
        rangeConnection = nil
        rangeCheck:Destroy()
        rangeCheck = nil
    end)
    rangeCheck:Fire()
end

--// Handle Interaction Checks Occurred; This part at least must be handled on the client
function customProximityPrompt:InteractionCheck()
    local UserInputService = game:GetService("UserInputService")
    self.__uisConnection = UserInputService.InputBegan:Connect(function (input, isTyping)
        if isTyping then return end
        if input.KeyCode == self.Keybind or input.UserInputType == self.MouseInteraction then
            if self.__inRange and not self.__db then
                self.__db = true
                self.__signal:Fire() -- fire signal that player interacted with the prompt
                --// Interaction Ended/Wait for interaction to end then fire signl
                if self.Keybind ~= nil then
                    while UserInputService:IsKeyDown(self.Keybind) do
                        wait(0.05)
                    end
                elseif self.MouseInteraction ~= nil then
                    while UserInputService:IsMouseButtonPressed(self.MouseInteraction) do
                        wait(0.05)
                    end
                end
                self.__InteractionEnded:Fire()
                wait(self.interactionCooldown)
                self.__db = false
            end
        end
    end)
end

--// Destroy Prompt, Connections, and Signals
function customProximityPrompt:Destroy()
    setmetatable(self, nil)
    for _, property in pairs (self) do
         if type(property) == "userdata" then
            property:Disconnect()
        end
    end
    self.Parent.BillboardGui:Destroy()
    for _, _signal in pairs (self.signals) do
        _signal:Destroy()
    end
    self = nil
end

return customProximityPrompt
