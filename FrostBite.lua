 --// All of this is wrapped inside a function which gets called upon a remote being fired. That can be shown if requested
    for _, dmgType in ipairs (diffDamageTypes) do
			if char.Values[dmgType].Value == true then return end
		end

		--// Animation Playing
		local anim = animLoader.returnAnims(game.ReplicatedStorage.Assets.Animations.Magics.ModeStartup, char)
		anim:Play()
		char.Humanoid.WalkSpeed = 0

		--// Cancelling
		local cancelFrostBite = cancelHandle.New("FrostBite", char, anim)
		cancelFrostBite.__durationOfCheck = startup.FrostBite -- duration insert here
		if cancelFrostBite:Cancellation() then
			cancelFrostBite:Destroy()
			cancelFrostBite = nil
			return
		end
		cancelFrostBite:Destroy()
		cancelFrostBite = nil

		--// Fire Screen Shake Remote
		for _, play in ipairs (game.Players:GetPlayers()) do
			if functions.Magnitude(char.HumanoidRootPart.Position, play.Character.HumanoidRootPart.Position) < 200 then
				game.ReplicatedStorage.Remotes.Shake:FireClient(play, char.HumanoidRootPart.Position, {"flameMode", .4, nil, char})
			end	
		end

		--// Initiation
		char.Values.FrostBite.Value = true
		game.ReplicatedStorage.Signals.SprintingOff:Fire(char)
		functions.StunTog(char, true)
		local fxClone = game.ReplicatedStorage.Assets.FX.FrostBiteFX:Clone()
		fxClone.CFrame = char.HumanoidRootPart.CFrame
		fxClone.Parent = workspace
		fxClone.ParticleEmitter:Emit(500)
		wait(.4)
		fxClone:Destroy()
		for _, particle in ipairs (game.ReplicatedStorage.Assets.FX.FrostBite:GetChildren()) do
			local newParticle = particle:Clone()
			newParticle.Parent = char:FindFirstChild(newParticle.Name)
		end
		functions.StunTog(char, false)
		char.Humanoid.WalkSpeed = char.Humanoid.WalkSpeed + vals.Buffs.FrostBite.walkSpeed
		char.Values.OriginalWalkspeed.Value = char.Humanoid.WalkSpeed
		wait(20)
		char.Values.FrostBite.Value = false
		char.Humanoid.WalkSpeed = char.Humanoid.WalkSpeed - vals.Buffs.FrostBite.walkSpeed
		char.Values.OriginalWalkspeed.Value = char.Humanoid.WalkSpeed
		for _, particle in ipairs (char:GetDescendants()) do
			if particle:IsA("ParticleEmitter") then
				particle:Destroy()
			end
		end
