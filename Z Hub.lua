local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local keybindsEnabled = true

local localPlayer = Players.LocalPlayer
local accountText = "Logged in as: Unknown"
if localPlayer then
    accountText = "Logged in as: " .. localPlayer.DisplayName .. " (@" .. localPlayer.Name .. ")"
end

-- NOTE: Gen2's documented CreateWindow properties are name, subtitle, theme, icon,
-- showName, showIcon, configuration, locale, translations, translator, fallbackFont.
-- Discord/KeySystem/ScriptID from Gen1 aren't part of that list, so they're dropped here.
local Window = Rayfield:CreateWindow({
    name = "Z Hub",
    subtitle = "by Areeb Z (Fork of Wacky Hub)",
    theme = "cobalt", -- closest built-in match to the old AmberGlow theme
    showName = "Z Hub",
    configuration = {
        autoSave = false,
        autoLoad = false,
        fileName = "Z Hub",
    },
})

Window:Notify({
    title = "Z Hub is loading(hang tight!)",
    content = "Script's loading!",
    duration = 2.5,
})

-- Toast whenever someone joins the server
Players.PlayerAdded:Connect(function(player)
    Window:Toast({
        title = player.DisplayName,
        subtitle = "joined the server",
        avatar = player.UserId,
    })
end)

local homeTab = Window:CreateTab({ name = "Home", icon = 4483362458 })

homeTab:CreateSection({ name = "Welcome to Z Hub" })

homeTab:CreateButton({
    name = "Credits",
    description = "Z Hub is a fork - original source by RoboSubZero2/Fisticuffs",
    callback = function()
        Window:Notify({
            title = "Credits",
            content = "Z Hub by Areeb Z. Original source code by RoboSubZero2/Fisticuffs.",
            duration = 6.5,
        })
    end,
})

homeTab:CreateButton({
    name = "Account",
    description = accountText,
    callback = function()
        Window:Toast({
            title = localPlayer.DisplayName,
            subtitle = "@" .. localPlayer.Name,
            avatar = localPlayer.UserId,
        })
    end,
})

local profilePicGui = nil
local profilePicVisible = false

local function getGuiParent()
    if gethui then
        return gethui()
    else
        return Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function createProfilePicGui()
    if profilePicGui then return end

    local success, thumbnail = pcall(function()
        return Players:GetUserThumbnailAsync(
            Players.LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)

    if not success then
        warn("Failed to get thumbnail")
        return
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ProfilePicDisplay"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.Parent = getGuiParent()

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 150, 0, 190)
    Frame.Position = UDim2.new(0.5, -75, 0, 20)
    Frame.BackgroundTransparency = 1
    Frame.Parent = ScreenGui

    local ProfilePic = Instance.new("ImageLabel")
    ProfilePic.Size = UDim2.new(0, 150, 0, 150)
    ProfilePic.Position = UDim2.new(0, 0, 0, 0)
    ProfilePic.Image = thumbnail
    ProfilePic.BackgroundTransparency = 1
    ProfilePic.Parent = Frame

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, 0, 0, 30)
    NameLabel.Position = UDim2.new(0, 0, 0, 155)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = Players.LocalPlayer.DisplayName .. " (@" .. Players.LocalPlayer.Name .. ")"
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextStrokeTransparency = 0
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextScaled = true
    NameLabel.Parent = Frame

    profilePicGui = ScreenGui
end

homeTab:CreateToggle({
    name = "Show Profile Picture",
    value = false,
    flag = "ProfilePicToggle",
    callback = function(value)
        profilePicVisible = value
        if value then
            createProfilePicGui()
            if profilePicGui then
                profilePicGui.Enabled = true
            end
        else
            if profilePicGui then
                profilePicGui.Enabled = false
            end
        end
    end,
})

homeTab:CreateButton({
    name = "Destroy UI",
    callback = function()
        Window:Popup({
            title = "Are you sure?",
            content = "This will completely remove the UI from your screen.",
            options = {
                { text = "Cancel" },
                {
                    text = "Yes, Destroy",
                    style = "danger",
                    callback = function()
                        Window:Unload()
                    end
                },
            },
        })
    end,
})

homeTab:CreateSection({ name = "Server Info" })

local StatsService = game:GetService("Stats")

local pingStat = homeTab:CreateStat({
    name = "Ping",
    value = 0,
    suffix = "ms",
})

homeTab:CreateButton({
    name = "Server Info",
    description = "View current server details",
    callback = function()
        Window:Popup({
            title = "Server Information",
            subtitle = "Current Session Details",
            boxes = {
                {
                    title = "Job ID",
                    description = game.JobId,
                    icon = 93364949241311
                },
                {
                    title = "Place ID",
                    description = tostring(game.PlaceId)
                },
                {
                    title = "Player Count",
                    description = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
                },
            },
            options = {
                { text = "Close", style = "primary" }
            },
        })
    end,
})

if getgenv().ZHubPingConn then
    getgenv().ZHubPingConn:Disconnect()
end

getgenv().ZHubPingConn = RunService.Heartbeat:Connect(function()
    local success, pingValue = pcall(function()
        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)

    if success then
        pingStat:Set(math.floor(pingValue))
    end
end)

homeTab:CreateSection({ name = "Interface" })

local executorName = "Unknown"
local execSuccess, execResult = pcall(function()
    if identifyexecutor then
        return identifyexecutor()
    elseif getexecutorname then
        return getexecutorname()
    end
    return "Unknown"
end)

if execSuccess and execResult then
    executorName = execResult
end

-- Stat's value must be a number, so the executor name goes in prefix instead,
-- with value/suffix left blank since there's no real number to show here.
homeTab:CreateStat({
    name = "Executor",
    prefix = tostring(executorName),
    value = 0,
    suffix = "",
})

local fpsStat = homeTab:CreateStat({
    name = "FPS",
    value = 0,
})

local fpsCounterEnabled = false
local fpsFrameCount = 0
local fpsElapsed = 0

if getgenv().ZHubFpsConn then
    getgenv().ZHubFpsConn:Disconnect()
end

getgenv().ZHubFpsConn = RunService.RenderStepped:Connect(function(deltaTime)
    if not fpsCounterEnabled then return end

    fpsFrameCount += 1
    fpsElapsed += deltaTime

    if fpsElapsed >= 1 then
        fpsStat:Set(math.floor(fpsFrameCount / fpsElapsed))
        fpsFrameCount = 0
        fpsElapsed = 0
    end
end)

homeTab:CreateToggle({
    name = "Show FPS Counter",
    value = false,
    flag = "ShowFPSCounterToggle",
    callback = function(value)
        fpsCounterEnabled = value
        fpsFrameCount = 0
        fpsElapsed = 0
        if not value then
            fpsStat:Set(0)
        end
    end,
})

-- Anti-AFK, same trick Infinite Yield uses: on Idled, simulate a click via
-- VirtualUser so Roblox's idle/kick timer resets without moving your character.
local antiAfkEnabled = false
local VirtualUser = game:GetService("VirtualUser")

if getgenv().ZHubAntiAfkConn then
    getgenv().ZHubAntiAfkConn:Disconnect()
end

getgenv().ZHubAntiAfkConn = Players.LocalPlayer.Idled:Connect(function()
    if not antiAfkEnabled then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

homeTab:CreateToggle({
    name = "Anti-AFK",
    value = false,
    flag = "AntiAFKToggle",
    callback = function(value)
        antiAfkEnabled = value
    end,
})

local walkSpeedValue = 16
local jumpHeightValue = 10

-- Disconnect any leftover loop from a previous run of this script before
-- starting a new one, or re-executing without a full server rejoin leaves
-- the old loop fighting the new one over WalkSpeed/JumpHeight forever.
if getgenv().ZHubWalkJumpConn then
    getgenv().ZHubWalkJumpConn:Disconnect()
end

getgenv().ZHubWalkJumpConn = RunService.Heartbeat:Connect(function()
    local char = Players.LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = walkSpeedValue
        hum.JumpHeight = jumpHeightValue
    end
end)


local localPlayerTab = Window:CreateTab({ name = "Local Player", icon = 4483362458 })

localPlayerTab:CreateSlider({
    name = "Walkspeed Override",
    range = { 16, 250 },
    increment = 1,
    value = 16,
    suffix = "Speed",
    flag = "walkspeed",
    callback = function(value)
        walkSpeedValue = value
    end,
})

localPlayerTab:CreateSlider({
    name = "Jump Power Override",
    range = { 0, 250 },
    increment = 1,
    value = 10,
    suffix = "Jump Power",
    flag = "jumpheight",
    callback = function(value)
        jumpHeightValue = value
    end,
})

localPlayerTab:CreateSlider({
    name = "Gravity Override",
    range = { 0, 500 },
    increment = 10,
    value = 196.2,
    suffix = "Gravity",
    flag = "gravity",
    callback = function(value)
        game.workspace.Gravity = value
    end,
})

local ProximityPromptService = game:GetService("ProximityPromptService")

local instantPromptsEnabled = false
local originalHoldDurations = {}

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
    print("PromptShown fired:", prompt.Name, "| Parent:", prompt.Parent and prompt.Parent.Name or "nil", "| HoldDuration:", prompt.HoldDuration)
    if not instantPromptsEnabled then return end
    if originalHoldDurations[prompt] == nil then
        originalHoldDurations[prompt] = prompt.HoldDuration
    end
    prompt.HoldDuration = 0.1
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
    if originalHoldDurations[prompt] then
        prompt.HoldDuration = originalHoldDurations[prompt]
        originalHoldDurations[prompt] = nil
    end
end)

