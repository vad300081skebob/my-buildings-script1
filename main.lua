-- ============ СТРОИТЕЛЬ v21.0 — ЗДАНИЯ + ДЕКОРАЦИИ + АРТЫ ============

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer or Players:GetPlayers()[1]
if not LocalPlayer then warn("LocalPlayer не найден"); return end

local MATERIALS = {
    "Default", "Glass", "Diamond Plate", "Fabric", "Grass", "Ice",
    "Sand", "Wood", "Wooden Planks", "Foil", "Metal", "Brick",
    "Concrete", "Marble", "Granite", "Slate", "Corroded Metal", "Force Field"
}

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

-- ============ ОБЩИЕ ФУНКЦИИ ПОСТРОЙКИ ============

local function buildWalls(bx, by, bz, w, d, h, wall, glass, door, colorWall, colorGlass, colorDoor)
    colorWall = colorWall or Color3.fromRGB(200,180,160)
    colorGlass = colorGlass or Color3.fromRGB(100,200,255)
    colorDoor = colorDoor or Color3.fromRGB(150,100,50)
    local dX = math.floor(w/2)
    for y = 0, h-1 do
        for x = 0, w-1 do
            for z = 0, d-1 do
                if x == 0 or x == w-1 or z == 0 or z == d-1 then
                    if z == 0 and x == dX and y < 2 then
                        placeBlock(bx+x, by+y, bz+z, colorDoor, door, 75)
                    elseif (z == 0 or z == d-1) and y >= 1 and y <= 2 and (x == dX-2 or x == dX+2 or x == 1 or x == w-2) then
                        placeBlock(bx+x, by+y, bz+z, colorGlass, glass, 82)
                    else
                        placeBlock(bx+x, by+y, bz+z, colorWall, wall, 43)
                    end
                end
            end
        end
    end
end

local function buildFloorRoof(bx, by, bz, w, d, h, floor, roof, colorFloor, colorRoof)
    colorFloor = colorFloor or Color3.fromRGB(180,150,100)
    colorRoof = colorRoof or Color3.fromRGB(150,80,50)
    for x = 0, w-1 do for z = 0, d-1 do
        placeBlock(bx+x, by, bz+z, colorFloor, floor, 43)
        placeBlock(bx+x, by+h, bz+z, colorFloor, floor, 43)
        placeBlock(bx+x, by+h+1, bz+z, colorRoof, roof, 43)
    end end
end

-- ============ 🏠 ДОМА ============

local function buildSmallHouse(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏠 Одноэтажный дом...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(100,100,100), "Concrete", 43)
    end end
    buildWalls(bx,by,bz,w,d,h,wall,glass,door)
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof)
    print("✅ Дом готов!")
end

local function buildCottage(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏡 Двухэтажный коттедж...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(100,100,100), "Concrete", 43)
    end end
    buildWalls(bx,by,bz,w,d,h,wall,glass,door)
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof)
    -- Балкон
    local midY = math.floor(h/2)
    for x = -2, -1 do
        placeBlock(bx+x, by+midY, bz+1, Color3.fromRGB(150,100,50), "Wooden Planks", 43)
    end
    -- Перила
    for x = -2, -1 do
        placeBlock(bx+x, by+midY+1, bz+1, Color3.fromRGB(100,70,40), "Wood", 43)
    end
    print("✅ Коттедж готов!")
end

local function buildHutSmall(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏚️ Хижина...")
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(160,130,100), wall, 43)
        end
    end end end
    for y = 1, 3 do for x = y-1, w-y do for z = y-1, d-y do
        if x == y-1 or x == w-y or z == y-1 or z == d-y then
            placeBlock(bx+x, by+h+y-1, bz+z, Color3.fromRGB(180,150,80), roof, 43)
        end
    end end end
    print("✅ Хижина готова!")
end

local function buildBungalow(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏘️ Бунгало...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(150,140,120), "Sand", 43)
    end end
    buildWalls(bx,by,bz,w,d,h,wall,glass,door)
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof)
    -- Плоская крыша с выходом
    for x = 2, w-3 do for z = 2, d-3 do
        placeBlock(bx+x, by+h+2, bz+z, Color3.fromRGB(200,180,150), "Concrete", 43)
    end end
    print("✅ Бунгало готово!")
end

-- ============ 🏢 МАГАЗИНЫ И ТЦ ============

local function buildShop(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏪 Магазин...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(120,120,120), "Concrete", 43)
    end end
    buildWalls(bx,by,bz,w,d,h,wall,glass,door)
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof)
    -- Витрина (спереди стеклянная)
    for x = 1, w-2 do
        placeBlock(bx+x, by+1, bz, Color3.fromRGB(150,220,255), "Glass", 82)
        placeBlock(bx+x, by+2, bz, Color3.fromRGB(150,220,255), "Glass", 82)
    end
    -- Вывеска
    placeBlock(bx+math.floor(w/2), by+h+2, bz, Color3.fromRGB(255,100,100), "Neon", 33)
    print("✅ Магазин готов!")
end

local function buildMall(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏬 Торговый центр...")
    for x = -2, w+1 do for z = -2, d+1 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(100,100,100), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if y >= 1 and y <= 3 and (x % 3 == 0 or z % 3 == 0) then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,220,255), glass, 82)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(220,220,230), wall, 43)
            end
        end
    end end end
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof, Color3.fromRGB(180,180,180), Color3.fromRGB(80,80,80))
    -- Вход
    local dX = math.floor(w/2)
    for x = dX-1, dX+1 do
        for y = 0, 3 do
            placeBlock(bx+x, by+y, bz, Color3.fromRGB(100,200,255), "Glass", 82)
        end
    end
    print("✅ ТЦ готов!")
