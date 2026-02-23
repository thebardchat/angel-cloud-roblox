--[[
	MathUtil.spec.lua — Unit tests for ReplicatedStorage.Shared.MathUtil
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MathUtil = require(ReplicatedStorage.Shared.MathUtil)

return function()
	describe("MathUtil", function()
		describe("Lerp", function()
			it("should interpolate between two values", function()
				expect(MathUtil.Lerp(0, 100, 0.5)).to.equal(50)
				expect(MathUtil.Lerp(0, 100, 0)).to.equal(0)
				expect(MathUtil.Lerp(0, 100, 1)).to.equal(100)
			end)

			it("should handle negative values", function()
				expect(MathUtil.Lerp(-10, 10, 0.5)).to.equal(0)
			end)
		end)

		describe("InverseLerp", function()
			it("should return normalized position", function()
				expect(MathUtil.InverseLerp(0, 100, 50)).to.equal(0.5)
				expect(MathUtil.InverseLerp(0, 100, 0)).to.equal(0)
				expect(MathUtil.InverseLerp(0, 100, 100)).to.equal(1)
			end)

			it("should handle equal bounds", function()
				expect(MathUtil.InverseLerp(5, 5, 5)).to.equal(0)
			end)
		end)

		describe("Map", function()
			it("should map between ranges", function()
				-- Map 50 from [0,100] to [0,1]
				expect(MathUtil.Map(50, 0, 100, 0, 1)).to.equal(0.5)
				-- Map 0.5 from [0,1] to [0,360]
				expect(MathUtil.Map(0.5, 0, 1, 0, 360)).to.equal(180)
			end)
		end)

		describe("Clamp01", function()
			it("should clamp to 0-1 range", function()
				expect(MathUtil.Clamp01(0.5)).to.equal(0.5)
				expect(MathUtil.Clamp01(-1)).to.equal(0)
				expect(MathUtil.Clamp01(2)).to.equal(1)
			end)
		end)

		describe("Approach", function()
			it("should move toward target by delta", function()
				expect(MathUtil.Approach(0, 10, 3)).to.equal(3)
				expect(MathUtil.Approach(8, 10, 3)).to.equal(10) -- snaps when close enough
				expect(MathUtil.Approach(10, 0, 3)).to.equal(7) -- moves down
			end)
		end)

		describe("Easing", function()
			it("should start and end at bounds", function()
				-- All easing functions should return 0 at t=0 and 1 at t=1
				expect(MathUtil.EaseInQuad(0)).to.equal(0)
				expect(MathUtil.EaseInQuad(1)).to.equal(1)
				expect(MathUtil.EaseOutQuad(0)).to.equal(0)
				expect(MathUtil.EaseOutQuad(1)).to.equal(1)
				expect(MathUtil.EaseInOutQuad(0)).to.equal(0)
				expect(MathUtil.EaseInOutQuad(1)).to.equal(1)
				expect(MathUtil.EaseOutBack(0)).to.near(0, 0.01)
				expect(MathUtil.EaseOutBack(1)).to.near(1, 0.01)
				expect(MathUtil.EaseOutElastic(0)).to.equal(0)
				expect(MathUtil.EaseOutElastic(1)).to.equal(1)
			end)

			it("EaseOutQuad should decelerate (midpoint > 0.5)", function()
				expect(MathUtil.EaseOutQuad(0.5)).to.be.near(0.75, 0.01)
			end)

			it("EaseInQuad should accelerate (midpoint < 0.5)", function()
				expect(MathUtil.EaseInQuad(0.5)).to.be.near(0.25, 0.01)
			end)
		end)

		describe("WrapAngle", function()
			it("should wrap angles to (-180, 180]", function()
				expect(MathUtil.WrapAngle(0)).to.equal(0)
				expect(MathUtil.WrapAngle(360)).to.equal(0)
				expect(MathUtil.WrapAngle(270)).to.equal(-90)
				expect(MathUtil.WrapAngle(-90)).to.equal(-90)
			end)
		end)

		describe("RandomFloat", function()
			it("should return values within range", function()
				for _ = 1, 100 do
					local val = MathUtil.RandomFloat(5, 10)
					expect(val >= 5).to.equal(true)
					expect(val <= 10).to.equal(true)
				end
			end)
		end)
	end)
end
