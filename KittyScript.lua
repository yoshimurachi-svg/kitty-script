-- Kitty Script v3.2
-- LocalScript → StarterPlayerScripts
-- RightCtrl — показать / скрыть

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse     = player:GetMouse()
local camera    = workspace.CurrentCamera

UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true

-- ════════════════════════════════
--   УВЕДОМЛЕНИЯ
-- ════════════════════════════════
local notifGui = Instance.new("ScreenGui", playerGui)
notifGui.Name = "KittyNotif"; notifGui.ResetOnSpawn = false; notifGui.DisplayOrder = 9999

local function showNotif(text, color)
    color = color or Color3.fromRGB(90,80,200)
    local frame = Instance.new("Frame", notifGui)
    frame.Size = UDim2.new(0,260,0,50)
    frame.Position = UDim2.new(1,20,1,-70)
    frame.BackgroundColor3 = Color3.fromRGB(10,8,20)
    frame.BorderSizePixel = 0; frame.ZIndex = 10
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)
    local st = Instance.new("UIStroke", frame)
    st.Color = color; st.Thickness = 1.2; st.Transparency = 0.2
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0,3,1,-12); bar.Position = UDim2.new(0,0,0,6)
    bar.BackgroundColor3 = color; bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,4)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-18,1,0); lbl.Position = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(215,212,255)
    lbl.TextSize = 13; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextWrapped = true; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 11
    TweenService:Create(frame, TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{
        Position = UDim2.new(1,-275,1,-70)
    }):Play()
    task.delay(3, function()
        local h = TweenService:Create(frame,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{
            Position = UDim2.new(1,20,1,-70)
        })
        h:Play(); h.Completed:Connect(function() frame:Destroy() end)
    end)
end

-- ════════════════════════════════
--   HELPERS
-- ════════════════════════════════
local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function neonPart(sz, col, trans)
    local p = Instance.new("Part")
    p.Size = Vector3.new(sz,sz,sz); p.Shape = Enum.PartType.Ball
    p.Material = Enum.Material.Neon; p.Color = col
    p.CastShadow = false; p.CanCollide = false; p.Anchored = true
    p.Transparency = trans or 0.1
    return p
end

-- ════════════════════════════════
--   СИНЕЕ СВЕЧЕНИЕ ПОДНЯТОГО ПРЕДМЕТА
--   Работает через mouse.Target polling
--   (не через Button1Down — в Roblox
--    инструменты перехватывают клик)
-- ════════════════════════════════
local glowEnabled    = true
local glowColor      = Color3.fromRGB(20, 60, 255)
local glowColor2     = Color3.fromRGB(0,  30, 180)
local glowedParts    = {}
local selBox         = nil
local glowPulseConn  = nil
local lastGlowTarget = nil
local heldObject     = nil   -- объект который сейчас держат

local function clearGlow()
    if selBox then selBox:Destroy(); selBox = nil end
    for part, orig in pairs(glowedParts) do
        if part and part.Parent then
            part.Material    = orig.Material
            part.Color       = orig.Color
            part.Transparency= orig.Transparency
        end
    end
    glowedParts = {}
    lastGlowTarget = nil
    heldObject = nil
    if glowPulseConn then glowPulseConn:Disconnect(); glowPulseConn = nil end
end

local function applyGlowToModel(model)
    if not model then return end
    local parts = {}
    if model:IsA("BasePart") then table.insert(parts, model) end
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then table.insert(parts, v) end
    end
    for _, part in ipairs(parts) do
        if not glowedParts[part] then
            glowedParts[part] = {
                Material     = part.Material,
                Color        = part.Color,
                Transparency = part.Transparency,
            }
        end
        part.Material    = Enum.Material.Neon
        part.Color       = glowColor
        part.Transparency= 0.05
    end
    if selBox then selBox:Destroy() end
    selBox = Instance.new("SelectionBox", workspace)
    selBox.Adornee              = model
    selBox.Color3               = Color3.fromRGB(0, 100, 255)
    selBox.LineThickness        = 0.07
    selBox.SurfaceTransparency  = 0.8
    selBox.SurfaceColor3        = Color3.fromRGB(10, 50, 200)

    if glowPulseConn then glowPulseConn:Disconnect() end
    local t0 = tick()
    glowPulseConn = RunService.Heartbeat:Connect(function()
        local mix = (math.sin((tick()-t0)*3)+1)/2
        local c = Color3.new(
            glowColor.R  + (glowColor2.R  - glowColor.R)  * mix,
            glowColor.G  + (glowColor2.G  - glowColor.G)  * mix,
            glowColor.B  + (glowColor2.B  - glowColor.B)  * mix
        )
        for part in pairs(glowedParts) do
            if part and part.Parent then part.Color = c end
        end
        if selBox then selBox.Color3 = Color3.new(0, 0.3+mix*0.4, 1) end
    end)
end

-- Polling: каждый кадр смотрим что под мышью
-- В Roblox инструменты меняют mouse.Target когда держат предмет
RunService.Heartbeat:Connect(function()
    if not glowEnabled then
        if lastGlowTarget then clearGlow() end
        return
    end

    local target = mouse.Target
    local char   = player.Character

    -- Нет цели или цель — земля/персонаж
    if not target or not target:IsA("BasePart") then
        if lastGlowTarget then clearGlow() end
        return
    end
    if char and target:IsDescendantOf(char) then
        if lastGlowTarget then clearGlow() end
        return
    end
    -- Игнорируем наш собственный визуал
    if target:IsDescendantOf(workspace:FindFirstChild("KittySnow") or Instance.new("Folder"))
    or target:IsDescendantOf(workspace:FindFirstChild("KittyTrail") or Instance.new("Folder"))
    or target:IsDescendantOf(workspace:FindFirstChild("KittyOrbit") or Instance.new("Folder"))
    or target:IsDescendantOf(workspace:FindFirstChild("KittyCage") or Instance.new("Folder"))
    or target:IsDescendantOf(workspace:FindFirstChild("KittySparks") or Instance.new("Folder"))
    or target:IsDescendantOf(workspace:FindFirstChild("KittyRainbow") or Instance.new("Folder")) then
        return
    end

    -- Проверяем — предмет двигается? (значит его держат)
    -- Смотрим на Anchored=false + не BasePart на земле
    if target.Anchored then
        if lastGlowTarget then clearGlow() end
        return
    end

    -- Ищем модель-предка
    local model = target
    local anc = target.Parent
    if anc and anc:IsA("Model") and anc ~= workspace then
        model = anc
    end

    if model == lastGlowTarget then return end
    clearGlow()
    lastGlowTarget = model
    applyGlowToModel(model)
end)

