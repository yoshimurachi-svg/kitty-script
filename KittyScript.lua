-- Kitty Script
-- LocalScript → StarterPlayerScripts
-- RightCtrl — показать / скрыть

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true

-- ========================
--   УВЕДОМЛЕНИЯ
-- ========================
local notifGui = Instance.new("ScreenGui", playerGui)
notifGui.Name = "KittyNotif"
notifGui.ResetOnSpawn = false
notifGui.DisplayOrder = 9999

local function showNotif(text, color)
    color = color or Color3.fromRGB(90, 80, 200)
    local frame = Instance.new("Frame", notifGui)
    frame.Size = UDim2.new(0, 260, 0, 52)
    frame.Position = UDim2.new(1, 20, 1, -70)
    frame.BackgroundColor3 = Color3.fromRGB(12, 10, 22)
    frame.BorderSizePixel = 0; frame.ZIndex = 10
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = color; stroke.Thickness = 1.2; stroke.Transparency = 0.25
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0, 3, 1, -14); bar.Position = UDim2.new(0, 0, 0, 7)
    bar.BackgroundColor3 = color; bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -20, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(215, 212, 255)
    lbl.TextSize = 13; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextWrapped = true; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 11
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -275, 1, -70)
    }):Play()
    task.delay(3, function()
        local hide = TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
            Position = UDim2.new(1, 20, 1, -70)
        })
        hide:Play()
        hide.Completed:Connect(function() frame:Destroy() end)
    end)
end

-- ========================
--   НЕБО
-- ========================
local function applySky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") then obj:Destroy() end
    end
    local sky = Instance.new("Sky", Lighting)
    sky.SkyboxBk = "rbxassetid://159454299"
    sky.SkyboxDn = "rbxassetid://159454296"
    sky.SkyboxFt = "rbxassetid://159454293"
    sky.SkyboxLf = "rbxassetid://159454286"
    sky.SkyboxRt = "rbxassetid://159454302"
    sky.SkyboxUp = "rbxassetid://159454309"
    local atmo = Instance.new("Atmosphere", Lighting)
    atmo.Density = 0.35; atmo.Offset = 0.1
    atmo.Color   = Color3.fromRGB(199, 215, 255)
    atmo.Decay   = Color3.fromRGB(90, 110, 160)
    atmo.Glare   = 0.1; atmo.Haze = 1.5
    Lighting.Ambient        = Color3.fromRGB(160, 180, 220)
    Lighting.OutdoorAmbient = Color3.fromRGB(120, 150, 200)
    Lighting.FogColor       = Color3.fromRGB(180, 200, 230)
    Lighting.FogEnd         = 500; Lighting.FogStart = 200
    Lighting.Brightness     = 1.2; Lighting.ClockTime = 18
    showNotif("Скайбокс применён!", Color3.fromRGB(80, 130, 200))
end

local function setTime(t)
    Lighting.ClockTime = t
    local n = {[0]="Ночь",[14]="День",[18]="Закат"}
    showNotif("Время: " .. (n[t] or t), Color3.fromRGB(200, 160, 60))
end

local function setFog(d)
    Lighting.FogEnd = d; Lighting.FogStart = d*0.4
    Lighting.FogColor = Color3.fromRGB(180,200,230)
    showNotif("Туман включён!", Color3.fromRGB(120,120,180))
end
local function removeFog()
    Lighting.FogEnd = 100000; Lighting.FogStart = 99000
    showNotif("Туман убран!", Color3.fromRGB(100,100,160))
end

-- ========================
--   СНЕГ (больше, крупнее)
-- ========================
local snowParts  = {}
local snowActive = false
local snowConn   = nil
local snowFolder = Instance.new("Folder", workspace)
snowFolder.Name  = "KittySnow"