end

local function buildCafe(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("☕ Кафе...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(150,120,90), "Wooden Planks", 43)
    end end
    buildWalls(bx,by,bz,w,d,h,wall,glass,door)
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof, Color3.fromRGB(120,80,50), Color3.fromRGB(180,100,50))
    -- Зонтики снаружи
    for _, off in ipairs({{-2,2},{w+1,2}}) do
        placeBlock(bx+off[1], by+h+2, bz+off[2], Color3.fromRGB(220,50,50), "Fabric", 43)
        placeBlock(bx+off[1], by+h+1, bz+off[2], Color3.fromRGB(220,50,50), "Fabric", 43)
    end
    print("✅ Кафе готово!")
end

local function buildSupermarket(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🛒 Супермаркет...")
    for x = -2, w+1 do for z = -2, d+1 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(100,100,100), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if y == 1 or y == 2 then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,220,255), glass, 82)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(230,230,230), wall, 43)
            end
        end
    end end end
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof, Color3.fromRGB(200,200,200), Color3.fromRGB(70,70,70))
    print("✅ Супермаркет готов!")
end

-- ============ 🏬 МНОГОЭТАЖКИ ============

local function buildPanelHouse(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏢 Панельный дом...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(80,80,80), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            -- Окна через каждые 2 блока
            if y >= 1 and y <= h-2 and (x % 2 == 0 or z % 2 == 0) and y % 2 == 1 then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,220,255), glass, 82)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(180,180,180), wall, 43)
            end
        end
    end end end
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof, Color3.fromRGB(150,150,150), Color3.fromRGB(100,100,100))
    print("✅ Панельный дом готов!")
end

local function buildFiveStory(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏢 Пятиэтажка...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(90,90,90), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if y == 0 and z == 0 and x == math.floor(w/2) then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,100,50), door, 75)
            elseif y >= 1 and (y % 2 == 1) then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,220,255), glass, 82)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(200,180,150), wall, 43)
            end
        end
    end end end
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof, Color3.fromRGB(180,160,130), Color3.fromRGB(120,80,60))
    print("✅ Пятиэтажка готова!")
end

local function buildTenStory(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏢 Десятиэтажка...")
    for x = -2, w+1 do for z = -2, d+1 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(80,80,80), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if y == 0 and z == 0 and x == math.floor(w/2) then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(100,150,220), "Glass", 75)
            elseif y >= 1 and y % 2 == 1 then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(140,200,255), glass, 82)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(180,180,200), wall, 43)
            end
        end
    end end end
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof, Color3.fromRGB(160,160,170), Color3.fromRGB(70,70,90))
    print("✅ Десятиэтажка готова!")
end

local function buildSkyscraper(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏙️ Небоскрёб...")
    for x = -2, w+1 do for z = -2, d+1 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(60,60,60), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if y % 2 == 0 then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,220,255), glass, 82)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(80,80,100), wall, 43)
            end
        end
    end end end
    for x = 0, w-1 do for z = 0, d-1 do
        placeBlock(bx+x, by+h, bz+z, Color3.fromRGB(100,100,120), floor, 43)
    end end
    -- Антенна
    for y = 1, 6 do
        placeBlock(bx+math.floor(w/2), by+h+y, bz+math.floor(d/2), Color3.fromRGB(200,50,50), "Metal", 46)
    end
    print("✅ Небоскрёб готов!")
end

-- ============ 🏛️ ОБЩЕСТВЕННЫЕ ============

local function buildSchool(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏫 Школа...")
    for x = -2, w+1 do for z = -2, d+1 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(120,120,120), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if y >= 1 and y <= h-2 and x % 2 == 0 then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(150,220,255), glass, 82)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(240,220,180), wall, 43)
            end
        end
    end end end
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof, Color3.fromRGB(200,180,150), Color3.fromRGB(160,60,60))
    print("✅ Школа готова!")
end

local function buildHospital(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏥 Больница...")
    for x = -2, w+1 do for z = -2, d+1 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(120,120,120), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if y % 2 == 0 then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(200,240,255), glass, 82)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(240,240,240), wall, 43)
            end
        end
    end end end
    buildFloorRoof(bx,by,bz,w,d,h,floor,roof, Color3.fromRGB(220,220,220), Color3.fromRGB(220,50,50))
    -- Красный крест
    local mx = math.floor(w/2)
    for x = mx-1, mx+1 do
        placeBlock(bx+x, by+h-2, bz, Color3.fromRGB(255,50,50), "Default", 43)
    end
    for y = h-3, h-1 do
        placeBlock(bx+mx, by+y, bz, Color3.fromRGB(255,50,50), "Default", 43)
    end
    print("✅ Больница готова!")
end

local function buildChurch(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("⛪ Церковь...")
    for x = -2, w+1 do for z = -2, d+1 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(100,100,100), "Concrete", 43)
    end end
    buildWalls(bx,by,bz,w,d,h,wall,glass,door)
    for y = 1, 4 do for x = y-1, w-y do for z = y-1, d-y do
        if x == y-1 or x == w-y or z == y-1 or z == d-y then
            placeBlock(bx+x, by+h+y-1, bz+z, Color3.fromRGB(150,100,60), roof, 43)
        end
    end end end
    -- Шпиль
    for y = 1, 4 do
        local sz = math.max(0, 2 - y)
        for x = -sz, sz do for z = -sz, sz do
            if math.abs(x) == sz or math.abs(z) == sz then
                placeBlock(bx+math.floor(w/2)+x, by+h+4+y, bz+math.floor(d/2)+z, Color3.fromRGB(150,100,60), roof, 43)
            end
        end end
    end
    print("✅ Церковь готова!")
