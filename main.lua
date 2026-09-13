-- ============ СТРОИТЕЛЬ v26.1 — АРТЫ + 3D-СХЕМА (фикс стёкол) ============

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer or Players:GetPlayers()[1]
if not LocalPlayer then warn("LocalPlayer не найден"); return end

local BitBuffer
do
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789#$"
    local lookup = {}
    for i = 1, 64 do lookup[b64:sub(i, i)] = i - 1 end
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
                table.insert(r, b64:sub(s + 1, s + 1)); c, s = 0, 0
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
local function Position2Code(x, y, z)
    local b = BitBuffer.new()
    b:WriteUnsigned(8, x); b:WriteUnsigned(8, y); b:WriteUnsigned(8, z)
    return b:ToBase64()
end
local function gridToWorld(g) return PositionOrigin + g * GrandeurBloc end

local function placeBlock(x, y, z, color, material, blockId)
    task.spawn(function()
        local ev = ReplicatedStorage:FindFirstChild("Events")
        if not ev then return end
        local pb = ev:FindFirstChild("PlacerBloc")
        if not pb then return end
        local args = {
            [1] = tostring(blockId or 43),
            [2] = Position2Code(x, y, z),
            [3] = nil, [4] = nil,
            [5] = string.format("%d_%d_%d", x, y, z),
            [6] = "A",
            [8] = color or Color3.new(1,1,1),
            [9] = (material and material ~= "") and material or "Default"
        }
        pcall(function() pb:InvokeServer(unpack(args)) end)
    end)
end

local function parseHex(hex)
    local c = hex:gsub("#", "")
    if #c == 6 then
        local r = tonumber(c:sub(1,2), 16)
        local g = tonumber(c:sub(3,4), 16)
        local b = tonumber(c:sub(5,6), 16)
        if r and g and b then return Color3.fromRGB(r, g, b) end
    end
    return nil
end

-- ============ АЛИАСЫ ============
local BLOCK_ALIASES = {
    -- Строительные
    ["block"] = 43, ["brick"] = 43, ["stone"] = 43, ["wood"] = 43,
    ["stair"] = 44, ["stair_inner"] = 49, ["stair_outer"] = 50, ["stair_tri"] = 132,
    ["ladder"] = 45,
    ["slab"] = 48, ["plate"] = 53,
    ["empty"] = 79, ["reinforced"] = 143, ["clay"] = 144,
    ["junction"] = 153, ["checkered"] = 174,
    ["obsidian"] = 139,
    -- Двери и окна
    ["door"] = 75, ["door_el"] = 76, ["trapdoor"] = 127, ["trapdoor_el"] = 128,
    ["pane"] = 82, ["corner_pane"] = 81, ["glass"] = 82,
    -- Мебель
    ["chair"] = 71, ["chair_stair"] = 154, ["chair_solid"] = 155, ["chair_slab"] = 156,
    -- Столбы
    ["pole"] = 108, ["pole3"] = 110, ["pole4"] = 86, ["pole5"] = 87, ["pole6"] = 88,
    ["pole4b"] = 105, ["corner_pole"] = 107, ["tpole"] = 109,
    -- Балки
    ["beam2"] = 188, ["beam3"] = 189, ["beam4"] = 96, ["beam5"] = 190,
    ["beam6"] = 191, ["beam7"] = 97, ["beam8"] = 192,
    -- Свет
    ["torch"] = 46, ["lamp"] = 33, ["light"] = 12, ["neon"] = 32,
    ["rgb_light"] = 34, ["led"] = 61, ["spotlight"] = 187,
    -- Знаки и кнопки
    ["sign"] = 22, ["sign12"] = 175, ["text_panel"] = 73,
    ["lever"] = 23, ["button"] = 21, ["button_toggle"] = 24, ["button_instant"] = 25,
    ["plate_btn"] = 120, ["pressure"] = 118,
    -- Спец
    ["tnt"] = 78, ["nuclear"] = 125, ["cake"] = 178,
    ["piston"] = 54, ["sticky_piston"] = 77,
    ["spawn"] = 113, ["checkpoint"] = 185, ["barrier"] = 30,
}