localPlayerTab:CreateToggle({
    name = "Fast Proximity Prompts",
    value = false,
    flag = "InstantPromptsToggle",
    callback = function(value)
        instantPromptsEnabled = value
    end,
})

localPlayerTab:CreateSection({ name = "Character" })

-- NoClip: stop our own parts from colliding. Original CanCollide values are
-- remembered per part so turning it off restores them instead of permanently
-- leaving everything walk-through.
local noclipEnabled = false

-- Re-execution hygiene, same idea as the other loops in this script: stop a
-- leftover loop and put back any parts the previous run left non-collidable.
if getgenv().ZHubNoClipConn then
    getgenv().ZHubNoClipConn:Disconnect()
    getgenv().ZHubNoClipConn = nil
end

local staleNoclipOriginals = getgenv().ZHubNoClipOriginals
if staleNoclipOriginals then
    for part, original in pairs(staleNoclipOriginals) do
        if part and part.Parent then
            pcall(function() part.CanCollide = original end)
        end
    end
end

local noclipOriginalCollide = setmetatable({}, { __mode = "k" })
getgenv().ZHubNoClipOriginals = noclipOriginalCollide
local noclipConnection

local function startNoClip()
    if noclipConnection then noclipConnection:Disconnect() end

    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        local char = Players.LocalPlayer.Character
        if not char then return end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if noclipOriginalCollide[part] == nil then
                    noclipOriginalCollide[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)
    getgenv().ZHubNoClipConn = noclipConnection
end

local function stopNoClip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    getgenv().ZHubNoClipConn = nil

    for part, original in pairs(noclipOriginalCollide) do
        if part and part.Parent then
            pcall(function() part.CanCollide = original end)
        end
    end
    noclipOriginalCollide = setmetatable({}, { __mode = "k" })
    getgenv().ZHubNoClipOriginals = noclipOriginalCollide
end

localPlayerTab:CreateToggle({
    name = "NoClip",
    value = false,
    flag = "NoClipToggle",
    callback = function(value)
        noclipEnabled = value
        if value then startNoClip() else stopNoClip() end
    end,
})

-- Infinite Jump: every JumpRequest re-enters the Jumping state, so holding or
-- tapping space in mid-air keeps the character going up.
local infiniteJumpEnabled = false
local jumpInputService = game:GetService("UserInputService")

jumpInputService.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end

    local char = Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

localPlayerTab:CreateToggle({
    name = "Infinite Jump",
    value = false,
    flag = "InfiniteJumpToggle",
    callback = function(value)
        infiniteJumpEnabled = value
    end,
})

-- Hitbox Expander: grows other players' HumanoidRootPart locally. Original
-- sizes are cached so disabling restores every hitbox exactly as it was.
local hitboxExpanderEnabled = false
local hitboxSize = 5

if getgenv().ZHubHitboxConn then
    getgenv().ZHubHitboxConn:Disconnect()
    getgenv().ZHubHitboxConn = nil
end

local staleHitboxSizes = getgenv().ZHubHitboxOriginals
if staleHitboxSizes then
    for part, originalSize in pairs(staleHitboxSizes) do
        if part and part.Parent then
            pcall(function() part.Size = originalSize end)
        end
    end
end

local hitboxOriginalSizes = setmetatable({}, { __mode = "k" })
getgenv().ZHubHitboxOriginals = hitboxOriginalSizes
local hitboxConnection

local function applyHitboxSize(player)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if hitboxOriginalSizes[hrp] == nil then
        hitboxOriginalSizes[hrp] = hrp.Size
    end
    hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
end

local function restoreHitboxes()
    for part, originalSize in pairs(hitboxOriginalSizes) do
        if part and part.Parent then
            pcall(function() part.Size = originalSize end)
        end
    end
    hitboxOriginalSizes = setmetatable({}, { __mode = "k" })
    getgenv().ZHubHitboxOriginals = hitboxOriginalSizes
end

local function startHitboxExpander()
    if hitboxConnection then hitboxConnection:Disconnect() end

    hitboxConnection = RunService.Heartbeat:Connect(function()
        if not hitboxExpanderEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                applyHitboxSize(player)
            end
        end
    end)
    getgenv().ZHubHitboxConn = hitboxConnection
end

local function stopHitboxExpander()
    if hitboxConnection then
        hitboxConnection:Disconnect()
        hitboxConnection = nil
    end
    getgenv().ZHubHitboxConn = nil
    restoreHitboxes()
end

localPlayerTab:CreateToggle({
    name = "Hitbox Expander",
    value = false,
    flag = "HitboxExpanderToggle",
    callback = function(value)
        hitboxExpanderEnabled = value
        if value then startHitboxExpander() else stopHitboxExpander() end
    end,
})

localPlayerTab:CreateSlider({
    name = "Hitbox Size",
    range = { 1, 30 },
    increment = 1,
    value = 5,
    suffix = "studs",
    flag = "HitboxSizeSlider",
    callback = function(value)
        hitboxSize = value
    end,
})

localPlayerTab:CreateButton({
    name = "Reset Character",
    description = "Respawn your character",
    callback = function()
        Window:Popup({
            title = "Reset character?",
            content = "This kills your current character and respawns you.",
            options = {
                { text = "Cancel" },
                {
                    text = "Reset",
                    style = "danger",
                    callback = function()
                        local char = Players.LocalPlayer.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum.Health = 0
                        end
                    end,
                },
            },
        })
    end,
})


-- Fly variables
local flying = false
local flySpeed = 50
local bodyVelocity
local bodyGyro
local flyConnection

local function startFly()
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end

    local player = Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:WaitForChild("Humanoid", 5)

    if not hrp or not hum then
        warn("Fly failed: character parts not found")
        return
    end

    hum.PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.Parent = hrp

    local UserInputService = game:GetService("UserInputService")

    flyConnection = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            bodyVelocity.Velocity = moveDir.Unit * flySpeed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        bodyGyro.CFrame = cam.CFrame
    end)
end

local function stopFly()
    local char = Players.LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
end

local flyToggle = localPlayerTab:CreateToggle({
    name = "Fly",
    value = false,
    flag = "FlyToggle",
    callback = function(value)
        flying = value
        if flying then
            startFly()
        else
            stopFly()
        end
    end,
})

-- Gen2 keybinds fire cleanly once per press, so no debounce/guard flags needed here.
-- flyToggle:Set(flying, true) updates the switch's visuals without re-firing its callback.
localPlayerTab:CreateKeybind({
    name = "Fly Keybind",
    value = Enum.KeyCode.F,
    callback = function()
        if not keybindsEnabled then return end
        flying = not flying
        if flying then startFly() else stopFly() end
        flyToggle:Set(flying, true)
    end,
})

localPlayerTab:CreateSlider({
    name = "Fly Speed",
    range = { 10, 300 },
    increment = 5,
    value = 50,
    suffix = "spd",
    flag = "FlySpeedSlider",
    callback = function(value)
        flySpeed = value
    end,
})

local antiFlingEnabled = false
local maxVelocity = 100
local antiFlingConnection
local lastSafePosition = nil
local maxDistancePerFrame = 15

local function startAntiFling()
    local char = Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then lastSafePosition = hrp.Position end

    antiFlingConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local c = Players.LocalPlayer.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then return end

        if lastSafePosition then
            local distanceMoved = (h.Position - lastSafePosition).Magnitude
            local allowedDistance = maxDistancePerFrame + (maxVelocity * deltaTime)

            if distanceMoved > allowedDistance then
                h.CFrame = CFrame.new(lastSafePosition)
                h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                h.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end

        local velocity = h.AssemblyLinearVelocity
        if velocity.Magnitude > maxVelocity then
            h.AssemblyLinearVelocity = velocity.Unit * maxVelocity
        end

        lastSafePosition = h.Position
    end)
end

local function stopAntiFling()
    if antiFlingConnection then
        antiFlingConnection:Disconnect()
        antiFlingConnection = nil
    end
    lastSafePosition = nil
end

