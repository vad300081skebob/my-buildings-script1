-- ============ МЕГА-СТРОИТЕЛЬ v50.0 ============
-- Здания + Декорации + Техника + Оружие + Люди + Флаги + Памятники

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

-- Цвета
local GREEN = Color3.fromRGB(59, 107, 42)
local DARK_GREEN = Color3.fromRGB(45, 85, 32)
local LIGHT_GREEN = Color3.fromRGB(75, 125, 55)
local BLACK = Color3.fromRGB(28, 28, 28)
local DARK_GRAY = Color3.fromRGB(60, 60, 60)
local GUNMETAL = Color3.fromRGB(45, 48, 52)
local YELLOW = Color3.fromRGB(255, 220, 80)
local RED = Color3.fromRGB(200, 50, 50)
local WHITE = Color3.fromRGB(240, 240, 240)
local BLUE = Color3.fromRGB(20, 70, 180)
local SKIN = Color3.fromRGB(240, 200, 170)
local BROWN = Color3.fromRGB(80, 60, 40)
local SAND = Color3.fromRGB(210, 180, 130)

local POLE_ID = 86

local function buildGunBarrel(bx, by, bz, length, color)
    for i = 0, length - 1 do
        placeBlock(bx, by, bz - i, color or GUNMETAL, "Metal", POLE_ID)
    end
    placeBlock(bx, by, bz - length, color or GUNMETAL, "Metal", 43)
end

-- ============ ЗДАНИЯ ============

local function buildHouse(bx, by, bz, w, d, h)
    print("🏠 Дом...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(100,100,100), "Concrete", 43)
    end end
    local dX = math.floor(w/2)
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if z == 0 and x == dX and y < 3 then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,100,50), "Wood", 75)
            elseif (z == 0 or z == d-1) and y >= 1 and y <= 2 and (x == dX-2 or x == dX+2) then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,220,255), "Glass", 43)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(200,180,160), "Brick", 43)
            end
        end
    end end end
    for x = 0, w-1 do for z = 0, d-1 do
        placeBlock(bx+x, by, bz+z, Color3.fromRGB(180,150,100), "Wood", 43)
        placeBlock(bx+x, by+h, bz+z, Color3.fromRGB(200,200,200), "Concrete", 43)
    end end
    print("✅ Дом готов!")
end

local function buildShop(bx, by, bz, w, d, h)
    print("🏪 Магазин...")
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(220,220,230), "Concrete", 43)
        end
    end end end
    for x = 0, w-1 do for z = 0, d-1 do
        placeBlock(bx+x, by, bz+z, Color3.fromRGB(180,180,180), "Concrete", 43)
        placeBlock(bx+x, by+h, bz+z, Color3.fromRGB(180,180,180), "Concrete", 43)
    end end
    placeBlock(bx+math.floor(w/2), by+h+1, bz, RED, "Neon", 33)
    print("✅ Магазин готов!")
end

local function buildSkyscraper(bx, by, bz, w, d, h)
    print("🏢 Небоскрёб...")
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if y % 2 == 0 then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,220,255), "Glass", 43)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(80,80,100), "Metal", 43)
            end
        end
    end end end
    for y = 1, 6 do
        placeBlock(bx+math.floor(w/2), by+h+y, bz+math.floor(d/2), RED, "Metal", 46)
    end
    print("✅ Небоскрёб готов!")
end

local function buildCastle(bx, by, bz, w, d, h)
    print("🏰 Замок...")
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(180,160,140), "Brick", 43)
        end
    end end end
    for _, t in ipairs({{0,0},{w-1,0},{0,d-1},{w-1,d-1}}) do
        local tx, tz = t[1], t[2]
        for y = 0, h+2 do for x = -2, 2 do for z = -2, 2 do
            if math.abs(x) == 2 or math.abs(z) == 2 then
                placeBlock(bx+tx+x, by+y, bz+tz+z, Color3.fromRGB(180,160,140), "Brick", 43)
            end
        end end end
    end
    print("✅ Замок готов!")
end

-- ============ ДЕКОРАЦИИ ============

local function buildTree(cx, cy, cz)
    print("🌳 Дерево...")
    for y = 0, 4 do
        placeBlock(cx, cy+y, cz, BROWN, "Wood", 43)
    end
    for y = 5, 8 do
        local r = 8 - y + 1
        for x = -r, r do for z = -r, r do
            if x*x + z*z <= r*r then
                placeBlock(cx+x, cy+y, cz+z, Color3.fromRGB(50,150,50), "Grass", 43)
            end
        end end
    end
    print("✅ Дерево готово!")
end

local function buildPineTree(cx, cy, cz)
    print("🌲 Ёлка...")
    for y = 0, 3 do
        placeBlock(cx, cy+y, cz, Color3.fromRGB(70,50,30), "Wood", 43)
    end
    for y = 4, 8 do
        local r = math.max(0, math.floor((8 - y) / 2) + 1)
        for x = -r, r do for z = -r, r do
            if x*x + z*z <= r*r then
                placeBlock(cx+x, cy+y, cz+z, Color3.fromRGB(30,100,40), "Grass", 43)
            end
        end end
    end
    print("✅ Ёлка готова!")
end

local function buildBench(cx, cy, cz)
    print("🪑 Скамейка...")
    for x = -1, 1 do
        placeBlock(cx+x, cy, cz, Color3.fromRGB(120,80,50), "Wooden Planks", 43)
        placeBlock(cx+x, cy+1, cz-1, Color3.fromRGB(120,80,50), "Wooden Planks", 43)
        placeBlock(cx+x, cy+2, cz-1, Color3.fromRGB(120,80,50), "Wooden Planks", 43)
    end
    print("✅ Скамейка готова!")
end