-- Когда отпускаем ЛКМ — убираем свечение через секунду
mouse.Button1Up:Connect(function()
    task.delay(0.5, function()
        if lastGlowTarget then clearGlow() end
    end)
end)

-- ════════════════════════════════
--   НЕБО
-- ════════════════════════════════
local function applySky()
    for _,o in ipairs(Lighting:GetChildren()) do
        if o:IsA("Sky") or o:IsA("Atmosphere") then o:Destroy() end
    end
    local sky = Instance.new("Sky", Lighting)
    sky.SkyboxBk="rbxassetid://159454299"; sky.SkyboxDn="rbxassetid://159454296"
    sky.SkyboxFt="rbxassetid://159454293"; sky.SkyboxLf="rbxassetid://159454286"
    sky.SkyboxRt="rbxassetid://159454302"; sky.SkyboxUp="rbxassetid://159454309"
    local a=Instance.new("Atmosphere",Lighting)
    a.Density=0.35;a.Offset=0.1;a.Color=Color3.fromRGB(199,215,255)
    a.Decay=Color3.fromRGB(90,110,160);a.Glare=0.1;a.Haze=1.5
    Lighting.Ambient=Color3.fromRGB(160,180,220)
    Lighting.OutdoorAmbient=Color3.fromRGB(120,150,200)
    Lighting.FogColor=Color3.fromRGB(180,200,230)
    Lighting.FogEnd=500;Lighting.FogStart=200
    Lighting.Brightness=1.2;Lighting.ClockTime=18
    showNotif("Скайбокс применён!", Color3.fromRGB(80,130,200))
end
local function setTime(t)
    Lighting.ClockTime=t
    local n={[0]="Ночь",[14]="День",[18]="Закат"}
    showNotif("Время: "..(n[t] or t), Color3.fromRGB(200,160,60))
end
local function setFog(d)
    Lighting.FogEnd=d;Lighting.FogStart=d*0.4
    Lighting.FogColor=Color3.fromRGB(180,200,230)
    showNotif("Туман включён!", Color3.fromRGB(120,120,180))
end
local function removeFog()
    Lighting.FogEnd=100000;Lighting.FogStart=99000
    showNotif("Туман убран!", Color3.fromRGB(100,100,160))
end

-- ════════════════════════════════
--   СНЕГ
-- ════════════════════════════════
local snowParts={};local snowActive=false;local snowConn=nil
local snowFolder=Instance.new("Folder",workspace);snowFolder.Name="KittySnow"

local function startSnow()
    if snowActive then return end
    snowActive=true
    local spread=160;local height=80
    for i=1,600 do
        local root=getRoot();if not root then break end
        local sz=0.35+math.random()*(0.85-0.35)
        local p=neonPart(sz, Color3.fromRGB(200,225,255), 0.1)
        local rp=root.Position
        p.Position=Vector3.new(
            rp.X+math.random(-spread,spread),
            rp.Y+math.random(0,height),
            rp.Z+math.random(-spread,spread))
        p.Parent=snowFolder
        table.insert(snowParts,{part=p,speed=12+math.random()*18})
    end
    snowConn=RunService.Heartbeat:Connect(function(dt)
        if not snowActive then return end
        local root=getRoot();if not root then return end
        local rpos=root.Position
        for _,f in ipairs(snowParts) do
            local p=f.part
            if p and p.Parent then
                local fp=p.Position
                local ny=fp.Y-f.speed*dt
                if ny<rpos.Y-12 then
                    p.Position=Vector3.new(
                        rpos.X+math.random(-spread,spread),
                        rpos.Y+height,
                        rpos.Z+math.random(-spread,spread))
                else
                    p.Position=Vector3.new(
                        fp.X+math.sin(tick()*0.9+fp.X*0.5)*0.4*dt,
                        ny,
                        fp.Z+math.cos(tick()*0.7+fp.Z*0.5)*0.3*dt)
                end
            end
        end
    end)
    showNotif("Снег запущен! (600 снежинок)", Color3.fromRGB(100,160,220))
end

local function stopSnow()
    snowActive=false
    if snowConn then snowConn:Disconnect();snowConn=nil end
    for _,f in ipairs(snowParts) do
        if f.part and f.part.Parent then f.part:Destroy() end
    end
    snowParts={}
    showNotif("Снег остановлен!", Color3.fromRGB(90,90,150))
end

-- ════════════════════════════════
--   ДОЖДЬ
-- ════════════════════════════════
local function setRain()
    stopSnow()
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local em=Instance.new("Part")
    em.Size=Vector3.new(80,1,80);em.Anchored=true
    em.CanCollide=false;em.Transparency=1
    em.Position=root.Position+Vector3.new(0,40,0)
    em.Name="KittyRain";em.Parent=workspace
    local pe=Instance.new("ParticleEmitter",em)
    pe.Texture="rbxassetid://241922778";pe.Rate=500
    pe.Lifetime=NumberRange.new(1.5,2.5);pe.Speed=NumberRange.new(70,90)
    pe.EmissionDirection=Enum.NormalId.Bottom
    pe.Transparency=NumberSequence.new(0.35)
    pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.06),NumberSequenceKeypoint.new(1,0.02)})
    showNotif("Дождь запущен!", Color3.fromRGB(60,120,200))
end
local function stopRain()
    local rp=workspace:FindFirstChild("KittyRain")
    if rp then rp:Destroy() end
    showNotif("Дождь остановлен!", Color3.fromRGB(60,90,140))
end

-- ════════════════════════════════
--   ОРБИТА
-- ════════════════════════════════
local orbitActive=false;local orbitConn=nil
local orbitFolder=Instance.new("Folder",workspace);orbitFolder.Name="KittyOrbit"
local orbitParts={}