local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function startSnow()
    if snowActive then return end
    snowActive = true
    local count  = 600   -- больше снежинок
    local spread = 160   -- шире разброс
    local height = 80    -- выше спавн
    local minSz  = 0.35  -- минимальный размер
    local maxSz  = 0.85  -- максимальный размер (крупные)

    for i = 1, count do
        local root = getRoot(); if not root then break end
        local sz = minSz + math.random() * (maxSz - minSz)
        local p = Instance.new("Part")
        p.Size        = Vector3.new(sz, sz, sz)
        p.Shape       = Enum.PartType.Ball
        p.Material    = Enum.Material.Neon   -- светящиеся
        p.Color       = Color3.fromRGB(200, 225, 255)
        p.CastShadow  = false
        p.CanCollide  = false
        p.Anchored    = true
        p.Transparency = 0.1
        local rp = root.Position
        p.Position = Vector3.new(
            rp.X + math.random(-spread, spread),
            rp.Y + math.random(0, height),
            rp.Z + math.random(-spread, spread)
        )
        p.Parent = snowFolder
        table.insert(snowParts, { part=p, speed=12+math.random()*18, sz=sz })
    end

    snowConn = RunService.Heartbeat:Connect(function(dt)
        if not snowActive then return end
        local root = getRoot(); if not root then return end
        local rpos = root.Position
        for _, flake in ipairs(snowParts) do
            local p = flake.part
            if p and p.Parent then
                local fp = p.Position
                local ny = fp.Y - flake.speed * dt
                if ny < rpos.Y - 12 then
                    p.Position = Vector3.new(
                        rpos.X + math.random(-spread, spread),
                        rpos.Y + height,
                        rpos.Z + math.random(-spread, spread)
                    )
                else
                    p.Position = Vector3.new(
                        fp.X + math.sin(tick()*0.9 + fp.X*0.5)*0.4*dt,
                        ny,
                        fp.Z + math.cos(tick()*0.7 + fp.Z*0.5)*0.3*dt
                    )
                end
            end
        end
    end)
    showNotif("Снег запущен! (" .. count .. " снежинок)", Color3.fromRGB(100, 160, 220))
end

local function stopSnow()
    snowActive = false
    if snowConn then snowConn:Disconnect(); snowConn = nil end
    for _, f in ipairs(snowParts) do
        if f.part and f.part.Parent then f.part:Destroy() end
    end
    snowParts = {}
    showNotif("Снег остановлен!", Color3.fromRGB(90, 90, 150))
end

-- ========================
--   ДОЖДЬ
-- ========================
local function setRain()
    stopSnow()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local em = Instance.new("Part")
    em.Size = Vector3.new(80,1,80); em.Anchored = true
    em.CanCollide = false; em.Transparency = 1
    em.Position = root.Position + Vector3.new(0,40,0)
    em.Name = "KittyRain"; em.Parent = workspace
    local pe = Instance.new("ParticleEmitter", em)
    pe.Texture = "rbxassetid://241922778"; pe.Rate = 500
    pe.Lifetime = NumberRange.new(1.5,2.5); pe.Speed = NumberRange.new(70,90)
    pe.EmissionDirection = Enum.NormalId.Bottom
    pe.Transparency = NumberSequence.new(0.35)
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.06),NumberSequenceKeypoint.new(1,0.02)})
    showNotif("Дождь запущен!", Color3.fromRGB(60, 120, 200))
end

local function stopRain()
    local rp = workspace:FindFirstChild("KittyRain")
    if rp then rp:Destroy() end
    showNotif("Дождь остановлен!", Color3.fromRGB(60,90,140))
end

-- ========================
--   СИНЯЯ ЛИНИЯ ЗА ИГРОКОМ
-- ========================
local trailActive = false
local trailConn   = nil
local trailFolder = Instance.new("Folder", workspace)
trailFolder.Name  = "KittyTrail"
local trailParts  = {}

local function startTrail()
    if trailActive then return end
    trailActive = true
    local maxParts = 40
    local lastPos  = nil

    trailConn = RunService.Heartbeat:Connect(function(dt)
        local root = getRoot()
        if not root then return end
        local pos = root.Position

        if lastPos and (pos - lastPos).Magnitude > 1.5 then
            local p = Instance.new("Part")
            p.Size        = Vector3.new(0.4, 0.4, (pos - lastPos).Magnitude)
            p.Material    = Enum.Material.Neon
            p.Color       = Color3.fromRGB(80, 160, 255)
            p.CastShadow  = false
            p.CanCollide  = false
            p.Anchored    = true
            p.Transparency = 0.3
            p.CFrame = CFrame.new((pos + lastPos)/2, pos)
            p.Parent = trailFolder
            table.insert(trailParts, { part=p, born=tick() })
        end
        lastPos = pos

        -- Затухание старых частей
        local now = tick()
        for i = #trailParts, 1, -1 do
            local tp = trailParts[i]
            if tp.part and tp.part.Parent then
                local age = now - tp.born
                if age > 0.8 then
                    tp.part:Destroy()
                    table.remove(trailParts, i)
                else
                    tp.part.Transparency = 0.3 + (age / 0.8) * 0.7
                    -- Синева переходит в фиолетовый
                    local t = age / 0.8
                    tp.part.Color = Color3.fromRGB(
                        math.floor(80 + t*80),
                        math.floor(160 - t*100),
                        255
                    )
                end
            else
                table.remove(trailParts, i)
            end
        end
    end)
    showNotif("Линия за игроком включена!", Color3.fromRGB(80, 160, 255))
