-- ============ СТРОИТЕЛЬ ПОСТРОЕК v19.3 ============
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer or Players:GetPlayers()[1]

if not LocalPlayer then warn("❌ LocalPlayer не найден"); return end

local MATERIALS = {
    "Default", "Glass", "Diamond Plate", "Fabric", "Grass", "Ice",
    "Sand", "Wood", "Wooden Planks", "Foil", "Metal", "Brick",
    "Concrete", "Marble", "Granite", "Slate", "Corroded Metal", "Force Field"
}

local BUILDING_TYPES = {
    "🏠 Дом", "🗼 Вышка", "🏰 Замок", "🏛️ Храм",
    "🗽 Маяк", "🏢 Небоскрёб", "⛪ Церковь", "🏚️ Хижина"
}

-- BitBuffer
local BitBuffer
do
    local base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789#$"
    local base64lookup = {}
    for i = 1, 64 do base64lookup[base64chars:sub(i, i)] = i - 1 end
    local pow2 = {}
    for j = 0, 64 do pow2[j] = 2 ^ j end
    local B = {}; B.__index = B
    function B.new() return setmetatable({bits = {}, ptr = 0}, B) end
    function B:WriteUnsigned(w, v)
        for i = 1, w do
            self.ptr = self.ptr + 1
            self.bits[self.ptr] = v % 2
            v = math.floor(v / 2)
        end
    end
    function B:ToBase64()
        local c, s = 0, 0; local r = {}
        for i = 1, math.ceil(#self.bits / 6) * 6 do
            s = s + pow2[c] * (self.bits[i] or 0); c = c + 1
            if c >= 6 then
                table.insert(r, base64chars:sub(s + 1, s + 1)); c, s = 0, 0
            end
        end
        return table.concat(r)
    end
    BitBuffer = B
end

local GrandeurBloc = 1
local PositionOrigin = Vector3.new(0, 0, 0)

pcall(function()
    local mf = ReplicatedStorage:FindFirstChild("Modules")
    if mf then
        local bm = mf:FindFirstChild("BlocMap")
        if bm then
            local BM = require(bm)
            if BM and BM.GrandeurBloc then GrandeurBloc = BM.GrandeurBloc end
        end
    end
    local po = Workspace:FindFirstChild("PosOrigin")
    if po then PositionOrigin = po.Position end
end)

local function MathRound(x) return math.floor(x + 0.5) end
local function Position2CodePosition(x, y, z)
    local b = BitBuffer.new()
    b:WriteUnsigned(8, x); b:WriteUnsigned(8, y); b:WriteUnsigned(8, z)
    return b:ToBase64()
end
local function gridToWorld(g) return PositionOrigin + g * GrandeurBloc end

local function placeBlock(x, y, z, color, material)
    task.spawn(function()
        local ev = ReplicatedStorage:FindFirstChild("Events")
        if not ev then return end
        local pb = ev:FindFirstChild("PlacerBloc")
        if not pb then return end
        local posCode = Position2CodePosition(x, y, z)
        local posList = string.format("%d_%d_%d", x, y, z)
        local args = {
            [1]="43",[2]=posCode,[3]=nil,[4]=nil,[5]=posList,[6]="A",
            [8]=color or Color3.new(1,1,1),
            [9]=(material and material ~= "") and material or "Default"
        }
        pcall(function() pb:InvokeServer(unpack(args)) end)
    end)
end

-- === ПОСТРОЙКИ ===
local function buildHouse(bx,by,bz,w,d,h,wall,floor,roof,glass,door)
    print("🏠 Дом...")
    for x=-1,w do for z=-1,d do placeBlock(bx+x,by-1,bz+z,Color3.fromRGB(100,100,100),"Concrete") end end
    local dX = math.floor(w/2)
    for y=0,h-1 do for x=0,w-1 do for z=0,d-1 do
        if x==0 or x==w-1 or z==0 or z==d-1 then
            if z==0 and x==dX and y<2 then placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(150,100,50),door)
            elseif (z==0 or z==d-1) and y>=1 and y<=2 and (x==dX-2 or x==dX+2 or x==1 or x==w-2) then
                placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(100,200,255),glass)
            else placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(200,180,160),wall) end
        end
    end end end
    for x=0,w-1 do for z=0,d-1 do
        placeBlock(bx+x,by,bz+z,Color3.fromRGB(180,150,100),floor)
        placeBlock(bx+x,by+h,bz+z,Color3.fromRGB(200,200,200),floor)
        placeBlock(bx+x,by+h+1,bz+z,Color3.fromRGB(150,80,50),roof)
    end end
    print("✅ Дом готов!")
