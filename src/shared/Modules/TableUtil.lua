--[[
	TableUtil.lua — Table helper functions
	ModuleScript → ReplicatedStorage.Shared.TableUtil

	Common table operations used across client and server.
	Avoids relying on Wally TableUtil in case packages aren't installed.
]]

local TableUtil = {}

-- Deep copy a table (handles nested tables, no metatables)
function TableUtil.DeepCopy(original: { [any]: any }): { [any]: any }
	local copy = {}
	for key, value in original do
		if type(value) == "table" then
			copy[key] = TableUtil.DeepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Shallow copy a table
function TableUtil.ShallowCopy(original: { [any]: any }): { [any]: any }
	local copy = {}
	for key, value in original do
		copy[key] = value
	end
	return copy
end

-- Merge source into target (shallow, source overwrites)
function TableUtil.Merge(target: { [any]: any }, source: { [any]: any }): { [any]: any }
	local result = TableUtil.ShallowCopy(target)
	for key, value in source do
		result[key] = value
	end
	return result
end

-- Deep merge (recursively merges nested tables)
function TableUtil.DeepMerge(target: { [any]: any }, source: { [any]: any }): { [any]: any }
	local result = TableUtil.DeepCopy(target)
	for key, value in source do
		if type(value) == "table" and type(result[key]) == "table" then
			result[key] = TableUtil.DeepMerge(result[key], value)
		else
			result[key] = value
		end
	end
	return result
end

-- Reconcile: fill in missing keys from template (for data migration)
function TableUtil.Reconcile(data: { [any]: any }, template: { [any]: any }): { [any]: any }
	for key, value in template do
		if data[key] == nil then
			if type(value) == "table" then
				data[key] = TableUtil.DeepCopy(value)
			else
				data[key] = value
			end
		elseif type(data[key]) == "table" and type(value) == "table" then
			TableUtil.Reconcile(data[key], value)
		end
	end
	return data
end

-- Count entries in a dictionary-style table
function TableUtil.Count(tbl: { [any]: any }): number
	local count = 0
	for _ in tbl do
		count += 1
	end
	return count
end

-- Check if table contains value
function TableUtil.Contains(tbl: { any }, value: any): boolean
	for _, v in tbl do
		if v == value then
			return true
		end
	end
	return false
end

-- Find index of value in array
function TableUtil.IndexOf(tbl: { any }, value: any): number?
	for i, v in tbl do
		if v == value then
			return i
		end
	end
	return nil
end

-- Filter array by predicate
function TableUtil.Filter(tbl: { any }, predicate: (any) -> boolean): { any }
	local result = {}
	for _, value in tbl do
		if predicate(value) then
			table.insert(result, value)
		end
	end
	return result
end

-- Map array through transform function
function TableUtil.Map(tbl: { any }, transform: (any) -> any): { any }
	local result = {}
	for _, value in tbl do
		table.insert(result, transform(value))
	end
	return result
end

-- Get all keys from a dictionary
function TableUtil.Keys(tbl: { [any]: any }): { any }
	local keys = {}
	for key in tbl do
		table.insert(keys, key)
	end
	return keys
end

-- Get all values from a dictionary
function TableUtil.Values(tbl: { [any]: any }): { any }
	local values = {}
	for _, value in tbl do
		table.insert(values, value)
	end
	return values
end

-- Freeze table (makes read-only, shallow)
function TableUtil.Freeze(tbl: { [any]: any }): { [any]: any }
	return table.freeze(tbl)
end

-- Deep freeze (recursively freezes nested tables)
function TableUtil.DeepFreeze(tbl: { [any]: any }): { [any]: any }
	for _, value in tbl do
		if type(value) == "table" then
			TableUtil.DeepFreeze(value)
		end
	end
	return table.freeze(tbl)
end

return TableUtil