-- ============ ПАРСЕР ЯЧЕЙКИ (с фиксом стёкол) ============
local function parseCell(str)
    if str == "." or str == "" then return nil, nil, nil end
    local material, hex, blockId

    local parts = {}
    for p in str:gmatch("[^#]+") do
        table.insert(parts, p)
    end

    local firstName = parts[1] or ""
    local nameL = firstName:lower()

    if #parts >= 2 then
        hex = "#" .. parts[2]
        if BLOCK_ALIASES[nameL] then
            blockId = BLOCK_ALIASES[nameL]
            material = "Default"
        else
            local n = tonumber(firstName)
            if n then
                blockId = n
                material = "Default"
            else
                material = firstName
            end
        end
    elseif #parts == 1 then
        if str:sub(1,1) == "#" then
            hex = str
        else
            if BLOCK_ALIASES[nameL] then
                blockId = BLOCK_ALIASES[nameL]
                material = "Default"
            else
                local n = tonumber(firstName)
                if n then
                    blockId = n
                    material = "Default"
                else
                    material = firstName
                end
            end
        end
    end

    -- Считаем цвет СРАЗУ
    local color = hex and parseHex(hex) or nil

    -- 🔧 ФИКС СТЁКОЛ: pane (82) и corner_pane (81) → обычный блок 43 с материалом Glass
    if blockId == 82 or blockId == 81 then
        blockId = 43
        material = "Glass"
        if not color then
            color = Color3.fromRGB(150, 220, 255)
        end
    end

    return material, color, blockId
end

-- ============ ПАРСЕР СХЕМЫ ============
local function parseSchema(text)
    local layers = {}
    local currentLayer = {}
    local currentRow = {}

    for line in (text .. "\n"):gmatch("[^\n]*\n") do
        line = line:gsub("\n", "")
        if line:match("^%s*$") then
            if #currentRow > 0 then
                table.insert(currentLayer, currentRow)
                currentRow = {}
            end
            if #currentLayer > 0 then
                table.insert(layers, currentLayer)
                currentLayer = {}
            end
        else
            for cell in line:gmatch("[^%s,]+") do
                table.insert(currentRow, cell)
            end
            if #currentRow > 0 then
                table.insert(currentLayer, currentRow)
                currentRow = {}
            end
        end
    end
    if #currentRow > 0 then table.insert(currentLayer, currentRow) end
    if #currentLayer > 0 then table.insert(layers, currentLayer) end
    return layers
end

-- ============ BUILDER ============
local builder = {
    active = false,
    previewParts = {},
    rotation = 0,
    baseY = 0,
    mode = "art",
    artWidth = 10, artHeight = 10, artColors = {},
    schemaData = nil
}

-- ============ PREVIEW ============
local function createPreview(color, pos)
    local p = Instance.new("Part")
    p.Size = Vector3.new(GrandeurBloc * 0.95, GrandeurBloc * 0.95, GrandeurBloc * 0.95)
    p.Anchored = true
    p.CanCollide = false
    p.Transparency = 0.5
    p.Color = color
    p.Position = pos
    p.Parent = Workspace
    return p
end

local function clearPreview()
    for _, p in ipairs(builder.previewParts) do
        pcall(function() p:Destroy() end)
    end
    builder.previewParts = {}
end

local function getMouseGrid()
    local mouse = LocalPlayer:GetMouse()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local res = Workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 1000, params)
    if res then
        local hp = res.Position
        return Vector3.new(
            MathRound((hp.X - PositionOrigin.X) / GrandeurBloc),
            MathRound((hp.Y - PositionOrigin.Y) / GrandeurBloc),
            MathRound((hp.Z - PositionOrigin.Z) / GrandeurBloc)
        )
    end
    return Vector3.new(0, 0, 0)
end

local function addP(cx, cy, cz, color)
    table.insert(builder.previewParts, createPreview(color, gridToWorld(Vector3.new(cx, cy, cz))))
