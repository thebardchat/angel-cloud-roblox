--[[
	Test Runner — Discovers and runs all .spec.lua files using TestEZ
	Script → ServerStorage.TestRunner.runner

	HOW TO RUN:
	1. In Roblox Studio: Run mode → this script auto-executes
	2. Or via Lune: lune run tests/runner
	3. Results print to Output window

	WRITING TESTS:
	Create files named *.spec.lua next to the module they test.
	Example: tests/ReplicatedStorage/TableUtil.spec.lua
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for game to load
task.wait(2)

-- Try to load TestEZ
local TestEZ
local ok, err = pcall(function()
	-- Check Packages first (Wally install)
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	if packages and packages:FindFirstChild("TestEZ") then
		TestEZ = require(packages.TestEZ)
		return
	end

	-- Check DevPackages
	local devPackages = ReplicatedStorage:FindFirstChild("DevPackages")
	if devPackages and devPackages:FindFirstChild("TestEZ") then
		TestEZ = require(devPackages.TestEZ)
		return
	end

	-- Check ServerStorage (manual install)
	local serverTestEZ = ServerStorage:FindFirstChild("TestEZ")
	if serverTestEZ then
		TestEZ = require(serverTestEZ)
		return
	end

	error("TestEZ not found — run `wally install` or manually add TestEZ to ServerStorage")
end)

if not ok then
	warn("[TestRunner] " .. tostring(err))
	warn("[TestRunner] Skipping tests. Install TestEZ via: wally install")
	return
end

print("=" .. string.rep("=", 59))
print("[TestRunner] Angel Cloud ROBLOX — Test Suite")
print("=" .. string.rep("=", 59))

-- Collect all test roots
local testRoots = {}

local testRunner = ServerStorage:FindFirstChild("TestRunner")
if testRunner then
	-- Find all spec files in the test directories
	local function findSpecs(parent)
		for _, child in parent:GetChildren() do
			if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
				table.insert(testRoots, child)
			end
			if child:IsA("Folder") then
				findSpecs(child)
			end
		end
	end
	findSpecs(testRunner)
end

if #testRoots == 0 then
	print("[TestRunner] No .spec files found. Add tests to tests/ directory.")
	return
end

print("[TestRunner] Found " .. #testRoots .. " test file(s)")
print("")

-- Run all tests
local results = TestEZ.TestBootstrap:run(testRoots)

-- Summary
print("")
print("=" .. string.rep("=", 59))
if results.failureCount == 0 then
	print("[TestRunner] ALL TESTS PASSED (" .. results.successCount .. " passed, " .. results.skippedCount .. " skipped)")
else
	print("[TestRunner] TESTS FAILED: " .. results.failureCount .. " failed, " .. results.successCount .. " passed")
end
print("=" .. string.rep("=", 59))