local function startOrbit(colorA,colorB,label)
    if orbitConn then orbitConn:Disconnect();orbitConn=nil end
    for _,p in ipairs(orbitParts) do if p and p.Parent then p:Destroy() end end
    orbitParts={};orbitActive=true
    colorA=colorA or Color3.fromRGB(120,255,80)
    colorB=colorB or Color3.fromRGB(200,255,100)
    local COUNT=80;local RADIUS=8
    for i=1,COUNT do
        local p=Instance.new("Part")
        p.Size=Vector3.new(0.55,0.55,0.55);p.Shape=Enum.PartType.Ball
        p.Material=Enum.Material.Neon;p.Color=colorA
        p.CastShadow=false;p.CanCollide=false;p.Anchored=true;p.Transparency=0.05
        p.Parent=orbitFolder;table.insert(orbitParts,p)
    end
    local TAIL=20
    for i=1,TAIL do
        local p=Instance.new("Part")
        local sz=0.9*(1-i/TAIL)+0.15
        p.Size=Vector3.new(sz,sz,sz);p.Shape=Enum.PartType.Ball
        p.Material=Enum.Material.Neon;p.Color=colorB
        p.CastShadow=false;p.CanCollide=false;p.Anchored=true;p.Transparency=0.0
        p.Parent=orbitFolder;table.insert(orbitParts,p)
    end
    local t0=tick()
    orbitConn=RunService.Heartbeat:Connect(function()
        local root=getRoot();if not root then return end
        local pos=root.Position;local t=(tick()-t0);local speed=1.4
        for i,p in ipairs(orbitParts) do
            if i>COUNT then break end
            if p and p.Parent then
                local angle=(i/COUNT)*math.pi*2+t*speed
                local x=math.cos(angle)*RADIUS
                local y=math.sin(angle)*RADIUS*0.35+math.sin(t*0.5)*0.8
                local z=math.sin(angle)*RADIUS
                p.Position=Vector3.new(pos.X+x,pos.Y+y,pos.Z+z)
                local mix=(math.sin(t*2+i*0.2)+1)/2
                p.Color=Color3.new(colorA.R+(colorB.R-colorA.R)*mix,colorA.G+(colorB.G-colorA.G)*mix,colorA.B+(colorB.B-colorA.B)*mix)
                local pulse=0.45+math.sin(t*3+i*0.15)*0.1
                p.Size=Vector3.new(pulse,pulse,pulse)
            end
        end
        local headAngle=t*speed
        for j=1,TAIL do
            local idx=COUNT+j;local p=orbitParts[idx]
            if p and p.Parent then
                local a=headAngle-j*0.12
                local x=math.cos(a)*RADIUS;local y=math.sin(a)*RADIUS*0.35+math.sin(t*0.5)*0.8;local z=math.sin(a)*RADIUS
                p.Position=Vector3.new(pos.X+x,pos.Y+y,pos.Z+z)
                local fade=1-(j/TAIL);p.Transparency=1-fade*0.95
                local sz=(0.9*fade)+0.1;p.Size=Vector3.new(sz,sz,sz);p.Color=colorB
            end
        end
    end)
    showNotif(label or "Орбита включена!", colorA)
end

local function stopOrbit()
    orbitActive=false
    if orbitConn then orbitConn:Disconnect();orbitConn=nil end
    for _,p in ipairs(orbitParts) do if p and p.Parent then p:Destroy() end end
    orbitParts={}
    showNotif("Орбита выключена!", Color3.fromRGB(80,80,140))
end

-- ════════════════════════════════
--   СЛЕД (ПОЧИНЕН)
--   Используем Attachment + Trail
--   вместо Part-цепочки
-- ════════════════════════════════
local trailActive   = false
local trailObject   = nil   -- сам Trail инстанс
local att0          = nil
local att1          = nil
local trailConn     = nil

local function startTrail(colorA, colorB, label)
    -- Сброс старого
    if trailObject then trailObject:Destroy(); trailObject=nil end
    if att0 then att0:Destroy(); att0=nil end
    if att1 then att1:Destroy(); att1=nil end
    if trailConn then trailConn:Disconnect(); trailConn=nil end

    trailActive = true
    colorA = colorA or Color3.fromRGB(80,160,255)
    colorB = colorB or Color3.fromRGB(160,80,255)

    local function attachTrail()
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Два аттачмента на разной высоте для ширины следа
        att0 = Instance.new("Attachment", root)
        att0.Position = Vector3.new(0, 1, 0)
        att1 = Instance.new("Attachment", root)
        att1.Position = Vector3.new(0, -1, 0)

        trailObject = Instance.new("Trail", root)
        trailObject.Attachment0 = att0
        trailObject.Attachment1 = att1
        trailObject.Lifetime    = 0.8
        trailObject.MinLength   = 0
        trailObject.FaceCamera  = true
        trailObject.LightEmission = 1
        trailObject.LightInfluence = 0
        trailObject.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colorA),
            ColorSequenceKeypoint.new(1, colorB),
        })
        trailObject.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.0),
            NumberSequenceKeypoint.new(1, 1.0),
        })
        trailObject.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })
    end

    attachTrail()

    -- Переподключаем при респавне
    trailConn = player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if trailActive then attachTrail() end
    end)

    showNotif(label or "След включён!", colorA)
end

local function stopTrail()
    trailActive = false
    if trailObject then trailObject:Destroy(); trailObject=nil end
    if att0 then att0:Destroy(); att0=nil end
    if att1 then att1:Destroy(); att1=nil end
    if trailConn then trailConn:Disconnect(); trailConn=nil end
    showNotif("След выключен!", Color3.fromRGB(70,90,150))
end

-- ════════════════════════════════
--   РАСТЯЖКА ТЕЛА (Body Scale)
-- ════════════════════════════════
local originalScales = {}

local function getHumanoidDesc()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    return hum:FindFirstChildOfClass("HumanoidDescription") or hum
end

local function applyBodyScale(bodyDepth, bodyHeight, bodyWidth, headScale, label)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Сохраняем оригинал
    if not originalScales.saved then
        originalScales.BodyDepthScale  = hum.BodyDepthScale
        originalScales.BodyHeightScale = hum.BodyHeightScale
        originalScales.BodyWidthScale  = hum.BodyWidthScale
        originalScales.HeadScale       = hum.HeadScale
        originalScales.saved = true
    end

    -- Плавная анимация через TweenService на Humanoid
    -- (Humanoid не поддерживает Tween напрямую, меняем пошагово)
    local steps = 20
    local startD = hum.BodyDepthScale
    local startH = hum.BodyHeightScale
    local startW = hum.BodyWidthScale
    local startHd= hum.HeadScale

    local stepConn
    local stepN = 0
    stepConn = RunService.Heartbeat:Connect(function()
        stepN = stepN + 1
        local t = math.min(stepN / steps, 1)
        local ease = 1 - (1-t)^3  -- cubic ease out
        hum.BodyDepthScale  = startD  + (bodyDepth  - startD)  * ease
        hum.BodyHeightScale = startH  + (bodyHeight - startH)  * ease
        hum.BodyWidthScale  = startW  + (bodyWidth  - startW)  * ease
        hum.HeadScale       = startHd + (headScale  - startHd) * ease
        if stepN >= steps then stepConn:Disconnect() end
    end)

    showNotif(label or "Размер изменён!", Color3.fromRGB(180,100,255))