end

local function updatePreview()
    if not builder.active then return end
    clearPreview()
    local baseGrid = getMouseGrid()
    local bX, bZ = baseGrid.X, baseGrid.Z
    local rot = builder.rotation

    if builder.mode == "art" then
        local w, h = builder.artWidth, builder.artHeight
        local idx = 1
        for row = 0, h - 1 do
            for col = 0, w - 1 do
                local wx, wz = bX + col, bZ + row
                if rot == 90 then wx, wz = bX - row, bZ + col
                elseif rot == 180 then wx, wz = bX - col, bZ - row
                elseif rot == 270 then wx, wz = bX + row, bZ - col end
                local color = builder.artColors[idx] or Color3.new(1,1,1)
                addP(wx, builder.baseY, wz, color)
                idx = idx + 1
            end
        end

    elseif builder.mode == "schema" then
        if not builder.schemaData then return end
        for y, layer in ipairs(builder.schemaData) do
            for rowIdx, row in ipairs(layer) do
                for colIdx, cell in ipairs(row) do
                    local material, color, blockId = parseCell(cell)
                    if material or color or blockId then
                        local wx = bX + colIdx - 1
                        local wz = bZ + rowIdx - 1
                        local wy = builder.baseY + y - 1
                        if rot == 90 then wx, wz = bX - (rowIdx - 1), bZ + (colIdx - 1)
                        elseif rot == 180 then wx, wz = bX - (colIdx - 1), bZ - (rowIdx - 1)
                        elseif rot == 270 then wx, wz = bX + (rowIdx - 1), bZ - (colIdx - 1) end
                        addP(wx, wy, wz, color or Color3.fromRGB(200,180,160))
                    end
                end
            end
        end
    end
end

local function onMouseClick()
    if not builder.active then return end
    builder.active = false
    clearPreview()
    local baseGrid = getMouseGrid()
    local bX, bZ = baseGrid.X, baseGrid.Z
    local rot = builder.rotation

    if builder.mode == "art" then
        print("🎨 Строим арт "..builder.artWidth.."x"..builder.artHeight)
        local w, h = builder.artWidth, builder.artHeight
        local idx = 1
        for row = h - 1, 0, -1 do
            for col = 0, w - 1 do
                local color = builder.artColors[idx]
                if color then
                    local wx, wz = bX + col, bZ + row
                    if rot == 90 then wx, wz = bX - row, bZ + col
                    elseif rot == 180 then wx, wz = bX - col, bZ - row
                    elseif rot == 270 then wx, wz = bX + row, bZ - col end
                    placeBlock(wx, builder.baseY, wz, color, "Default", 43)
                end
                idx = idx + 1
            end
        end
        print("✅ Арт построен!")

    elseif builder.mode == "schema" then
        if not builder.schemaData then return end
        print("📐 Строим схему...")
        local placed = 0
        for y, layer in ipairs(builder.schemaData) do
            for rowIdx, row in ipairs(layer) do
                for colIdx, cell in ipairs(row) do
                    local material, color, blockId = parseCell(cell)
                    if material or color or blockId then
                        local wx = bX + colIdx - 1
                        local wz = bZ + rowIdx - 1
                        local wy = builder.baseY + y - 1
                        if rot == 90 then wx, wz = bX - (rowIdx - 1), bZ + (colIdx - 1)
                        elseif rot == 180 then wx, wz = bX - (colIdx - 1), bZ - (rowIdx - 1)
                        elseif rot == 270 then wx, wz = bX + (rowIdx - 1), bZ - (colIdx - 1) end
                        placeBlock(wx, wy, wz, color or Color3.fromRGB(200,180,160), material or "Default", blockId or 43)
                        placed = placed + 1
                    end
                end
            end
        end
        print("✅ Схема построена! Блоков: "..placed)
    end
end

