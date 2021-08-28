-- SilentsReplacement
-- init
-- August 12, 2021

local RunService = game:GetService("RunService")

if RunService:IsClient() then
    return require(script.Client)
else
    return require(script.Server)
end