end

local function resetBodyScale()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if originalScales.saved then
        hum.BodyDepthScale  = originalScales.BodyDepthScale
        hum.BodyHeightScale = originalScales.BodyHeightScale
        hum.BodyWidthScale  = originalScales.BodyWidthScale
        hum.HeadScale       = originalScales.HeadScale
        originalScales.saved = false
    else
        hum.BodyDepthScale  = 1
        hum.BodyHeightScale = 1
        hum.BodyWidthScale  = 1
        hum.HeadScale       = 1
    end
    showNotif("Размер сброшен!", Color3.fromRGB(130,100,180))
end

-- ════════════════════════════════
--   РАДУГА
-- ════════════════════════════════
local rainbowActive=false;local rainbowConn=nil
local rainbowFolder=Instance.new("Folder",workspace);rainbowFolder.Name="KittyRainbow"
local rainbowParts={}

local function startRainbow()
    if rainbowActive then return end
    rainbowActive=true
    rainbowConn=RunService.Heartbeat:Connect(function(dt)
        local root=getRoot();if not root then return end
        local pos=root.Position;local h=(tick()*0.4)%1
        local p=Instance.new("Part")
        p.Size=Vector3.new(0.8,0.12,0.8);p.Material=Enum.Material.Neon
        p.Color=Color3.fromHSV(h,1,1);p.CastShadow=false;p.CanCollide=false;p.Anchored=true;p.Transparency=0.05
        p.Position=Vector3.new(pos.X+math.random(-10,10)*0.1,pos.Y-2.8,pos.Z+math.random(-10,10)*0.1)
        p.Parent=rainbowFolder;table.insert(rainbowParts,{part=p,born=tick()})
        local now=tick()
        for i=#rainbowParts,1,-1 do
            local rp=rainbowParts[i]
            if rp.part and rp.part.Parent then
                local age=now-rp.born
                if age>0.8 then rp.part:Destroy();table.remove(rainbowParts,i)
                else rp.part.Transparency=0.05+(age/0.8)*0.95;local s=0.8+age*1.2;rp.part.Size=Vector3.new(s,0.12,s) end
            else table.remove(rainbowParts,i) end
        end
    end)
    showNotif("Радуга под ногами включена!", Color3.fromRGB(255,120,200))
end

local function stopRainbow()
    rainbowActive=false
    if rainbowConn then rainbowConn:Disconnect();rainbowConn=nil end
    for _,rp in ipairs(rainbowParts) do if rp.part and rp.part.Parent then rp.part:Destroy() end end
    rainbowParts={}
    showNotif("Радуга выключена!", Color3.fromRGB(140,80,150))
end

-- ════════════════════════════════
--   КРИСТАЛЬНАЯ КЛЕТКА
-- ════════════════════════════════
local cageActive=false;local cageConn=nil
local cageFolder=Instance.new("Folder",workspace);cageFolder.Name="KittyCage"
local cageParts={}

local function startCage(col,label)
    if cageConn then cageConn:Disconnect();cageConn=nil end
    for _,p in ipairs(cageParts) do if p and p.Parent then p:Destroy() end end
    cageParts={};cageActive=true
    col=col or Color3.fromRGB(0,200,255)
    local rings={{axis="X",offset=0},{axis="Y",offset=math.pi/3},{axis="Z",offset=math.pi*2/3}}
    local COUNT=30;local RADIUS=4.5
    for _,ring in ipairs(rings) do
        for i=1,COUNT do
            local p=neonPart(0.3,col,0.05);p.Parent=cageFolder
            table.insert(cageParts,{part=p,ring=ring,idx=i,total=COUNT})
        end
    end
    local t0=tick()
    cageConn=RunService.Heartbeat:Connect(function()
        local root=getRoot();if not root then return end
        local pos=root.Position;local t=(tick()-t0)*1.1
        for _,cp in ipairs(cageParts) do
            if cp.part and cp.part.Parent then
                local angle=(cp.idx/cp.total)*math.pi*2+t+cp.ring.offset
                local x,y,z=0,0,0
                if cp.ring.axis=="X" then y=math.cos(angle)*RADIUS;z=math.sin(angle)*RADIUS
                elseif cp.ring.axis=="Y" then x=math.cos(angle)*RADIUS;z=math.sin(angle)*RADIUS
                else x=math.cos(angle)*RADIUS;y=math.sin(angle)*RADIUS end
                cp.part.Position=Vector3.new(pos.X+x,pos.Y+y,pos.Z+z)
                local mix=(math.sin(t*2+cp.idx*0.3)+1)/2
                cp.part.Color=Color3.new(col.R*mix+1*(1-mix),col.G*mix+1*(1-mix),col.B*mix+0.3*(1-mix))
            end
        end
    end)
    showNotif(label or "Кристальная клетка включена!", col)
end

local function stopCage()
    cageActive=false
    if cageConn then cageConn:Disconnect();cageConn=nil end
    for _,p in ipairs(cageParts) do if p and p.Parent then p:Destroy() end end
    cageParts={}
    showNotif("Клетка выключена!", Color3.fromRGB(0,150,200))
end

-- ════════════════════════════════
--   ИСКРЫ
-- ════════════════════════════════
local sparkActive=false;local sparkConn=nil
local sparkFolder=Instance.new("Folder",workspace);sparkFolder.Name="KittySparks"
local sparkParts={}