end

local function stopTrail()
    trailActive = false
    if trailConn then trailConn:Disconnect(); trailConn = nil end
    for _, tp in ipairs(trailParts) do
        if tp.part and tp.part.Parent then tp.part:Destroy() end
    end
    trailParts = {}
    showNotif("Линия выключена!", Color3.fromRGB(80, 100, 160))
end

-- ========================
--   АУРА ВОКРУГ ИГРОКА
-- ========================
local auraActive = false
local auraParts  = {}
local auraConn   = nil
local auraFolder = Instance.new("Folder", workspace)
auraFolder.Name  = "KittyAura"

local function startAura(colorA, colorB, label)
    if auraActive then
        -- Сброс текущей ауры
        auraActive = false
        if auraConn then auraConn:Disconnect(); auraConn = nil end
        for _, ap in ipairs(auraParts) do
            if ap and ap.Parent then ap:Destroy() end
        end
        auraParts = {}
    end
    auraActive = true
    colorA = colorA or Color3.fromRGB(80, 160, 255)
    colorB = colorB or Color3.fromRGB(180, 100, 255)

    -- Создаём кольцо из шаров
    local ringCount = 12
    for i = 1, ringCount do
        local p = Instance.new("Part")
        p.Size        = Vector3.new(0.5, 0.5, 0.5)
        p.Shape       = Enum.PartType.Ball
        p.Material    = Enum.Material.Neon
        p.Color       = colorA
        p.CastShadow  = false
        p.CanCollide  = false
        p.Anchored    = true
        p.Transparency = 0.2
        p.Parent = auraFolder
        table.insert(auraParts, p)
    end

    local t0 = tick()
    auraConn = RunService.Heartbeat:Connect(function()
        local root = getRoot()
        if not root then return end
        local pos   = root.Position
        local t     = tick() - t0
        local count = #auraParts

        for i, p in ipairs(auraParts) do
            if p and p.Parent then
                local angle  = (i / count) * math.pi * 2 + t * 1.8
                local radius = 3.2
                local wave   = math.sin(t * 2 + i) * 0.5
                p.Position = Vector3.new(
                    pos.X + math.cos(angle) * radius,
                    pos.Y + wave,
                    pos.Z + math.sin(angle) * radius
                )
                -- Переливается между двумя цветами
                local mix = (math.sin(t * 2 + i * 0.5) + 1) / 2
                p.Color = Color3.new(
                    colorA.R + (colorB.R - colorA.R) * mix,
                    colorA.G + (colorB.G - colorA.G) * mix,
                    colorA.B + (colorB.B - colorA.B) * mix
                )
            end
        end
    end)
    showNotif(label or "Аура включена!", Color3.fromRGB(colorA.R*255, colorA.G*255, colorA.B*255))
end

local function stopAura()
    auraActive = false
    if auraConn then auraConn:Disconnect(); auraConn = nil end
    for _, ap in ipairs(auraParts) do
        if ap and ap.Parent then ap:Destroy() end
    end
    auraParts = {}
    showNotif("Аура выключена!", Color3.fromRGB(90,80,160))
end

-- ========================
--   РАДУГА ПОД НОГАМИ
-- ========================
local rainbowActive = false
local rainbowConn   = nil
local rainbowFolder = Instance.new("Folder", workspace)
rainbowFolder.Name  = "KittyRainbow"
local rainbowParts  = {}