end

local function buildCastle(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏰 Замок...")
    for x = -3, w+2 do for z = -3, d+2 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(80,80,80), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(180,160,140), wall, 43)
        end
    end end end
    for x = 0, w-1 do for z = 0, d-1 do
        if (x == 0 or x == w-1 or z == 0 or z == d-1) and x % 2 == 0 and z % 2 == 0 then
            placeBlock(bx+x, by+h, bz+z, Color3.fromRGB(180,160,140), wall, 43)
        end
    end end
    for _, t in ipairs({{0,0},{w-1,0},{0,d-1},{w-1,d-1}}) do
        local tx, tz = t[1], t[2]
        for y = 0, h+2 do for x = -2, 2 do for z = -2, 2 do
            if math.abs(x) == 2 or math.abs(z) == 2 then
                placeBlock(bx+tx+x, by+y, bz+tz+z, Color3.fromRGB(180,160,140), wall, 43)
            end
        end end end
        for x = -2, 2 do for z = -2, 2 do
            placeBlock(bx+tx+x, by+h+3, bz+tz+z, Color3.fromRGB(120,60,40), roof, 43)
        end end
    end
    print("✅ Замок готов!")
end

local function buildTemple(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🏛️ Храм...")
    for x = -3, w+2 do for z = -3, d+2 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(150,150,150), "Marble", 43)
    end end
    for s = 1, 3 do
        for x = -s, w-1+s do
            placeBlock(bx+x, by+s-1, bz-s, Color3.fromRGB(220,220,220), "Marble", 43)
        end
    end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(240,235,220), wall, 43)
        end
    end end end
    -- Колонны
    for x = 0, w-1 do
        if x % 2 == 0 then
            for y = 0, h do
                placeBlock(bx+x, by+y, bz-2, Color3.fromRGB(220,220,220), "Marble", 43)
                placeBlock(bx+x, by+y, bz+d+1, Color3.fromRGB(220,220,220), "Marble", 43)
            end
        end
    end
    for y = 1, 3 do for x = y-1, w-y do for z = y-1, d-y do
        if x == y-1 or x == w-y or z == y-1 or z == d-y then
            placeBlock(bx+x, by+h+y-1, bz+z, Color3.fromRGB(200,180,160), roof, 43)
        end
    end end end
    print("✅ Храм готов!")
end

-- ============ 🗼 СПЕЦСООРУЖЕНИЯ ============

local function buildTower(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🗼 Вышка...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(100,100,100), "Concrete", 43)
    end end
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x == 0 or x == w-1 or z == 0 or z == d-1 then
            if y % 2 == 0 then
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(100,200,255), glass, 82)
            else
                placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(200,200,200), wall, 43)
            end
        end
    end end end
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by+h, bz+z, Color3.fromRGB(150,100,50), roof, 43)
    end end
    for y = 1, 3 do
        placeBlock(bx+math.floor(w/2), by+h+y, bz+math.floor(d/2), Color3.fromRGB(255,200,50), "Metal", 46)
    end
    print("✅ Вышка готова!")
end

local function buildLighthouse(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🗽 Маяк...")
    for x = -2, w+1 do for z = -2, d+1 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(80,80,80), "Concrete", 43)
    end end
    for y = 0, h-1 do
        local off = math.floor(y / 3)
        for x = off, w-1-off do for z = off, d-1-off do
            if x == off or x == w-1-off or z == off or z == d-1-off then
                if y >= h-2 then
                    placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(100,200,255), glass, 82)
                else
                    placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(220,60,60), wall, 43)
                end
            end
        end end
    end
    for x = -1, 1 do for z = -1, 1 do
        placeBlock(bx+math.floor(w/2)+x, by+h, bz+math.floor(d/2)+z, Color3.fromRGB(255,255,150), "Glass", 33)
    end end
    print("✅ Маяк готов!")
end

