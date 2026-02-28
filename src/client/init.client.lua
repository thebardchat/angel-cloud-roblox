--[[
    init.client.lua — Knit client bootstrap
    Loads all Controllers, starts Knit, initializes UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- Load all Controllers
local Controllers = StarterPlayerScripts:FindFirstChild("Controllers")
if Controllers then
    for _, module in ipairs(Controllers:GetChildren()) do
        if module:IsA("ModuleScript") then
            require(module)
        end
    end
end

Knit.Start():andThen(function()
    print("[AngelCloud] Client started successfully")
end):catch(function(err)
    warn("[AngelCloud] Client start failed:", err)
end)