local function buildFountain(cx, cy, cz)
    print("⛲ Фонтан...")
    for x = -2, 2 do for z = -2, 2 do
        if math.abs(x) == 2 or math.abs(z) == 2 then
            placeBlock(cx+x, cy, cz+z, Color3.fromRGB(200,200,200), "Marble", 43)
        end
    end end
    for x = -1, 1 do for z = -1, 1 do
        placeBlock(cx+x, cy, cz+z, Color3.fromRGB(100,180,255), "Glass", 43)
    end end
    for y = 1, 2 do
        placeBlock(cx, cy+y, cz, Color3.fromRGB(220,220,220), "Marble", 43)
    end
    placeBlock(cx, cy+3, cz, Color3.fromRGB(150,200,255), "Glass", 33)
    print("✅ Фонтан готов!")
end

local function buildLamp(cx, cy, cz)
    print("💡 Фонарь...")
    for y = 0, 3 do
        placeBlock(cx, cy+y, cz, Color3.fromRGB(50,50,50), "Metal", POLE_ID)
    end
    placeBlock(cx, cy+4, cz, Color3.fromRGB(255,240,180), "Glass", 33)
    print("✅ Фонарь готов!")
end

local function buildBush(cx, cy, cz)
    print("🌿 Куст...")
    for x = -1, 1 do for z = -1, 1 do for y = 0, 1 do
        if math.abs(x) + math.abs(z) + y <= 2 then
            placeBlock(cx+x, cy+y, cz+z, Color3.fromRGB(60,130,60), "Grass", 43)
        end
    end end end
    print("✅ Куст готов!")
end

local function buildFlowerBed(cx, cy, cz)
    print("🌷 Клумба...")
    for x = -1, 1 do for z = -1, 1 do
        placeBlock(cx+x, cy-1, cz+z, Color3.fromRGB(120,80,40), "Wood", 43)
    end end
    local colors = {Color3.fromRGB(255,100,150), Color3.fromRGB(255,200,100), Color3.fromRGB(200,100,255), Color3.fromRGB(255,50,50)}
    local i = 1
    for x = -1, 1 do for z = -1, 1 do
        placeBlock(cx+x, cy, cz+z, colors[(i % 4) + 1], "Grass", 43)
        i = i + 1
    end end
    print("✅ Клумба готова!")
end

local function buildFence(cx, cy, cz)
    print("🚧 Забор...")
    for x = -3, 3 do
        placeBlock(cx+x, cy, cz, BROWN, "Wood", POLE_ID)
        placeBlock(cx+x, cy+1, cz, BROWN, "Wood", POLE_ID)
    end
    print("✅ Забор готов!")
end

local function buildWell(cx, cy, cz)
    print("🕳️ Колодец...")
    for x = -1, 1 do for z = -1, 1 do
        if math.abs(x) == 1 or math.abs(z) == 1 then
            placeBlock(cx+x, cy, cz+z, DARK_GRAY, "Brick", 43)
            placeBlock(cx+x, cy+1, cz+z, DARK_GRAY, "Brick", 43)
        end
    end end
    for y = 2, 3 do
        placeBlock(cx-1, cy+y, cz-1, BROWN, "Wood", POLE_ID)
        placeBlock(cx+1, cy+y, cz+1, BROWN, "Wood", POLE_ID)
    end
    placeBlock(cx, cy+4, cz, BROWN, "Wood", 43)
    print("✅ Колодец готов!")
end

-- ============ ТАНКИ ============

local function buildT72(bx, by, bz)
    print("🚁 Т-72...")
    for z = 0, 13 do
        for xx = 0, 1 do
            placeBlock(bx + xx, by + 0, bz + z, BLACK, "Fabric", 43)
            placeBlock(bx + 7 + xx, by + 0, bz + z, BLACK, "Fabric", 43)
            placeBlock(bx + xx, by + 1, bz + z, BLACK, "Fabric", 43)
            placeBlock(bx + 7 + xx, by + 1, bz + z, BLACK, "Fabric", 43)
        end
    end
    for y = 2, 4 do
        for z = 1, 13 do
            for x = 2, 6 do
                if x == 2 or x == 6 or z == 13 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 5, 8 do for x = 2, 6 do
        if not ((z == 5 or z == 8) and (x == 2 or x == 6)) then
            placeBlock(bx + x, by + 5, bz + z, GREEN, "Metal", 43)
        end
    end end
    for z = 6, 7 do for x = 3, 5 do
        placeBlock(bx + x, by + 6, bz + z, GREEN, "Metal", 43)
    end end
    buildGunBarrel(bx + 4, by + 6, bz + 4, 7, GUNMETAL)
    for y = 7, 10 do placeBlock(bx + 3, by + y, bz + 9, DARK_GRAY, "Metal", POLE_ID) end
    print("✅ Т-72 готов!")
end

local function buildT90(bx, by, bz)
    print("🚁 Т-90...")
    for z = 0, 14 do
        for xx = 0, 1 do
            placeBlock(bx + xx, by + 0, bz + z, BLACK, "Fabric", 43)
            placeBlock(bx + 7 + xx, by + 0, bz + z, BLACK, "Fabric", 43)
        end
    end
    for y = 2, 4 do
        for z = 1, 14 do
            for x = 2, 6 do
                if x == 2 or x == 6 or z == 14 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 5, 9 do for x = 2, 6 do
        if not ((z == 5 or z == 9) and (x == 2 or x == 6)) then
            placeBlock(bx + x, by + 5, bz + z, GREEN, "Metal", 43)
        end
    end end
    buildGunBarrel(bx + 4, by + 6, bz + 4, 8, GUNMETAL)
    for y = 7, 11 do placeBlock(bx + 3, by + y, bz + 10, DARK_GRAY, "Metal", POLE_ID) end
    print("✅ Т-90 готов!")
end