local function startSparks(col,label,rainbow)
    if sparkConn then sparkConn:Disconnect();sparkConn=nil end
    for _,sp in ipairs(sparkParts) do if sp.part and sp.part.Parent then sp.part:Destroy() end end
    sparkParts={};sparkActive=true
    col=col or Color3.fromRGB(255,200,0)
    sparkConn=RunService.Heartbeat:Connect(function(dt)
        local root=getRoot();if not root then return end
        local pos=root.Position
        local useCol = rainbow and Color3.fromHSV((tick()*0.5)%1,1,1) or col
        for i=1,3 do
            local p=neonPart(0.18,useCol,0.0);p.Position=pos+Vector3.new(0,1,0);p.Parent=sparkFolder
            local dir=Vector3.new(math.random(-100,100)/100,math.random(20,100)/100,math.random(-100,100)/100).Unit
            table.insert(sparkParts,{part=p,born=tick(),vel=dir*(8+math.random()*14)})
        end
        local now=tick()
        for i=#sparkParts,1,-1 do
            local sp=sparkParts[i]
            if sp.part and sp.part.Parent then
                local age=now-sp.born;local life=0.75
                if age>life then sp.part:Destroy();table.remove(sparkParts,i)
                else
                    local t=age/life
                    sp.vel=sp.vel+Vector3.new(0,-18*dt,0)
                    sp.part.Position=sp.part.Position+sp.vel*dt
                    sp.part.Transparency=t*0.97
                    local s=0.18*(1-t*0.8);sp.part.Size=Vector3.new(s,s,s)
                end
            else table.remove(sparkParts,i) end
        end
    end)
    showNotif(label or "Искры включены!", col)
end

local function stopSparks()
    sparkActive=false
    if sparkConn then sparkConn:Disconnect();sparkConn=nil end
    for _,sp in ipairs(sparkParts) do if sp.part and sp.part.Parent then sp.part:Destroy() end end
    sparkParts={}
    showNotif("Искры выключены!", Color3.fromRGB(150,120,0))
end

-- ════════════════════════════════
--   ВЫКЛ ВСЁ
-- ════════════════════════════════
local function stopAll()
    stopOrbit();stopTrail();stopRainbow();stopCage();stopSparks();stopSnow();stopRain()
    showNotif("Все эффекты выключены!", Color3.fromRGB(150,80,80))
end

-- ════════════════════════════════
--   GUI
-- ════════════════════════════════
local screenGui=Instance.new("ScreenGui",playerGui)
screenGui.Name="KittyGui";screenGui.ResetOnSpawn=false
screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;screenGui.DisplayOrder=999

local main=Instance.new("Frame",screenGui)
main.Size=UDim2.new(0,545,0,400)
main.Position=UDim2.new(0.5,-272,0.5,-200)
main.BackgroundColor3=Color3.fromRGB(10,9,18)
main.BorderSizePixel=0;main.Active=true;main.Draggable=true;main.Visible=true
Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)
local ms=Instance.new("UIStroke",main)
ms.Color=Color3.fromRGB(75,65,175);ms.Thickness=1;ms.Transparency=0.3

local titleBar=Instance.new("Frame",main)
titleBar.Size=UDim2.new(1,0,0,44);titleBar.BackgroundColor3=Color3.fromRGB(13,11,26)
titleBar.BorderSizePixel=0
Instance.new("UICorner",titleBar).CornerRadius=UDim.new(0,12)
local tfx=Instance.new("Frame",titleBar)
tfx.Size=UDim2.new(1,0,0.5,0);tfx.Position=UDim2.new(0,0,0.5,0)
tfx.BackgroundColor3=Color3.fromRGB(13,11,26);tfx.BorderSizePixel=0

local titleTxt=Instance.new("TextLabel",titleBar)
titleTxt.Size=UDim2.new(1,-100,1,0);titleTxt.Position=UDim2.new(0,16,0,0)
titleTxt.BackgroundTransparency=1;titleTxt.Text="Kitty Script"
titleTxt.TextColor3=Color3.fromRGB(210,205,255)
titleTxt.TextSize=16;titleTxt.Font=Enum.Font.GothamBold
titleTxt.TextXAlignment=Enum.TextXAlignment.Left;titleTxt.ZIndex=3

local function makeTBtn(offX,bg,txt)
    local b=Instance.new("TextButton",titleBar)
    b.Size=UDim2.new(0,28,0,28);b.Position=UDim2.new(1,offX,0.5,-14)
    b.BackgroundColor3=bg;b.Text=txt
    b.TextColor3=Color3.fromRGB(255,255,255);b.TextSize=14
    b.Font=Enum.Font.GothamBold;b.BorderSizePixel=0;b.ZIndex=4
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    return b
end
local closeBtn=makeTBtn(-36,Color3.fromRGB(145,32,32),"x")
local minBtn=makeTBtn(-70,Color3.fromRGB(42,38,98),"-")

local navPanel=Instance.new("Frame",main)
navPanel.Size=UDim2.new(0,152,1,-44);navPanel.Position=UDim2.new(0,0,0,44)
navPanel.BackgroundColor3=Color3.fromRGB(12,10,22);navPanel.BorderSizePixel=0
local navLayout=Instance.new("UIListLayout",navPanel)
navLayout.Padding=UDim.new(0,0);navLayout.SortOrder=Enum.SortOrder.LayoutOrder

local divLine=Instance.new("Frame",main)
divLine.Size=UDim2.new(0,1,1,-44);divLine.Position=UDim2.new(0,152,0,44)
divLine.BackgroundColor3=Color3.fromRGB(38,35,78);divLine.BorderSizePixel=0

local contentArea=Instance.new("Frame",main)
contentArea.Size=UDim2.new(1,-152,1,-44);contentArea.Position=UDim2.new(0,152,0,44)
contentArea.BackgroundColor3=Color3.fromRGB(15,13,28);contentArea.BorderSizePixel=0

-- Аватарка
local avaFrame=Instance.new("Frame",navPanel)
avaFrame.Size=UDim2.new(1,0,0,50);avaFrame.LayoutOrder=99
avaFrame.BackgroundColor3=Color3.fromRGB(10,8,20);avaFrame.BorderSizePixel=0
local avaDiv=Instance.new("Frame",avaFrame)
avaDiv.Size=UDim2.new(1,0,0,1);avaDiv.BackgroundColor3=Color3.fromRGB(36,34,70);avaDiv.BorderSizePixel=0
local avaIco=Instance.new("TextLabel",avaFrame)
avaIco.Size=UDim2.new(0,28,0,28);avaIco.Position=UDim2.new(0,8,0.5,-14)
avaIco.BackgroundColor3=Color3.fromRGB(58,48,138);avaIco.BorderSizePixel=0
avaIco.Text=string.sub(player.Name,1,1):upper()
avaIco.TextColor3=Color3.fromRGB(210,205,255);avaIco.TextSize=13;avaIco.Font=Enum.Font.GothamBold
Instance.new("UICorner",avaIco).CornerRadius=UDim.new(1,0)
local avaName=Instance.new("TextLabel",avaFrame)
avaName.Size=UDim2.new(1,-44,1,0);avaName.Position=UDim2.new(0,42,0,0)
avaName.BackgroundTransparency=1;avaName.Text=player.Name
avaName.TextColor3=Color3.fromRGB(135,130,195);avaName.TextSize=12;avaName.Font=Enum.Font.Gotham
avaName.TextXAlignment=Enum.TextXAlignment.Left