end

local function buildTower(bx,by,bz,w,d,h,wall,glass)
    print("🗼 Вышка...")
    for x=-1,w do for z=-1,d do placeBlock(bx+x,by-1,bz+z,Color3.fromRGB(100,100,100),"Concrete") end end
    for y=0,h-1 do for x=0,w-1 do for z=0,d-1 do
        if x==0 or x==w-1 or z==0 or z==d-1 then
            if y%2==0 then placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(100,200,255),glass)
            else placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(200,200,200),wall) end
        end
    end end end
    for x=-1,w do for z=-1,d do placeBlock(bx+x,by+h,bz+z,Color3.fromRGB(150,100,50),"Slate") end end
    for y=1,3 do placeBlock(bx+math.floor(w/2),by+h+y,bz+math.floor(d/2),Color3.fromRGB(255,200,50),"Metal") end
    print("✅ Вышка готова!")
end

local function buildCastle(bx,by,bz,w,d,h,wall,roof)
    print("🏰 Замок...")
    for x=-2,w+1 do for z=-2,d+1 do placeBlock(bx+x,by-1,bz+z,Color3.fromRGB(80,80,80),"Concrete") end end
    for y=0,h-1 do for x=0,w-1 do for z=0,d-1 do
        if x==0 or x==w-1 or z==0 or z==d-1 then placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(180,160,140),wall) end
    end end end
    for x=0,w-1 do for z=0,d-1 do
        if (x==0 or x==w-1 or z==0 or z==d-1) and x%2==0 and z%2==0 then
            placeBlock(bx+x,by+h,bz+z,Color3.fromRGB(180,160,140),wall)
        end
    end end
    for _,t in ipairs({{0,0},{w-1,0},{0,d-1},{w-1,d-1}}) do
        local tx,tz=t[1],t[2]
        for y=0,h+1 do for x=-1,1 do for z=-1,1 do
            if math.abs(x)==1 or math.abs(z)==1 then
                placeBlock(bx+tx+x,by+y,bz+tz+z,Color3.fromRGB(180,160,140),wall)
            end
        end end end
        for x=-1,1 do for z=-1,1 do placeBlock(bx+tx+x,by+h+2,bz+tz+z,Color3.fromRGB(150,80,50),roof) end end
    end
    print("✅ Замок готов!")
end

local function buildTemple(bx,by,bz,w,d,h,wall,roof)
    print("🏛️ Храм...")
    for x=-2,w+1 do for z=-2,d+1 do placeBlock(bx+x,by-1,bz+z,Color3.fromRGB(150,150,150),"Marble") end end
    for y=0,h-1 do for x=0,w-1 do for z=0,d-1 do
        if x==0 or x==w-1 or z==0 or z==d-1 then placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(220,210,190),wall) end
    end end end
    for x=0,w-1 do if x%2==0 then
        for y=0,h do
            placeBlock(bx+x,by+y,bz-1,Color3.fromRGB(200,200,200),"Marble")
            placeBlock(bx+x,by+y,bz+d,Color3.fromRGB(200,200,200),"Marble")
        end
    end end
    for y=1,3 do for x=y-1,w-y do for z=y-1,d-y do
        if x==y-1 or x==w-y or z==y-1 or z==d-y then
            placeBlock(bx+x,by+h+y-1,bz+z,Color3.fromRGB(200,180,160),roof)
        end
    end end end
    print("✅ Храм готов!")
end

local function buildLighthouse(bx,by,bz,w,d,h,wall,glass)
    print("🗽 Маяк...")
    for x=-2,w+1 do for z=-2,d+1 do placeBlock(bx+x,by-1,bz+z,Color3.fromRGB(100,100,100),"Concrete") end end
    for y=0,h-1 do
        local off = math.floor(y/3)
        for x=off,w-1-off do for z=off,d-1-off do
            if x==off or x==w-1-off or z==off or z==d-1-off then
                if y>=h-2 then placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(100,200,255),glass)
                else placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(200,100,50),wall) end
            end
        end end
    end
    for x=-1,1 do for z=-1,1 do placeBlock(bx+math.floor(w/2)+x,by+h,bz+math.floor(d/2)+z,Color3.fromRGB(255,255,100),"Glass") end end
    print("✅ Маяк готов!")
