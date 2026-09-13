-- ПРОСТОЙ ТЕСТ: GUI + галочка
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("✅ Скрипт загружен!")

local gui = Instance.new("ScreenGui")
gui.Name = "TestGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 120)
frame.Position = UDim2.new(0.5, -125, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
title.Text = "✅ ТЕСТ РАБОТАЕТ"
title.TextColor3 = Color3.fromRGB(0, 255, 100)
title.Font = Enum.Font.Code
title.TextSize = 16
title.BorderSizePixel = 0
title.Parent = frame

local check = Instance.new("TextButton")
check.Size = UDim2.new(0, 25, 0, 25)
check.Position = UDim2.new(0, 20, 0, 50)
check.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
check.Text = ""
check.BorderSizePixel = 0
check.Parent = frame

local checkLabel = Instance.new("TextLabel")
checkLabel.Size = UDim2.new(1, -60, 0, 25)
checkLabel.Position = UDim2.new(0, 55, 0, 50)
checkLabel.BackgroundTransparency = 1
checkLabel.Text = "Галочка: ВЫКЛ"
checkLabel.TextColor3 = Color3.new(1, 1, 1)
checkLabel.Font = Enum.Font.Code
checkLabel.TextSize = 12
checkLabel.TextXAlignment = Enum.TextXAlignment.Left
checkLabel.Parent = frame

local checked = false
check.MouseButton1Click:Connect(function()
    checked = not checked
    if checked then
        check.Text = "✔"
        check.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        checkLabel.Text = "Галочка: ВКЛ"
    else
        check.Text = ""
        check.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        checkLabel.Text = "Галочка: ВЫКЛ"
    end
    print("Галочка: " .. (checked and "ВКЛ" or "ВЫКЛ"))
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -40, 0, 25)
closeBtn.Position = UDim2.new(0, 20, 0, 85)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
closeBtn.Text = "Закрыть"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.Code
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    print("❌ GUI закрыт")
end)