local function buildT14(bx, by, bz)
    print("🚁 Т-14 Армата...")
    for y = 2, 4 do
        for z = 1, 15 do
            for x = 2, 7 do
                if x == 2 or x == 7 or z == 15 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 6, 10 do for x = 3, 6 do
        placeBlock(bx + x, by + 5, bz + z, GREEN, "Metal", 43)
    end end
    buildGunBarrel(bx + 4, by + 6, bz + 5, 8, GUNMETAL)
    print("✅ Т-14 Армата готова!")
end

local function buildT80(bx, by, bz)
    print("🚁 Т-80...")
    for y = 2, 4 do
        for z = 1, 14 do
            for x = 2, 6 do
                if x == 2 or x == 6 or z == 14 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 5, 9 do for x = 2, 6 do
        placeBlock(bx + x, by + 5, bz + z, GREEN, "Metal", 43)
    end end
    buildGunBarrel(bx + 4, by + 6, bz + 4, 7, GUNMETAL)
    print("✅ Т-80 готов!")
end

-- ============ БМП / БТР ============

local function buildBMP2(bx, by, bz)
    print("🚁 БМП-2...")
    for z = 0, 13 do
        placeBlock(bx + 0, by + 0, bz + z, BLACK, "Fabric", 43)
        placeBlock(bx + 6, by + 0, bz + z, BLACK, "Fabric", 43)
        placeBlock(bx + 0, by + 1, bz + z, BLACK, "Fabric", 43)
        placeBlock(bx + 6, by + 1, bz + z, BLACK, "Fabric", 43)
    end
    for y = 2, 4 do
        for z = 1, 12 do
            for x = 1, 5 do
                if x == 1 or x == 5 or z == 12 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 5, 8 do for x = 2, 4 do
        placeBlock(bx + x, by + 5, bz + z, GREEN, "Metal", 43)
    end end
    placeBlock(bx + 3, by + 6, bz + 6, GREEN, "Metal", 43)
    placeBlock(bx + 3, by + 6, bz + 7, GREEN, "Metal", 43)
    buildGunBarrel(bx + 3, by + 6, bz + 5, 6, GUNMETAL)
    for y = 7, 9 do placeBlock(bx + 2, by + y, bz + 9, DARK_GRAY, "Metal", POLE_ID) end
    print("✅ БМП-2 готова!")
end

local function buildBMP3(bx, by, bz)
    print("🚁 БМП-3...")
    for y = 2, 5 do
        for z = 1, 14 do
            for x = 1, 6 do
                if x == 1 or x == 6 or z == 14 or y == 5 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 6, 10 do for x = 2, 5 do
        placeBlock(bx + x, by + 6, bz + z, GREEN, "Metal", 43)
    end end
    buildGunBarrel(bx + 4, by + 7, bz + 5, 7, GUNMETAL)
    print("✅ БМП-3 готова!")
end

local function buildBTR80(bx, by, bz)
    print("🚁 БТР-80...")
    for y = 1, 4 do
        for z = 0, 12 do
            for x = 1, 5 do
                if x == 1 or x == 5 or z == 0 or z == 12 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 5, 7 do for x = 2, 4 do
        placeBlock(bx + x, by + 5, bz + z, GREEN, "Metal", 43)
    end end
    buildGunBarrel(bx + 3, by + 6, bz + 4, 4, GUNMETAL)
    print("✅ БТР-80 готов!")
end

local function buildBTR82A(bx, by, bz)
    print("🚁 БТР-82А...")
    for y = 1, 4 do
        for z = 0, 12 do
            for x = 1, 5 do
                if x == 1 or x == 5 or z == 0 or z == 12 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 5, 8 do for x = 2, 4 do
        placeBlock(bx + x, by + 5, bz + z, GREEN, "Metal", 43)
    end end
    buildGunBarrel(bx + 3, by + 6, bz + 4, 5, GUNMETAL)
    print("✅ БТР-82А готов!")
end

local function buildTerminator(bx, by, bz)
    print("🚁 БМПТ Терминатор...")
    for y = 2, 4 do
        for z = 1, 13 do
            for x = 1, 6 do
                if x == 1 or x == 6 or z == 13 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 5, 9 do for x = 2, 5 do
        placeBlock(bx + x, by + 5, bz + z, GREEN, "Metal", 43)
    end end
    buildGunBarrel(bx + 3, by + 6, bz + 4, 6, GUNMETAL)
    buildGunBarrel(bx + 4, by + 6, bz + 4, 6, GUNMETAL)
    print("✅ Терминатор готов!")
end

local function buildTigr(bx, by, bz)
    print("🚁 Тигр...")
    for y = 1, 4 do
        for z = 0, 12 do
            for x = 1, 5 do
                if x == 1 or x == 5 or z == 0 or z == 12 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    placeBlock(bx + 3, by + 5, bz + 5, GREEN, "Metal", 43)
    buildGunBarrel(bx + 3, by + 5, bz + 4, 3, GUNMETAL)
    print("✅ Тигр готов!")
end

-- ============ ПВО / АРТИЛЛЕРИЯ ============

local function buildS400(bx, by, bz)
    print("🚁 С-400...")
    for y = 2, 4 do
        for z = 0, 15 do
            for x = 1, 8 do
                if x == 1 or x == 8 or z == 0 or z == 15 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, DARK_GREEN, "Metal", 43)
                end
            end
        end
    end
    for i = 0, 3 do
        local zz = 4 + i * 2
        for y = 5, 6 do
            placeBlock(bx + 3, by + y, bz + zz, DARK_GREEN, "Metal", POLE_ID)
            placeBlock(bx + 6, by + y, bz + zz, DARK_GREEN, "Metal", POLE_ID)
        end
    end
    for y = 5, 8 do placeBlock(bx + 4, by + y, bz + 13, DARK_GRAY, "Metal", POLE_ID) end
    print("✅ С-400 готов!")