local function onKeyDown(input)
    if not builder.active then return end
    if input.KeyCode == Enum.KeyCode.R then
        builder.rotation = (builder.rotation + 90) % 360
        print("🔄 Поворот: "..builder.rotation.."°")
        updatePreview()
    elseif input.KeyCode == Enum.KeyCode.T then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
            builder.baseY = math.max(0, builder.baseY - 1)
            print("⬆️ Высота: "..builder.baseY)
        end
        updatePreview()
    elseif input.KeyCode == Enum.KeyCode.Escape then
        builder.active = false
        clearPreview()
        print("❌ Отменено")
    end
end

local function onMouseWheel(input)
    if not builder.active then return end
    builder.rotation = (builder.rotation + (input.Position.Z > 0 and 90 or -90)) % 360
    if builder.rotation < 0 then builder.rotation = builder.rotation + 360 end
    updatePreview()
end

local function onMouseMove()
    if not builder.active then return end
    updatePreview()
end

-- ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "BuilderGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 500, 0, 650)
main.Position = UDim2.new(0.5, -250, 0.02, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Parent = gui

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🏗️ СТРОИТЕЛЬ v26.1 (фикс стёкол)"
title.TextColor3 = Color3.fromRGB(255, 200, 50)
title.Font = Enum.Font.Code
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -28, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header
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
        main.Position = UDim2.new(fS.X.Scale, fS.X.Offset + delta.X, fS.Y.Scale, fS.Y.Offset + delta.Y)
    end
end)

local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -20, 0, 26)
tabsFrame.Position = UDim2.new(0, 10, 0, 35)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = main

local tabBtn1 = Instance.new("TextButton")
tabBtn1.Size = UDim2.new(0, 220, 0, 24)
tabBtn1.Position = UDim2.new(0, 0, 0, 0)
tabBtn1.Text = "🎨 Арты (2D)"
tabBtn1.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
tabBtn1.TextColor3 = Color3.new(1,1,1)
tabBtn1.Font = Enum.Font.Code
tabBtn1.TextSize = 12
tabBtn1.BorderSizePixel = 0
tabBtn1.Parent = tabsFrame

local tabBtn2 = Instance.new("TextButton")
tabBtn2.Size = UDim2.new(0, 240, 0, 24)
tabBtn2.Position = UDim2.new(0, 225, 0, 0)
tabBtn2.Text = "📐 Схема (3D + материалы)"
tabBtn2.BackgroundColor3 = Color3.fromRGB(60,60,60)
tabBtn2.TextColor3 = Color3.new(1,1,1)
tabBtn2.Font = Enum.Font.Code
tabBtn2.TextSize = 12
tabBtn2.BorderSizePixel = 0
tabBtn2.Parent = tabsFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -105)
content.Position = UDim2.new(0, 10, 0, 65)
content.BackgroundTransparency = 1
content.Parent = main

-- ============ ВКЛАДКА 1: АРТЫ ============
local tab1 = Instance.new("Frame")
tab1.Size = UDim2.new(1, 0, 1, 0)
tab1.BackgroundTransparency = 1
tab1.Parent = content

local y = 5
local artSizeW, artSizeH
for i, lab in ipairs({"📐 Ширина:", "📏 Высота:"}) do
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 80, 0, 20)
    l.Position = UDim2.new(0, 0, 0, y + (i-1)*28)
    l.BackgroundTransparency = 1
    l.Text = lab
    l.TextColor3 = Color3.new(1,1,1)
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = tab1

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 60, 0, 20)
    box.Position = UDim2.new(0, 90, 0, y + (i-1)*28)
    box.Text = "10"
    box.BackgroundColor3 = Color3.fromRGB(10,10,15)
    box.TextColor3 = Color3.new(1,1,1)
    box.Font = Enum.Font.Code
    box.TextSize = 12
    box.BorderSizePixel = 0
    box.Parent = tab1
    if i == 1 then artSizeW = box else artSizeH = box end
end

y = y + 2*28 + 10
local artLbl = Instance.new("TextLabel")
artLbl.Size = UDim2.new(1, 0, 0, 20)
artLbl.Position = UDim2.new(0, 0, 0, y)
artLbl.BackgroundTransparency = 1
artLbl.Text = "🎨 HEX-коды (через пробел):"
artLbl.TextColor3 = Color3.new(1,1,1)
artLbl.Font = Enum.Font.Code
artLbl.TextSize = 11
artLbl.TextXAlignment = Enum.TextXAlignment.Left
artLbl.Parent = tab1