local function buildBridge(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🌉 Мост...")
    -- Опора
    for y = 0, h-1 do for x = 0, w-1 do for z = 0, d-1 do
        if x % 4 == 0 then
            placeBlock(bx+x, by-y, bz+z, Color3.fromRGB(150,150,150), "Concrete", 43)
        end
    end end end
    -- Пол
    for x = 0, w-1 do for z = 0, d-1 do
        placeBlock(bx+x, by, bz+z, Color3.fromRGB(120,120,120), "Concrete", 43)
    end end
    -- Перила
    for x = 0, w-1 do
        placeBlock(bx+x, by+1, bz, Color3.fromRGB(200,200,200), "Metal", 43)
        placeBlock(bx+x, by+1, bz+d-1, Color3.fromRGB(200,200,200), "Metal", 43)
    end
    print("✅ Мост готов!")
end

local function buildStatue(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🗿 Статуя...")
    for x = -1, w do for z = -1, d do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(150,150,150), "Marble", 43)
    end end
    -- Постамент
    for y = 0, 1 do for x = 0, w-1 do for z = 0, d-1 do
        placeBlock(bx+x, by+y, bz+z, Color3.fromRGB(200,200,200), "Marble", 43)
    end end end
    -- Фигура (упрощённая)
    local mx, mz = math.floor(w/2), math.floor(d/2)
    for y = 2, h do
        placeBlock(bx+mx, by+y, bz+mz, Color3.fromRGB(180,180,180), "Marble", 43)
    end
    -- Голова
    placeBlock(bx+mx, by+h+1, bz+mz, Color3.fromRGB(180,180,180), "Marble", 43)
    -- Руки
    placeBlock(bx+mx-1, by+h-1, bz+mz, Color3.fromRGB(180,180,180), "Marble", 43)
    placeBlock(bx+mx+1, by+h-1, bz+mz, Color3.fromRGB(180,180,180), "Marble", 43)
    print("✅ Статуя готова!")
end

-- ============ 🌳 ДЕКОРАЦИИ ============

local function buildTree(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🌳 Дерево...")
    local mx, mz = math.floor(w/2), math.floor(d/2)
    -- Ствол
    for y = 0, h-1 do
        placeBlock(bx+mx, by+y, bz+mz, Color3.fromRGB(90,60,30), "Wood", 43)
    end
    -- Крона
    for y = h, h+3 do
        local r = h + 3 - y + 2
        for x = -r, r do for z = -r, r do
            if x*x + z*z <= r*r then
                placeBlock(bx+mx+x, by+y, bz+mz+z, Color3.fromRGB(50,150,50), "Grass", 43)
            end
        end end
    end
    print("✅ Дерево готово!")
end

local function buildPineTree(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🌲 Ёлка...")
    local mx, mz = math.floor(w/2), math.floor(d/2)
    for y = 0, h-1 do
        placeBlock(bx+mx, by+y, bz+mz, Color3.fromRGB(70,50,30), "Wood", 43)
    end
    -- Конус
    for y = 2, h+3 do
        local r = math.max(0, math.floor((h+3 - y) / 2))
        for x = -r, r do for z = -r, r do
            if x*x + z*z <= r*r then
                placeBlock(bx+mx+x, by+y, bz+mz+z, Color3.fromRGB(30,100,40), "Grass", 43)
            end
        end end
    end
    print("✅ Ёлка готова!")
end

local function buildBench(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🪑 Скамейка...")
    for x = 0, w-1 do
        placeBlock(bx+x, by, bz, Color3.fromRGB(120,80,50), "Wooden Planks", 43)
    end
    for x = 0, w-1 do
        placeBlock(bx+x, by+1, bz-1, Color3.fromRGB(120,80,50), "Wooden Planks", 43)
        placeBlock(bx+x, by+2, bz-1, Color3.fromRGB(120,80,50), "Wooden Planks", 43)
    end
    -- Ножки
    placeBlock(bx, by-1, bz, Color3.fromRGB(80,50,30), "Wood", 43)
    placeBlock(bx+w-1, by-1, bz, Color3.fromRGB(80,50,30), "Wood", 43)
    print("✅ Скамейка готова!")
end

local function buildFountain(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("⛲ Фонтан...")
    local mx, mz = math.floor(w/2), math.floor(d/2)
    -- Чаша
    for x = -2, 2 do for z = -2, 2 do
        if math.abs(x) == 2 or math.abs(z) == 2 then
            placeBlock(bx+mx+x, by, bz+mz+z, Color3.fromRGB(200,200,200), "Marble", 43)
        end
    end end
    for x = -2, 2 do for z = -2, 2 do
        if math.abs(x) < 2 and math.abs(z) < 2 then
            placeBlock(bx+mx+x, by, bz+mz+z, Color3.fromRGB(100,180,255), "Glass", 43)
        end
    end end
    -- Колонна в центре
    for y = 1, 2 do
        placeBlock(bx+mx, by+y, bz+mz, Color3.fromRGB(220,220,220), "Marble", 43)
    end
    -- Струи воды
    placeBlock(bx+mx, by+3, bz+mz, Color3.fromRGB(150,200,255), "Glass", 33)
    placeBlock(bx+mx-1, by+3, bz+mz, Color3.fromRGB(150,200,255), "Glass", 33)
    placeBlock(bx+mx+1, by+3, bz+mz, Color3.fromRGB(150,200,255), "Glass", 33)
    print("✅ Фонтан готов!")
end

local function buildLamp(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("💡 Фонарь...")
    local mx, mz = math.floor(w/2), math.floor(d/2)
    for y = 0, 3 do
        placeBlock(bx+mx, by+y, bz+mz, Color3.fromRGB(50,50,50), "Metal", 43)
    end
    placeBlock(bx+mx, by+4, bz+mz, Color3.fromRGB(255,240,180), "Glass", 33)
    -- Свет вокруг
    for _, off in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        placeBlock(bx+mx+off[1], by+4, bz+mz+off[2], Color3.fromRGB(255,240,180), "Glass", 33)
    end
    print("✅ Фонарь готов!")
end

local function buildBush(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🌿 Куст...")
    local mx, mz = math.floor(w/2), math.floor(d/2)
    for x = -1, 1 do for z = -1, 1 do for y = 0, 1 do
        if math.abs(x) + math.abs(z) + y <= 2 then
            placeBlock(bx+mx+x, by+y, bz+mz+z, Color3.fromRGB(60,130,60), "Grass", 43)
        end
    end end end
    print("✅ Куст готов!")
end

local function buildFlowerBed(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    print("🌷 Клумба...")
    for x = 0, w-1 do for z = 0, d-1 do
        placeBlock(bx+x, by-1, bz+z, Color3.fromRGB(120,80,40), "Wood", 43)
    end end
    local colors = {
        Color3.fromRGB(255,100,150),
        Color3.fromRGB(255,200,100),
        Color3.fromRGB(200,100,255),
        Color3.fromRGB(255,50,50)
    }
    for x = 0, w-1 do for z = 0, d-1 do
        if (x+z) % 2 == 0 then
            local c = colors[((x+z) % #colors) + 1]
            placeBlock(bx+x, by, bz+z, c, "Grass", 43)
        end
    end end
    print("✅ Клумба готова!")
end

-- ============ СЛОВАРИ ГРУПП ============

local BUILDING_GROUPS = {
    {
        name = "🏠 Дома",
        buildings = {
            {name = "🏠 Одноэтажный дом", func = buildSmallHouse, defW=7, defD=7, defH=4},
            {name = "🏡 Двухэтажный коттедж", func = buildCottage, defW=8, defD=8, defH=6},
            {name = "🏚️ Хижина", func = buildHutSmall, defW=5, defD=5, defH=3},
            {name = "🏘️ Бунгало", func = buildBungalow, defW=9, defD=7, defH=3},
        }
    },
    {
        name = "🏢 Магазины и ТЦ",
        buildings = {
            {name = "🏪 Магазин", func = buildShop, defW=8, defD=6, defH=4},
            {name = "🏬 Торговый центр", func = buildMall, defW=15, defD=12, defH=6},
            {name = "🛒 Супермаркет", func = buildSupermarket, defW=12, defD=10, defH=5},
            {name = "☕ Кафе", func = buildCafe, defW=7, defD=6, defH=4},
        }
    },
    {
        name = "🏢 Многоэтажки",
        buildings = {
            {name = "🏢 Панелька", func = buildPanelHouse, defW=6, defD=6, defH=9},
            {name = "🏢 Пятиэтажка", func = buildFiveStory, defW=7, defD=7, defH=5},
            {name = "🏢 Десятиэтажка", func = buildTenStory, defW=8, defD=8, defH=10},
            {name = "🏙️ Небоскрёб", func = buildSkyscraper, defW=9, defD=9, defH=20},
        }
    },
    {
        name = "🏛️ Общественные",
        buildings = {
            {name = "🏫 Школа", func = buildSchool, defW=12, defD=10, defH=4},
            {name = "🏥 Больница", func = buildHospital, defW=10, defD=10, defH=5},
            {name = "⛪ Церковь", func = buildChurch, defW=8, defD=8, defH=4},
            {name = "🏰 Замок", func = buildCastle, defW=14, defD=14, defH=6},
            {name = "🏛️ Храм", func = buildTemple, defW=10, defD=10, defH=5},
        }
    },
    {
        name = "🗼 Спецсооружения",
        buildings = {
            {name = "🗼 Вышка", func = buildTower, defW=5, defD=5, defH=10},
            {name = "🗽 Маяк", func = buildLighthouse, defW=6, defD=6, defH=12},
            {name = "🌉 Мост", func = buildBridge, defW=15, defD=4, defH=3},
            {name = "🗿 Статуя", func = buildStatue, defW=5, defD=5, defH=8},
        }
    },
    {
        name = "🌳 Декорации",
        buildings = {
            {name = "🌳 Дерево", func = buildTree, defW=5, defD=5, defH=5},
            {name = "🌲 Ёлка", func = buildPineTree, defW=5, defD=5, defH=6},
            {name = "🪑 Скамейка", func = buildBench, defW=3, defD=2, defH=1},
            {name = "⛲ Фонтан", func = buildFountain, defW=5, defD=5, defH=1},
            {name = "💡 Фонарь", func = buildLightLamp, defW=1, defD=1, defH=1},
            {name = "🌿 Куст", func = buildBush, defW=3, defD=3, defH=1},
            {name = "🌷 Клумба", func = buildFlowerBed, defW=4, defD=4, defH=1},
        }
    }
}

-- Заглушка для фонаря (функция объявлена, но в этой части)
local function buildLightLamp(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
    buildLamp(bx, by, bz, w, d, h, wall, floor, roof, glass, door)
end

-- ============ BUILDER STATE ============
local builder = {
    active = false,
    previewParts = {},
    rotation = 0,
    baseY = 0,
    mode = "buildings",
    buildingType = "🏠 Одноэтажный дом",
    buildingFunc = buildSmallHouse,
    width = 7, depth = 7, height = 4,
    wallMat = "Brick", floorMat = "Wood", roofMat = "Slate",
    glassMat = "Glass", doorMat = "Wood",
    artWidth = 10, artHeight = 10,
    artColors = {},
    previewInitialized = false
}

-- ============ PREVIEW ============
local function createPreview(color, pos, transparency)
    local p = Instance.new("Part")
    p.Size = Vector3.new(GrandeurBloc * 0.95, GrandeurBloc * 0.95, GrandeurBloc * 0.95)
    p.Anchored = true
    p.CanCollide = false
    p.Transparency = transparency or 0.5
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
    builder.previewInitialized = false
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
    local char = LocalPlayer.Character
    if char and char.PrimaryPart then
        local look = char.PrimaryPart.CFrame.LookVector
        local pos = char.PrimaryPart.Position + look * 5
        return Vector3.new(
            MathRound((pos.X - PositionOrigin.X) / GrandeurBloc),
            0,
            MathRound((pos.Z - PositionOrigin.Z) / GrandeurBloc)
        )
    end
    return Vector3.new(0, 0, 0)
end

local function updatePreview()
    if not builder.active then return end
    clearPreview()
    local baseGrid = getMouseGrid()
    local rot = builder.rotation
    local parts = {}

    if builder.mode == "buildings" then
        local w, d, h = builder.width, builder.depth, builder.height
        local bX, bZ = baseGrid.X, baseGrid.Z
        for x = -2, w + 1 do
            for z = -2, d + 1 do
                for y = -1, h + 5 do
                    local wx, wz = bX + x, bZ + z
                    if rot == 90 then wx, wz = bX - z, bZ + x
                    elseif rot == 180 then wx, wz = bX - x, bZ - z
                    elseif rot == 270 then wx, wz = bX + z, bZ - x end
                    local color
                    if y == -1 then color = Color3.fromRGB(80,80,80)
                    elseif y > h then color = Color3.fromRGB(200,100,50)
                    elseif y == h then color = Color3.fromRGB(200,200,200)
                    elseif y == 0 then color = Color3.fromRGB(150,100,50)
                    elseif x == 0 or x == w-1 or z == 0 or z == d-1 then color = Color3.fromRGB(200,180,160)
                    else color = Color3.fromRGB(100,100,100) end
                    table.insert(parts, {color = color, pos = gridToWorld(Vector3.new(wx, builder.baseY + y, wz))})
                end
            end
        end
    elseif builder.mode == "art" then
        local w, h = builder.artWidth, builder.artHeight
        local bX, bZ = baseGrid.X, baseGrid.Z
        local idx = 1
        for row = 0, h - 1 do
            for col = 0, w - 1 do
                local localX, localZ = col, row
                local wx, wz
                if rot == 0 then wx, wz = bX + localX, bZ + localZ
                elseif rot == 90 then wx, wz = bX - localZ, bZ + localX
                elseif rot == 180 then wx, wz = bX - localX, bZ - localZ
                else wx, wz = bX + localZ, bZ - localX end
                local color = builder.artColors[idx] or Color3.new(1,1,1)
                table.insert(parts, {color = color, pos = gridToWorld(Vector3.new(wx, builder.baseY, wz))})
                idx = idx + 1
            end
        end
    end

    for _, data in ipairs(parts) do
        table.insert(builder.previewParts, createPreview(data.color, data.pos, 0.5))
    end
    builder.previewInitialized = true
end

local function onMouseClick()
    if not builder.active then return end
    builder.active = false
    clearPreview()
    local baseGrid = getMouseGrid()

    if builder.mode == "buildings" then
        if builder.buildingFunc then
            builder.buildingFunc(baseGrid.X, builder.baseY, baseGrid.Z,
                builder.width, builder.depth, builder.height,
                builder.wallMat, builder.floorMat, builder.roofMat,
                builder.glassMat, builder.doorMat)
        end
    elseif builder.mode == "art" then
        print("🎨 Строим арт "..builder.artWidth.."x"..builder.artHeight)
        local w, h = builder.artWidth, builder.artHeight
        local bX, bZ = baseGrid.X, baseGrid.Z
        local rot = builder.rotation
        local idx = 1
        for row = h - 1, 0, -1 do
            for col = 0, w - 1 do
                local color = builder.artColors[idx]
                if color then
                    local localX, localZ = col, row
                    local wx, wz
                    if rot == 0 then wx, wz = bX + localX, bZ + localZ
                    elseif rot == 90 then wx, wz = bX - localZ, bZ + localX
                    elseif rot == 180 then wx, wz = bX - localX, bZ - localZ
                    else wx, wz = bX + localZ, bZ - localX end
                    placeBlock(wx, builder.baseY, wz, color, "Default", 43)
                end
                idx = idx + 1
            end
        end
        print("✅ Арт построен!")
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
main.Size = UDim2.new(0, 450, 0, 650)
main.Position = UDim2.new(0.5, -225, 0.02, 0)
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
title.Text = "🏗️ СТРОИТЕЛЬ v21.0"
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

-- Перемещение
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

-- Вкладки
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -20, 0, 26)
tabsFrame.Position = UDim2.new(0, 10, 0, 35)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = main

local tabBtn1 = Instance.new("TextButton")
tabBtn1.Size = UDim2.new(0, 200, 0, 24)
tabBtn1.Position = UDim2.new(0, 0, 0, 0)
tabBtn1.Text = "🏗️ Здания и Декорации"
tabBtn1.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
tabBtn1.TextColor3 = Color3.new(1,1,1)
tabBtn1.Font = Enum.Font.Code
tabBtn1.TextSize = 12
tabBtn1.BorderSizePixel = 0
tabBtn1.Parent = tabsFrame

local tabBtn2 = Instance.new("TextButton")
tabBtn2.Size = UDim2.new(0, 150, 0, 24)
tabBtn2.Position = UDim2.new(0, 205, 0, 0)
tabBtn2.Text = "🎨 Арты"
tabBtn2.BackgroundColor3 = Color3.fromRGB(60,60,60)
tabBtn2.TextColor3 = Color3.new(1,1,1)
tabBtn2.Font = Enum.Font.Code
tabBtn2.TextSize = 12
tabBtn2.BorderSizePixel = 0
tabBtn2.Parent = tabsFrame

-- Контент
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -105)
content.Position = UDim2.new(0, 10, 0, 65)
content.BackgroundTransparency = 1
content.Parent = main

-- Функция дропдауна
local function makeDropdown(parent, pos, options, default, width, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, width or 170, 0, 24)
    f.Position = pos
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    f.BorderSizePixel = 1
    f.BorderColor3 = Color3.fromRGB(50, 50, 60)
    f.ClipsDescendants = false
    f.ZIndex = 10
    f.Parent = parent

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 1, 0)
    b.Text = default
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Code
    b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.ZIndex = 10
    b.Parent = f

    local arr = Instance.new("TextLabel")
    arr.Size = UDim2.new(0, 20, 1, 0)
    arr.Position = UDim2.new(1, -20, 0, 0)
    arr.Text = "▼"
    arr.TextColor3 = Color3.new(1,1,1)
    arr.BackgroundTransparency = 1
    arr.Font = Enum.Font.Code
    arr.TextSize = 11
    arr.ZIndex = 10
    arr.Parent = f

    local lf = Instance.new("Frame")
    lf.Size = UDim2.new(1, 0, 0, math.min(#options, 10) * 22 + 4)
    lf.Position = UDim2.new(0, 0, 0, 24)
    lf.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    lf.BorderSizePixel = 1
    lf.BorderColor3 = Color3.fromRGB(50, 50, 60)
    lf.Visible = false
    lf.ZIndex = 100
    lf.Parent = f

    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, -2, 1, -2)
    sf.Position = UDim2.new(0, 1, 0, 1)
    sf.BackgroundTransparency = 1
    sf.CanvasSize = UDim2.new(0, 0, 0, #options * 22)
    sf.ScrollBarThickness = 4
    sf.BorderSizePixel = 0
    sf.ZIndex = 100
    sf.Parent = lf

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 22)
        ob.Position = UDim2.new(0, 0, 0, (i-1) * 22)
        ob.Text = type(opt) == "table" and opt.name or opt
        ob.TextColor3 = Color3.new(1,1,1)
        ob.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(40,40,50) or Color3.fromRGB(30,30,40)
        ob.BorderSizePixel = 0
        ob.Font = Enum.Font.Code
        ob.TextSize = 11
        ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.ZIndex = 100
        ob.Parent = sf
        ob.MouseButton1Click:Connect(function()
            b.Text = type(opt) == "table" and opt.name or opt
            lf.Visible = false
            if cb then cb(opt) end
        end)
    end

    b.MouseButton1Click:Connect(function()
        lf.Visible = not lf.Visible
    end)
    return f, b, lf
end

-- ============ ВКЛАДКА 1: ЗДАНИЯ ============
local tab1 = Instance.new("Frame")
tab1.Size = UDim2.new(1, 0, 1, 0)
tab1.BackgroundTransparency = 1
tab1.Parent = content

local y = 5
local lbl1 = Instance.new("TextLabel")
lbl1.Size = UDim2.new(0, 90, 0, 20)
lbl1.Position = UDim2.new(0, 0, 0, y)
lbl1.BackgroundTransparency = 1
lbl1.Text = "📁 Группа:"
lbl1.TextColor3 = Color3.new(1,1,1)
lbl1.Font = Enum.Font.Code
lbl1.TextSize = 12
lbl1.TextXAlignment = Enum.TextXAlignment.Left
lbl1.Parent = tab1

local groupNames = {}
for _, g in ipairs(BUILDING_GROUPS) do
    table.insert(groupNames, g.name)
end

local buildingDropdownBox

makeDropdown(tab1, UDim2.new(0, 90, 0, y), groupNames, BUILDING_GROUPS[1].name, 200, function(groupName)
    -- Находим выбранную группу
    for _, g in ipairs(BUILDING_GROUPS) do
        if g.name == groupName then
            -- Обновляем здания в группе
            local buildingsList = {}
            for _, b in ipairs(g.buildings) do
                table.insert(buildingsList, b.name)
            end
            -- Меняем содержимое дропдауна зданий
            if buildingDropdownBox then
                buildingDropdownBox.Text = g.buildings[1].name
                builder.buildingType = g.buildings[1].name
                builder.buildingFunc = g.buildings[1].func
                builder.width = g.buildings[1].defW
                builder.depth = g.buildings[1].defD
                builder.height = g.buildings[1].defH
            end
            break
        end
    end
end)

y = y + 30
local lbl2 = Instance.new("TextLabel")
lbl2.Size = UDim2.new(0, 90, 0, 20)
lbl2.Position = UDim2.new(0, 0, 0, y)
lbl2.BackgroundTransparency = 1
lbl2.Text = "🏗️ Здание:"
lbl2.TextColor3 = Color3.new(1,1,1)
lbl2.Font = Enum.Font.Code
lbl2.TextSize = 12
lbl2.TextXAlignment = Enum.TextXAlignment.Left
lbl2.Parent = tab1

local firstBuildings = {}
for _, b in ipairs(BUILDING_GROUPS[1].buildings) do
    table.insert(firstBuildings, b.name)
end

local _, buildingDropdownBoxRef = makeDropdown(tab1, UDim2.new(0, 90, 0, y), firstBuildings, firstBuildings[1], 240, function(buildingName)
    for _, g in ipairs(BUILDING_GROUPS) do
        for _, b in ipairs(g.buildings) do
            if b.name == buildingName then
                builder.buildingType = b.name
                builder.buildingFunc = b.func
                builder.width = b.defW
                builder.depth = b.defD
                builder.height = b.defH
                -- Обновляем поля размеров
                if sizeBoxes then
                    sizeBoxes[1].Text = tostring(b.defW)
                    sizeBoxes[2].Text = tostring(b.defD)
                    sizeBoxes[3].Text = tostring(b.defH)
                end
                print("🏗️ "..b.name.." "..b.defW.."x"..b.defD.."x"..b.defH)
                break
            end
        end
    end
end)
buildingDropdownBox = buildingDropdownBoxRef

y = y + 30
local sizeBoxes = {}
for i, lab in ipairs({"📐 Ширина:", "📏 Глубина:", "📐 Высота:"}) do
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
    box.Text = tostring(BUILDING_GROUPS[1].buildings[1].defW)
    if i == 2 then box.Text = tostring(BUILDING_GROUPS[1].buildings[1].defD) end
    if i == 3 then box.Text = tostring(BUILDING_GROUPS[1].buildings[1].defH) end
    box.BackgroundColor3 = Color3.fromRGB(10,10,15)
    box.TextColor3 = Color3.new(1,1,1)
    box.Font = Enum.Font.Code
    box.TextSize = 12
    box.BorderSizePixel = 0
    box.Parent = tab1
    sizeBoxes[i] = box
end

y = y + 3*28 + 10
local matConfigs = {
    {"🧱 Стены:", "Brick", "wallMat"},
    {"🪵 Пол:", "Wood", "floorMat"},
    {"🏠 Крыша:", "Slate", "roofMat"},
    {"🪟 Стекло:", "Glass", "glassMat"},
    {"🚪 Дверь:", "Wood", "doorMat"}
}
for i, cfg in ipairs(matConfigs) do
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 75, 0, 20)
    l.Position = UDim2.new(0, 0, 0, y + (i-1)*26)
    l.BackgroundTransparency = 1
    l.Text = cfg[1]
    l.TextColor3 = Color3.new(1,1,1)
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = tab1

    makeDropdown(tab1, UDim2.new(0, 85, 0, y + (i-1)*26), MATERIALS, cfg[2], 160, function(opt)
        builder[cfg[3]] = opt
    end)
end

y = y + 5*26 + 10
local buildBtn = Instance.new("TextButton")
buildBtn.Size = UDim2.new(1, 0, 0, 32)
buildBtn.Position = UDim2.new(0, 0, 0, y)
buildBtn.Text = "🏗️ Построить"
buildBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
buildBtn.TextColor3 = Color3.new(1,1,1)
buildBtn.Font = Enum.Font.Code
buildBtn.TextSize = 13
buildBtn.BorderSizePixel = 0
buildBtn.Parent = tab1

buildBtn.MouseButton1Click:Connect(function()
    builder.mode = "buildings"
    builder.width = tonumber(sizeBoxes[1].Text) or 7
    builder.depth = tonumber(sizeBoxes[2].Text) or 7
    builder.height = tonumber(sizeBoxes[3].Text) or 4
    if builder.width < 1 or builder.depth < 1 or builder.height < 1 then
        print("❌ Минимум 1x1x1")
        return
    end
    builder.rotation = 0
    builder.baseY = 0
    builder.active = true
    updatePreview()
    print("✅ "..builder.buildingType.." готов к постройке")
    print("🖱️ Наведи мышь и кликни ЛКМ")
end)

-- ============ ВКЛАДКА 2: АРТЫ ============
local tab2 = Instance.new("Frame")
tab2.Size = UDim2.new(1, 0, 1, 0)
tab2.BackgroundTransparency = 1
tab2.Visible = false
tab2.Parent = content

y = 5
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
    l.Parent = tab2

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 60, 0, 20)
    box.Position = UDim2.new(0, 90, 0, y + (i-1)*28)
    box.Text = "10"
    box.BackgroundColor3 = Color3.fromRGB(10,10,15)
    box.TextColor3 = Color3.new(1,1,1)
    box.Font = Enum.Font.Code
    box.TextSize = 12
    box.BorderSizePixel = 0
    box.Parent = tab2
    if i == 1 then sizeBoxes.artW = box else sizeBoxes.artH = box end
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
artLbl.Parent = tab2

y = y + 22
local artBox = Instance.new("TextBox")
artBox.Size = UDim2.new(1, 0, 0, 250)
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
artBox.Parent = tab2

y = y + 260
local artBtn = Instance.new("TextButton")
artBtn.Size = UDim2.new(1, 0, 0, 32)
artBtn.Position = UDim2.new(0, 0, 0, y)
artBtn.Text = "🎨 Построить арт"
artBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
artBtn.TextColor3 = Color3.new(1,1,1)
artBtn.Font = Enum.Font.Code
artBtn.TextSize = 13
artBtn.BorderSizePixel = 0
artBtn.Parent = tab2

artBtn.MouseButton1Click:Connect(function()
    builder.mode = "art"
    local w = tonumber(sizeBoxes.artW.Text) or 10
    local h = tonumber(sizeBoxes.artH.Text) or 10
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

-- Переключение вкладок
tabBtn1.MouseButton1Click:Connect(function()
    tab1.Visible = true
    tab2.Visible = false
    tabBtn1.BackgroundColor3 = Color3.fromRGB(0,100,200)
    tabBtn2.BackgroundColor3 = Color3.fromRGB(60,60,60)
    builder.mode = "buildings"
end)

tabBtn2.MouseButton1Click:Connect(function()
    tab1.Visible = false
    tab2.Visible = true
    tabBtn1.BackgroundColor3 = Color3.fromRGB(60,60,60)
    tabBtn2.BackgroundColor3 = Color3.fromRGB(0,100,200)
    builder.mode = "art"
end)

-- Обработчики ввода
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

print("🏗️ СТРОИТЕЛЬ v21.0 загружен!")
print("Группы: Дома, Магазины, Многоэтажки, Общественные, Спецсооружения, Декорации")
print("Плюс режим Артов")