local function startRainbow()
    if rainbowActive then return end
    rainbowActive = true

    rainbowConn = RunService.Heartbeat:Connect(function(dt)
        local root = getRoot(); if not root then return end
        local pos  = root.Position
        local t    = tick()

        -- Новая частица под ногами
        local p = Instance.new("Part")
        p.Size        = Vector3.new(0.7, 0.15, 0.7)
        p.Material    = Enum.Material.Neon
        local h = (t * 0.4) % 1
        p.Color       = Color3.fromHSV(h, 1, 1)
        p.CastShadow  = false
        p.CanCollide  = false
        p.Anchored    = true
        p.Transparency = 0.1
        p.Position    = Vector3.new(pos.X + math.random(-1,1)*0.3, pos.Y - 2.8, pos.Z + math.random(-1,1)*0.3)
        p.Parent      = rainbowFolder
        table.insert(rainbowParts, { part=p, born=tick() })

        local now = tick()
        for i = #rainbowParts, 1, -1 do
            local rp = rainbowParts[i]
            if rp.part and rp.part.Parent then
                local age = now - rp.born
                if age > 0.7 then
                    rp.part:Destroy(); table.remove(rainbowParts, i)
                else
                    rp.part.Transparency = 0.1 + (age/0.7)*0.9
                    rp.part.Size = Vector3.new(0.7 + age*0.5, 0.15, 0.7 + age*0.5)
                end
            else
                table.remove(rainbowParts, i)
            end
        end
    end)
    showNotif("Радуга под ногами включена!", Color3.fromRGB(255, 120, 200))
end

local function stopRainbow()
    rainbowActive = false
    if rainbowConn then rainbowConn:Disconnect(); rainbowConn = nil end
    for _, rp in ipairs(rainbowParts) do
        if rp.part and rp.part.Parent then rp.part:Destroy() end
    end
    rainbowParts = {}
    showNotif("Радуга выключена!", Color3.fromRGB(150, 90, 160))
end

-- ========================
--   GUI
-- ========================
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "KittyGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999

local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0, 540, 0, 390)
main.Position = UDim2.new(0.5, -270, 0.5, -195)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
main.BorderSizePixel = 0
main.Active = true; main.Draggable = true; main.Visible = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local ms = Instance.new("UIStroke", main)
ms.Color = Color3.fromRGB(80,70,180); ms.Thickness = 1; ms.Transparency = 0.35

-- Заголовок
local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(14, 12, 28)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
local tfx = Instance.new("Frame", titleBar)
tfx.Size = UDim2.new(1,0,0.5,0); tfx.Position = UDim2.new(0,0,0.5,0)
tfx.BackgroundColor3 = Color3.fromRGB(14,12,28); tfx.BorderSizePixel = 0

local titleTxt = Instance.new("TextLabel", titleBar)
titleTxt.Size = UDim2.new(1,-100,1,0); titleTxt.Position = UDim2.new(0,16,0,0)
titleTxt.BackgroundTransparency = 1; titleTxt.Text = "Kitty Script"
titleTxt.TextColor3 = Color3.fromRGB(210,205,255)
titleTxt.TextSize = 16; titleTxt.Font = Enum.Font.GothamBold
titleTxt.TextXAlignment = Enum.TextXAlignment.Left; titleTxt.ZIndex = 3

local function makeTBtn(offX, bg, txt)
    local b = Instance.new("TextButton", titleBar)
    b.Size = UDim2.new(0,28,0,28); b.Position = UDim2.new(1,offX,0.5,-14)
    b.BackgroundColor3 = bg; b.Text = txt
    b.TextColor3 = Color3.fromRGB(255,255,255); b.TextSize = 14
    b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0; b.ZIndex = 4
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
    return b
end
local closeBtn = makeTBtn(-36, Color3.fromRGB(150,35,35), "x")
local minBtn   = makeTBtn(-70, Color3.fromRGB(45,40,100), "-")

-- Навигация
local navPanel = Instance.new("Frame", main)
navPanel.Size = UDim2.new(0,150,1,-44); navPanel.Position = UDim2.new(0,0,0,44)
navPanel.BackgroundColor3 = Color3.fromRGB(13,11,24); navPanel.BorderSizePixel = 0
local navLayout = Instance.new("UIListLayout", navPanel)
navLayout.Padding = UDim.new(0,0); navLayout.SortOrder = Enum.SortOrder.LayoutOrder

