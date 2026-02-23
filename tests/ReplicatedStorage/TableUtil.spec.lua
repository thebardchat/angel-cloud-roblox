--[[
	TableUtil.spec.lua — Unit tests for ReplicatedStorage.Shared.TableUtil
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.TableUtil)

return function()
	describe("TableUtil", function()
		describe("DeepCopy", function()
			it("should create an independent copy", function()
				local original = { a = 1, b = { c = 2 } }
				local copy = TableUtil.DeepCopy(original)

				expect(copy.a).to.equal(1)
				expect(copy.b.c).to.equal(2)

				-- Modifying copy should not affect original
				copy.b.c = 99
				expect(original.b.c).to.equal(2)
			end)

			it("should handle empty tables", function()
				local copy = TableUtil.DeepCopy({})
				expect(TableUtil.Count(copy)).to.equal(0)
			end)
		end)

		describe("Merge", function()
			it("should merge two tables with source overwriting", function()
				local target = { a = 1, b = 2 }
				local source = { b = 3, c = 4 }
				local result = TableUtil.Merge(target, source)

				expect(result.a).to.equal(1)
				expect(result.b).to.equal(3)
				expect(result.c).to.equal(4)
			end)

			it("should not modify the original tables", function()
				local target = { a = 1 }
				local source = { b = 2 }
				TableUtil.Merge(target, source)

				expect(target.b).to.equal(nil)
			end)
		end)

		describe("Reconcile", function()
			it("should fill in missing keys from template", function()
				local data = { motes = 50 }
				local template = { motes = 0, level = "Newborn", wings = 1 }
				TableUtil.Reconcile(data, template)

				expect(data.motes).to.equal(50) -- existing value preserved
				expect(data.level).to.equal("Newborn") -- filled from template
				expect(data.wings).to.equal(1) -- filled from template
			end)

			it("should recursively reconcile nested tables", function()
				local data = { stats = { health = 100 } }
				local template = { stats = { health = 50, mana = 25 } }
				TableUtil.Reconcile(data, template)

				expect(data.stats.health).to.equal(100) -- preserved
				expect(data.stats.mana).to.equal(25) -- filled
			end)
		end)

		describe("Contains", function()
			it("should return true for existing values", function()
				local tbl = { "apple", "banana", "cherry" }
				expect(TableUtil.Contains(tbl, "banana")).to.equal(true)
			end)

			it("should return false for missing values", function()
				local tbl = { "apple", "banana" }
				expect(TableUtil.Contains(tbl, "grape")).to.equal(false)
			end)
		end)

		describe("Filter", function()
			it("should return only matching elements", function()
				local numbers = { 1, 2, 3, 4, 5, 6 }
				local evens = TableUtil.Filter(numbers, function(n)
					return n % 2 == 0
				end)

				expect(#evens).to.equal(3)
				expect(evens[1]).to.equal(2)
				expect(evens[2]).to.equal(4)
				expect(evens[3]).to.equal(6)
			end)
		end)

		describe("Map", function()
			it("should transform all elements", function()
				local numbers = { 1, 2, 3 }
				local doubled = TableUtil.Map(numbers, function(n)
					return n * 2
				end)

				expect(#doubled).to.equal(3)
				expect(doubled[1]).to.equal(2)
				expect(doubled[2]).to.equal(4)
				expect(doubled[3]).to.equal(6)
			end)
		end)

		describe("Count", function()
			it("should count dictionary entries", function()
				local dict = { a = 1, b = 2, c = 3 }
				expect(TableUtil.Count(dict)).to.equal(3)
			end)

			it("should return 0 for empty tables", function()
				expect(TableUtil.Count({})).to.equal(0)
			end)
		end)

		describe("Keys and Values", function()
			it("should extract keys", function()
				local dict = { x = 10, y = 20 }
				local keys = TableUtil.Keys(dict)
				expect(#keys).to.equal(2)
				expect(TableUtil.Contains(keys, "x")).to.equal(true)
				expect(TableUtil.Contains(keys, "y")).to.equal(true)
			end)

			it("should extract values", function()
				local dict = { x = 10, y = 20 }
				local values = TableUtil.Values(dict)
				expect(#values).to.equal(2)
				expect(TableUtil.Contains(values, 10)).to.equal(true)
				expect(TableUtil.Contains(values, 20)).to.equal(true)
			end)
		end)
	end)
end