end

local function buildPantsir(bx, by, bz)
    print("🚁 Панцирь-С1...")
    for y = 1, 4 do
        for z = 0, 10 do
            for x = 1, 5 do
                if x == 1 or x == 5 or z == 0 or z == 10 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 3, 7 do for x = 2, 4 do
        placeBlock(bx + x, by + 5, bz + z, GREEN, "Metal", 43)
    end end
    for i = 0, 2 do
        placeBlock(bx + 2, by + 6, bz + 4 + i, DARK_GRAY, "Metal", POLE_ID)
        placeBlock(bx + 4, by + 6, bz + 4 + i, DARK_GRAY, "Metal", POLE_ID)
    end
    print("✅ Панцирь-С1 готов!")
end

local function buildIskander(bx, by, bz)
    print("🚁 Искандер...")
    for y = 1, 4 do
        for z = 0, 15 do
            for x = 1, 7 do
                if x == 1 or x == 7 or z == 0 or z == 15 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, DARK_GREEN, "Metal", 43)
                end
            end
        end
    end
    for i = 0, 6 do
        placeBlock(bx + 3, by + 5 + i, bz + 4 + i, DARK_GREEN, "Metal", POLE_ID)
        placeBlock(bx + 5, by + 5 + i, bz + 4 + i, DARK_GREEN, "Metal", POLE_ID)
    end
    print("✅ Искандер готов!")
end

local function buildSmerch(bx, by, bz)
    print("🚁 Смерч...")
    for y = 1, 4 do
        for z = 0, 15 do
            for x = 1, 7 do
                if x == 1 or x == 7 or z == 0 or z == 15 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, DARK_GREEN, "Metal", 43)
                end
            end
        end
    end
    for i = 0, 3 do
        for xx = 2, 6, 2 do
            placeBlock(bx + xx, by + 5, bz + 6 + i, DARK_GREEN, "Metal", POLE_ID)
            placeBlock(bx + xx, by + 5, bz + 10 + i, DARK_GREEN, "Metal", POLE_ID)
        end
    end
    print("✅ Смерч готов!")
end

local function buildGrad(bx, by, bz)
    print("🚁 Град...")
    for y = 1, 4 do
        for z = 0, 12 do
            for x = 1, 5 do
                if x == 1 or x == 5 or z == 0 or z == 12 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, DARK_GREEN, "Metal", 43)
                end
            end
        end
    end
    for i = 0, 3 do
        for xx = 2, 4, 2 do
            placeBlock(bx + xx, by + 5, bz + 5 + i, DARK_GREEN, "Metal", POLE_ID)
            placeBlock(bx + xx, by + 5, bz + 9 + i, DARK_GREEN, "Metal", POLE_ID)
        end
    end
    print("✅ Град готов!")
end

-- ============ ГРУЗОВИКИ ============

local function buildUral(bx, by, bz)
    print("🚁 Урал...")
    for y = 1, 4 do
        for z = 0, 4 do
            for x = 1, 5 do
                if x == 1 or x == 5 or z == 0 or z == 4 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 5, 12 do
        for x = 1, 5 do
            if x == 1 or x == 5 then
                placeBlock(bx + x, by + 2, bz + z, GREEN, "Metal", 43)
                placeBlock(bx + x, by + 3, bz + z, GREEN, "Metal", 43)
            end
        end
    end
    print("✅ Урал готов!")
end

local function buildKamaz(bx, by, bz)
    print("🚁 Камаз...")
    for y = 1, 4 do
        for z = 0, 4 do
            for x = 1, 5 do
                if x == 1 or x == 5 or z == 0 or z == 4 or y == 4 then
                    placeBlock(bx + x, by + y, bz + z, BLUE, "Metal", 43)
                end
            end
        end
    end
    for z = 5, 12 do
        for x = 1, 5 do
            if x == 1 or x == 5 then
                placeBlock(bx + x, by + 2, bz + z, WHITE, "Metal", 43)
                placeBlock(bx + x, by + 3, bz + z, WHITE, "Metal", 43)
            end
        end
    end
    print("✅ Камаз готов!")
end

-- ============ АВИАЦИЯ ============

local function buildMi24(bx, by, bz)
    print("🚁 Ми-24...")
    for y = 2, 4 do
        for z = 0, 2 do
            for x = 2, 4 do
                placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
            end
        end
    end
    for y = 2, 5 do
        for z = 3, 12 do
            for x = 2, 4 do
                if y == 5 or x == 2 or x == 4 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for y = 3, 4 do
        placeBlock(bx + 3, by + y, bz + 13, GREEN, "Metal", 43)
        placeBlock(bx + 3, by + y, bz + 14, GREEN, "Metal", 43)
    end
    placeBlock(bx + 3, by + 6, bz + 14, GREEN, "Metal", 43)
    for i = -2, 2 do
        placeBlock(bx + 3 + i, by + 6, bz + 5, DARK_GRAY, "Metal", POLE_ID)
    end
    placeBlock(bx + 5, by + 5, bz + 14, DARK_GRAY, "Metal", POLE_ID)
    placeBlock(bx + 5, by + 3, bz + 14, DARK_GRAY, "Metal", POLE_ID)
    print("✅ Ми-24 готов!")
end