localPlayerTab:CreateToggle({
    name = "Anti-Fling",
    value = false,
    flag = "AntiFlingToggle",
    callback = function(value)
        antiFlingEnabled = value
        if value then
            startAntiFling()
        else
            stopAntiFling()
        end
    end,
})

localPlayerTab:CreateSlider({
    name = "Max Velocity",
    range = { 20, 300 },
    increment = 10,
    value = 100,
    suffix = "studs/s",
    flag = "AntiFlingMaxVelocitySlider",
    callback = function(value)
        maxVelocity = value
    end,
})

local cameraTab = localPlayerTab
cameraTab:CreateSection({ name = "Camera" })

cameraTab:CreateSlider({
    name = "FOV Changer",
    range = { 0, 120 },
    increment = 1,
    value = 70,
    suffix = "FOV",
    flag = "fovchanger",
    callback = function(value)
        local camera = workspace.CurrentCamera
        if camera then
            camera.FieldOfView = value
        end
    end,
})

local UserInputService = game:GetService("UserInputService")

local freecamOn = false
local freecamSpeed = 50
local savedCameraType

local camYaw = 0
local camPitch = 0
local mouseSensitivity = 0.002
local rightMouseDown = false

local currentVelocity = Vector3.new(0, 0, 0)
local smoothingFactor = 8

local function toggleFreecam(enabled)
    local camera = workspace.CurrentCamera
    local char = Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if enabled then
        savedCameraType = camera.CameraType

        local lookVector = camera.CFrame.LookVector
        camYaw = math.atan2(-lookVector.X, -lookVector.Z)
        camPitch = math.asin(lookVector.Y)

        camera.CameraType = Enum.CameraType.Scriptable
        currentVelocity = Vector3.new(0, 0, 0)

        if hrp then
            hrp.Anchored = true
        end
    else
        camera.CameraType = savedCameraType or Enum.CameraType.Custom
        if hrp then
            hrp.Anchored = false
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        rightMouseDown = false
    end
end

UserInputService.InputBegan:Connect(function(input)
    if not freecamOn then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not freecamOn then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

RunService:BindToRenderStep("FreecamUpdate", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
    if not freecamOn then return end
    local camera = workspace.CurrentCamera

    if rightMouseDown then
        local delta = UserInputService:GetMouseDelta()
        camYaw = camYaw - (delta.X * mouseSensitivity)
        camPitch = camPitch - (delta.Y * mouseSensitivity)
        camPitch = math.clamp(camPitch, -math.rad(89), math.rad(89))
    end

    local rotationCFrame = CFrame.fromOrientation(camPitch, camYaw, 0)

    local moveDir = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += rotationCFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= rotationCFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= rotationCFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += rotationCFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end

    local targetVelocity = Vector3.new(0, 0, 0)
    if moveDir.Magnitude > 0 then
        targetVelocity = moveDir.Unit * freecamSpeed
    end

    local alpha = 1 - math.exp(-smoothingFactor * deltaTime)
    currentVelocity = currentVelocity:Lerp(targetVelocity, alpha)

    local newPosition = camera.CFrame.Position + currentVelocity * deltaTime
    camera.CFrame = CFrame.new(newPosition) * rotationCFrame
end)

local freecamToggle = cameraTab:CreateToggle({
    name = "Freecam",
    value = false,
    flag = "FreecamToggle",
    callback = function(value)
        freecamOn = value
        toggleFreecam(value)
    end,
})

cameraTab:CreateKeybind({
    name = "Freecam Keybind",
    value = Enum.KeyCode.C,
    callback = function()
        if not keybindsEnabled then return end
        freecamOn = not freecamOn
        toggleFreecam(freecamOn)
        freecamToggle:Set(freecamOn, true)
    end,
})

cameraTab:CreateSlider({
    name = "Freecam Speed",
    range = { 10, 300 },
    increment = 5,
    value = 50,
    suffix = "spd",
    flag = "FreecamSpeedSlider",
    callback = function(value)
        freecamSpeed = value
    end,
})

-- Fullbright: brighten the map and kill fog/shadows. Original Lighting values
-- are saved the first time it is enabled and put back when it is disabled.
local savedLighting = getgenv().ZHubSavedLighting

-- A previous execution may have crashed while Fullbright was on; put the
-- original Lighting values back before this run starts.
if savedLighting then
    local staleLighting = game:GetService("Lighting")
    for property, value in pairs(savedLighting) do
        pcall(function()
            staleLighting[property] = value
        end)
    end
    getgenv().ZHubSavedLighting = nil
    savedLighting = nil
end

local fullbrightSettings = {
    Brightness = 2,
    ClockTime = 14,
    Ambient = Color3.fromRGB(255, 255, 255),
    OutdoorAmbient = Color3.fromRGB(255, 255, 255),
    FogEnd = 100000,
    GlobalShadows = false,
    EnvironmentDiffuseScale = 1,
    EnvironmentSpecularScale = 1,
}

local function setFullbright(enabled)
    local Lighting = game:GetService("Lighting")

    if enabled then
        if not savedLighting then
            savedLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
                EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
            }
            getgenv().ZHubSavedLighting = savedLighting
        end

        for property, value in pairs(fullbrightSettings) do
            pcall(function()
                Lighting[property] = value
            end)
        end
    elseif savedLighting then
        for property, value in pairs(savedLighting) do
            pcall(function()
                Lighting[property] = value
            end)
        end
        getgenv().ZHubSavedLighting = nil
        savedLighting = nil
    end
end

cameraTab:CreateToggle({
    name = "Fullbright",
    value = false,
    flag = "FullbrightToggle",
    callback = function(value)
        setFullbright(value)
    end,
})

cameraTab:CreateSection({ name = "ESP" })

local espEnabled = false
local tracersEnabled = false
local teamColorEnabled = false
local healthESPEnabled = false
local espObjects = {}

local function getPlayerColor(player)
    if teamColorEnabled and player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 0, 0)
end

local function removeESP(player)
    local data = espObjects[player]
    if data then
        pcall(function() data.highlight:Destroy() end)
        pcall(function() data.billboard:Destroy() end)
        if data.tracer then pcall(function() data.tracer:Remove() end) end
        espObjects[player] = nil
    end
end

local function createESP(player)
    removeESP(player)

    local highlight = Instance.new("Highlight")
    highlight.FillColor = getPlayerColor(player)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Enabled = false

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Text = player.Name
    nameLabel.Parent = billboard

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1.5
    tracer.Color = getPlayerColor(player)
    tracer.Visible = false

    espObjects[player] = {
        highlight = highlight,
        billboard = billboard,
        nameLabel = nameLabel,
        tracer = tracer,
    }
end