local divLine = Instance.new("Frame", main)
divLine.Size = UDim2.new(0,1,1,-44); divLine.Position = UDim2.new(0,150,0,44)
divLine.BackgroundColor3 = Color3.fromRGB(40,38,80); divLine.BorderSizePixel = 0

local contentArea = Instance.new("Frame", main)
contentArea.Size = UDim2.new(1,-150,1,-44); contentArea.Position = UDim2.new(0,150,0,44)
contentArea.BackgroundColor3 = Color3.fromRGB(16,14,30); contentArea.BorderSizePixel = 0

-- Аватарка
local avaFrame = Instance.new("Frame", navPanel)
avaFrame.Size = UDim2.new(1,0,0,50); avaFrame.LayoutOrder = 99
avaFrame.BackgroundColor3 = Color3.fromRGB(11,9,20); avaFrame.BorderSizePixel = 0
local avaDiv = Instance.new("Frame", avaFrame)
avaDiv.Size = UDim2.new(1,0,0,1); avaDiv.BackgroundColor3 = Color3.fromRGB(38,36,72); avaDiv.BorderSizePixel = 0
local avaIco = Instance.new("TextLabel", avaFrame)
avaIco.Size = UDim2.new(0,28,0,28); avaIco.Position = UDim2.new(0,8,0.5,-14)
avaIco.BackgroundColor3 = Color3.fromRGB(60,50,140); avaIco.BorderSizePixel = 0
avaIco.Text = string.sub(player.Name,1,1):upper()
avaIco.TextColor3 = Color3.fromRGB(210,205,255); avaIco.TextSize = 13; avaIco.Font = Enum.Font.GothamBold
Instance.new("UICorner", avaIco).CornerRadius = UDim.new(1,0)
local avaName = Instance.new("TextLabel", avaFrame)
avaName.Size = UDim2.new(1,-44,1,0); avaName.Position = UDim2.new(0,42,0,0)
avaName.BackgroundTransparency = 1; avaName.Text = player.Name
avaName.TextColor3 = Color3.fromRGB(140,135,200); avaName.TextSize = 12; avaName.Font = Enum.Font.Gotham
avaName.TextXAlignment = Enum.TextXAlignment.Left

-- Страницы
local pages = {}
local function makePage(name)
    local pg = Instance.new("ScrollingFrame", contentArea)
    pg.Size = UDim2.new(1,0,1,0); pg.BackgroundTransparency = 1
    pg.BorderSizePixel = 0; pg.ScrollBarThickness = 3
    pg.ScrollBarImageColor3 = Color3.fromRGB(75,70,145)
    pg.CanvasSize = UDim2.new(0,0,0,0); pg.Visible = false
    local l = Instance.new("UIListLayout", pg)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        pg.CanvasSize = UDim2.new(0,0,0,l.AbsoluteContentSize.Y+16)
    end)
    pages[name] = pg; return pg
end

local function makeSection(page, title, order)
    local hdr = Instance.new("TextLabel", page)
    hdr.Size = UDim2.new(1,0,0,26); hdr.BackgroundTransparency = 1
    hdr.Text = title; hdr.TextColor3 = Color3.fromRGB(95,90,158)
    hdr.TextSize = 10; hdr.Font = Enum.Font.GothamBold
    hdr.TextXAlignment = Enum.TextXAlignment.Left; hdr.LayoutOrder = order
    local pad = Instance.new("UIPadding", hdr)
    pad.PaddingLeft = UDim.new(0,14); pad.PaddingTop = UDim.new(0,8)
end

local function makeActionBtn(page, label, order)
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1,0,0,40); row.BackgroundColor3 = Color3.fromRGB(20,18,36)
    row.BorderSizePixel = 0; row.LayoutOrder = order
    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1,0,0,1); div.Position = UDim2.new(0,0,1,-1)
    div.BackgroundColor3 = Color3.fromRGB(32,30,58); div.BorderSizePixel = 0
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-46,1,0); lbl.Position = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(200,198,248); lbl.TextSize = 13; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0,22,0,22); btn.Position = UDim2.new(1,-30,0.5,-11)
    btn.BackgroundColor3 = Color3.fromRGB(48,42,108); btn.Text = ">"
    btn.TextColor3 = Color3.fromRGB(175,170,250); btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    row.MouseEnter:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(30,27,50)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(20,18,36)}):Play()
    end)
    return btn