end

local function buildSkyscraper(bx,by,bz,w,d,h,wall,glass)
    print("🏢 Небоскрёб...")
    for x=-2,w+1 do for z=-2,d+1 do placeBlock(bx+x,by-1,bz+z,Color3.fromRGB(80,80,80),"Concrete") end end
    for y=0,h-1 do for x=0,w-1 do for z=0,d-1 do
        if x==0 or x==w-1 or z==0 or z==d-1 then
            if y%2==0 then placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(100,200,255),glass)
            else placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(150,150,170),wall) end
        end
    end end end
    for y=1,4 do placeBlock(bx+math.floor(w/2),by+h+y,bz+math.floor(d/2),Color3.fromRGB(200,50,50),"Metal") end
    print("✅ Небоскрёб готов!")
end

local function buildChurch(bx,by,bz,w,d,h,wall,roof,glass)
    print("⛪ Церковь...")
    for x=-2,w+1 do for z=-2,d+1 do placeBlock(bx+x,by-1,bz+z,Color3.fromRGB(100,100,100),"Concrete") end end
    for y=0,h-1 do for x=0,w-1 do for z=0,d-1 do
        if x==0 or x==w-1 or z==0 or z==d-1 then
            if y==1 and (x==math.floor(w/2) or z==math.floor(d/2)) then
                placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(100,200,255),glass)
            else placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(220,210,200),wall) end
        end
    end end end
    for y=1,4 do for x=y-1,w-y do for z=y-1,d-y do
        if x==y-1 or x==w-y or z==y-1 or z==d-y then
            placeBlock(bx+x,by+h+y-1,bz+z,Color3.fromRGB(150,100,60),roof)
        end
    end end end
    print("✅ Церковь готова!")
end

local function buildHut(bx,by,bz,w,d,h,wall,roof)
    print("🏚️ Хижина...")
    for y=0,h-1 do for x=0,w-1 do for z=0,d-1 do
        if x==0 or x==w-1 or z==0 or z==d-1 then
            placeBlock(bx+x,by+y,bz+z,Color3.fromRGB(160,130,100),wall)
        end
    end end end
    for y=1,3 do for x=y-1,w-y do for z=y-1,d-y do
        if x==y-1 or x==w-y or z==y-1 or z==d-y then
            placeBlock(bx+x,by+h+y-1,bz+z,Color3.fromRGB(180,150,80),roof)
        end
    end end end
    print("✅ Хижина готова!")
end

local function buildBuilding(t,bx,by,bz,w,d,h,wall,floor,roof,glass,door)
    if t=="🏠 Дом" then buildHouse(bx,by,bz,w,d,h,wall,floor,roof,glass,door)
    elseif t=="🗼 Вышка" then buildTower(bx,by,bz,w,d,h,wall,glass)
    elseif t=="🏰 Замок" then buildCastle(bx,by,bz,w,d,h,wall,roof)
    elseif t=="🏛️ Храм" then buildTemple(bx,by,bz,w,d,h,wall,roof)
    elseif t=="🗽 Маяк" then buildLighthouse(bx,by,bz,w,d,h,wall,glass)
    elseif t=="🏢 Небоскрёб" then buildSkyscraper(bx,by,bz,w,d,h,wall,glass)
    elseif t=="⛪ Церковь" then buildChurch(bx,by,bz,w,d,h,wall,roof,glass)
    elseif t=="🏚️ Хижина" then buildHut(bx,by,bz,w,d,h,wall,roof) end
end

local builder = {
    active=false, previewParts={}, rotation=0, baseY=0,
    width=7, depth=7, height=4,
    wallMat="Brick", floorMat="Wood", roofMat="Slate",
    glassMat="Glass", doorMat="Wood",
    buildingType="🏠 Дом", previewInitialized=false
}