local function updateESP(player)
    local data = espObjects[player]
    if not data then return end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp or not char then
        pcall(function()
            data.highlight.Enabled = false
            data.billboard.Enabled = false
            data.tracer.Visible = false
        end)
        return
    end

    local success = pcall(function()
        if data.highlight.Parent ~= char then data.highlight.Parent = char end
        if data.billboard.Parent ~= hrp then
            data.billboard.Parent = hrp
            data.billboard.StudsOffset = Vector3.new(0, 3, 0)
        end
    end)

    if not success then
        createESP(player)
        return
    end

    local color = getPlayerColor(player)
    data.highlight.FillColor = color
    data.tracer.Color = color

    data.highlight.Enabled = espEnabled
    data.billboard.Enabled = espEnabled

    local myChar = Players.LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local labelText = player.Name
    if myHrp then
        local distance = math.floor((hrp.Position - myHrp.Position).Magnitude)
        labelText = labelText .. " [" .. distance .. "m]"
    end

    if healthESPEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            labelText = labelText .. " [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]"
        end
    end

    data.nameLabel.Text = labelText

    if tracersEnabled then
        local camera = workspace.CurrentCamera
        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            data.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            data.tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            data.tracer.Visible = true
        else
            data.tracer.Visible = false
        end
    else
        data.tracer.Visible = false
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        createESP(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            createESP(player)
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= Players.LocalPlayer then
        createESP(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            createESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

if getgenv().ZHubESPConn then
    getgenv().ZHubESPConn:Disconnect()
end

getgenv().ZHubESPConn = RunService.Heartbeat:Connect(function()
    for player, _ in pairs(espObjects) do
        updateESP(player)
    end
end)

cameraTab:CreateToggle({
    name = "ESP",
    value = false,
    flag = "ESPToggle",
    callback = function(value)
        espEnabled = value
    end,
})

cameraTab:CreateToggle({
    name = "Tracers",
    value = false,
    flag = "TracersToggle",
    callback = function(value)
        tracersEnabled = value
    end,
})

cameraTab:CreateToggle({
    name = "Team Color ESP",
    value = false,
    flag = "TeamColorToggle",
    callback = function(value)
        teamColorEnabled = value
    end,
})

cameraTab:CreateToggle({
    name = "Show Health",
    value = false,
    flag = "HealthESPToggle",
    callback = function(value)
        healthESPEnabled = value
    end,
})

-- =====================================================================
-- 99 Nights in the Forest
-- Everything here is heuristic: names and ProximityPrompts are matched
-- loosely so the tab keeps working after the game renames a few things.
-- =====================================================================
local forestTab = Window:CreateTab({ name = "99 Nights", icon = 4483362458 })

local function forestRoot()
    local char = Players.LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function forestContains(text, keywords)
    if type(text) ~= "string" or text == "" then return false end
    local lower = string.lower(text)
    for _, keyword in ipairs(keywords) do
        if string.find(lower, keyword, 1, true) then
            return true
        end
    end
    return false
end

local function forestPosition(instance)
    local node = instance
    while node and node ~= workspace do
        if node:IsA("BasePart") then
            return node.Position
        elseif node:IsA("Model") then
            local ok, pivot = pcall(function()
                return node:GetPivot().Position
            end)
            if ok and pivot then return pivot end
        end
        node = node.Parent
    end
    return nil
end

local function forestDistance(instance)
    local root = forestRoot()
    local position = forestPosition(instance)
    if not root or not position then return math.huge end
    return (position - root.Position).Magnitude
end

local function forestTeleport(instance, height)
    local root = forestRoot()
    local position = forestPosition(instance)
    if not root or not position then return false end
    root.CFrame = CFrame.new(position + Vector3.new(0, height or 4, 0))
    return true
end

-- Teleport next to a target instead of inside it, so chopping a tree does not
-- drop the player into the trunk.
local function forestTeleportBeside(instance, offset)
    local root = forestRoot()
    local position = forestPosition(instance)
    if not root or not position then return false end

    local direction = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
    if direction.Magnitude < 0.1 then
        direction = Vector3.new(1, 0, 0)
    else
        direction = direction.Unit
    end

    local distance = offset or 7
    root.CFrame = CFrame.new(position + direction * distance + Vector3.new(0, 2, 0))
    return true
end

local VirtualInputManager = game:GetService("VirtualInputManager")

local function forestPressKey(keyCode)
    local ok = pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)

    if not ok and keypress then
        pcall(function()
            keypress(keyCode.Value)
        end)
    end

    return ok
end

local function forestAncestorText(instance, depth)
    local parts = {}
    local node = instance
    local count = 0
    while node and node ~= workspace and count < (depth or 4) do
        table.insert(parts, string.lower(node.Name))
        node = node.Parent
        count = count + 1
    end
    return table.concat(parts, " ")
end

-- Name groups. Kept intentionally broad so renamed assets still match.
local treeKeywords = { "tree", "pine", "oak", "birch", "spruce", "willow", "palm", "trunk" }
local axeKeywords = { "axe", "hatchet", "chainsaw" }
local woodKeywords = { "wood", "tree", "log", "branch", "stick", "timber", "plank", "trunk", "stump" }
local stoneKeywords = { "rock", "stone", "ore", "flint", "coal", "clay", "ice", "iron", "copper", "gold", "gem", "crystal", "boulder" }
local berryKeywords = { "berry", "berries", "bush" }
local mushroomKeywords = { "mushroom", "fungus", "toadstool" }
local chestKeywords = { "chest", "crate", "loot", "supply", "barrel" }
local fireKeywords = { "campfire", "fire", "furnace", "hearth", "brazier", "stove" }
local fuelKeywords = { "log", "coal", "fuel", "plank", "firewood", "biofuel" }
local foodKeywords = { "apple", "carrot", "potato", "corn", "pumpkin", "berry", "berries", "mushroom", "meat", "morsel", "steak", "ribs", "fish", "egg", "food", "fruit", "herb", "ration", "jerky", "stew", "soup", "bread", "cake", "chili", "sandwich", "pie", "jelly", "chowder", "cooked", "water", "drink", "canteen" }
local resourceKeywords = { "fiber", "leaf", "leaves", "seed", "hide", "pelt", "feather" }

for _, list in ipairs({ woodKeywords, stoneKeywords, berryKeywords, mushroomKeywords, chestKeywords, fireKeywords, foodKeywords }) do
    for _, keyword in ipairs(list) do
        table.insert(resourceKeywords, keyword)
    end
end

local hostileAnimalKeywords = { "wolf", "bear", "boar", "cougar", "panther", "lynx", "snake", "spider", "scorpion", "crocodile", "monster", "zombie", "bandit", "raider", "enemy", "demon", "creature", "cultist", "golem", "wendigo" }
local passiveAnimalKeywords = { "deer", "rabbit", "bunny", "fox", "moose", "elk", "chicken", "cow", "pig", "sheep", "goat", "bird", "duck", "turkey", "squirrel", "animal", "horse", "mammoth" }
local animalKeywords = {}

for _, list in ipairs({ hostileAnimalKeywords, passiveAnimalKeywords }) do
    for _, keyword in ipairs(list) do
        table.insert(animalKeywords, keyword)
    end
end

local gatherActionKeywords = { "chop", "mine", "gather", "harvest", "pick", "collect", "forage", "search", "loot", "cut", "dig", "break", "take", "grab" }
local fireActionKeywords = { "fire", "campfire", "furnace", "hearth", "torch", "brazier", "stove", "fuel", "stoke", "light", "burn", "cook" }
local dropKeywords = { "pickup", "pick up", "drop", "loot", "item", "collect", "coin", "crate", "chest", "bag", "supply", "reward" }
local ignoredAnimalKeywords = { "spawner", "spawn", "cave", "den", "nest", "zone", "area", "shop", "sign", "gui", "folder", "npc" }

local function forestIsIgnored(name)
    return forestContains(name, ignoredAnimalKeywords)
end

-- One shared world scan. Each feature reads this cache instead of walking
-- workspace on every tick.
local forestCache = {
    time = 0,
    resources = {},
    animals = {},
    gatherPrompts = {},
    firePrompts = {},
    dropPrompts = {},
    dropClicks = {},
}

local function forestRefreshCache()
    local now = os.clock()
    if now - forestCache.time < 0.75 then return end
    forestCache.time = now

    local resources, animals = {}, {}
    local gatherPrompts, firePrompts, dropPrompts, dropClicks = {}, {}, {}, {}
    local resourceSeen, animalSeen = {}, {}

    pcall(function()
        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("ProximityPrompt") then
                local text = string.lower((object.ActionText or "") .. " " .. (object.ObjectText or "") .. " " .. forestAncestorText(object.Parent, 4))
                if forestContains(text, fireActionKeywords) then
                    table.insert(firePrompts, object)
                elseif forestContains(text, dropKeywords) then
                    table.insert(dropPrompts, object)
                elseif forestContains(text, gatherActionKeywords) then
                    table.insert(gatherPrompts, object)
                end
            elseif object:IsA("ClickDetector") then
                local text = forestAncestorText(object.Parent, 3)
                if forestContains(text, dropKeywords) then
                    table.insert(dropClicks, object)
                end
            elseif object:IsA("Model") or object:IsA("BasePart") then
                local name = object.Name

                if forestContains(name, animalKeywords) then
                    local anchor = object
                    if object:IsA("BasePart") then
                        local node = object.Parent
                        while node and node ~= workspace do
                            if node:IsA("Model") and forestContains(node.Name, animalKeywords) then
                                anchor = node
                                break
                            end
                            node = node.Parent
                        end
                    end
                    if not animalSeen[anchor] then
                        animalSeen[anchor] = true
                        table.insert(animals, anchor)
                    end
                elseif forestContains(name, resourceKeywords) then
                    local anchor = object
                    local node = object
                    while node and node ~= workspace do
                        if node:IsA("Model") and forestContains(node.Name, resourceKeywords) then
                            anchor = node
                            break
                        end
                        node = node.Parent
                    end
                    if not resourceSeen[anchor] then
                        resourceSeen[anchor] = true
                        table.insert(resources, anchor)
                    end
                end
            end
        end
    end)

    forestCache.resources = resources
    forestCache.animals = animals
    forestCache.gatherPrompts = gatherPrompts
    forestCache.firePrompts = firePrompts
    forestCache.dropPrompts = dropPrompts
    forestCache.dropClicks = dropClicks
end

local function forestFirePrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return false end

    local ok = pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end
    end)
    return ok
end

local function forestFireClick(detector)
    if not detector or not detector.Parent or not fireclickdetector then return false end
    return pcall(function()
        fireclickdetector(detector)
    end)
end

local function forestNearestPrompt(list, range)
    local best, bestDistance = nil, math.huge
    for _, prompt in ipairs(list) do
        if prompt.Parent and prompt.Enabled then
            local distance = forestDistance(prompt)
            if distance <= range and distance < bestDistance then
                best = prompt
                bestDistance = distance
            end
        end
    end
    return best
end