-- Страницы
local pages={}
local function makePage(name)
    local pg=Instance.new("ScrollingFrame",contentArea)
    pg.Size=UDim2.new(1,0,1,0);pg.BackgroundTransparency=1
    pg.BorderSizePixel=0;pg.ScrollBarThickness=3
    pg.ScrollBarImageColor3=Color3.fromRGB(75,70,145)
    pg.CanvasSize=UDim2.new(0,0,0,0);pg.Visible=false
    local l=Instance.new("UIListLayout",pg)
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        pg.CanvasSize=UDim2.new(0,0,0,l.AbsoluteContentSize.Y+16)
    end)
    pages[name]=pg;return pg
end

local function makeSection(page,title,order)
    local hdr=Instance.new("TextLabel",page)
    hdr.Size=UDim2.new(1,0,0,26);hdr.BackgroundTransparency=1
    hdr.Text=title;hdr.TextColor3=Color3.fromRGB(90,85,155)
    hdr.TextSize=10;hdr.Font=Enum.Font.GothamBold
    hdr.TextXAlignment=Enum.TextXAlignment.Left;hdr.LayoutOrder=order
    local pad=Instance.new("UIPadding",hdr)
    pad.PaddingLeft=UDim.new(0,14);pad.PaddingTop=UDim.new(0,8)
end

local function makeActionBtn(page,label,order)
    local row=Instance.new("Frame",page)
    row.Size=UDim2.new(1,0,0,40);row.BackgroundColor3=Color3.fromRGB(19,17,34)
    row.BorderSizePixel=0;row.LayoutOrder=order
    local div=Instance.new("Frame",row)
    div.Size=UDim2.new(1,0,0,1);div.Position=UDim2.new(0,0,1,-1)
    div.BackgroundColor3=Color3.fromRGB(30,28,55);div.BorderSizePixel=0
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-46,1,0);lbl.Position=UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency=1;lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(198,195,245);lbl.TextSize=13;lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(0,22,0,22);btn.Position=UDim2.new(1,-30,0.5,-11)
    btn.BackgroundColor3=Color3.fromRGB(45,40,105);btn.Text=">"
    btn.TextColor3=Color3.fromRGB(170,165,245);btn.TextSize=12
    btn.Font=Enum.Font.GothamBold;btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    row.MouseEnter:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(28,25,48)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(19,17,34)}):Play()
    end)
    return btn
end

-- ════ НЕБО ════
local pgSky=makePage("sky")
makeSection(pgSky,"СКАЙБОКС",1)
local bSky=makeActionBtn(pgSky,"Применить красивое небо",2)
local bDay=makeActionBtn(pgSky,"День  (14:00)",3)
local bSunset=makeActionBtn(pgSky,"Закат  (18:00)",4)
local bNight=makeActionBtn(pgSky,"Ночь  (0:00)",5)
makeSection(pgSky,"АТМОСФЕРА",6)
local bFogOn=makeActionBtn(pgSky,"Включить туман",7)
local bFogOff=makeActionBtn(pgSky,"Убрать туман",8)
bSky.MouseButton1Click:Connect(applySky)
bDay.MouseButton1Click:Connect(function() setTime(14) end)
bSunset.MouseButton1Click:Connect(function() setTime(18) end)
bNight.MouseButton1Click:Connect(function() setTime(0) end)
bFogOn.MouseButton1Click:Connect(function() setFog(200) end)
bFogOff.MouseButton1Click:Connect(removeFog)

-- ════ ПОГОДА ════
local pgWeather=makePage("weather")
makeSection(pgWeather,"СНЕГ",1)
local bSnowOn=makeActionBtn(pgWeather,"Запустить снег  (600шт)",2)
local bSnowOff=makeActionBtn(pgWeather,"Остановить снег",3)
makeSection(pgWeather,"ДОЖДЬ",4)
local bRainOn=makeActionBtn(pgWeather,"Запустить дождь",5)
local bRainOff=makeActionBtn(pgWeather,"Остановить дождь",6)
bSnowOn.MouseButton1Click:Connect(startSnow)
bSnowOff.MouseButton1Click:Connect(stopSnow)
bRainOn.MouseButton1Click:Connect(setRain)
bRainOff.MouseButton1Click:Connect(stopRain)

-- ════ ВИЗУАЛ ════
local pgVisual=makePage("visual")
makeSection(pgVisual,"ОРБИТА",1)
local bOrbGreen=makeActionBtn(pgVisual,"Зеленая орбита",2)
local bOrbBlue=makeActionBtn(pgVisual,"Синяя орбита",3)
local bOrbFire=makeActionBtn(pgVisual,"Огненная орбита",4)
local bOrbCyan=makeActionBtn(pgVisual,"Cyan орбита",5)
local bOrbOff=makeActionBtn(pgVisual,"Орбита  ВЫКЛ",6)
makeSection(pgVisual,"СЛЕД",7)
local bTrailBlue=makeActionBtn(pgVisual,"Синий след",8)
local bTrailFire=makeActionBtn(pgVisual,"Огненный след",9)
local bTrailRainbow=makeActionBtn(pgVisual,"Радужный след",10)
local bTrailOff=makeActionBtn(pgVisual,"След  ВЫКЛ",11)
makeSection(pgVisual,"КОЛЬЦА",12)
local bCageBlue=makeActionBtn(pgVisual,"Синяя клетка",13)
local bCagePink=makeActionBtn(pgVisual,"Розовая клетка",14)
local bCageOff=makeActionBtn(pgVisual,"Клетка  ВЫКЛ",15)
makeSection(pgVisual,"ИСКРЫ",16)
local bSparkGold=makeActionBtn(pgVisual,"Золотые искры",17)
local bSparkBlue=makeActionBtn(pgVisual,"Синие искры",18)
local bSparkRainbow=makeActionBtn(pgVisual,"Радужные искры",19)
local bSparkOff=makeActionBtn(pgVisual,"Искры  ВЫКЛ",20)
makeSection(pgVisual,"ПОД НОГАМИ",21)
local bRainbowOn=makeActionBtn(pgVisual,"Радуга  ВКЛ",22)
local bRainbowOff=makeActionBtn(pgVisual,"Радуга  ВЫКЛ",23)
makeSection(pgVisual,"СБРОС",24)
local bStopAll=makeActionBtn(pgVisual,"Выключить ВСЕ",25)

