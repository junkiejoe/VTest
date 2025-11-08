local VTest = require(game:GetService("ReplicatedStorage").include.Vtest)
VTest.AddUnit {
	name = "Hello world!",
	Begin = function()
		print "HELLO WORLD MY NAME IS SERVER"
	end,
	
	End = function()
		print "\"GOODBYE WORLD\" - SERVER"
	end
}