end

-- === Небо ===
local pgSky = makePage("sky")
makeSection(pgSky, "СКАЙБОКС", 1)
local bSky    = makeActionBtn(pgSky, "Применить красивое небо",  2)
local bDay    = makeActionBtn(pgSky, "День  (14:00)",             3)
local bSunset = makeActionBtn(pgSky, "Закат  (18:00)",            4)
local bNight  = makeActionBtn(pgSky, "Ночь  (0:00)",              5)
makeSection(pgSky, "АТМОСФЕРА", 6)
local bFogOn  = makeActionBtn(pgSky, "Включить туман",            7)
local bFogOff = makeActionBtn(pgSky, "Убрать туман",              8)
bSky.MouseButton1Click:Connect(applySky)
bDay.MouseButton1Click:Connect(function() setTime(14) end)
bSunset.MouseButton1Click:Connect(function() setTime(18) end)
bNight.MouseButton1Click:Connect(function() setTime(0) end)
bFogOn.MouseButton1Click:Connect(function() setFog(200) end)
bFogOff.MouseButton1Click:Connect(removeFog)

-- === Погода ===
local pgWeather = makePage("weather")
makeSection(pgWeather, "СНЕГ", 1)
local bSnowOn  = makeActionBtn(pgWeather, "Запустить снег",   2)
local bSnowOff = makeActionBtn(pgWeather, "Остановить снег",  3)
makeSection(pgWeather, "ДОЖДЬ", 4)
local bRainOn  = makeActionBtn(pgWeather, "Запустить дождь",  5)
local bRainOff = makeActionBtn(pgWeather, "Остановить дождь", 6)
bSnowOn.MouseButton1Click:Connect(startSnow)
bSnowOff.MouseButton1Click:Connect(stopSnow)
bRainOn.MouseButton1Click:Connect(setRain)
bRainOff.MouseButton1Click:Connect(stopRain)

-- === Визуал ===
local pgVisual = makePage("visual")
makeSection(pgVisual, "СЛЕД ЗА ИГРОКОМ", 1)
local bTrailOn  = makeActionBtn(pgVisual, "Синяя линия  (вкл)",    2)
local bTrailOff = makeActionBtn(pgVisual, "Синяя линия  (выкл)",   3)
makeSection(pgVisual, "АУРА", 4)
local bAuraBlue = makeActionBtn(pgVisual, "Аура  синяя/фиолетовая", 5)
local bAureFire = makeActionBtn(pgVisual, "Аура  огонь",            6)
local bAureCyan = makeActionBtn(pgVisual, "Аура  cyan/зеленая",     7)
local bAuraOff  = makeActionBtn(pgVisual, "Аура  (выкл)",           8)
makeSection(pgVisual, "ЭФФЕКТ ПОД НОГАМИ", 9)
local bRainbowOn  = makeActionBtn(pgVisual, "Радуга под ногами  (вкл)",  10)
local bRainbowOff = makeActionBtn(pgVisual, "Радуга под ногами  (выкл)", 11)

bTrailOn.MouseButton1Click:Connect(startTrail)
bTrailOff.MouseButton1Click:Connect(stopTrail)
bAuraBlue.MouseButton1Click:Connect(function()
    startAura(Color3.fromRGB(80,160,255), Color3.fromRGB(180,80,255), "Аура синяя включена!")
end)
bAureFire.MouseButton1Click:Connect(function()
    startAura(Color3.fromRGB(255,80,20), Color3.fromRGB(255,210,30), "Аура огонь включена!")
end)
bAuraCyan = bAureCyan
bAureCyan.MouseButton1Click:Connect(function()
    startAura(Color3.fromRGB(0,220,220), Color3.fromRGB(0,255,120), "Аура cyan включена!")
end)
bAuraOff.MouseButton1Click:Connect(stopAura)
bRainbowOn.MouseButton1Click:Connect(startRainbow)
bRainbowOff.MouseButton1Click:Connect(stopRainbow)

