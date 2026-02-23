--[[
	Constants.spec.lua — Sanity checks for game constants
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

return function()
	describe("Constants", function()
		it("should have positive movement speeds", function()
			expect(Constants.WALK_SPEED).to.be.ok()
			expect(Constants.WALK_SPEED > 0).to.equal(true)
			expect(Constants.FLIGHT_SPEED > 0).to.equal(true)
			expect(Constants.FLIGHT_VERTICAL_SPEED > 0).to.equal(true)
		end)

		it("should have valid stamina values", function()
			expect(Constants.MAX_STAMINA > 0).to.equal(true)
			expect(Constants.STAMINA_DRAIN_RATE > 0).to.equal(true)
			expect(Constants.STAMINA_REGEN_RATE > 0).to.equal(true)
			-- Regen should be faster than drain so players can recover
			expect(Constants.STAMINA_REGEN_RATE > Constants.STAMINA_DRAIN_RATE).to.equal(true)
		end)

		it("should have all 6 level names", function()
			expect(#Constants.LEVEL_NAMES).to.equal(6)
			expect(Constants.LEVEL_NAMES[1]).to.equal("Newborn")
			expect(Constants.LEVEL_NAMES[6]).to.equal("Angel")
		end)

		it("should have matching level thresholds", function()
			for _, name in Constants.LEVEL_NAMES do
				expect(Constants.LEVEL_THRESHOLDS[name]).to.be.ok()
			end
		end)

		it("should have increasing thresholds", function()
			local prev = -1
			for _, name in Constants.LEVEL_NAMES do
				local threshold = Constants.LEVEL_THRESHOLDS[name]
				expect(threshold > prev).to.equal(true)
				prev = threshold
			end
		end)

		it("should have valid rate limits", function()
			expect(Constants.REMOTE_RATE_LIMIT > 0).to.equal(true)
			expect(Constants.REMOTE_TIMEOUT > 0).to.equal(true)
		end)

		it("should have positive economy values", function()
			expect(Constants.DAILY_LOGIN_REWARD > 0).to.equal(true)
			expect(Constants.MAX_DAILY_EARN > Constants.DAILY_LOGIN_REWARD).to.equal(true)
		end)
	end)
end