local function buildKa52(bx, by, bz)
    print("🚁 Ка-52...")
    for y = 2, 5 do
        for z = 0, 3 do
            for x = 2, 5 do
                if y == 5 or z == 0 or x == 2 or x == 5 then
                    placeBlock(bx + x, by + y, bz + z, DARK_GREEN, "Metal", 43)
                end
            end
        end
    end
    for y = 2, 5 do
        for z = 4, 12 do
            for x = 3, 4 do
                placeBlock(bx + x, by + y, bz + z, DARK_GREEN, "Metal", 43)
            end
        end
    end
    for i = -2, 2 do
        placeBlock(bx + 3 + i, by + 6, bz + 5, DARK_GRAY, "Metal", POLE_ID)
        placeBlock(bx + 3 + i, by + 7, bz + 5, DARK_GRAY, "Metal", POLE_ID)
    end
    placeBlock(bx + 3, by + 8, bz + 5, DARK_GRAY, "Metal", 43)
    print("✅ Ка-52 готов!")
end

local function buildSu34(bx, by, bz)
    print("🚁 Су-34...")
    for y = 2, 4 do
        for z = 0, 3 do
            for x = 3, 5 do
                placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
            end
        end
    end
    for y = 2, 5 do
        for z = 4, 14 do
            for x = 3, 5 do
                if y == 5 or x == 3 or x == 5 then
                    placeBlock(bx + x, by + y, bz + z, GREEN, "Metal", 43)
                end
            end
        end
    end
    for z = 6, 10 do
        for xx = 0, 2 do placeBlock(bx + xx, by + 3, bz + z, GREEN, "Metal", 43) end
        for xx = 6, 8 do placeBlock(bx + xx, by + 3, bz + z, GREEN, "Metal", 43) end
    end
    print("✅ Су-34 готов!")
end

-- ============ ЛЮДИ / ФЛАГИ / ПАМЯТНИКИ ============

local function buildSoldier(bx, by, bz)
    print("🪖 Российский солдат...")
    placeBlock(bx, by + 0, bz, Color3.fromRGB(50, 70, 40), "Fabric", 43)
    placeBlock(bx + 1, by + 0, bz, Color3.fromRGB(50, 70, 40), "Fabric", 43)
    for y = 1, 3 do
        placeBlock(bx, by + y, bz, GREEN, "Fabric", 43)
        placeBlock(bx + 1, by + y, bz, GREEN, "Fabric", 43)
    end
    placeBlock(bx, by + 4, bz, SKIN, "Default", 43)
    placeBlock(bx + 1, by + 4, bz, SKIN, "Default", 43)
    placeBlock(bx, by + 5, bz, GREEN, "Metal", 43)
    placeBlock(bx + 1, by + 5, bz, GREEN, "Metal", 43)
    placeBlock(bx - 1, by + 2, bz - 2, GUNMETAL, "Metal", POLE_ID)
    placeBlock(bx + 2, by + 2, bz - 2, GUNMETAL, "Metal", POLE_ID)
    print("✅ Солдат готов!")
end

local function buildFlagRF(bx, by, bz)
    print("🇷🇺 Флаг РФ...")
    for y = 0, 8 do
        placeBlock(bx, by + y, bz, BROWN, "Wood", POLE_ID)
    end
    for y = 6, 7 do for z = 1, 5 do placeBlock(bx, by + y, bz + z, WHITE, "Fabric", 43) end end
    for y = 5, 5 do for z = 1, 5 do placeBlock(bx, by + y, bz + z, BLUE, "Fabric", 43) end end
    for y = 3, 4 do for z = 1, 5 do placeBlock(bx, by + y, bz + z, RED, "Fabric", 43) end end
    print("✅ Флаг РФ готов!")
end

local function buildMonument(bx, by, bz)
    print("🗿 Памятник...")
    for x = -1, 1 do for z = -1, 1 do
        placeBlock(bx+x, by, bz+z, DARK_GRAY, "Marble", 43)
        placeBlock(bx+x, by+1, bz+z, DARK_GRAY, "Marble", 43)
    end end
    for y = 2, 6 do
        placeBlock(bx, by+y, bz, Color3.fromRGB(200,200,200), "Marble", POLE_ID)
    end
    placeBlock(bx, by+7, bz, YELLOW, "Neon", 33)
    print("✅ Памятник готов!")
end

local function buildBarricade(bx, by, bz)
    print("🚧 Баррикада...")
    for x = 0, 5 do
        placeBlock(bx+x, by, bz, DARK_GRAY, "Concrete", 43)
        placeBlock(bx+x, by+1, bz, DARK_GRAY, "Concrete", 43)
        if x % 2 == 0 then
            placeBlock(bx+x, by+2, bz, DARK_GRAY, "Concrete", 43)
        end
    end
    print("✅ Баррикада готова!")
end

local function buildCheckpoint(bx, by, bz)
    print("🚧 Блокпост...")
    for x = 0, 8 do
        placeBlock(bx+x, by, bz, DARK_GRAY, "Concrete", 43)
    end
    for y = 0, 4 do
        placeBlock(bx, by+y, bz, GREEN, "Metal", 43)
        placeBlock(bx+8, by+y, bz, GREEN, "Metal", 43)
    end
    for y = 5, 5 do
        for x = 0, 8 do
            placeBlock(bx+x, by+y, bz, DARK_GREEN, "Metal", 43)
        end
    end
    print("✅ Блокпост готов!")
end

-- ============ АЛИАСЫ ============
local BLOCK_ALIASES = {
    ["block"] = 43, ["brick"] = 43, ["stair"] = 44, ["slab"] = 48,
    ["door"] = 75, ["pane"] = 82, ["glass"] = 82, ["chair"] = 71,
    ["pole"] = 86, ["torch"] = 46, ["lamp"] = 33, ["neon"] = 32, ["led"] = 61,
}