local function createPreview(color,pos)
    local p = Instance.new("Part")
    p.Size = Vector3.new(GrandeurBloc*0.95,GrandeurBloc*0.95,GrandeurBloc*0.95)
    p.Anchored=true; p.CanCollide=false; p.Transparency=0.5
    p.Color=color; p.Position=pos; p.Parent=Workspace
    return p
end

local function clearPreview()
    for _,p in ipairs(builder.previewParts) do p:Destroy() end
    builder.previewParts = {}; builder.previewInitialized = false
end

local function updatePreview(rot, baseGrid, baseY)
    if not builder.previewInitialized then
        local c = (builder.width+4)*(builder.depth+4)*(builder.height+6)
        for _,p in ipairs(builder.previewParts) do p:Destroy() end
        builder.previewParts = {}
        for i=1,c do table.insert(builder.previewParts, createPreview(Color3.new(1,1,1),Vector3.new(0,-100,0))) end
        builder.previewInitialized = true
    end
    local bX,bZ = baseGrid.X, baseGrid.Z
    local i = 1
    for x=-2,builder.width+1 do
        for z=-2,builder.depth+1 do
            for y=-1,builder.height+5 do
                local p = builder.previewParts[i]
                if p then
                    local wx,wz = bX+x, bZ+z
                    if rot==90 then wx,wz = bX-z, bZ+x
                    elseif rot==180 then wx,wz = bX-x, bZ-z
                    elseif rot==270 then wx,wz = bX+z, bZ-x end
                    p.Position = gridToWorld(Vector3.new(wx, baseY+y, wz))
                    if y==-1 then p.Color = Color3.fromRGB(80,80,80)
                    elseif y>builder.height then p.Color = Color3.fromRGB(200,100,50)
                    elseif y==builder.height then p.Color = Color3.fromRGB(200,200,200)
                    elseif y==0 then p.Color = Color3.fromRGB(150,100,50)
                    elseif x==0 or x==builder.width-1 or z==0 or z==builder.depth-1 then p.Color = Color3.fromRGB(200,180,160)
                    else p.Color = Color3.fromRGB(100,100,100) end
                    p.Transparency = 0.5
                end
                i = i + 1
            end
        end
    end
end

local function getMouseGrid()
    local mouse = LocalPlayer:GetMouse()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local res = Workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction*1000, params)
    if res then
        local hp = res.Position
        return Vector3.new(MathRound((hp.X-PositionOrigin.X)/GrandeurBloc),0,MathRound((hp.Z-PositionOrigin.Z)/GrandeurBloc))
    end
    local char = LocalPlayer.Character
    if char and char.PrimaryPart then
        local look = char.PrimaryPart.CFrame.LookVector
        local pos = char.PrimaryPart.Position + look*5
        return Vector3.new(MathRound((pos.X-PositionOrigin.X)/GrandeurBloc),0,MathRound((pos.Z-PositionOrigin.Z)/GrandeurBloc))
    end
    return Vector3.new(0,0,0)
end

local function onMouseMove()
    if builder.active then updatePreview(builder.rotation, getMouseGrid(), builder.baseY) end
end

local function onKeyDown(input)
    if not builder.active then return end
    if input.KeyCode == Enum.KeyCode.R then
        builder.rotation = (builder.rotation+90)%360
        print("🔄 "..builder.rotation.."°"); onMouseMove()
    elseif input.KeyCode == Enum.KeyCode.T then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
            builder.baseY = math.max(0, builder.baseY-1); print("⬆️ "..builder.baseY)
        end
        onMouseMove()
    elseif input.KeyCode == Enum.KeyCode.Escape then
        builder.active = false; clearPreview(); print("❌ Отменено")
    end
end

local function onMouseWheel(input)
    if not builder.active then return end
    builder.rotation = (builder.rotation + (input.Position.Z>0 and 90 or -90))%360
    if builder.rotation<0 then builder.rotation = builder.rotation+360 end
    print("🔄 "..builder.rotation.."°"); onMouseMove()
end

local function onMouseClick()
    if not builder.active then return end
    builder.active = false; clearPreview()
    local pos = getMouseGrid()
    buildBuilding(builder.buildingType, pos.X, builder.baseY, pos.Z,
        builder.width, builder.depth, builder.height,
        builder.wallMat, builder.floorMat, builder.roofMat, builder.glassMat, builder.doorMat)
