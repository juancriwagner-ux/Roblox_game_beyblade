--!strict
-- UITheme.lua — design tokens + a small factory to keep UI code declarative.

local UITheme = {}

UITheme.Color = {
	BG = Color3.fromRGB(16, 18, 26),
	Panel = Color3.fromRGB(26, 30, 42),
	PanelLight = Color3.fromRGB(36, 41, 56),
	Stroke = Color3.fromRGB(58, 66, 88),
	Accent = Color3.fromRGB(0, 224, 255),
	Accent2 = Color3.fromRGB(178, 92, 255),
	Bolts = Color3.fromRGB(255, 196, 0),
	Cores = Color3.fromRGB(0, 224, 255),
	Text = Color3.fromRGB(236, 240, 248),
	SubText = Color3.fromRGB(150, 158, 176),
	Good = Color3.fromRGB(86, 214, 112),
	Bad = Color3.fromRGB(255, 92, 92),
}

UITheme.Font = Enum.Font.GothamBold
UITheme.FontRegular = Enum.Font.Gotham

local function apply(inst: Instance, props: { [string]: any }?)
	if props then
		for k, v in props do
			(inst :: any)[k] = v
		end
	end
	return inst
end

function UITheme.corner(radius: number, parent: Instance): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

function UITheme.stroke(color: Color3?, thickness: number?, parent: Instance): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or UITheme.Color.Stroke
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function UITheme.gradient(c0: Color3, c1: Color3, rotation: number?, parent: Instance): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c0, c1)
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

function UITheme.frame(props: { [string]: any }?, parent: Instance?): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = UITheme.Color.Panel
	f.BorderSizePixel = 0
	apply(f, props)
	if parent then
		f.Parent = parent
	end
	return f
end

function UITheme.label(props: { [string]: any }?, parent: Instance?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = UITheme.Font
	l.TextColor3 = UITheme.Color.Text
	l.TextScaled = false
	l.TextSize = 16
	l.RichText = true
	apply(l, props)
	if parent then
		l.Parent = parent
	end
	return l
end

function UITheme.button(props: { [string]: any }?, parent: Instance?): TextButton
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = UITheme.Color.Accent
	b.BorderSizePixel = 0
	b.Font = UITheme.Font
	b.TextColor3 = UITheme.Color.BG
	b.TextSize = 16
	b.AutoButtonColor = true
	apply(b, props)
	if parent then
		b.Parent = parent
	end
	return b
end

-- A 3D blade preview rendered into a ViewportFrame.
function UITheme.viewport(props: { [string]: any }?, parent: Instance?): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundColor3 = UITheme.Color.BG
	vp.BorderSizePixel = 0
	vp.Ambient = Color3.fromRGB(140, 140, 160)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	apply(vp, props)
	if parent then
		vp.Parent = parent
	end
	return vp
end

return UITheme
