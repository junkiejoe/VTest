--!nonstrict
--< Module begin >--
local VTest  = {}

---- Types ----
export type TestUnit = {
	-- The name of the test.
	-- Must be unique.
	name: string,
	-- The asset link for the test icon.
	icon: string?,
	-- Optional description of what the test does.
	description: string?,
	Begin: () -> (),
	End: () -> ()
}

---- Const ----
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local BeginTestEvent = game:GetService("ReplicatedStorage").events.BeginTest
-- Client data --

local LocalPlayer: Player
local PlayerGui: PlayerGui

local MainScreen: ScreenGui
local TestScreen: ScreenGui

local UnitContainerGUI: ScrollingFrame
local UnitGUI: TextButton -- The default test unit widget.
-- The container for all GUI created by VTest.NewGui
local TestContainerGUI: Frame 
--> Description container
local DescriptionContainerGUI: Frame
local UnitNameGUI: TextLabel
local UnitIconGUI: ImageLabel
local UnitBeginGUI: TextButton
local UnitDescGUI: TextLabel
---- Var ----

local TestUnitList: {[string]: TestUnit} = {}
local TestUnitCount = 0
local SelectedTestUnit: TestUnit = nil

---- Functions ----

local StartUnit : () -> ()
local StopUnit  : () -> ()
local SelectUnit: (unit: TestUnit) -> ()

---- Module functions ----

-- Register a new test unit.
function VTest.AddUnit(unit: TestUnit)
	assert(unit.name, "Attempt to create unit without field \"name\".")

	if TestUnitList[unit.name] then
		error(`Attempt to redefine unit {unit.name}.`)
	end

	TestUnitList[unit.name] = unit
	TestUnitCount += 1
	
	-- Create new entry UI
	if IsClient then
		local new_gui = UnitGUI:Clone()
		new_gui.Parent = UnitContainerGUI
		new_gui.Visible = true
		
		local image: ImageLabel = (new_gui :: any).Image
		local name: TextLabel = new_gui:FindFirstChild("Name")
		if unit.icon then
			image.Image =  unit.icon
		end

		name.Text = unit.name
		
		new_gui.Activated:Connect(function()
			SelectUnit(unit)
		end)
		
		--> Entry GUI logic
		-- Change the color when the player hovers over it
		new_gui:GetPropertyChangedSignal("GuiState"):Connect(function()
			local state = new_gui.GuiState
			
			if state == Enum.GuiState.Hover then
				new_gui.BackgroundTransparency = 0.5
			else
				new_gui.BackgroundTransparency = 1
			end
		end)
		
		--> Change UI layout to center after 2 elements
		if TestUnitCount > 2 then
			local layout = UnitContainerGUI:FindFirstChildOfClass("UIGridLayout")
			local padding = UnitContainerGUI:FindFirstChildOfClass("UIPadding")
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			padding.PaddingLeft = UDim.new()
			padding.PaddingRight = UDim.new()
		end--if
	end--if
end--AddUnit

-- Get the TestUnit from it's name, or return nil if it does not exist.
function VTest.GetUnit(name: string): TestUnit?
	return TestUnitList[name]
end

-- Create a new GuiObject and add it to the TestScreen.
-- The parameter value can be any of:
-- "Frame", "ImageLabel", "TextLabel", "ImageButton", "TextButton"
function VTest.NewGui(name:
	"Frame"      |
	"ImageLabel" |
	"TextLabel"  |
	"ImageButton"|
	"TextButton" )
	assert(IsClient, "Attempt to create UI on server")

	local new_object = Instance.new(name)
	new_object.Parent = TestContainerGUI

	return new_object
end

---- Implementation ----

SelectUnit = function(unit)
	if SelectedTestUnit == nil then
		for _, gui in DescriptionContainerGUI:GetChildren() do
			if gui:IsA "GuiObject" then
				gui.Visible = true
			end
		end
	end
	
	UnitNameGUI.Text = unit.name
	UnitIconGUI.Image = unit.icon or "rbxasset://textures/ui/Settings/MenuBarIcons/HelpTab@2x.png"
	UnitDescGUI.Text = unit.description or "..."
	SelectedTestUnit = unit
end

StartUnit = function()

	if IsClient then
		-- Change screens
		MainScreen.Enabled = false
		TestScreen.Enabled = true
		-- Request the server to start the test if it exists server side.
		BeginTestEvent:FireServer(SelectedTestUnit.name)
	end

	if SelectedTestUnit then
		SelectedTestUnit.Begin()
	end
end

StopUnit = function()

	if IsClient then
		-- Hide all GUI
		for _, gui in ipairs(TestContainerGUI:GetChildren()) do
			if not gui:IsA "GuiObject" then
				-- Wtf???
				continue
			end

			gui:Destroy()
		end
		
		TestScreen.Enabled = false
		MainScreen.Enabled = true
	end--if

	SelectedTestUnit.End()
end
---- Misc ----

--> Set up GUI
if RunService:IsClient() then

	LocalPlayer = Players.LocalPlayer
	PlayerGui =  (LocalPlayer :: Player).PlayerGui

	MainScreen = PlayerGui:WaitForChild("MainScreen") :: ScreenGui
	TestScreen = PlayerGui:WaitForChild("TestScreen") :: ScreenGui
	
	local container = (MainScreen :: any).Container
	
	TestContainerGUI = TestScreen:FindFirstChild "Container" :: Frame
	UnitContainerGUI = container.UnitContainer
	UnitGUI = UnitContainerGUI:FindFirstChild "Entry" :: TextButton
	

	DescriptionContainerGUI = container.UnitDescription
	local ui = DescriptionContainerGUI:FindFirstChild "UI"
	
	UnitNameGUI = DescriptionContainerGUI:FindFirstChild "Name" :: TextLabel
	UnitIconGUI = ui.Icon
	UnitBeginGUI = ui.StartButton
	UnitDescGUI = DescriptionContainerGUI:FindFirstChild "Description" :: TextLabel
	
	-- Default visibility
	MainScreen.Enabled = true
	TestScreen.Enabled = false	
	UnitGUI.Visible = false
	
	-- Hide description elements until a test is selected
	for _, gui in DescriptionContainerGUI:GetChildren() do
		if gui:IsA "GuiObject" then
			gui.Visible = false
		end
	end
	-- Button logic
	UnitBeginGUI.Activated:Connect(function()
		StartUnit()
	end);
	
	(TestScreen:: any).StopButton.Activated:Connect(function()
		StopUnit()
	end)

	--> Hide default UI elements
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
else
	-- Logic for starting a test on the server
	BeginTestEvent.OnServerEvent:Connect(function(player: Player, name: string)
		local unit = TestUnitList[name]
		
		if unit then
			SelectedTestUnit = unit
			StartUnit()
		end
	end)
end--if RunService:IsClient()

--< Module end >--
return VTest