bOrbGreen.MouseButton1Click:Connect(function() startOrbit(Color3.fromRGB(100,255,80),Color3.fromRGB(200,255,120),"Зеленая орбита!") end)
bOrbBlue.MouseButton1Click:Connect(function() startOrbit(Color3.fromRGB(80,160,255),Color3.fromRGB(160,80,255),"Синяя орбита!") end)
bOrbFire.MouseButton1Click:Connect(function() startOrbit(Color3.fromRGB(255,80,20),Color3.fromRGB(255,220,30),"Огненная орбита!") end)
bOrbCyan.MouseButton1Click:Connect(function() startOrbit(Color3.fromRGB(0,220,220),Color3.fromRGB(0,255,180),"Cyan орбита!") end)
bOrbOff.MouseButton1Click:Connect(stopOrbit)
bTrailBlue.MouseButton1Click:Connect(function() startTrail(Color3.fromRGB(80,160,255),Color3.fromRGB(160,80,255),"Синий след!") end)
bTrailFire.MouseButton1Click:Connect(function() startTrail(Color3.fromRGB(255,120,20),Color3.fromRGB(255,220,0),"Огненный след!") end)
bTrailRainbow.MouseButton1Click:Connect(function() startTrail(Color3.fromRGB(255,80,200),Color3.fromRGB(80,200,255),"Радужный след!") end)
bTrailOff.MouseButton1Click:Connect(stopTrail)
bCageBlue.MouseButton1Click:Connect(function() startCage(Color3.fromRGB(0,200,255),"Синяя клетка!") end)
bCagePink.MouseButton1Click:Connect(function() startCage(Color3.fromRGB(255,80,200),"Розовая клетка!") end)
bCageOff.MouseButton1Click:Connect(stopCage)
bSparkGold.MouseButton1Click:Connect(function() startSparks(Color3.fromRGB(255,200,0),"Золотые искры!") end)
bSparkBlue.MouseButton1Click:Connect(function() startSparks(Color3.fromRGB(80,160,255),"Синие искры!") end)
bSparkRainbow.MouseButton1Click:Connect(function() startSparks(nil,"Радужные искры!",true) end)
bSparkOff.MouseButton1Click:Connect(stopSparks)
bRainbowOn.MouseButton1Click:Connect(startRainbow)
bRainbowOff.MouseButton1Click:Connect(stopRainbow)
bStopAll.MouseButton1Click:Connect(stopAll)

-- ════ РАСТЯЖКА ════
local pgScale=makePage("scale")
makeSection(pgScale,"РАСТЯЖКА ТЕЛА",1)
local bTall=makeActionBtn(pgScale,"Высокий  (x2.0)",2)
local bShort=makeActionBtn(pgScale,"Маленький  (x0.5)",3)
local bFat=makeActionBtn(pgScale,"Толстый  (x2.0 ширина)",4)
local bThin=makeActionBtn(pgScale,"Тонкий  (x0.4 ширина)",5)
local bBigHead=makeActionBtn(pgScale,"Большая голова  (x2.5)",6)
local bSmallHead=makeActionBtn(pgScale,"Маленькая голова  (x0.3)",7)
makeSection(pgScale,"ПРЕСЕТЫ",8)
local bGiant=makeActionBtn(pgScale,"Гигант",9)
local bMini=makeActionBtn(pgScale,"Мини",10)
local bNoodle=makeActionBtn(pgScale,"Лапша (тонкий высокий)",11)
local bBall=makeActionBtn(pgScale,"Колобок (толстый низкий)",12)
makeSection(pgScale,"СБРОС",13)
local bScaleReset=makeActionBtn(pgScale,"Сбросить размер",14)

-- bodyDepth, bodyHeight, bodyWidth, headScale
bTall.MouseButton1Click:Connect(function()       applyBodyScale(1,2.0,1,1,"Высокий!") end)
bShort.MouseButton1Click:Connect(function()      applyBodyScale(1,0.5,1,1,"Маленький!") end)
bFat.MouseButton1Click:Connect(function()        applyBodyScale(2,1,2,1,"Толстый!") end)
bThin.MouseButton1Click:Connect(function()       applyBodyScale(0.4,1,0.4,1,"Тонкий!") end)
bBigHead.MouseButton1Click:Connect(function()    applyBodyScale(1,1,1,2.5,"Большая голова!") end)
bSmallHead.MouseButton1Click:Connect(function()  applyBodyScale(1,1,1,0.3,"Маленькая голова!") end)
bGiant.MouseButton1Click:Connect(function()      applyBodyScale(2,3,2,2,"Гигант!") end)
bMini.MouseButton1Click:Connect(function()       applyBodyScale(0.5,0.4,0.5,0.5,"Мини!") end)
bNoodle.MouseButton1Click:Connect(function()     applyBodyScale(0.3,2.5,0.3,0.5,"Лапша!") end)
bBall.MouseButton1Click:Connect(function()       applyBodyScale(2,0.5,2,1.5,"Колобок!") end)
bScaleReset.MouseButton1Click:Connect(resetBodyScale)