local function parseCell(str)
    if str == "." or str == "" then return nil, nil, nil end
    local material, hex, blockId
    local parts = {}
    for p in str:gmatch("[^#]+") do table.insert(parts, p) end
    local firstName = parts[1] or ""
    local nameL = firstName:lower()
    if #parts >= 2 then
        hex = "#" .. parts[2]
        if BLOCK_ALIASES[nameL] then blockId = BLOCK_ALIASES[nameL]; material = "Default"
        else
            local n = tonumber(firstName)
            if n then blockId = n; material = "Default"
            else material = firstName end
        end
    elseif #parts == 1 then
        if str:sub(1,1) == "#" then hex = str
        else
            if BLOCK_ALIASES[nameL] then blockId = BLOCK_ALIASES[nameL]; material = "Default"
            else
                local n = tonumber(firstName)
                if n then blockId = n; material = "Default"
                else material = firstName end
            end
        end
    end
    local color = hex and parseHex(hex) or nil
    if blockId == 82 or blockId == 81 then
        blockId = 43; material = "Glass"
        if not color then color = Color3.fromRGB(150, 220, 255) end
    end
    return material, color, blockId
end

local function parseSchema(text)
    local layers, currentLayer, currentRow = {}, {}, {}
    for line in (text .. "\n"):gmatch("[^\n]*\n") do
        line = line:gsub("\n", "")
        if line:match("^%s*$") then
            if #currentRow > 0 then table.insert(currentLayer, currentRow); currentRow = {} end
            if #currentLayer > 0 then table.insert(layers, currentLayer); currentLayer = {} end
        else
            for cell in line:gmatch("[^%s,]+") do table.insert(currentRow, cell) end
            if #currentRow > 0 then table.insert(currentLayer, currentRow); currentRow = {} end
        end
    end
    if #currentRow > 0 then table.insert(currentLayer, currentRow) end
    if #currentLayer > 0 then table.insert(layers, currentLayer) end
    return layers
end

local builder = {
    active = false, previewParts = {}, rotation = 0, baseY = 0,
    mode = "art",
    artWidth = 10, artHeight = 10, artColors = {},
    schemaData = nil, techType = nil
}

local function createPreview(color, pos)
    local p = Instance.new("Part")
    p.Size = Vector3.new(GrandeurBloc * 0.95, GrandeurBloc * 0.95, GrandeurBloc * 0.95)
    p.Anchored = true; p.CanCollide = false; p.Transparency = 0.5
    p.Color = color; p.Position = pos; p.Parent = Workspace
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
                addP(wx, builder.baseY, wz, builder.artColors[idx] or Color3.new(1,1,1))
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
                        addP(wx, wy, wz, color or Color3.fromRGB(200,180,160))
                    end
                end
            end
        end
    elseif builder.mode == "tech" then
        for x = 0, 8 do
            for z = 0, 15 do
                addP(bX + x, builder.baseY + 1, bZ + z, Color3.fromRGB(100, 200, 100))
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
        for y, layer in ipairs(builder.schemaData) do
            for rowIdx, row in ipairs(layer) do
                for colIdx, cell in ipairs(row) do
                    local material, color, blockId = parseCell(cell)
                    if material or color or blockId then
                        local wx = bX + colIdx - 1
                        local wz = bZ + rowIdx - 1
                        local wy = builder.baseY + y - 1
                        placeBlock(wx, wy, wz, color or Color3.fromRGB(200,180,160), material or "Default", blockId or 43)
                    end
                end
            end
        end
        print("✅ Схема построена!")
    elseif builder.mode == "tech" then
        local t = builder.techType
        local w = builder.width or 0
        local d = builder.depth or 0
        local h = builder.height or 0
        if t == "house" then buildHouse(bX, builder.baseY, bZ, w, d, h)
        elseif t == "shop" then buildShop(bX, builder.baseY, bZ, w, d, h)
        elseif t == "skyscraper" then buildSkyscraper(bX, builder.baseY, bZ, w, d, h)
        elseif t == "castle" then buildCastle(bX, builder.baseY, bZ, w, d, h)
        elseif t == "tree" then buildTree(bX, builder.baseY, bZ)
        elseif t == "pine" then buildPineTree(bX, builder.baseY, bZ)
        elseif t == "bench" then buildBench(bX, builder.baseY, bZ)
        elseif t == "fountain" then buildFountain(bX, builder.baseY, bZ)
        elseif t == "lamp" then buildLamp(bX, builder.baseY, bZ)
        elseif t == "bush" then buildBush(bX, builder.baseY, bZ)
        elseif t == "flowerbed" then buildFlowerBed(bX, builder.baseY, bZ)
        elseif t == "fence" then buildFence(bX, builder.baseY, bZ)
        elseif t == "well" then buildWell(bX, builder.baseY, bZ)
        elseif t == "t72" then buildT72(bX, builder.baseY, bZ)
        elseif t == "t90" then buildT90(bX, builder.baseY, bZ)
        elseif t == "t14" then buildT14(bX, builder.baseY, bZ)
        elseif t == "t80" then buildT80(bX, builder.baseY, bZ)
        elseif t == "bmp2" then buildBMP2(bX, builder.baseY, bZ)
        elseif t == "bmp3" then buildBMP3(bX, builder.baseY, bZ)
        elseif t == "btr80" then buildBTR80(bX, builder.baseY, bZ)
        elseif t == "btr82a" then buildBTR82A(bX, builder.baseY, bZ)
        elseif t == "terminator" then buildTerminator(bX, builder.baseY, bZ)
        elseif t == "tigr" then buildTigr(bX, builder.baseY, bZ)
        elseif t == "s400" then buildS400(bX, builder.baseY, bZ)
        elseif t == "pantsir" then buildPantsir(bX, builder.baseY, bZ)
        elseif t == "iskander" then buildIskander(bX, builder.baseY, bZ)
        elseif t == "smerch" then buildSmerch(bX, builder.baseY, bZ)
        elseif t == "grad" then buildGrad(bX, builder.baseY, bZ)
        elseif t == "ural" then buildUral(bX, builder.baseY, bZ)
        elseif t == "kamaz" then buildKamaz(bX, builder.baseY, bZ)
        elseif t == "mi24" then buildMi24(bX, builder.baseY, bZ)
        elseif t == "ka52" then buildKa52(bX, builder.baseY, bZ)
        elseif t == "su34" then buildSu34(bX, builder.baseY, bZ)
        elseif t == "soldier" then buildSoldier(bX, builder.baseY, bZ)
        elseif t == "flag" then buildFlagRF(bX, builder.baseY, bZ)
        elseif t == "monument" then buildMonument(bX, builder.baseY, bZ)
        elseif t == "barricade" then buildBarricade(bX, builder.baseY, bZ)
        elseif t == "checkpoint" then buildCheckpoint(bX, builder.baseY, bZ)
        end
    end
