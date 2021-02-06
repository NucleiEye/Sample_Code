--[[ Key for my sped brain:
Choice1Clicked_1 -> Choice "1" means that that's the button order 1 = first button
Choice1Clicked_1 -> Choice1Clicked_ "1" means that that's the round
------------------------------------------------------------------------------------

Choice1Clicked_2_From2 -> Choice "1" means same thing
Choice1Clicked_2_From2 -> Choice1Clicked_ "2" means that you're on the next text round
Choice1Clicked_2_From2 -> Choice1Clicked_2_From "2" means that you clicked two on the previous round
----------------------------------------------------------------------------------------------------

Choice1_1 -> Choice "1" represents the button number in order; 1 = first button
Choice1_1 -> Choice1_ "1" represents the text round; so this is the first text round 1st choice
-----------------------------------------------------------------------------------------------

Choice1_2_From2	 -> Choice "1" represents the button number in orer; 1 = first button
Choice1_2_From2	 -> Choice1_2_From "2" represents the button that was pressed in the last round;
				  In this situation, the button pressed was 2
Choice1_2_From2	 -> Choice1_ "2" represents the round of text
-------------------------------------------------------------------------------------------

Options -> Option1 = quest path
quest path = {} in this table, insert the dialogue, for everything starting the 2nd selection aka 3rd text round
CAN be stacked or changed in mid-script but as of right now this system will only support up to 3 rounds of text
]]--

--// Future note: make quest indices more specific for better recognition and so my sped mind won't lose track of what everything is

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
	--// Create and fire a signal
	local stopSignal = signals.New()
	local stopConnection
	stopConnection = stopSignal:Connect(function()
		--/// Wait and destroy
		local waitPeriod = ( waitTime ) or ( 1.5 )
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

--// Eventually use a module for specific zone dialogues; rn testing purposes only
--// Quest Dialogues
local questDialogue = {
	Desert = {
		CollectFood = {
			MaxRounds = 3, --// Maximum amount of text dialogue rounds

			--// Quest Paths
			Option1				= nil,
			Option2 			= "canIHelp",
			Option3				= "deadBodySeen",

			--// Interaction 1
			Dialogue1                       = "So... hungry... Help... I  can't survive much longer",
			Choice1_1                       = "That's a skill issue.",
			Choice2_1                       = "That sucks... is there any way I can help?",
			Choice3_1                       = "I always thought you could just eat the cacti",

			--// Interaction 2
			Choice1Clicked_1                = function(gui) --// Dialogue Ends
				stopDialogue(gui)
				return "Wow... I guess... I'll starve now"
			end,
			Choice2Clicked_1                = "I think I may have seen a market somewhere around this area... could you get me some food?",
			Choice3Clicked_1                = "One of my people thought in a similar fashion... do you see that area below the cliff?",

			--// Interaction 2 Choice 2 Interaction Options
			Choice1_2_From2			= "Sure!",
			Choice2_2_From2			= "Nah, I'm good.",

			--// Interaction 2 Choice 3 Interaction Options
			Choice1_2_From3			= "Yea I saw it... I thought the body came from somethin else",
			Choice2_2_From3			= "No, I didn't see it? Mind showing me?",

			--// Can I help dialogue path
			canIHelp 						= {
				Choice1Clicked_2_From1 	= "Thank you so much! c:",
				Choice2Clicked_2_From2	= "Unfortunate... thank you for your time though :c"
			},

			--// Dead body seen path
			deadBodySeen			= {
				Choice1Clicked_2_From1	= "Well it for sure didn't.",
				Choice2Clicked_2_From2	= "Here it is..."
			}
		},
	}
}

--// Dialogue Class
local dialogue = {}
dialogue.__index = dialogue

--// Create a new Dialogue/choose a quest line
function dialogue.New(zone, gui) --// Zone -> the zone that the player is in; gui -> 
	--// Variables
	--// Note: Uncomment following 2 lines of code once all those quests have dialogues
	--local questCategory = ( type(zone) == "string" and zoneQuests[zone] ) or warn("Zone argument must be a string")
	--local quest = questCategory[math.random(#questCategory)] -- choose a random quest from the category
	local quest = "CollectFood"
	--// Properties
	local self = setmetatable({
		chosenQuest = quest, -- string of the questline
		questZone = zone, -- the zone the quest is in
		frame = gui, -- the frame that the quest ui will be in
		textRound = 1, -- the round of text the dialogue is at
		selectedOption = nil, -- the selected option of the player
		path = nil -- the dialogue path the player chooses
	}, dialogue)
	return self
end

--// Click detection for gui/updating text
function dialogue:Update(npcText)
	--// Variables
	local initiationDialogue = questDialogue[self.questZone][self.chosenQuest]
	local mainTextFrame = self.frame.MainText
	local options = {self.frame.Option1, self.frame.Option2, self.frame.Option3}

	--// If the frmae doesn't exist then break off of the recursive function
	if not self.frame then return end

	--// Set Text
	if not npcText then
		mainTextFrame.Text = ( initiationDialogue["Dialogue" .. self.textRound] ) or ( "No valid text found for the main text frame." )
	else
		mainTextFrame.Text = npcText
	end

	--// If max rounds met then delete dialogue and break off of the recursive function
	if self.textRound == initiationDialogue.MaxRounds then
		wait(1.5)
		self.frame.Parent:Destroy()
		return
	end

	--// Button Down Click; text for buttons
	for optionNum, option in ipairs (options) do
		--// Variables
		local lastClicked = ( self.selectedOption and "_From" .. self.selectedOption ) or ( "" )
		local index = "Choice" .. optionNum .. "_" .. self.textRound .. lastClicked
		local optionConnection

		--// Set Text
		option.Text = ( initiationDialogue[index] ) or ( "N/A" )

		--// On button click
		optionConnection = option.MouseButton1Down:Connect(function ()
			if self.textRound == initiationDialogue.MaxRounds then return end --// check to fix bug temporarily

			--// Update Selected Options
			self.selectedOption = optionNum
			if self.textRound >= 2 then
				lastClicked = ( self.selectedOption and "_From" .. self.selectedOption ) or ( "" )
			else --// if text round isn't greater then or equal to 2 then text round is equal to 1 so choose a path
				self.path = initiationDialogue[option.Name]
			end

			--// Variables
			local mainDialogueIndex = "Choice" .. optionNum .. "Clicked_" .. self.textRound .. lastClicked
			self.dialogueGetter = ( self.textRound >= 2 and initiationDialogue[self.path[mainDialogueIndex]] ) or ( mainDialogueIndex )
			local functionGetter = ( initiationDialogue[self.path] and initiationDialogue[self.path][mainDialogueIndex] ) or initiationDialogue[mainDialogueIndex]

			--// Update Dialogue
			functionGetter = ( type(functionGetter) == "function" and  functionGetter(self.frame.Parent) ) or functionGetter

				--// Increment text round
			self.textRound = self.textRound + 1

			--// Recurse
			self:Update(functionGetter)

			--// Clean up
			optionConnection:Disconnect()
			optionConnection = nil
		end)
	end
end

return dialogue
