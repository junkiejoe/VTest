local VTest = require(game:GetService("ReplicatedStorage").include.Vtest)

VTest.AddUnit {
	name = "Hello world!",
	icon = "rbxasset://textures/loading/robloxlogo.png",
	description = "I'm going to say hello to the world.",
	
	Begin = function()
		print "HELLO WORLD MY NAME IS Client"
		local gui: TextLabel = VTest.NewGui "TextLabel"
		
		gui.Text = "Hello world!"
		
		gui.AnchorPoint = Vector2.new(0.5, 0.5)
		gui.Position = UDim2.fromScale(0.5, 0.5)
		gui.Size = UDim2.fromScale(0.25, 0.25)
		gui.TextScaled = true

	end,

	-- GUI created by VTest.NewGui gets cleaned up upon ending tests.
	End = function()
		print "\"GOODBYE WORLD\" - Client"
	end
}