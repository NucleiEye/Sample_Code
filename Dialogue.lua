--[[
Bugs in question -> why the heck is there 2 registrations of a click
Details: on the last click self:Update() gets fired twice; reason why seems to be 
the line that changes the self.nextPath
]]

--// Variables
local zoneQuests = {
	Desert = {
		"collectFood",
		"collectWater",
		"assasination",
		"teamFight"
	}
}

--// Modules
local signals = require(script.Parent.Signals)

--// Functions
local function stopDialogue(gui, waitTime) --// stop dialogue/destroy ui clean up connectionsn
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

--// Dialogue; put in a seperate module in the future
local questDialogue = {
	Desert = {
		collectFood = {
			maxRounds = 3, --// Number of rounds maximum

			--// Initiation Path when interaction initiates
			initiationPath = {
				--// Paths for respectively clicked options
				futurePaths = {"skillIssue", "helpPart1", "storyPart1"},

				--// NPC text
				textForNPC = "So... hungry... Help... I  can't survive much longer",

				--// Option Texts
				Option1 = "That's a skill issue.",
				Option2 = "That sucks... is there any way I can help?",
				Option3 = "I always thought you could just eat the cacti."
			},

			----------------------------------------------------------------------------------------------

			--// Skill Issue Path
			skillIssue = {
				--// NPC text; Terminate Dialogue
				textForNPC = function (gui)
					stopDialogue(gui)
					return "Wow... I guess... I'll starve now"
				end
			},

			----------------------------------------------------------------------------------------------

			--// Help Part1 Path
			helpPart1 = {
				--// Paths for respectively clicked options
				futurePaths = {"helpAccept", "helpRejection"},

				--// NPC text
				textForNPC = "I think I may have seen a market somewhere around this area... could you get me some food?",

				--// Option Texts
				Option1 = "Sure! This will be a piece of cake!! Get it? Food... cake.. ahahah",
				Option2 = "Eh, I don't think I have the time I'm so very sorry."
			},

			--// Help Accepted Path
			helpAccept = {
				--// NPC text
				textForNPC = "Thank you so much! c: **Stomach groans** I need you to hurry good sir... please",
			},

			--// Help Rejected Path
			helpRejection = {
				--// NPC text
				textForNPC = "Unfortunate... thank you for your time though :c"
			},

			----------------------------------------------------------------------------------------------

			--// Story Part1 Path
			storyPart1 = {
				--// Future Paths
				futurePaths = {"alreadySeen", "notSeen"},

				--// NPC text
				textForNPC = "One of my people thought in a similar fashion... do you see that area below the cliff?",

				--// Option Texts
				Option1 = "Yea I saw it... I thought the body came from somethin else",
				Option2 = "No, I didn't see it? Mind showing me?"
			},

			--// Already Seen Path
			alreadySeen = {
				--// NPC text
				textForNPC = "Well it for sure didn't."
			},

			--// Not Seen path
			notSeen = {
				--// NPC text
				textForNPC = function()
					--// Perform cutscene to body here
					return "Here it is..."
				end
			},
		}
	}
}

--// Dialogue Handling Class
local dialogue = {}
dialogue.__index = dialogue

--// Initiate a new Dialogue
function dialogue.New(zone, gui, character) --// Zone -> String of Zone || Gui -> Element containing elements of options and text
	--// Variables
	--// Note: Uncomment following 2 lines of code once all those quests have dialogues
	--local questCategory = ( type(zone) == "string" and zoneQuests[zone] ) or warn("Zone argument must be a string")
	--local quest = questCategory[math.random(#questCategory)] -- choose a random quest from the category
	local quest = "collectFood"

	--// Define self and add properties
	local self = setmetatable({
		character = character,
		chosenQuest = quest, --// Quest chosen for the individual
		questZone = zone, --// Zone of the quest
		currentRound = 1, --// Round of Text
		elementContainer = gui, --// Container of the elements for the dialogue handling
		nextPath = nil --// Next Path Available
	}, dialogue)

	--// Update and initiate dialogue
	self:Update()

	--// Return the value
	return self
end

function dialogue:Update()
	--// Variables
	local elementContainer = self.elementContainer
	local currentRound = self.currentRound
	local dialogueLines = questDialogue[self.questZone][self.chosenQuest]
	local currentChosenPath = ( self.nextPath and dialogueLines[self.nextPath] ) or ( dialogueLines.initiationPath )
	local mainTextFrame = elementContainer.MainText
	local options = {elementContainer.Option1, elementContainer.Option2, elementContainer.Option3}
	local maxRounds = dialogueLines.maxRounds
	local questScreenGUI = elementContainer.Parent

	--// Temporary fix to bug bc im annoyed :)
	if currentRound > maxRounds then return end

	--// Text for npc is the chosen path's text; if nothing is found then filler text given
	local npcText = ( currentChosenPath.textForNPC ) or ( "No text found for the npc." )
	npcText = ( type(npcText) == "function" and npcText(questScreenGUI) ) or ( npcText )

	--// If you can't find an existing container then break off the recursive function
	if not elementContainer then return end

	--// Set the text
	mainTextFrame.Text = npcText

	--// If the max round number has been met then break off the recursive function
	if currentRound == maxRounds then
		wait(1.5)
		questScreenGUI:Destroy()
		return
	end

	--// Loop through options to set their text and set their interaction events
	for optionNumber, option in ipairs (options) do
		--// Variables
		local optionClickConnection

		--// Set Text of Option
		option.Text = ( currentChosenPath[option.Name] ) or ( "N/A" )

		--// Click Detection
		optionClickConnection = option.MouseButton1Click:Connect(function ()
			--// Update Path for next round of text
			self.nextPath = currentChosenPath.futurePaths[optionNumber]

			--// Text round increased accordingly
			self.currentRound = self.currentRound + 1

			--// Recursively call :Update with the text for the npc to say
			self:Update()

			--// Clean up connections
			optionClickConnection:Disconnect()
			optionClickConnection = nil
			return
		end)
	end
end

return dialogue
