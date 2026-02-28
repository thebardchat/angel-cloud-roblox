--[[
	MathUtil.lua — Math helper functions
	ModuleScript → ReplicatedStorage.Shared.MathUtil

	Common math operations for gameplay: interpolation, mapping, clamping, easing.
]]

local MathUtil = {}

-- Linearly interpolate between a and b by t (0-1)
function MathUtil.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Inverse lerp: given a value between a and b, return 0-1
function MathUtil.InverseLerp(a: number, b: number, value: number): number
	if a == b then
		return 0
	end
	return (value - a) / (b - a)
end

-- Map value from one range to another
function MathUtil.Map(value: number, inMin: number, inMax: number, outMin: number, outMax: number): number
	local t = MathUtil.InverseLerp(inMin, inMax, value)
	return MathUtil.Lerp(outMin, outMax, t)
end

-- Clamp value between min and max
function MathUtil.Clamp(value: number, min: number, max: number): number
	return math.clamp(value, min, max)
end

-- Clamp01: shorthand for Clamp(value, 0, 1)
function MathUtil.Clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

-- Smooth damp (spring-like interpolation)
-- Returns new value and new velocity
function MathUtil.SmoothDamp(
	current: number,
	target: number,
	velocity: number,
	smoothTime: number,
	dt: number
): (number, number)
	smoothTime = math.max(0.0001, smoothTime)
	local omega = 2 / smoothTime
	local x = omega * dt
	local exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
	local change = current - target
	local temp = (velocity + omega * change) * dt
	local newVelocity = (velocity - omega * temp) * exp
	local newValue = target + (change + temp) * exp
	return newValue, newVelocity
end

-- Approach: move current toward target by maxDelta per step
function MathUtil.Approach(current: number, target: number, maxDelta: number): number
	if math.abs(target - current) <= maxDelta then
		return target
	end
	return current + math.sign(target - current) * maxDelta
end

-- Wrap angle to (-180, 180] range
function MathUtil.WrapAngle(angle: number): number
	angle = angle % 360
	if angle > 180 then
		angle -= 360
	end
	return angle
end

-- Random float between min and max
function MathUtil.RandomFloat(min: number, max: number): number
	return min + math.random() * (max - min)
end

-- Random point inside a circle of given radius (2D)
function MathUtil.RandomInCircle(radius: number): Vector3
	local angle = math.random() * math.pi * 2
	local dist = math.sqrt(math.random()) * radius
	return Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
end

-- Ease In Quad
function MathUtil.EaseInQuad(t: number): number
	return t * t
end

-- Ease Out Quad
function MathUtil.EaseOutQuad(t: number): number
	return 1 - (1 - t) * (1 - t)
end

-- Ease In Out Quad
function MathUtil.EaseInOutQuad(t: number): number
	if t < 0.5 then
		return 2 * t * t
	else
		return 1 - (-2 * t + 2) ^ 2 / 2
	end
end

-- Ease Out Back (slight overshoot — satisfying for UI animations)
function MathUtil.EaseOutBack(t: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

-- Ease Out Elastic (bouncy — great for collectible feedback)
function MathUtil.EaseOutElastic(t: number): number
	if t == 0 or t == 1 then
		return t
	end
	local c4 = (2 * math.pi) / 3
	return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

-- Bezier interpolation (quadratic)
function MathUtil.QuadBezier(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	local u = 1 - t
	return u * u * p0 + 2 * u * t * p1 + t * t * p2
end

return MathUtil