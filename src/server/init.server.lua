--[[
    init.server.lua — Knit server bootstrap
    Loads all Services, starts Knit, handles player lifecycle.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- Load all Services (Knit auto-discovers them via require)
local Services = ServerScriptService:FindFirstChild("Services")
if Services then
    for _, module in ipairs(Services:GetChildren()) do
        if module:IsA("ModuleScript") then
            require(module)
        end
    end
end

Knit.Start():andThen(function()
    print("[AngelCloud] Server started successfully")
end):catch(function(err)
    warn("[AngelCloud] Server start failed:", err)
end)