local autoChopEnabled = false
local gatherNearbyEnabled = false
local gatherTeleportEnabled = false
local autoPickupEnabled = false
local autoLootEnabled = false
local autoFeedFireEnabled = false
local autoRefuelEnabled = false
local autoEatEnabled = false
local autoHuntEnabled = false
local resourceESPEnabled = false
local animalESPEnabled = false
local voidProtectionEnabled = false

local gatherRange = 40
local chopRange = 250
local eatThreshold = 35
local huntRange = 25
local huntTeleportEnabled = false
local resourceESPRange = 150
local animalESPRange = 200
local forestLastSafeCFrame = nil

-- Re-execution hygiene: stop the previous run's loops and remove leftovers.
if getgenv().ZHubForestHighlights then
    for _, entry in pairs(getgenv().ZHubForestHighlights) do
        pcall(function() entry.highlight:Destroy() end)
    end
end

local forestRunId = (getgenv().ZHubForestRunId or 0) + 1
getgenv().ZHubForestRunId = forestRunId

local function forestRunActive()
    return getgenv().ZHubForestRunId == forestRunId
end

local chopIgnoreKeywords = { "sapling", "seed", "stump", "log" }

local function forestFindTool(keywords)
    local player = Players.LocalPlayer
    local char = player.Character

    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and forestContains(item.Name, keywords) then
                return item
            end
        end
    end

    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and forestContains(item.Name, keywords) then
                return item
            end
        end
    end

    return nil
end

-- Auto chop: this game cuts trees by swinging an axe, not by prompts, so the
-- loop teleports beside the nearest tree and activates the axe repeatedly.
local lastChopNotify = 0

task.spawn(function()
    while forestRunActive() do
        task.wait(0.25)
        if autoChopEnabled then
            forestRefreshCache()

            local tree, treeDistance = nil, math.huge
            for _, object in ipairs(forestCache.resources) do
                if object.Parent and forestContains(object.Name, treeKeywords) and not forestContains(object.Name, chopIgnoreKeywords) then
                    local distance = forestDistance(object)
                    if distance <= chopRange and distance < treeDistance then
                        tree, treeDistance = object, distance
                    end
                end
            end

            local char = Players.LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local root = forestRoot()
            local axe = forestFindTool(axeKeywords)

            if not axe then
                if os.clock() - lastChopNotify > 15 then
                    lastChopNotify = os.clock()
                    Window:Notify({
                        title = "Auto Chop",
                        content = "No axe was found in your backpack. Equip or pick one up first.",
                        duration = 4,
                    })
                end
            elseif tree and humanoid and root then
                local position = forestPosition(tree)
                if position then
                    if treeDistance > 8 then
                        forestTeleportBeside(tree, 7)
                        task.wait(0.15)
                        root = forestRoot()
                    end

                    if root then
                        pcall(function()
                            if axe.Parent ~= char then
                                humanoid:EquipTool(axe)
                                task.wait(0.1)
                            end
                            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(position.X, root.Position.Y, position.Z))
                            axe:Activate()
                        end)
                    end
                end
            end
        end
    end
end)

-- Auto loot: the game uses E for eating, chests and ground loot.
task.spawn(function()
    while forestRunActive() do
        task.wait(0.55)
        if autoLootEnabled then
            forestPressKey(Enum.KeyCode.E)
        end
    end
end)

-- Auto feed fire: hold a log / fuel item and press F next to a campfire.
task.spawn(function()
    while forestRunActive() do
        task.wait(0.8)
        if autoFeedFireEnabled then
            forestRefreshCache()

            local nearestFire, nearestDistance = nil, math.huge
            for _, object in ipairs(forestCache.resources) do
                if object.Parent and forestContains(object.Name, fireKeywords) then
                    local distance = forestDistance(object)
                    if distance <= 15 and distance < nearestDistance then
                        nearestFire, nearestDistance = object, distance
                    end
                end
            end
            if not nearestFire then
                for _, prompt in ipairs(forestCache.firePrompts) do
                    if prompt.Parent then
                        local distance = forestDistance(prompt)
                        if distance <= 15 and distance < nearestDistance then
                            nearestFire, nearestDistance = prompt, distance
                        end
                    end
                end
            end

            if nearestFire then
                local char = Players.LocalPlayer.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local fuel = forestFindTool(fuelKeywords)

                if humanoid and fuel then
                    pcall(function()
                        if fuel.Parent ~= char then
                            humanoid:EquipTool(fuel)
                            task.wait(0.1)
                        end
                    end)
                    forestPressKey(Enum.KeyCode.F)
                end
            end
        end
    end
end)

-- Auto gather: fire nearby resource prompts without moving.
task.spawn(function()
    while forestRunActive() do
        task.wait(0.45)
        if gatherNearbyEnabled then
            forestRefreshCache()
            local fired = 0
            for _, prompt in ipairs(forestCache.gatherPrompts) do
                if fired >= 4 then break end
                if prompt.Parent and prompt.Enabled and forestDistance(prompt) <= gatherRange then
                    if forestFirePrompt(prompt) then
                        fired = fired + 1
                        task.wait(0.08)
                    end
                end
            end
        end
    end
end)

-- Auto gather with teleport: fly to the nearest node, then fire its prompt.
task.spawn(function()
    while forestRunActive() do
        task.wait(0.5)
        if gatherTeleportEnabled then
            forestRefreshCache()
            local prompt = forestNearestPrompt(forestCache.gatherPrompts, gatherRange)
            if prompt then
                forestTeleportBeside(prompt, 6)
                task.wait(0.15)
                forestFirePrompt(prompt)
                task.wait(0.15)
            end
        end
    end
end)

-- Auto pickup: dropped loot usually uses a prompt or a ClickDetector.
task.spawn(function()
    while forestRunActive() do
        task.wait(0.7)
        if autoPickupEnabled then
            forestRefreshCache()
            local fired = 0
            for _, prompt in ipairs(forestCache.dropPrompts) do
                if fired >= 6 then break end
                if prompt.Parent and prompt.Enabled and forestDistance(prompt) <= gatherRange then
                    if forestFirePrompt(prompt) then
                        fired = fired + 1
                        task.wait(0.08)
                    end
                end
            end
            for _, detector in ipairs(forestCache.dropClicks) do
                if fired >= 6 then break end
                if forestDistance(detector) <= gatherRange then
                    if forestFireClick(detector) then
                        fired = fired + 1
                        task.wait(0.08)
                    end
                end
            end
        end
    end
end)

-- Auto refuel: interacts with campfires / furnaces in range.
task.spawn(function()
    while forestRunActive() do
        task.wait(2)
        if autoRefuelEnabled then
            forestRefreshCache()
            local fired = 0
            for _, prompt in ipairs(forestCache.firePrompts) do
                if fired >= 2 then break end
                if prompt.Parent and prompt.Enabled and forestDistance(prompt) <= 30 then
                    if forestFirePrompt(prompt) then
                        fired = fired + 1
                    end
                end
            end
        end
    end
end)

local hungerStatKeywords = { "hunger", "starving", "starvation", "satiety", "fullness" }
local hungerBarKeywords = { "hunger", "food" }
local barFillKeywords = { "fill", "bar", "progress", "amount", "value" }

local function forestMatchScore(name, keywords)
    if type(name) ~= "string" then return nil end
    local lower = string.lower(name)
    for index, keyword in ipairs(keywords) do
        if string.find(lower, keyword, 1, true) then
            return index
        end
    end
    return nil
end

local function forestReadStat(keywords)
    local player = Players.LocalPlayer
    local roots = {}

    local char = player.Character
    if char then table.insert(roots, char) end
    table.insert(roots, player)

    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then table.insert(roots, playerGui) end

    local bestValue, bestScore = nil, math.huge

    for _, root in ipairs(roots) do
        local ok, descendants = pcall(function()
            return root:GetDescendants()
        end)
        if ok then
            for _, object in ipairs(descendants) do
                if object:IsA("ValueBase") then
                    local score = forestMatchScore(object.Name, keywords)
                    if score and score < bestScore then
                        local value = tonumber(object.Value)
                        if value then
                            bestValue, bestScore = value, score
                        end
                    end
                end
            end
        end

        local attrsOk, attributes = pcall(function()
            return root:GetAttributes()
        end)
        if attrsOk then
            for name, value in pairs(attributes) do
                if type(value) == "number" then
                    local score = forestMatchScore(name, keywords)
                    if score and score < bestScore then
                        bestValue, bestScore = value, score
                    end
                end
            end
        end
    end

    return bestValue
end