-- === Мышь ===
local pgMisc = makePage("misc")
makeSection(pgMisc, "МЫШЬ", 1)
local bUnlock = makeActionBtn(pgMisc, "Разблокировать мышь", 2)
local bHide   = makeActionBtn(pgMisc, "Скрыть курсор",       3)
local bShow   = makeActionBtn(pgMisc, "Показать курсор",      4)
bUnlock.MouseButton1Click:Connect(function()
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    showNotif("Мышь разблокирована!", Color3.fromRGB(80,200,120))
end)
bHide.MouseButton1Click:Connect(function()
    UserInputService.MouseIconEnabled = false
    showNotif("Курсор скрыт!", Color3.fromRGB(130,100,200))
end)
bShow.MouseButton1Click:Connect(function()
    UserInputService.MouseIconEnabled = true
    showNotif("Курсор показан!", Color3.fromRGB(130,100,200))
end)

-- ========================
--   НАВИГАЦИЯ
-- ========================
local navItems = {
    { label = "  Небо",     page = "sky"     },
    { label = "  Погода",   page = "weather" },
    { label = "  Визуал",   page = "visual"  },
    { label = "  Прочее",   page = "misc"    },
}
local navBtns = {}
local currentPage = nil

local function selectPage(name)
    for n, pg in pairs(pages) do pg.Visible = (n == name) end
    for _, nb in ipairs(navBtns) do
        local active = nb.pageName == name
        TweenService:Create(nb.btn, TweenInfo.new(0.12), {
            BackgroundColor3 = active and Color3.fromRGB(44,40,105) or Color3.fromRGB(13,11,24)
        }):Play()
        nb.dot.Visible = active
    end
    currentPage = name
end

for i, item in ipairs(navItems) do
    local btn = Instance.new("TextButton", navPanel)
    btn.Size = UDim2.new(1,0,0,40); btn.LayoutOrder = i
    btn.BackgroundColor3 = Color3.fromRGB(13,11,24)
    btn.Text = ""; btn.BorderSizePixel = 0

    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0,3,0.5,0); dot.Position = UDim2.new(0,0,0.25,0)
    dot.BackgroundColor3 = Color3.fromRGB(100,90,210); dot.BorderSizePixel = 0; dot.Visible = false

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1,-8,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = item.label
    lbl.TextColor3 = Color3.fromRGB(165,160,220); lbl.TextSize = 13; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local divN = Instance.new("Frame", btn)
    divN.Size = UDim2.new(1,0,0,1); divN.Position = UDim2.new(0,0,1,-1)
    divN.BackgroundColor3 = Color3.fromRGB(28,26,52); divN.BorderSizePixel = 0

    btn.MouseButton1Click:Connect(function() selectPage(item.page) end)
    btn.MouseEnter:Connect(function()
        if currentPage ~= item.page then
            TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(22,20,44)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentPage ~= item.page then
            TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(13,11,24)}):Play()
        end
    end)
    table.insert(navBtns, { btn=btn, dot=dot, pageName=item.page })
end

selectPage("sky")

-- ========================
--   КНОПКИ ЗАГОЛОВКА
-- ========================
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    UserInputService.MouseBehavior    = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false
    showNotif("Kitty скрыт", Color3.fromRGB(80,70,160))
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    navPanel.Visible    = not minimized
    contentArea.Visible = not minimized
    divLine.Visible     = not minimized
    main.Size = minimized and UDim2.new(0,540,0,44) or UDim2.new(0,540,0,390)
end)

-- ========================
--   RIGHT CTRL
-- ========================
local guiOpen = true
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        guiOpen = not guiOpen
        main.Visible = guiOpen
        if guiOpen then
            UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
            showNotif("Kitty открыт", Color3.fromRGB(90,80,200))
        else
            UserInputService.MouseBehavior    = Enum.MouseBehavior.LockCenter
            UserInputService.MouseIconEnabled = false
            showNotif("Kitty скрыт", Color3.fromRGB(60,55,130))
        end
    end
end)

-- ========================
--   ПРИВЕТСТВИЕ
-- ========================
task.wait(0.8)
showNotif("Kitty Script запущен!", Color3.fromRGB(100,85,220))
task.wait(1.2)
showNotif("Привет, " .. player.Name .. "!", Color3.fromRGB(60,160,100))

print("[Kitty] Готово! RightCtrl — открыть/скрыть.")