end

-- === GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "BuilderGUI"; gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0,400,0,560)
main.Position = UDim2.new(0.5,-200,0.1,0)
main.BackgroundColor3 = Color3.fromRGB(20,20,25)
main.BorderSizePixel = 0; main.Parent = gui

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,28)
header.BackgroundColor3 = Color3.fromRGB(30,30,35)
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-35,1,0); title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1; title.Text = "🏗️ СТРОИТЕЛЬ ПОСТРОЕК"
title.TextColor3 = Color3.fromRGB(255,200,50); title.Font = Enum.Font.Code
title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,28,0,28); closeBtn.Position = UDim2.new(1,-28,0,0)
closeBtn.BackgroundColor3 = Color3.fromRGB(30,30,35); closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,100,100); closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14; closeBtn.BorderSizePixel = 0; closeBtn.Parent = header
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local dS, fS
header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dS = inp.Position; fS = main.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dS = nil end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dS and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dS
        main.Position = UDim2.new(fS.X.Scale, fS.X.Offset+delta.X, fS.Y.Scale, fS.Y.Offset+delta.Y)
    end
end)

local function makeDropdown(parent, pos, options, default, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0,170,0,24); f.Position = pos
    f.BackgroundColor3 = Color3.fromRGB(20,20,25)
    f.BorderSizePixel = 1; f.BorderColor3 = Color3.fromRGB(50,50,60)
    f.ClipsDescendants = false; f.ZIndex = 10; f.Parent = parent
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,1,0); b.Text = default
    b.TextColor3 = Color3.new(1,1,1); b.BackgroundColor3 = Color3.fromRGB(20,20,25)
    b.BorderSizePixel = 0; b.Font = Enum.Font.Code; b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left; b.ZIndex = 10; b.Parent = f
    local arr = Instance.new("TextLabel")
    arr.Size = UDim2.new(0,20,1,0); arr.Position = UDim2.new(1,-20,0,0)
    arr.Text = "▼"; arr.TextColor3 = Color3.new(1,1,1)
    arr.BackgroundTransparency = 1; arr.Font = Enum.Font.Code
    arr.TextSize = 11; arr.ZIndex = 10; arr.Parent = f
    local lf = Instance.new("Frame")
    lf.Size = UDim2.new(1,0,0,math.min(#options,8)*22+4)
    lf.Position = UDim2.new(0,0,0,24)
    lf.BackgroundColor3 = Color3.fromRGB(30,30,40)
    lf.BorderSizePixel = 1; lf.BorderColor3 = Color3.fromRGB(50,50,60)
    lf.Visible = false; lf.ZIndex = 50; lf.Parent = f
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1,-2,1,-2); sf.Position = UDim2.new(0,1,0,1)
    sf.BackgroundTransparency = 1
    sf.CanvasSize = UDim2.new(0,0,0,#options*22)
    sf.ScrollBarThickness = 4; sf.BorderSizePixel = 0
    sf.ZIndex = 50; sf.Parent = lf
    for i,opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1,0,0,22)
        ob.Position = UDim2.new(0,0,0,(i-1)*22)
        ob.Text = opt; ob.TextColor3 = Color3.new(1,1,1)
        ob.BackgroundColor3 = (i%2==0) and Color3.fromRGB(40,40,50) or Color3.fromRGB(30,30,40)
        ob.BorderSizePixel = 0; ob.Font = Enum.Font.Code; ob.TextSize = 11
        ob.TextXAlignment = Enum.TextXAlignment.Left; ob.ZIndex = 50; ob.Parent = sf
        ob.MouseButton1Click:Connect(function()
            b.Text = opt; lf.Visible = false
            if cb then cb(opt) end
        end)
    end
    b.MouseButton1Click:Connect(function() lf.Visible = not lf.Visible end)
    return f
end

local y = 40
local sizeLabels = {"📐 Ширина:", "📏 Глубина:", "📐 Высота:"}
local sizeBoxes = {}
for i,label in ipairs(sizeLabels) do
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0,80,0,20)
    lbl.Position = UDim2.new(0,10,0,y+(i-1)*28)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.Code
    lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = main
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0,60,0,20)
    box.Position = UDim2.new(0,100,0,y+(i-1)*28)
    box.Text = (i==3) and "4" or "7"
    box.BackgroundColor3 = Color3.fromRGB(10,10,15)
    box.TextColor3 = Color3.new(1,1,1); box.Font = Enum.Font.Code
    box.TextSize = 12; box.BorderSizePixel = 0; box.Parent = main
    sizeBoxes[i] = box