-- Some games keep hunger in a LocalScript, so the only readable copy is the
-- on-screen bar. Look for a named bar and read its fill scale.
local function forestReadGuiBar()
    local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    for _, object in ipairs(playerGui:GetDescendants()) do
        local isBarObject = object:IsA("Frame") or object:IsA("ImageLabel")
        if isBarObject and forestContains(object.Name, hungerBarKeywords) then
            local candidates = {}
            for _, child in ipairs(object:GetDescendants()) do
                if (child:IsA("Frame") or child:IsA("ImageLabel")) and forestContains(child.Name, barFillKeywords) then
                    table.insert(candidates, child)
                end
            end
            if #candidates == 0 then
                table.insert(candidates, object)
            end

            for _, bar in ipairs(candidates) do
                local size = bar.Size
                local x, y = size.X.Scale, size.Y.Scale

                local scale
                if x > 0 and y > 0 then
                    scale = math.min(x, y)
                elseif x > 0 then
                    scale = x
                elseif y > 0 then
                    scale = y
                end

                if not scale and bar.AbsoluteSize.X > 0 and bar.Parent and bar.Parent:IsA("GuiObject") and bar.Parent.AbsoluteSize.X > 0 then
                    scale = bar.AbsoluteSize.X / bar.Parent.AbsoluteSize.X
                end

                if scale and scale >= 0 and scale <= 1 then
                    return scale * 100
                end
            end
        end
    end

    return nil
end

local function forestReadHunger()
    return forestReadStat(hungerStatKeywords) or forestReadGuiBar()
end

local function forestFindFoodTool()
    local player = Players.LocalPlayer
    local containers = {}

    local char = player.Character
    if char then table.insert(containers, char) end

    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then table.insert(containers, backpack) end

    for _, container in ipairs(containers) do
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and (forestContains(item.Name, foodKeywords) or forestContains(item.ToolTip or "", foodKeywords)) then
                return item
            end
        end
    end

    return nil
end

local function forestEat()
    local tool = forestFindFoodTool()

    if tool then
        local char = Players.LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end

        return pcall(function()
            if tool.Parent ~= char then
                humanoid:EquipTool(tool)
                task.wait(0.1)
            end
            tool:Activate()
        end)
    end

    -- No food tool: walk to the nearest food in the world and press E.
    forestRefreshCache()
    local target, targetDistance = nil, math.huge
    for _, object in ipairs(forestCache.resources) do
        if object.Parent and forestContains(object.Name, foodKeywords) then
            local distance = forestDistance(object)
            if distance <= 300 and distance < targetDistance then
                target, targetDistance = object, distance
            end
        end
    end

    if target then
        forestTeleportBeside(target, 5)
        task.wait(0.2)
    end

    forestPressKey(Enum.KeyCode.E)
    return true
end

local lastForestEatTime = 0

task.spawn(function()
    while forestRunActive() do
        task.wait(1)
        if autoEatEnabled and os.clock() - lastForestEatTime > 2 then
            local hunger = forestReadHunger()
            if hunger then
                if hunger <= 1 then hunger = hunger * 100 end
                if hunger <= eatThreshold then
                    if forestEat() then
                        lastForestEatTime = os.clock()
                    end
                end
            end
        end
    end
end)

local weaponKeywords = { "axe", "pickaxe", "hatchet", "spear", "sword", "knife", "club", "bat", "mace", "dagger", "bow", "revolver", "rifle", "shotgun", "pistol", "gun", "blade", "hammer", "sledge", "scythe", "weapon" }

local function forestFindWeapon()
    return forestFindTool(weaponKeywords)
end

task.spawn(function()
    while forestRunActive() do
        task.wait(0.25)
        if autoHuntEnabled then
            forestRefreshCache()

            local nearest, nearestDistance = nil, math.huge
            for _, animal in ipairs(forestCache.animals) do
                if animal.Parent and not forestIsIgnored(animal.Name) then
                    local distance = forestDistance(animal)
                    if distance <= huntRange and distance < nearestDistance then
                        nearest, nearestDistance = animal, distance
                    end
                end
            end

            local char = Players.LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local root = forestRoot()
            local weapon = forestFindWeapon()

            if nearest and humanoid and root and weapon then
                if huntTeleportEnabled and nearestDistance > 9 then
                    forestTeleportBeside(nearest, 5)
                    task.wait(0.1)
                    root = forestRoot()
                end

                local position = forestPosition(nearest)
                if position and root then
                    pcall(function()
                        root.CFrame = CFrame.lookAt(root.Position, Vector3.new(position.X, root.Position.Y, position.Z))
                    end)
                    pcall(function()
                        if weapon.Parent ~= char then
                            humanoid:EquipTool(weapon)
                            task.wait(0.08)
                        end
                        weapon:Activate()
                    end)
                end
            end
        end
    end
end)

-- Void protection: remember the last safe spot above ground and recover.
task.spawn(function()
    while forestRunActive() do
        task.wait(0.2)
        if voidProtectionEnabled then
            local root = forestRoot()
            if root then
                if root.Position.Y > 0 then
                    forestLastSafeCFrame = root.CFrame
                elseif root.Position.Y < -120 and forestLastSafeCFrame then
                    root.CFrame = forestLastSafeCFrame + Vector3.new(0, 5, 0)
                end
            end
        end
    end
end)

local function forestResourceColor(name)
    if forestContains(name, chestKeywords) then return Color3.fromRGB(255, 205, 70) end
    if forestContains(name, fireKeywords) then return Color3.fromRGB(255, 140, 40) end
    if forestContains(name, woodKeywords) then return Color3.fromRGB(190, 130, 70) end
    if forestContains(name, stoneKeywords) then return Color3.fromRGB(170, 175, 190) end
    if forestContains(name, berryKeywords) then return Color3.fromRGB(235, 70, 105) end
    if forestContains(name, mushroomKeywords) then return Color3.fromRGB(185, 95, 235) end
    return Color3.fromRGB(90, 230, 150)
end

local function forestAnimalColor(name)
    if forestContains(name, hostileAnimalKeywords) then
        return Color3.fromRGB(255, 65, 65)
    end
    return Color3.fromRGB(90, 255, 130)
end

