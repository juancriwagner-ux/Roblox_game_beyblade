--!strict
-- TutorialController.lua — first-time user experience. Shows a short guided
-- sequence the first time a player joins, then grants an onboarding reward and
-- flags the profile so it never shows again.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)

local UITheme = require(script.Parent.UITheme)
local ClientState = require(script.Parent.ClientState)

local TutorialController = {}

local STEPS = {
	{ Icon = "🌀", Title = "¡Bienvenido, Blader!", Body = "Colecciona Beyblades, combate y sube de liga. Te muestro lo básico en 5 pasos." },
	{ Icon = "✨", Title = "Recolecta Beyblades", Body = "En el jardín aparecen Beyblades cada cierto tiempo. Acércate y mantén pulsado para recogerlos. ¡Los raros brillan más!" },
	{ Icon = "⚔️", Title = "Combate y gana trofeos", Body = "Pulsa el botón BATALLAR para enfrentarte a otros Bladers. El resultado depende de las habilidades de tu Beyblade. Ganar te sube de liga." },
	{ Icon = "🎒", Title = "Mejora tu arsenal", Body = "En Colección equipas y asciendes Beyblades (fusiona 3 iguales). En la Tienda y los Cofres consigues skins y trompos nuevos." },
	{ Icon = "🎯", Title = "Vuelve cada día", Body = "Completa Misiones, reclama tu Recompensa Diaria y canjea Códigos en Extras. ¡Toma tu regalo de bienvenida!" },
}

local started = false

local function showStep(gui: ScreenGui, index: number)
	local step = STEPS[index]
	local isLast = index == #STEPS

	local card = UITheme.frame({
		Name = "TutorialCard", Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 1, -40),
		AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = UITheme.Color.Panel, ZIndex = 60,
	}, gui)
	UITheme.corner(16, card)
	UITheme.stroke(UITheme.Color.Accent, 2.5, card)
	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 460, 0, 150),
	}):Play()

	UITheme.label({ Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 16, 0, 16), Text = step.Icon, TextSize = 40, ZIndex = 61 }, card)
	UITheme.label({ Size = UDim2.new(1, -90, 0, 26), Position = UDim2.new(0, 84, 0, 16), Text = step.Title, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61 }, card)
	UITheme.label({
		Size = UDim2.new(1, -100, 0, 56), Position = UDim2.new(0, 84, 0, 44), Text = step.Body,
		TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 61,
	}, card)
	UITheme.label({ Size = UDim2.new(0, 60, 0, 16), Position = UDim2.new(1, -72, 0, 12), Text = ("%d / %d"):format(index, #STEPS), TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 12, ZIndex = 61 }, card)

	local next = UITheme.button({ Size = UDim2.new(0, 150, 0, 38), Position = UDim2.new(1, -166, 1, -48), Text = isLast and "🎁 ¡Empezar!" or "Siguiente ▶", TextSize = 15, ZIndex = 61 }, card)
	UITheme.corner(10, next)

	if not isLast then
		local skip = UITheme.button({ Size = UDim2.new(0, 80, 0, 38), Position = UDim2.new(0, 16, 1, -48), Text = "Saltar", TextSize = 13, BackgroundColor3 = UITheme.Color.PanelLight, TextColor3 = UITheme.Color.SubText, ZIndex = 61 }, card)
		UITheme.corner(10, skip)
		skip.MouseButton1Click:Connect(function()
			card:Destroy()
			showStep(gui, #STEPS) -- jump to the final reward step
		end)
	end

	next.MouseButton1Click:Connect(function()
		card:Destroy()
		if isLast then
			(Net.get("CompleteTutorial") :: RemoteFunction):InvokeServer()
		else
			showStep(gui, index + 1)
		end
	end)
end

function TutorialController.start(gui: ScreenGui)
	ClientState.onChanged(function(profile)
		if started or not profile then
			return
		end
		started = true
		if not profile.TutorialDone then
			task.wait(0.6)
			showStep(gui, 1)
		end
	end)
end

return TutorialController