end

local function onKeyDown(input)
    if not builder.active then return end
    if input.KeyCode == Enum.KeyCode.R then
        builder.rotation = (builder.rotation + 90) % 360
        updatePreview()
    elseif input.KeyCode == Enum.KeyCode.T then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            builder.baseY = math.max(0, builder.baseY - 1)
        end
        updatePreview()
    elseif input.KeyCode == Enum.KeyCode.Escape then
        builder.active = false
        clearPreview()
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
gui.Name = "MegaBuilderGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 550, 0, 650)
main.Position = UDim2.new(0.5, -275, 0.02, 0)
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
title.Text = "🇷🇺 МЕГА-СТРОИТЕЛЬ v50.0"
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

local tabNames = {"🎨 Арты", "📐 Схема", "🏗️ Здания", "🚁 Техника", "🪖 Люди/Флаг", "🚧 Баррикады"}
local tabBtns = {}
for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 85, 0, 24)
    btn.Position = UDim2.new(0, (i-1)*87, 0, 0)
    btn.Text = name
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(0,100,200) or Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Code
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = tabsFrame
    tabBtns[i] = btn
end

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -105)
content.Position = UDim2.new(0, 10, 0, 65)
content.BackgroundTransparency = 1
content.Parent = main

local tabs = {}

-- Вкладка 1: АРТЫ
local tab1 = Instance.new("Frame")
tab1.Size = UDim2.new(1, 0, 1, 0)
tab1.BackgroundTransparency = 1
tab1.Parent = content
tabs[1] = tab1

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
local artBox = Instance.new("TextBox")
artBox.Size = UDim2.new(1, 0, 0, 380)
artBox.Position = UDim2.new(0, 0, 0, y)
artBox.Text = "#FF0000 #00FF00 #0000FF"
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
    for s in artBox.Text:gmatch("%S+") do table.insert(hexes, s) end
    if #hexes ~= w * h then print("❌ Нужно "..(w*h)..", есть "..#hexes); return end
    local colors = {}
    for _, hx in ipairs(hexes) do
        local c = parseHex(hx); if not c then print("❌ "..hx); return end
        table.insert(colors, c)
    end
    builder.artWidth = w; builder.artHeight = h; builder.artColors = colors
    builder.rotation = 0; builder.baseY = 0; builder.active = true
    updatePreview()
    print("✅ Арт готов")
end)

-- Вкладка 2: СХЕМА
local tab2 = Instance.new("Frame")
tab2.Size = UDim2.new(1, 0, 1, 0)
tab2.BackgroundTransparency = 1
tab2.Visible = false
tab2.Parent = content
tabs[2] = tab2
local schemaBox = Instance.new("TextBox")
schemaBox.Size = UDim2.new(1, 0, 0, 430)
schemaBox.Position = UDim2.new(0, 0, 0, 5)
schemaBox.Text = "brick#CC9966 brick#CC9966 brick#CC9966\nbrick#CC9966 glass#88DDFF brick#CC9966\nbrick#CC9966 door#AA7744 brick#CC9966"
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
local schemaBtn = Instance.new("TextButton")
schemaBtn.Size = UDim2.new(1, 0, 0, 40)
schemaBtn.Position = UDim2.new(0, 0, 0, 445)
schemaBtn.Text = "📐 Построить схему"
schemaBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
schemaBtn.TextColor3 = Color3.new(1,1,1)
schemaBtn.Font = Enum.Font.Code
schemaBtn.TextSize = 13
schemaBtn.BorderSizePixel = 0
schemaBtn.Parent = tab2
schemaBtn.MouseButton1Click:Connect(function()
    builder.mode = "schema"
    local layers = parseSchema(schemaBox.Text)
    if #layers == 0 then print("❌ Пусто"); return end
    builder.schemaData = layers
    builder.rotation = 0; builder.baseY = 0; builder.active = true
    updatePreview()
    print("✅ Схема готова")
end)

