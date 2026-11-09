getgenv().Config = getgenv().Config or {
    Enabled = true,
    TeamCheck = true,
    WallCheck = true,
    MaxDistance = 5000,
    FOV = 60,
    StickyAim = true
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Dibujar el círculo del FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Thickness = 1.5
fovCircle.NumSides = 64
fovCircle.Radius = getgenv().Config.FOV
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 0.8

-- Actualizar la posición y el radio dinámicamente en cada frame
local fovConnection
fovConnection = RunService.RenderStepped:Connect(function()
    local Config = getgenv().Config
    if not Config or not Config.Enabled then
        fovCircle.Visible = false
        return
    end
    fovCircle.Visible = true
    fovCircle.Radius = Config.FOV
    fovCircle.Position = UserInputService:GetMouseLocation()
end)

local MouseModule = require(game:GetService("ReplicatedStorage").TREK_SERVICES.TREK_Modules.TREKMouseModule)
local mouseMeta = getrawmetatable(MouseModule)
local originalIndex = mouseMeta.__index

local lockedTarget = nil
local needsRelease = false

-- Lista de partes corporales evaluadas dinámicamente
local HitPartsList = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg"}

mouseMeta.__index = function(self, key)
    local Config = getgenv().Config
    if not Config or not Config.Enabled then
        lockedTarget = nil
        needsRelease = false
        return originalIndex(self, key)
    end

    if key ~= "HitPosition" and key ~= "Hit" and key ~= "Target" then
        return originalIndex(self, key)
    end

    if not Camera then
        return originalIndex(self, key)
    end

    local mousePos = UserInputService:GetMouseLocation()

    -- Gestión de Sticky Aim
    local isAimingOrFiring = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    if Config.StickyAim then
        if needsRelease then
            if not isAimingOrFiring then
                needsRelease = false
            else
                lockedTarget = nil
                return originalIndex(self, key)
            end
        end

        -- Validar si el objetivo bloqueado sigue dentro del FOV y rango
        if lockedTarget and lockedTarget.Parent and lockedTarget:IsA("BasePart") then
            local char = lockedTarget.Parent
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                if root and root:IsA("BasePart") and (root.Position - Camera.CFrame.Position).Magnitude <= Config.MaxDistance then
                    local screenPosition, onScreen = Camera:WorldToViewportPoint(lockedTarget.Position)
                    if onScreen then
                        local distanceToMouse = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePos).Magnitude
                        if distanceToMouse <= Config.FOV then
                            local isValid = true
                            if Config.WallCheck then
                                local rayParams = RaycastParams.new()
                                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                                rayParams.FilterDescendantsInstances = {LocalPlayer.Character, char}
                                local rayResult = Workspace:Raycast(Camera.CFrame.Position, lockedTarget.Position - Camera.CFrame.Position, rayParams)
                                if rayResult then
                                    isValid = false
                                end
                            end
                            if isValid then
                                if key == "HitPosition" then return lockedTarget.Position end
                                if key == "Hit" then return CFrame.new(lockedTarget.Position) end
                                if key == "Target" then return lockedTarget end
                            end
                        end
                    end
                end
            end
            lockedTarget = nil
            needsRelease = true
            return originalIndex(self, key)
        else
            lockedTarget = nil
        end
    else
        lockedTarget = nil
    end

    -- Búsqueda inteligente: evaluar cuál es la parte más cercana al mouse DENTRO del FOV
    local closestPart = nil
    local closestDistance = Config.FOV

    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        if Config.TeamCheck and LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team then
            continue
        end

        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
                if rootPart and rootPart:IsA("BasePart") and (rootPart.Position - Camera.CFrame.Position).Magnitude <= Config.MaxDistance then
                    
                    -- Iterar sobre todas las partes posibles para hallar la óptima
                    for _, partName in ipairs(HitPartsList) do
                        local part = character:FindFirstChild(partName)
                        if part and part:IsA("BasePart") then
                            local screenPosition, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local screenPos2D = Vector2.new(screenPosition.X, screenPosition.Y)
                                local distanceToMouse = (screenPos2D - mousePos).Magnitude

                                if distanceToMouse <= closestDistance then
                                    if Config.WallCheck then
                                        local rayParams = RaycastParams.new()
                                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                                        rayParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
                                        local rayResult = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
                                        if rayResult then
                                            continue
                                        end
                                    end

                                    closestDistance = distanceToMouse
                                    closestPart = part
                                end
                            end
                        end
                    end

                end
            end
        end
    end

    if not closestPart or not closestPart:IsA("BasePart") then
        return originalIndex(self, key)
    end

    if Config.StickyAim then
        lockedTarget = closestPart
    end

    if key == "HitPosition" then
        return closestPart.Position
    elseif key == "Hit" then
        return CFrame.new(closestPart.Position)
    elseif key == "Target" then
        return closestPart
    end

    return originalIndex(self, key)
end

-- Kill Switch con F5
local killConnection
killConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F5 then
        if mouseMeta and originalIndex then
            mouseMeta.__index = originalIndex
        end
        if killConnection then
            killConnection:Disconnect()
        end
        if fovConnection then
            fovConnection:Disconnect()
        end
        if fovCircle then
            fovCircle:Remove()
        end
        getgenv().Config = nil
        print("[KILL SWITCH] Script y visuales eliminados por completo.")
    end
end)
