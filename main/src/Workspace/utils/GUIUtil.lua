local Cast = require(script.Parent.Cast)
local MathUtil = require(script.Parent.MathUtil)
local Timer = require(script.Parent.Timer)

local GUIUtil = {}
GUIUtil.__index = GUIUtil

function GUIUtil.new(runtime)
	local self = setmetatable({}, GUIUtil)
	self.runtime = runtime
	return self
end

function GUIUtil:getPrimitives()
	return {
		motion_movesteps = function(args, util) self:moveSteps(args, util) end,
		motion_gotoxy = function(args, util) self:goToXY(args, util) end,
		motion_goto = function(args, util) self:goTo(args, util) end,
		motion_turnright = function(args, util) self:turnRight(args, util) end,
		motion_turnleft = function(args, util) self:turnLeft(args, util) end,
		motion_pointindirection = function(args, util) self:pointInDirection(args, util) end,
		motion_pointtowards = function(args, util) self:pointTowards(args, util) end,
		motion_glidesecstoxy = function(args, util) self:glide(args, util) end,
		motion_glideto = function(args, util) self:glideTo(args, util) end,
		motion_ifonedgebounce = function(args, util) self:ifOnEdgeBounce(args, util) end,
		motion_setrotationstyle = function(args, util) self:setRotationStyle(args, util) end,
		motion_changexby = function(args, util) self:changeX(args, util) end,
		motion_setx = function(args, util) self:setX(args, util) end,
		motion_changeyby = function(args, util) self:changeY(args, util) end,
		motion_sety = function(args, util) self:setY(args, util) end,
		motion_xposition = function(args, util) return self:getX(args, util) end,
		motion_yposition = function(args, util) return self:getY(args, util) end,
		motion_direction = function(args, util) return self:getDirection(args, util) end,
		motion_scroll_right = function() end,
		motion_scroll_up = function() end,
		motion_align_scene = function() end,
		motion_xscroll = function() end,
		motion_yscroll = function() end
	}
end

function GUIUtil:getMonitored()
	return {
		motion_xposition = {
			isSpriteSpecific = true,
			getId = function(targetId) return targetId .. "_xposition" end
		},
		motion_yposition = {
			isSpriteSpecific = true,
			getId = function(targetId) return targetId .. "_yposition" end
		},
		motion_direction = {
			isSpriteSpecific = true,
			getId = function(targetId) return targetId .. "_direction" end
		}
	}
end

function GUIUtil:moveSteps(args, util)
	local steps = Cast.toNumber(args.STEPS)
	local radians = MathUtil.degToRad(90 - util.target.direction)
	local dx = steps * math.cos(radians)
	local dy = steps * math.sin(radians)
	util.target:setXY(util.target.x + dx, util.target.y + dy)
end

function GUIUtil:goToXY(args, util)
	local x = Cast.toNumber(args.X)
	local y = Cast.toNumber(args.Y)
	util.target:setXY(x, y)
end

function GUIUtil:getTargetXY(targetName, util)
	local targetX, targetY = 0, 0
	if targetName == '_mouse_' then
		targetX = util.ioQuery('mouse', 'getScratchX')
		targetY = util.ioQuery('mouse', 'getScratchY')
	elseif targetName == '_random_' then
		local stageWidth = self.runtime.constructor.STAGE_WIDTH
		local stageHeight = self.runtime.constructor.STAGE_HEIGHT
		targetX = math.round(stageWidth * (math.random() - 0.5))
		targetY = math.round(stageHeight * (math.random() - 0.5))
	else
		targetName = Cast.toString(targetName)
		local goToTarget = self.runtime:getSpriteTargetByName(targetName)
		if not goToTarget then return end
		targetX = goToTarget.x
		targetY = goToTarget.y
	end
	return {targetX, targetY}
end

function GUIUtil:goTo(args, util)
	local targetXY = self:getTargetXY(args.TO, util)
	if targetXY then
		util.target:setXY(targetXY[1], targetXY[2])
	end
end

function GUIUtil:turnRight(args, util)
	local degrees = Cast.toNumber(args.DEGREES)
	util.target:setDirection(util.target.direction + degrees)
end

function GUIUtil:turnLeft(args, util)
	local degrees = Cast.toNumber(args.DEGREES)
	util.target:setDirection(util.target.direction - degrees)
end

function GUIUtil:pointInDirection(args, util)
	local direction = Cast.toNumber(args.DIRECTION)
	util.target:setDirection(direction)
end

function GUIUtil:pointTowards(args, util)
	local targetX, targetY = 0, 0
	if args.TOWARDS == '_mouse_' then
		targetX = util.ioQuery('mouse', 'getScratchX')
		targetY = util.ioQuery('mouse', 'getScratchY')
	elseif args.TOWARDS == '_random_' then
		util.target:setDirection(math.round(math.random() * 360) - 180)
		return
	else
		args.TOWARDS = Cast.toString(args.TOWARDS)
		local pointTarget = self.runtime:getSpriteTargetByName(args.TOWARDS)
		if not pointTarget then return end
		targetX = pointTarget.x
		targetY = pointTarget.y
	end

	local dx = targetX - util.target.x
	local dy = targetY - util.target.y
	local direction = 90 - MathUtil.radToDeg(math.atan2(dy, dx))
	util.target:setDirection(direction)