-- ════ ПРОЧЕЕ ════
local pgMisc=makePage("misc")
makeSection(pgMisc,"МЫШЬ",1)
local bUnlock=makeActionBtn(pgMisc,"Разблокировать мышь",2)
local bHide=makeActionBtn(pgMisc,"Скрыть курсор",3)
local bShow=makeActionBtn(pgMisc,"Показать курсор",4)
makeSection(pgMisc,"СВЕЧЕНИЕ ПРЕДМЕТОВ",5)
-- Toggle кнопка Object Glow
local glowToggleRow=Instance.new("Frame",pgMisc)
glowToggleRow.Size=UDim2.new(1,0,0,40);glowToggleRow.BackgroundColor3=Color3.fromRGB(19,17,34)
glowToggleRow.BorderSizePixel=0;glowToggleRow.LayoutOrder=6
local glowDiv=Instance.new("Frame",glowToggleRow)
glowDiv.Size=UDim2.new(1,0,0,1);glowDiv.Position=UDim2.new(0,0,1,-1)
glowDiv.BackgroundColor3=Color3.fromRGB(30,28,55);glowDiv.BorderSizePixel=0
local glowLbl=Instance.new("TextLabel",glowToggleRow)
glowLbl.Size=UDim2.new(1,-60,1,0);glowLbl.Position=UDim2.new(0,14,0,0)
glowLbl.BackgroundTransparency=1;glowLbl.Text="Синее свечение предмета"
glowLbl.TextColor3=Color3.fromRGB(198,195,245);glowLbl.TextSize=13;glowLbl.Font=Enum.Font.Gotham
glowLbl.TextXAlignment=Enum.TextXAlignment.Left
local glowToggleBtn=Instance.new("TextButton",glowToggleRow)
glowToggleBtn.Size=UDim2.new(0,40,0,22);glowToggleBtn.Position=UDim2.new(1,-50,0.5,-11)
glowToggleBtn.BorderSizePixel=0;glowToggleBtn.Font=Enum.Font.GothamBold;glowToggleBtn.TextSize=10
Instance.new("UICorner",glowToggleBtn).CornerRadius=UDim.new(0,11)
local function updateGlowBtn()
    if glowEnabled then
        glowToggleBtn.BackgroundColor3=Color3.fromRGB(40,100,255)
        glowToggleBtn.TextColor3=Color3.fromRGB(255,255,255)
        glowToggleBtn.Text="ON"
    else
        glowToggleBtn.BackgroundColor3=Color3.fromRGB(45,40,70)
        glowToggleBtn.TextColor3=Color3.fromRGB(130,125,180)
        glowToggleBtn.Text="OFF"
        clearGlow()
    end
end
updateGlowBtn()
glowToggleBtn.MouseButton1Click:Connect(function()
    glowEnabled=not glowEnabled
    updateGlowBtn()
    showNotif("Свечение: "..(glowEnabled and "ON" or "OFF"),
        glowEnabled and Color3.fromRGB(40,100,255) or Color3.fromRGB(80,80,130))
end)
glowToggleRow.MouseEnter:Connect(function()
    TweenService:Create(glowToggleRow,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(28,25,48)}):Play()
end)
glowToggleRow.MouseLeave:Connect(function()
    TweenService:Create(glowToggleRow,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(19,17,34)}):Play()
end)

bUnlock.MouseButton1Click:Connect(function()
    UserInputService.MouseBehavior=Enum.MouseBehavior.Default
    showNotif("Мышь разблокирована!", Color3.fromRGB(80,200,120))
end)
bHide.MouseButton1Click:Connect(function()
    UserInputService.MouseIconEnabled=false
    showNotif("Курсор скрыт!", Color3.fromRGB(130,100,200))
end)
bShow.MouseButton1Click:Connect(function()
    UserInputService.MouseIconEnabled=true
    showNotif("Курсор показан!", Color3.fromRGB(130,100,200))
end)

-- ════════════════════════════════
--   НАВИГАЦИЯ
-- ════════════════════════════════
local navItems={
    {label="  Sky",      page="sky"},
    {label="  Weather",  page="weather"},
    {label="  Visual",   page="visual"},
    {label="  Scale",    page="scale"},
    {label="  Misc",     page="misc"},
}
local navBtns={};local currentPage=nil

local function selectPage(name)
    for n,pg in pairs(pages) do pg.Visible=(n==name) end
    for _,nb in ipairs(navBtns) do
        local active=nb.pageName==name
        TweenService:Create(nb.btn,TweenInfo.new(0.12),{
            BackgroundColor3=active and Color3.fromRGB(42,38,102) or Color3.fromRGB(12,10,22)
        }):Play()
        nb.dot.Visible=active
    end
    currentPage=name
end

for i,item in ipairs(navItems) do
    local btn=Instance.new("TextButton",navPanel)
    btn.Size=UDim2.new(1,0,0,40);btn.LayoutOrder=i
    btn.BackgroundColor3=Color3.fromRGB(12,10,22)
    btn.Text="";btn.BorderSizePixel=0
    local dot=Instance.new("Frame",btn)
    dot.Size=UDim2.new(0,3,0.5,0);dot.Position=UDim2.new(0,0,0.25,0)
    dot.BackgroundColor3=Color3.fromRGB(95,85,205);dot.BorderSizePixel=0;dot.Visible=false
    local lbl=Instance.new("TextLabel",btn)
    lbl.Size=UDim2.new(1,-8,1,0);lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1;lbl.Text=item.label
    lbl.TextColor3=Color3.fromRGB(160,155,215);lbl.TextSize=13;lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local divN=Instance.new("Frame",btn)
    divN.Size=UDim2.new(1,0,0,1);divN.Position=UDim2.new(0,0,1,-1)
    divN.BackgroundColor3=Color3.fromRGB(26,24,50);divN.BorderSizePixel=0
    btn.MouseButton1Click:Connect(function() selectPage(item.page) end)
    btn.MouseEnter:Connect(function()
        if currentPage~=item.page then
            TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(20,18,42)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentPage~=item.page then
            TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(12,10,22)}):Play()
        end
    end)
    table.insert(navBtns,{btn=btn,dot=dot,pageName=item.page})
end

selectPage("sky")

-- ════════════════════════════════
--   ЗАГОЛОВОК
-- ════════════════════════════════
closeBtn.MouseButton1Click:Connect(function()
    main.Visible=false
    UserInputService.MouseBehavior=Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled=false
    showNotif("Kitty скрыт", Color3.fromRGB(75,65,155))
end)

local minimized=false
minBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    navPanel.Visible=not minimized
    contentArea.Visible=not minimized
    divLine.Visible=not minimized
    main.Size=minimized and UDim2.new(0,545,0,44) or UDim2.new(0,545,0,400)
end)

-- ════════════════════════════════
--   RIGHT CTRL
-- ════════════════════════════════
local guiOpen=true
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.RightControl then
        guiOpen=not guiOpen
        main.Visible=guiOpen
        if guiOpen then
            UserInputService.MouseBehavior=Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled=true
            showNotif("Kitty открыт", Color3.fromRGB(90,80,200))
        else
            UserInputService.MouseBehavior=Enum.MouseBehavior.LockCenter
            UserInputService.MouseIconEnabled=false
            showNotif("Kitty скрыт", Color3.fromRGB(60,55,130))
        end
    end
end)

-- ════════════════════════════════
--   ПРИВЕТСТВИЕ
-- ════════════════════════════════
task.wait(0.8)
showNotif("Kitty Script v3.2 запущен!", Color3.fromRGB(100,85,220))
task.wait(1.2)
showNotif("Привет, "..player.Name.."!", Color3.fromRGB(60,160,100))

print("[Kitty v3.2] Готово! RightCtrl — открыть/скрыть.")