end

local typeLbl = Instance.new("TextLabel")
typeLbl.Size = UDim2.new(0,80,0,20)
typeLbl.Position = UDim2.new(0,10,0,y+3*28+5)
typeLbl.BackgroundTransparency = 1; typeLbl.Text = "🏗️ Тип:"
typeLbl.TextColor3 = Color3.new(1,1,1); typeLbl.Font = Enum.Font.Code
typeLbl.TextSize = 12; typeLbl.TextXAlignment = Enum.TextXAlignment.Left
typeLbl.Parent = main

makeDropdown(main, UDim2.new(0,100,0,y+3*28+5), BUILDING_TYPES, "🏠 Дом", function(s)
    builder.buildingType = s
    print("🏗️ Тип: "..s)
end)

local matY = y+3*28+35
local matConfigs = {
    {"🧱 Стены:", "Brick", "wallMat"},
    {"🪵 Пол:", "Wood", "floorMat"},
    {"🏠 Крыша:", "Slate", "roofMat"},
    {"🪟 Стекло:", "Glass", "glassMat"},
    {"🚪 Дверь:", "Wood", "doorMat"}
}
for i,cfg in ipairs(matConfigs) do
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0,70,0,20)
    lbl.Position = UDim2.new(0,10,0,matY+(i-1)*28)
    lbl.BackgroundTransparency = 1; lbl.Text = cfg[1]
    lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.Code
    lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = main
    makeDropdown(main, UDim2.new(0,85,0,matY+(i-1)*28), MATERIALS, cfg[2], function(s)
        builder[cfg[3]] = s
        print(cfg[1].." "..s)
    end)
end

local buildBtnY = matY + 5*28 + 10
local buildBtn = Instance.new("TextButton")
buildBtn.Size = UDim2.new(0,170,0,32)
buildBtn.Position = UDim2.new(0,10,0,buildBtnY)
buildBtn.Text = "🏗️ Построить"
buildBtn.BackgroundColor3 = Color3.fromRGB(200,100,0)
buildBtn.TextColor3 = Color3.new(1,1,1); buildBtn.Font = Enum.Font.Code
buildBtn.TextSize = 13; buildBtn.BorderSizePixel = 0; buildBtn.Parent = main

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0,90,0,32)
cancelBtn.Position = UDim2.new(0,190,0,buildBtnY)
cancelBtn.Text = "❌ Отмена"
cancelBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
cancelBtn.TextColor3 = Color3.new(1,1,1); cancelBtn.Font = Enum.Font.Code
cancelBtn.TextSize = 13; cancelBtn.BorderSizePixel = 0; cancelBtn.Parent = main

cancelBtn.MouseButton1Click:Connect(function()
    builder.active = false; clearPreview(); print("❌ Отменено")
end)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1,-20,0,50)
hint.Position = UDim2.new(0,10,0,buildBtnY+40)
hint.BackgroundTransparency = 1
hint.Text = "🔄 R = поворот | Колесо = поворот\n⬆️ Shift+T = высота | Esc/ПКМ = отмена"
hint.TextColor3 = Color3.fromRGB(150,150,150); hint.Font = Enum.Font.Code
hint.TextSize = 10; hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = main

buildBtn.MouseButton1Click:Connect(function()
    local w = tonumber(sizeBoxes[1].Text) or 7
    local d = tonumber(sizeBoxes[2].Text) or 7
    local h = tonumber(sizeBoxes[3].Text) or 4
    if w<2 or d<2 or h<2 then
        print("❌ Минимальный размер: 2x2x2"); return
    end
    builder.width=w; builder.depth=d; builder.height=h
    builder.rotation=0; builder.baseY=0
    builder.active=true; builder.previewInitialized=false
    clearPreview(); onMouseMove()
    print(string.format("✅ %s %dx%dx%d готов!", builder.buildingType, w, d, h))
    print("🖱️