local function forestCollectNearby(list, range, limit, filterAnimals)
    local root = forestRoot()
    if not root then return {} end

    local found = {}
    for _, object in ipairs(list) do
        if object.Parent then
            local position = forestPosition(object)
            if position then
                local distance = (position - root.Position).Magnitude
                if distance <= range and not (filterAnimals and forestIsIgnored(object.Name)) then
                    table.insert(found, { object = object, distance = distance })
                end
            end
        end
    end

    table.sort(found, function(a, b)
        return a.distance < b.distance
    end)

    local result = {}
    for index = 1, math.min(#found, limit) do
        result[index] = found[index].object
    end
    return result
end

local forestESPObjects = {}
getgenv().ZHubForestHighlights = forestESPObjects

local function forestRemoveHighlight(object)
    local entry = forestESPObjects[object]
    if entry then
        pcall(function() entry.highlight:Destroy() end)
        forestESPObjects[object] = nil
    end
end

local function forestUpdateESP()
    if not resourceESPEnabled and not animalESPEnabled then
        for object in pairs(forestESPObjects) do
            forestRemoveHighlight(object)
        end
        return
    end

    forestRefreshCache()
    local wanted = {}

    if resourceESPEnabled then
        for _, object in ipairs(forestCollectNearby(forestCache.resources, resourceESPRange, 80, false)) do
            wanted[object] = "resource"
        end
    end

    if animalESPEnabled then
        for _, object in ipairs(forestCollectNearby(forestCache.animals, animalESPRange, 60, true)) do
            wanted[object] = "animal"
        end
    end

    for object, entry in pairs(forestESPObjects) do
        if not wanted[object] or not object.Parent or entry.kind ~= wanted[object] then
            forestRemoveHighlight(object)
        end
    end

    for object, kind in pairs(wanted) do
        if not forestESPObjects[object] then
            local color = kind == "resource" and forestResourceColor(object.Name) or forestAnimalColor(object.Name)

            local highlight = Instance.new("Highlight")
            highlight.Name = "ZHubForestESP"
            highlight.Adornee = object
            highlight.FillColor = color
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = color
            highlight.OutlineTransparency = 0.1
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

            local parented = pcall(function()
                highlight.Parent = object
            end)
            if not parented then
                highlight.Parent = workspace
            end

            forestESPObjects[object] = { highlight = highlight, kind = kind }
        end
    end
end

task.spawn(function()
    while forestRunActive() do
        task.wait(1)
        forestUpdateESP()
    end
end)

-- ---------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------
forestTab:CreateSection({ name = "Auto Farm" })

forestTab:CreateToggle({
    name = "Auto Chop Trees (Teleport)",
    description = "Finds the nearest tree, teleports beside it and swings your axe",
    value = false,
    flag = "ForestAutoChopToggle",
    callback = function(value)
        autoChopEnabled = value
    end,
})

forestTab:CreateSlider({
    name = "Tree Search Range",
    range = { 25, 1000 },
    increment = 25,
    value = 250,
    suffix = "studs",
    flag = "ForestChopRange",
    callback = function(value)
        chopRange = value
    end,
})

forestTab:CreateToggle({
    name = "Auto Gather (Nearby)",
    description = "Fires resource prompts in range without moving",
    value = false,
    flag = "ForestGatherNearbyToggle",
    callback = function(value)
        gatherNearbyEnabled = value
    end,
})

forestTab:CreateToggle({
    name = "Auto Gather (Teleport)",
    description = "Teleports to the nearest tree / rock / bush and gathers it",
    value = false,
    flag = "ForestGatherTeleportToggle",
    callback = function(value)
        gatherTeleportEnabled = value
    end,
})

forestTab:CreateToggle({
    name = "Auto Pickup Drops",
    description = "Collects nearby dropped items and loot",
    value = false,
    flag = "ForestAutoPickupToggle",
    callback = function(value)
        autoPickupEnabled = value
    end,
})

forestTab:CreateToggle({
    name = "Auto Loot (Press E)",
    description = "Spams E to grab ground loot, chests and food",
    value = false,
    flag = "ForestAutoLootToggle",
    callback = function(value)
        autoLootEnabled = value
    end,
})

forestTab:CreateToggle({
    name = "Auto Feed Fire (F)",
    description = "Near a campfire: holds a log / fuel item and presses F to drop it in",
    value = false,
    flag = "ForestAutoFeedFireToggle",
    callback = function(value)
        autoFeedFireEnabled = value
    end,
})

forestTab:CreateToggle({
    name = "Auto Refuel Fire (Prompts)",
    description = "Fires nearby campfire / furnace prompts",
    value = false,
    flag = "ForestAutoRefuelToggle",
    callback = function(value)
        autoRefuelEnabled = value
    end,
})

forestTab:CreateSlider({
    name = "Gather / Pickup Range",
    range = { 10, 200 },
    increment = 5,
    value = 40,
    suffix = "studs",
    flag = "ForestGatherRange",
    callback = function(value)
        gatherRange = value
    end,
})

forestTab:CreateSection({ name = "Survival" })

forestTab:CreateToggle({
    name = "Auto Eat",
    description = "Eats food / walks to nearby food when hunger is low",
    value = false,
    flag = "ForestAutoEatToggle",
    callback = function(value)
        autoEatEnabled = value
    end,
})

forestTab:CreateSlider({
    name = "Eat Below",
    range = { 1, 90 },
    increment = 1,
    value = 35,
    suffix = "%",
    flag = "ForestEatThreshold",
    callback = function(value)
        eatThreshold = value
    end,
})

forestTab:CreateButton({
    name = "Check Hunger Value",
    description = "Shows the hunger value this script can detect",
    callback = function()
        local hunger = forestReadHunger()
        if hunger then
            Window:Notify({
                title = "Hunger Detected",
                content = string.format("Current value: %.1f", hunger),
                duration = 4,
            })
        else
            Window:Notify({
                title = "Hunger Not Found",
                content = "Neither a hunger value nor a hunger bar was found. Auto Eat needs one to work.",
                duration = 5,
            })
        end
    end,
})

forestTab:CreateButton({
    name = "Eat Now",
    description = "Tries a food tool, then walks to nearby food and presses E",
    callback = function()
        if forestEat() then
            Window:Notify({
                title = "Eating",
                content = "Tried the best food source available.",
                duration = 3,
            })
        end
    end,
})

forestTab:CreateToggle({
    name = "Void Protection",
    description = "Teleports you back up if you fall under the map",
    value = false,
    flag = "ForestVoidProtectionToggle",
    callback = function(value)
        voidProtectionEnabled = value
    end,
})

forestTab:CreateSection({ name = "Combat" })

forestTab:CreateToggle({
    name = "Auto Hunt Animals",
    description = "Swings your equipped weapon at nearby animals",
    value = false,
    flag = "ForestAutoHuntToggle",
    callback = function(value)
        autoHuntEnabled = value
    end,
})

forestTab:CreateToggle({
    name = "Hunt Teleport",
    description = "Teleports beside the target animal before attacking",
    value = false,
    flag = "ForestHuntTeleportToggle",
    callback = function(value)
        huntTeleportEnabled = value
    end,
})

forestTab:CreateSlider({
    name = "Hunt Range",
    range = { 5, 200 },
    increment = 1,
    value = 25,
    suffix = "studs",
    flag = "ForestHuntRange",
    callback = function(value)
        huntRange = value
    end,
})

forestTab:CreateSection({ name = "ESP" })

forestTab:CreateToggle({
    name = "Resource ESP",
    description = "Highlights trees, rocks, berries, mushrooms, chests and campfires",
    value = false,
    flag = "ForestResourceESPToggle",
    callback = function(value)
        resourceESPEnabled = value
    end,
})

forestTab:CreateSlider({
    name = "Resource ESP Range",
    range = { 25, 500 },
    increment = 5,
    value = 150,
    suffix = "studs",
    flag = "ForestResourceESPRange",
    callback = function(value)
        resourceESPRange = value
    end,
})

forestTab:CreateToggle({
    name = "Animal ESP",
    description = "Highlights animals (red = hostile, green = passive)",
    value = false,
    flag = "ForestAnimalESPToggle",
    callback = function(value)
        animalESPEnabled = value
    end,
})

forestTab:CreateSlider({
    name = "Animal ESP Range",
    range = { 25, 500 },
    increment = 5,
    value = 200,
    suffix = "studs",
    flag = "ForestAnimalESPRange",
    callback = function(value)
        animalESPRange = value
    end,
})

forestTab:CreateSection({ name = "Teleport" })

local forestTargetOptions = { "Any Resource", "Wood", "Stone", "Berries", "Mushrooms", "Food", "Chest", "Animals", "Campfire" }
local forestTarget = "Any Resource"

forestTab:CreateDropdown({
    name = "Teleport Target",
    options = forestTargetOptions,
    value = "Any Resource",
    flag = "ForestTeleportTarget",
    callback = function(selected)
        forestTarget = selected
    end,
})

local function forestFindTarget(target)
    forestCache.time = 0
    forestRefreshCache()

    if target == "Animals" then
        local best, bestDistance = nil, math.huge
        for _, animal in ipairs(forestCache.animals) do
            if animal.Parent and not forestIsIgnored(animal.Name) then
                local distance = forestDistance(animal)
                if distance < bestDistance then
                    best, bestDistance = animal, distance
                end
            end
        end
        return best
    end

    if target == "Campfire" then
        local best, bestDistance = nil, math.huge
        for _, prompt in ipairs(forestCache.firePrompts) do
            if prompt.Parent then
                local distance = forestDistance(prompt)
                if distance < bestDistance then
                    best, bestDistance = prompt, distance
                end
            end
        end
        return best
    end

    local keywords = resourceKeywords
    if target == "Wood" then
        keywords = woodKeywords
    elseif target == "Stone" then
        keywords = stoneKeywords
    elseif target == "Berries" then
        keywords = berryKeywords
    elseif target == "Mushrooms" then
        keywords = mushroomKeywords
    elseif target == "Food" then
        keywords = foodKeywords
    elseif target == "Chest" then
        keywords = chestKeywords
    end

    local best, bestDistance = nil, math.huge
    for _, object in ipairs(forestCache.resources) do
        if object.Parent and forestContains(object.Name, keywords) then
            local distance = forestDistance(object)
            if distance < bestDistance then
                best, bestDistance = object, distance
            end
        end
    end
    return best
end

forestTab:CreateButton({
    name = "Teleport to Nearest",
    description = "Uses the target selected above",
    callback = function()
        local target = forestFindTarget(forestTarget)
        if not target then
            Window:Notify({
                title = "Not Found",
                content = "No matching object was detected nearby.",
                duration = 3,
            })
            return
        end

        if forestTeleport(target, 4) then
            Window:Notify({
                title = "Teleported",
                content = "Moved to the nearest " .. forestTarget .. ".",
                duration = 3,
            })
        end
    end,
})

forestTab:CreateButton({
    name = "Scan World (Debug)",
    description = "Shows how many resources, animals and prompts were detected",
    callback = function()
        forestCache.time = 0
        forestRefreshCache()

        Window:Notify({
            title = "99 Nights Scan",
            content = string.format(
                "%d resources, %d animals, %d gather prompts, %d fire prompts, %d drop prompts",
                #forestCache.resources,
                #forestCache.animals,
                #forestCache.gatherPrompts,
                #forestCache.firePrompts,
                #forestCache.dropPrompts
            ),
            duration = 6,
        })
    end,
})

local scriptsTab = Window:CreateTab({ name = "Scripts", icon = 4483362458 })

local topScriptsGroup = scriptsTab:CreateGroup({ direction = "row" })

topScriptsGroup:CreateButton({
    name = "Infinity Yield",
    callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/edgeiy/infiniteyield/master/source'))()
    end,
})

topScriptsGroup:CreateButton({
    name = "Better Save Instance",
    callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/ZentosDevOFF/SynSaveInstance-/main/ssi%2B%2B.lua'))()
    end,
})

scriptsTab:CreateSection({ name = "Rejoin Server / Server Hop" })

scriptsTab:CreateButton({
    name = "Rejoin Server",
    description = "Quickly rejoin the current server",
    callback = function()
        Window:Popup({
            title = "Which one would you like to do?",
            content = "Rejoin puts you back in this exact server. Server Hop finds you a different one.",
            options = {
                { text = "Cancel" },
                {
                    text = "Rejoin Server",
                    style = "primary",
                    callback = function()
                        local TeleportService = game:GetService("TeleportService")
                        local LocalPlayer = Players.LocalPlayer

                        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)

                        Window:Notify({
                            title = "Rejoining...",
                            content = "You are being teleported back to the server.",
                            duration = 3,
                        })
                    end
                },
                {
                    text = "Server Hop",
                    style = "danger",
                    callback = function()
                        local TeleportService = game:GetService("TeleportService")
                        local LocalPlayer = Players.LocalPlayer

                        TeleportService:Teleport(game.PlaceId, LocalPlayer)

                        Window:Notify({
                            title = "Hopping...",
                            content = "You are being teleported to another server.",
                            duration = 3,
                        })
                    end
                },
            },
        })
    end,
})

