--// Variables
local zoneQuests = {
	Desert = {
		"CollectFood",
		"CollectWater",
		"Assasination",
		"TeamFight"
	}
}

--// Modules
local signals = require(script.Parent.Signals)

--// Functions
local function stopDialogue(gui, waitTime)
	--// Create a signal
	local stopSignal = signals.New()
	local stopConnection
	stopConnection = stopSignal:Connect(function()
		--/// Wait and destroy
		local waitPeriod = waitTime or 1.5
		wait(waitPeriod)
		gui:Destroy()
		--// Clean up
		stopConnection:Disconnect()
		stopSignal:Destroy()
		stopConnection = nil
		stopSignal = nil
	end)
	stopSignal:Fire()
end

--// Quest Dialogues
local questDialogue = {
	Desert = {
		CollectFood = {
			MaxRounds = 3, --// Maximum amount of text dialogue rounds
			--// Interaction 1
			Dialogue1                       = "So... hungry... Help... I  can't survive much longer",
			Choice1_1                       = "That's a skill issue.",
			Choice2_1                       = "That sucks... is there any way I can help?",
			Choice3_1                       = "I always thought you could just eat the cacti",

			--// Interaction 2
			Dialogue2                       = "",
			Choice1Clicked_1                = function(gui)
				stopDialogue(gui)
				return "Wow... I guess... I'll starve now"
			end,
			Choice2Clicked_1                = "I think I may have seen a market somewhere around this area...",
			Choice3Clicked_1                = "One of my people thought in a similar fashion... do you see that area below the cliff?",
		},
		CollectWater = {
			--// Interaction 1
			Initiation                      = "Did you know that elves can survive 6 days without water?",
			Choice1_Initiation              = "No I didn't; impressive.",
			Choice2_Initiation              = "DNC",
			Choice3_Initiation              = "Of course I did; I am all-seeing after all."
		},
		Assasination = {
			--// Interaction 1
			Initiation                      = "Have you ever wondered how it feels to...",
			Choice1_Initiation              = "Die?",
			Choice2_Initiation              = "Nani!?!?",
			Choice3_Initiation              = "kill someone?"
		},
		TeamFight = {
			--// Interaction 1
			Initiation                      = "You wanna go kid????",
			Choice1_Initiation              = "Go where?",
			Choice2_Initiation              = "Yea, ezez; let's do it",
			Choice3_Initiation              = "Imagine. I'll drop you in half a second no doubt."
		}
	}
}

--// Dialogue Class
local dialogue = {}
dialogue.__index = dialogue

--// Create a new Dialogue/choose a quest line
function dialogue.New(zone, gui) --// Zone -> the zone that the player is in; gui -> 
	--// Variables
	local questCategory = ( type(zone) == "string" and zoneQuests[zone]) or warn("Zone argument must be a string")
	--local quest = questCategory[math.random(#questCategory)] -- choose a random quest from the category
	local quest = "CollectFood"
	--// Properties
	local self = setmetatable({
		chosenQuest = quest, -- string of the questline
		questZone = zone,
		frame = gui,
		textRound = 1
	}, dialogue)
	return self
end

--// Initiate Quest Dialogue
function dialogue:Initiate()
	--// Variables
	local initiationDialogue = questDialogue[self.questZone][self.chosenQuest]
	local mainTextFrame = self.frame.MainText
	local option1, option2, option3 = self.frame.Option1, self.frame.Option2, self.frame.Option3
	local options = {option1, option2, option3}

	--// Set Text
	mainTextFrame.Text = ( initiationDialogue.Initiation ) or "No valid text found for the main text frame."

	for optionNum, option in ipairs (options) do
		--// Variables
		local optionConnection
		local index = "Choice" .. tostring(optionNum) .. "_Initiation"

		--// Set Text
		option.Text = ( initiationDialogue[index] ) or "N/A"

		--// On button click
		optionConnection = option.MouseButton1Down:Connect(function ()
			self.textRound = self.textRound + 1
			--// Variables
			local dialogueGetter = "Choice" .. tostring(optionNum) .. "Clicked_Initiation"
			local functionGetter = initiationDialogue[dialogueGetter]
			print(dialogueGetter)
			--// Update Dialogue
			functionGetter = ( type(functionGetter) == "function" and  functionGetter() ) or functionGetter
			mainTextFrame.Text = ( functionGetter ) or "No valid text found for the text frame"
			self:Update()

			--// Clean up
			optionConnection:Disconnect()
			optionConnection = nil
		end)
	end
end

--// Click detection for gui/updating text
function dialogue:Update()
	--// Variables
	local initiationDialogue = questDialogue[self.questZone][self.chosenQuest]
	local mainTextFrame = self.frame.MainText
	local option1, option2, option3 = self.frame.Option1, self.frame.Option2, self.frame.Option3
	local round = tostring(self.textRound)
	local options = {option1, option2, option3}

	--// Checks
	if not self.frame then return end
	if self.textRound == initiationDialogue.MaxRounds then
		self.frame.Parent:Destroy()
		return
	end
	--// Set Text
	if self.textRound == 1 then
		mainTextFrame.Text = ( initiationDialogue["Dialogue" .. self.textRound] ) or ( "No valid text found for the main text frame." )
	end
	
	--// Button Down Click; text for buttons
	for optionNum, option in ipairs (options) do
		--// Variables
		local optionConnection
		local index = "Choice" .. optionNum .. "_" .. self.textRound

		--// Set Text
		option.Text = ( initiationDialogue[index] ) or ( "N/A" )

		--// On button click
		optionConnection = option.MouseButton1Down:Connect(function ()

			--// Variables
			local dialogueGetter = "Choice" .. optionNum .. "Clicked_" .. self.textRound
			local functionGetter = initiationDialogue[dialogueGetter]
			
			--// Update Dialogue
			functionGetter = ( type(functionGetter) == "function" and  functionGetter(self.frame.Parent) ) or functionGetter
			mainTextFrame.Text = ( functionGetter ) or self.frame.Parent:Destroy()

			--// Increment Text Round
			self.textRound = self.textRound + 1
			
			--// Reupdate Everything
			self:Update()
			
			--// Clean up
			optionConnection:Disconnect()
			optionConnection = nil
		end)
	end
end

return dialogue