-- Вкладка 3: ЗДАНИЯ
local tab3 = Instance.new("Frame")
tab3.Size = UDim2.new(1, 0, 1, 0)
tab3.BackgroundTransparency = 1
tab3.Visible = false
tab3.Parent = content
tabs[3] = tab3
local scroll3 = Instance.new("ScrollingFrame")
scroll3.Size = UDim2.new(1, 0, 1, 0)
scroll3.BackgroundTransparency = 1
scroll3.CanvasSize = UDim2.new(0, 0, 0, 500)
scroll3.ScrollBarThickness = 6
scroll3.Parent = tab3
y = 5
local buildingsList = {
    {name = "🏠 Дом (7x7x5)", key = "house", defW=7, defD=7, defH=5},
    {name = "🏪 Магазин (8x6x4)", key = "shop", defW=8, defD=6, defH=4},
    {name = "🏢 Небоскрёб (9x9x20)", key = "skyscraper", defW=9, defD=9, defH=20},
    {name = "🏰 Замок (14x14x6)", key = "castle", defW=14, defD=14, defH=6},
    {name = "🌳 Дерево", key = "tree"},
    {name = "🌲 Ёлка", key = "pine"},
    {name = "🪑 Скамейка", key = "bench"},
    {name = "⛲ Фонтан", key = "fountain"},
    {name = "💡 Фонарь", key = "lamp"},
    {name = "🌿 Куст", key = "bush"},
    {name = "🌷 Клумба", key = "flowerbed"},
    {name = "🚧 Забор", key = "fence"},
    {name = "🕳️ Колодец", key = "well"},
}
for _, item in ipairs(buildingsList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.Text = item.name
    btn.BackgroundColor3 = Color3.fromRGB(100, 60, 40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = scroll3
    btn.MouseButton1Click:Connect(function()
        builder.mode = "tech"
        builder.techType = item.key
        builder.width = item.defW or 0
        builder.depth = item.defD or 0
        builder.height = item.defH or 0
        builder.rotation = 0; builder.baseY = 0; builder.active = true
        updatePreview()
        print("✅ "..item.name.." готов")
    end)
    y = y + 45
end

-- Вкладка 4: ТЕХНИКА
local tab4 = Instance.new("Frame")
tab4.Size = UDim2.new(1, 0, 1, 0)
tab4.BackgroundTransparency = 1
tab4.Visible = false
tab4.Parent = content
tabs[4] = tab4
local scroll4 = Instance.new("ScrollingFrame")
scroll4.Size = UDim2.new(1, 0, 1, 0)
scroll4.BackgroundTransparency = 1
scroll4.CanvasSize = UDim2.new(0, 0, 0, 2000)
scroll4.ScrollBarThickness = 6
scroll4.Parent = tab4
y = 5
local techList = {
    {name = "🚁 Т-72", key = "t72"},
    {name = "🚁 Т-90", key = "t90"},
    {name = "🚁 Т-14 Армата", key = "t14"},
    {name = "🚁 Т-80", key = "t80"},
    {name = "🚁 БМП-2", key = "bmp2"},
    {name = "🚁 БМП-3", key = "bmp3"},
    {name = "🚁 БТР-80", key = "btr80"},
    {name = "🚁 БТР-82А", key = "btr82a"},
    {name = "🚁 БМПТ Терминатор", key = "terminator"},
    {name = "🚁 Тигр", key = "tigr"},
    {name = "🚁 С-400", key = "s400"},
    {name = "🚁 Панцирь-С1", key = "pantsir"},
    {name = "🚁 Искандер", key = "iskander"},
    {name = "🚁 Смерч", key = "smerch"},
    {name = "🚁 Град", key = "grad"},
    {name = "🚁 Урал", key = "ural"},
    {name = "🚁 Камаз", key = "kamaz"},
    {name = "🚁 Ми-24", key = "mi24"},
    {name = "🚁 Ка-52", key = "ka52"},
    {name = "🚁 Су-34", key = "su34"},
}
for _, item in ipairs(techList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.Text = item.name
    btn.BackgroundColor3 = GREEN
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = scroll4
    btn.MouseButton1Click:Connect(function()
        builder.mode = "tech"
        builder.techType = item.key
        builder.rotation = 0; builder.baseY = 0; builder.active = true
        updatePreview()
        print("✅ "..item.name.." готов")
    end)
    y = y + 45
end

-- Вкладка 5: ЛЮДИ/ФЛАГ
local tab5 = Instance.new("Frame")
tab5.Size = UDim2.new(1, 0, 1, 0)
tab5.BackgroundTransparency = 1
tab5.Visible = false
tab5.Parent = content
tabs[5] = tab5
y = 5
local humansList = {
    {name = "🪖 Российский солдат", key = "soldier"},
    {name = "🇷🇺 Флаг РФ", key = "flag"},
    {name = "🗿 Памятник", key = "monument"},
}
for _, item in ipairs(humansList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 60)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.Text = item.name
    btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = tab5
    btn.MouseButton1Click:Connect(function()
        builder.mode = "tech"
        builder.techType = item.key
        builder.rotation = 0; builder.baseY = 0; builder.active = true
        updatePreview()
        print("✅ "..item.name.." готов")
    end)
    y = y + 70
end

-- Вкладка 6: БАРРИКАДЫ
local tab6 = Instance.new("Frame")
tab6.Size = UDim2.new(1, 0, 1, 0)
tab6.BackgroundTransparency = 1
tab6.Visible = false
tab6.Parent = content
tabs[6] = tab6
y = 5
local barricadeList = {
    {name = "🚧 Баррикада", key = "barricade"},
    {name = "🚧 Блокпост", key = "checkpoint"},
}
for _, item in ipairs(barricadeList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 60)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.Text = item.name
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = tab6
    btn.MouseButton1Click:Connect(function()
        builder.mode = "tech"
        builder.techType = item.key
        builder.rotation = 0; builder.baseY = 0; builder.active = true
        updatePreview()
        print("✅ "..item.name.." готов")
    end)
    y = y + 70
end

local function setTab(n)
    for i, tab in ipairs(tabs) do
        tab.Visible = (i == n)
        tabBtns[i].BackgroundColor3 = (i == n) and Color3.fromRGB(0,100,200) or Color3.fromRGB(60,60,60)
    end
    if n == 1 then builder.mode = "art"
    elseif n == 2 then builder.mode = "schema"
    else builder.mode = "tech" end
end

for i, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() setTab(i) end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.Escape then
        onKeyDown(input)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        onMouseClick()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        if builder.active then
            builder.active = false; clearPreview(); print("❌ Отменено")
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

print("🇷🇺 МЕГА-СТРОИТЕЛЬ v50.0 загружен!")
print("Вкладки: 🎨 Арты | 📐 Схема | 🏗️ Здания | 🚁 Техника | 🪖 Люди | 🚧 Баррикады")