scriptsTab:CreateSection({ name = "Utility Scripts" })

local utilityScriptsGroup = scriptsTab:CreateGroup({ direction = "row" })

utilityScriptsGroup:CreateButton({
    name = "Dark Dex++",
    callback = function()
        loadstring(game:HttpGet('https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua'))()
    end,
})

utilityScriptsGroup:CreateButton({
    name = "UNC Test",
    callback = function()
        loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/UNC%20Checker.lua"))()
    end,
})

utilityScriptsGroup:CreateButton({
    name = "Dark Dex",
    callback = function()
        loadstring(game:HttpGet('https://github.com/OfficiallyMelon/BetterDecompiler/raw/main/dex_betterdecompiler.lua'))()
    end,
})

local teleportTab = Window:CreateTab({ name = "Teleportation", icon = 4483362458 })

local function getPlayerNames()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    return names
end

local selectedPlayer = nil

-- Gen2 dropdown callback returns a plain string in single-select mode (not a table)
local teleportDropdown = teleportTab:CreateDropdown({
    name = "Select Player",
    options = getPlayerNames(),
    flag = "TeleportPlayerDropdown",
    callback = function(selected)
        selectedPlayer = selected
    end,
})

teleportTab:CreateButton({
    name = "Teleport to Player",
    callback = function()
        if not selectedPlayer then return end
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        local myChar = Players.LocalPlayer.Character
        if targetPlayer and targetPlayer.Character and myChar then
            local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = myChar:FindFirstChild("HumanoidRootPart")
            if targetHrp and myHrp then
                myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end,
})

Players.PlayerAdded:Connect(function()
    teleportDropdown:Refresh(getPlayerNames())
end)
Players.PlayerRemoving:Connect(function()
    teleportDropdown:Refresh(getPlayerNames())
end)

teleportTab:CreateSection({ name = "Coordinates" })

local teleportXInput = teleportTab:CreateInput({
    name = "X Coordinate",
    numeric = true,
    value = "0",
    placeholder = "0",
    flag = "TeleportXInput",
})

local teleportYInput = teleportTab:CreateInput({
    name = "Y Coordinate",
    numeric = true,
    value = "0",
    placeholder = "0",
    flag = "TeleportYInput",
})

local teleportZInput = teleportTab:CreateInput({
    name = "Z Coordinate",
    numeric = true,
    value = "0",
    placeholder = "0",
    flag = "TeleportZInput",
})

local function getMyRootPart()
    local char = Players.LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

teleportTab:CreateButton({
    name = "Teleport to Coordinates",
    description = "Uses the X / Y / Z fields above",
    callback = function()
        local hrp = getMyRootPart()
        if not hrp then return end

        local x = tonumber(teleportXInput.value) or 0
        local y = tonumber(teleportYInput.value) or 0
        local z = tonumber(teleportZInput.value) or 0

        hrp.CFrame = CFrame.new(Vector3.new(x, y, z))
        Window:Notify({
            title = "Teleported",
            content = string.format("Moved to %.1f, %.1f, %.1f", x, y, z),
            duration = 3,
        })
    end,
})

teleportTab:CreateSection({ name = "Waypoints" })

local savedWaypoint = nil

teleportTab:CreateButton({
    name = "Teleport to Cursor",
    description = "Teleport to the part under your mouse",
    callback = function()
        local hrp = getMyRootPart()
        local mouse = Players.LocalPlayer:GetMouse()
        if not hrp or not mouse.Target then return end

        hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
    end,
})

teleportTab:CreateButton({
    name = "Save Waypoint",
    description = "Remember your current position",
    callback = function()
        local hrp = getMyRootPart()
        if not hrp then return end

        savedWaypoint = hrp.Position
        Window:Notify({
            title = "Waypoint Saved",
            content = string.format("%.1f, %.1f, %.1f", savedWaypoint.X, savedWaypoint.Y, savedWaypoint.Z),
            duration = 3,
        })
    end,
})

teleportTab:CreateButton({
    name = "Go to Waypoint",
    description = "Return to your last saved position",
    callback = function()
        local hrp = getMyRootPart()
        if not hrp then return end

        if not savedWaypoint then
            Window:Notify({
                title = "No Waypoint",
                content = "Save a waypoint first.",
                duration = 3,
            })
            return
        end

        hrp.CFrame = CFrame.new(savedWaypoint + Vector3.new(0, 3, 0))
    end,
})

teleportTab:CreateButton({
    name = "Copy Position",
    description = "Copy your X, Y, Z to the clipboard",
    callback = function()
        local hrp = getMyRootPart()
        if not hrp then return end

        local clipboard = (getgenv and getgenv().setclipboard) or setclipboard
        if not clipboard then
            Window:Notify({
                title = "Clipboard Unavailable",
                content = "Your executor does not support setclipboard.",
                duration = 4,
            })
            return
        end

        local pos = hrp.Position
        clipboard(string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z))
        Window:Notify({
            title = "Copied",
            content = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z),
            duration = 3,
        })
    end,
})



local settingsTab = Window:CreateTab({ name = "Settings", icon = 4483362458 })

settingsTab:CreateToggle({
    name = "Enable Keybinds",
    value = true,
    flag = "KeybindsEnabledToggle",
    callback = function(value)
        keybindsEnabled = value
    end,
})

settingsTab:CreateSection({ name = "Fun" })

local clickTeleportEnabled = false

settingsTab:CreateToggle({
    name = "Click Teleport",
    description = "Click anywhere in the world to teleport there",
    value = false,
    flag = "ClickTeleportToggle",
    callback = function(value)
        clickTeleportEnabled = value
    end,
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not clickTeleportEnabled or gameProcessed or freecamOn then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local hrp = getMyRootPart()
    local mouse = Players.LocalPlayer:GetMouse()
    if hrp and mouse.Target then
        hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
    end
end)

local function createExplosion(part)
    if not part then return end

    local position = part.Position

    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = 0
    explosion.BlastPressure = 0
    explosion.DestroyJointRadiusPercent = 0
    explosion.Visible = true
    explosion.Parent = workspace

    local attachment = Instance.new("Attachment")
    attachment.Parent = part

    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/fire_main.dds"
    particles.Lifetime = NumberRange.new(0.3, 0.6)
    particles.Rate = 0
    particles.Speed = NumberRange.new(10, 25)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 3),
        NumberSequenceKeypoint.new(1, 0),
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    particles.Parent = attachment

    particles:Emit(40)

    local camera = workspace.CurrentCamera
    local myChar = Players.LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myHrp then
        local distance = (myHrp.Position - position).Magnitude
        if distance < 50 then
            local shakeStrength = math.clamp((50 - distance) / 50, 0, 1) * 0.5
            local originalCFrame = camera.CFrame
            task.spawn(function()
                for i = 1, 10 do
                    local offset = Vector3.new(
                        (math.random() - 0.5) * shakeStrength,
                        (math.random() - 0.5) * shakeStrength,
                        0
                    )
                    camera.CFrame = originalCFrame * CFrame.new(offset)
                    task.wait(0.02)
                end
            end)
        end
    end

    task.delay(1, function()
        attachment:Destroy()
    end)
end

settingsTab:CreateButton({
    name = "Explode Selected Part",
    callback = function()
        local mouse = Players.LocalPlayer:GetMouse()
        local target = mouse.Target
        if target then
            createExplosion(target)
        end
    end,
})