end

function GUIUtil:glide(args, util)
	if util.stackFrame.timer then
		local timeElapsed = util.stackFrame.timer:timeElapsed()
		if timeElapsed < util.stackFrame.duration * 1000 then
			local frac = timeElapsed / (util.stackFrame.duration * 1000)
			local dx = frac * (util.stackFrame.endX - util.stackFrame.startX)
			local dy = frac * (util.stackFrame.endY - util.stackFrame.startY)
			util.target:setXY(
				util.stackFrame.startX + dx,
				util.stackFrame.startY + dy
			)
			util:yield()
		else
			util.target:setXY(util.stackFrame.endX, util.stackFrame.endY)
		end
	else
		util.stackFrame.timer = Timer.new()
		util.stackFrame.timer:start()
		util.stackFrame.duration = Cast.toNumber(args.SECS)
		util.stackFrame.startX = util.target.x
		util.stackFrame.startY = util.target.y
		util.stackFrame.endX = Cast.toNumber(args.X)
		util.stackFrame.endY = Cast.toNumber(args.Y)
		if util.stackFrame.duration <= 0 then
			util.target:setXY(util.stackFrame.endX, util.stackFrame.endY)
			return
		end
		util:yield()
	end
end

function GUIUtil:glideTo(args, util)
	local targetXY = self:getTargetXY(args.TO, util)
	if targetXY then
		self:glide({SECS = args.SECS, X = targetXY[1], Y = targetXY[2]}, util)
	end
end

function GUIUtil:ifOnEdgeBounce(args, util)
	local bounds = util.target:getBounds()
	if not bounds then
		return
	end
	local stageWidth = self.runtime.constructor.STAGE_WIDTH
	local stageHeight = self.runtime.constructor.STAGE_HEIGHT
	local distLeft = math.max(0, (stageWidth / 2) + bounds.left)
	local distTop = math.max(0, (stageHeight / 2) - bounds.top)
	local distRight = math.max(0, (stageWidth / 2) - bounds.right)
	local distBottom = math.max(0, (stageHeight / 2) + bounds.bottom)
	local nearestEdge = ''
	local minDist = math.huge
	if distLeft < minDist then
		minDist = distLeft
		nearestEdge = 'left'
	end
	if distTop < minDist then
		minDist = distTop
		nearestEdge = 'top'
	end
	if distRight < minDist then
		minDist = distRight
		nearestEdge = 'right'
	end
	if distBottom < minDist then
		minDist = distBottom
		nearestEdge = 'bottom'
	end
	if minDist > 0 then
		return
	end
	local radians = MathUtil.degToRad(90 - util.target.direction)
	local dx = math.cos(radians)
	local dy = -math.sin(radians)
	if nearestEdge == 'left' then
		dx = math.max(0.2, math.abs(dx))
	elseif nearestEdge == 'top' then
		dy = math.max(0.2, math.abs(dy))
	elseif nearestEdge == 'right' then
		dx = 0 - math.max(0.2, math.abs(dx))
	elseif nearestEdge == 'bottom' then
		dy = 0 - math.max(0.2, math.abs(dy))
	end
	local newDirection = MathUtil.radToDeg(math.atan2(dy, dx)) + 90
	util.target:setDirection(newDirection)
	local fencedPosition = util.target:keepInFence(util.target.x, util.target.y)
	util.target:setXY(fencedPosition[1], fencedPosition[2])
end

function GUIUtil:setRotationStyle(args, util)
	util.target:setRotationStyle(args.STYLE)
end

function GUIUtil:changeX(args, util)
	local dx = Cast.toNumber(args.DX)
	util.target:setXY(util.target.x + dx, util.target.y)
end

function GUIUtil:setX(args, util)
	local x = Cast.toNumber(args.X)
	util.target:setXY(x, util.target.y)
end

function GUIUtil:changeY(args, util)
	local dy = Cast.toNumber(args.DY)
	util.target:setXY(util.target.x, util.target.y + dy)
end

function GUIUtil:setY(args, util)
	local y = Cast.toNumber(args.Y)
	util.target:setXY(util.target.x, y)
end

function GUIUtil:getX(args, util)
	return self:limitPrecision(util.target.x)
end

function GUIUtil:getY(args, util)
	return self:limitPrecision(util.target.y)
end

function GUIUtil:getDirection(args, util)
	return util.target.direction
end

function GUIUtil:limitPrecision(coordinate)
	local rounded = math.round(coordinate)
	local delta = coordinate - rounded
	local limitedCoord = (math.abs(delta) < 1e-9) and rounded or coordinate
	return limitedCoord
end

return GUIUtil