y = y + 22
local artBox = Instance.new("TextBox")
artBox.Size = UDim2.new(1, 0, 0, 380)
artBox.Position = UDim2.new(0, 0, 0, y)
artBox.Text = "#FF0000 #00FF00 #0000FF #FFFF00 #FF00FF #00FFFF"
artBox.BackgroundColor3 = Color3.fromRGB(10,10,15)
artBox.TextColor3 = Color3.new(1,1,1)
artBox.Font = Enum.Font.Code
artBox.TextSize = 11
artBox.BorderSizePixel = 0
artBox.MultiLine = true
artBox.TextXAlignment = Enum.TextXAlignment.Left
artBox.TextYAlignment = Enum.TextYAlignment.Top
artBox.ClearTextOnFocus = false
artBox.Parent = tab1

y = y + 390
local artBtn = Instance.new("TextButton")
artBtn.Size = UDim2.new(1, 0, 0, 40)
artBtn.Position = UDim2.new(0, 0, 0, y)
artBtn.Text = "🎨 Построить арт"
artBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
artBtn.TextColor3 = Color3.new(1,1,1)
artBtn.Font = Enum.Font.Code
artBtn.TextSize = 13
artBtn.BorderSizePixel = 0
artBtn.Parent = tab1

artBtn.MouseButton1Click:Connect(function()
    builder.mode = "art"
    local w = tonumber(artSizeW.Text) or 10
    local h = tonumber(artSizeH.Text) or 10
    local hexes = {}
    for s in artBox.Text:gmatch("%S+") do
        table.insert(hexes, s)
    end
    if #hexes ~= w * h then
        print(string.format("❌ Нужно %d цветов, получено %d", w*h, #hexes))
        return
    end
    local colors = {}
    for _, hx in ipairs(hexes) do
        local c = parseHex(hx)
        if not c then
            print("❌ Неверный цвет: "..hx)
            return
        end
        table.insert(colors, c)
    end
    builder.artWidth = w
    builder.artHeight = h
    builder.artColors = colors
    builder.rotation = 0
    builder.baseY = 0
    builder.active = true
    updatePreview()
    print("✅ Арт "..w.."x"..h.." готов")
end)

-- ============ ВКЛАДКА 2: 3D-СХЕМА ============
local tab2 = Instance.new("Frame")
tab2.Size = UDim2.new(1, 0, 1, 0)
tab2.BackgroundTransparency = 1
tab2.Visible = false
tab2.Parent = content

y = 5
local schemaLbl = Instance.new("TextLabel")
schemaLbl.Size = UDim2.new(1, 0, 0, 20)
schemaLbl.Position = UDim2.new(0, 0, 0, y)
schemaLbl.BackgroundTransparency = 1
schemaLbl.Text = "📐 Схема (пустая строка = новый слой):"
schemaLbl.TextColor3 = Color3.new(1,1,1)
schemaLbl.Font = Enum.Font.Code
schemaLbl.TextSize = 11
schemaLbl.TextXAlignment = Enum.TextXAlignment.Left
schemaLbl.Parent = tab2

y = y + 22
local schemaHelp = Instance.new("TextLabel")
schemaHelp.Size = UDim2.new(1, 0, 0, 50)
schemaHelp.Position = UDim2.new(0, 0, 0, y)
schemaHelp.BackgroundTransparency = 1
schemaHelp.Text = "Формат: brick#CC9966 glass#88DDFF door#AA7744 . (пусто)\nАлиасы: block, stair, slab, pane, door, pole, beam, chair, torch, glass...\nID: 43#CC9966 82#88DDFF 75#AA7744"
schemaHelp.TextColor3 = Color3.fromRGB(150,150,150)
schemaHelp.Font = Enum.Font.Code
schemaHelp.TextSize = 9
schemaHelp.TextXAlignment = Enum.TextXAlignment.Left
schemaHelp.TextYAlignment = Enum.TextYAlignment.Top
schemaHelp.Parent = tab2

y = y + 55
local schemaBox = Instance.new("TextBox")
schemaBox.Size = UDim2.new(1, 0, 0, 375)
schemaBox.Position = UDim2.new(0, 0, 0, y)
schemaBox.Text = "brick#CC9966 brick#CC9966 brick#CC9966\nbrick#CC9966 glass#88DDFF brick#CC9966\nbrick#CC9966 door#AA7744 brick#CC9966\n\nbrick#CC9966 brick#CC9966 brick#CC9966\nbrick#CC9966 glass#88DDFF brick#CC9966\nbrick#CC9966 glass#88DDFF brick#CC9966\n\nslate#884422 slate#884422 slate#884422\nslate#884422 slate#884422 slate#884422\nslate#884422 slate#884422 slate#884422"
schemaBox.BackgroundColor3 = Color3.fromRGB(10,10,15)
schemaBox.TextColor3 = Color3.new(1,1,1)
schemaBox.Font = Enum.Font.Code
schemaBox.TextSize = 11
schemaBox.BorderSizePixel = 0
schemaBox.MultiLine = true
schemaBox.TextXAlignment = Enum.TextXAlignment.Left
schemaBox.TextYAlignment = Enum.TextYAlignment.Top
schemaBox.ClearTextOnFocus = false
schemaBox.Parent = tab2

y = y + 385
local schemaBtn = Instance.new("TextButton")
schemaBtn.Size = UDim2.new(1, 0, 0, 40)
schemaBtn.Position = UDim2.new(0, 0, 0, y)
schemaBtn.Text = "📐 Построить схему"
schemaBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
schemaBtn.TextColor3 = Color3.new(1,1,1)
schemaBtn.Font = Enum.Font.Code
schemaBtn.TextSize = 13
schemaBtn.BorderSizePixel = 0
schemaBtn.Parent = tab2

schemaBtn.MouseButton1Click:Connect(function()
    builder.mode = "schema"
    local text = schemaBox.Text
    if text == "" then
        print("❌ Схема пустая")
        return
    end
    local layers = parseSchema(text)
    if #layers == 0 then
        print("❌ Не удалось распарсить схему")
        return
    end
    builder.schemaData = layers
    builder.rotation = 0
    builder.baseY = 0
    builder.active = true
    updatePreview()

    local total = 0
    for _, layer in ipairs(layers) do
        for _, row in ipairs(layer) do
            for _, cell in ipairs(row) do
                if cell ~= "." and cell ~= "" then total = total + 1 end
            end
        end
    end
    print(string.format("✅ Схема готова! Слоёв: %d, блоков: %d", #layers, total))
end)

tabBtn1.MouseButton1Click:Connect(function()
    tab1.Visible = true
    tab2.Visible = false
    tabBtn1.BackgroundColor3 = Color3.fromRGB(0,100,200)
    tabBtn2.BackgroundColor3 = Color3.fromRGB(60,60,60)
    builder.mode = "art"
end)

tabBtn2.MouseButton1Click:Connect(function()
    tab1.Visible = false
    tab2.Visible = true
    tabBtn1.BackgroundColor3 = Color3.fromRGB(60,60,60)
    tabBtn2.BackgroundColor3 = Color3.fromRGB(0,100,200)
    builder.mode = "schema"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.Escape then
        onKeyDown(input)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        onMouseClick()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        if builder.active then
            builder.active = false
            clearPreview()
            print("❌ Отменено")
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        onMouseMove()
    elseif input.UserInputType == Enum.UserInputType.MouseWheel then
        onMouseWheel(input)
    end
end)

print("🏗️ СТРОИТЕЛЬ v26.1 загружен! (фикс стёкол)")
print("Алиасы: block, stair, slab, pane, door, pole, beam, chair, torch, glass...")
print("Можно писать ID напрямую: 43#CC9966 82#88DDFF")
