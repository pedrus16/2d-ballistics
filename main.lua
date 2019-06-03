require "vector"

local TICK_RATE = 1/60
local MAX_FRAME_SKIP = 25

local TIMESTEP = 1/60
local GRID_SCALE_METER = 100
local SCALE_PIXEL_PER_METER = 1
local BULLET_MUZZLE_VELOCITY = 825
local GRAVITY_METER_PER_SEC = 9.81

local timeDiff = 0

local mouseReleased = false
local dragStart = nil
local dragEnd = nil

local bullet = nil
local firingInitialTime = nil

function love.load()
    -- bullet = {
    --     position = { 100, 100 },
    --     velocity = { 1 * BULLET_MUZZLE_VELOCITY, 0 * BULLET_MUZZLE_VELOCITY }
    -- }
end

function love.update(dt)

    handleMouseDrag()

    if love.mouse.isDown(1) and firingInitialTime then
        firingInitialTime = nil
        bullet = nil
    end

    if mouseReleased and not firingInitialTime then
        firingInitialTime = love.timer.getTime()
    end

    if mouseReleased and dragStart and dragEnd and not bullet then
        local directionX, directionY = normalize(dragEnd[1] - dragStart[1], dragEnd[2] - dragStart[2])
        bullet = {
            position = { dragStart[1], dragStart[2] },
            velocity = { directionX * BULLET_MUZZLE_VELOCITY, directionY * BULLET_MUZZLE_VELOCITY }
        }
    end

    if bullet then
        bullet = getNextBulletPositionAndVelocityHeun(bullet.position[1], bullet.position[2], bullet.velocity[1], bullet.velocity[2], dt)
    end

end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 10)
    love.graphics.print("Time: "..tostring(love.timer.getTime()), 10, 30)

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setLineWidth(1)
    for i=1,10,1 do
        love.graphics.line(0, i * SCALE_PIXEL_PER_METER * GRID_SCALE_METER, love.graphics.getWidth(), i * SCALE_PIXEL_PER_METER * GRID_SCALE_METER)
        love.graphics.line(i * SCALE_PIXEL_PER_METER * GRID_SCALE_METER, 0, i * SCALE_PIXEL_PER_METER * GRID_SCALE_METER, love.graphics.getHeight())
    end

    if dragStart and dragEnd then
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(dragStart[1], dragStart[2], dragEnd[1], dragEnd[2])
    end

    if dragStart and dragEnd then
        local directionX, directionY = normalize(dragEnd[1] - dragStart[1], dragEnd[2] - dragStart[2])
        drawTrajectoryHeun(dragStart[1], dragStart[2], directionX * BULLET_MUZZLE_VELOCITY, directionY * BULLET_MUZZLE_VELOCITY, TIMESTEP)
    end

    if bullet ~= nil then
        love.graphics.setColor(1, 0, 0)
        love.graphics.setPointSize(8)
        love.graphics.points(bullet.position[1], bullet.position[2])
    end

end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
    local lag = 0

	-- Main loop time.
    return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
 
        -- Cap number of Frames that can be skipped so lag doesn't accumulate
        if love.timer then lag = math.min(lag + love.timer.step(), TICK_RATE * MAX_FRAME_SKIP) end

        while lag >= TICK_RATE do
            if love.update then love.update(TICK_RATE) end
            lag = lag - TICK_RATE
        end
 
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
 
			if love.draw then love.draw() end
 
			love.graphics.present()
		end
 
		if love.timer then love.timer.sleep(0.001) end
	end
end

function drawTrajectoryEuler(startX, startY, velocityX, velocityY, timeStep)
    local points = {}
    local trace = {
        position = { startX, startY },
        velocity = { velocityX, velocityY }
    }
    for i=0,10000,1 do
        table.insert(points, trace.position[1])
        table.insert(points, trace.position[2])
        trace = getNextBulletPositionAndVelocityEuler(trace.position[1], trace.position[2], trace.velocity[1], trace.velocity[2], timeStep)
    end

    love.graphics.setColor(0, 1, 0)
    love.graphics.setLineWidth(1)
    love.graphics.line(points)
end

function drawTrajectoryBackEuler(startX, startY, velocityX, velocityY, timeStep)
    local points = {}
    local trace = {
        position = { startX, startY },
        velocity = { velocityX, velocityY }
    }
    for i=0,10000,1 do
        table.insert(points, trace.position[1])
        table.insert(points, trace.position[2])
        trace = getNextBulletPositionAndVelocityBackEuler(trace.position[1], trace.position[2], trace.velocity[1], trace.velocity[2], timeStep)
    end

    love.graphics.setColor(0, 0, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(points)
end

function drawTrajectoryHeun(startX, startY, velocityX, velocityY, timeStep)
    local points = {}
    local trace = {
        position = { startX, startY },
        velocity = { velocityX, velocityY }
    }
    for i=0,10000,1 do
        table.insert(points, trace.position[1])
        table.insert(points, trace.position[2])
        trace = getNextBulletPositionAndVelocityHeun(trace.position[1], trace.position[2], trace.velocity[1], trace.velocity[2], timeStep)
    end

    love.graphics.setColor(1, 0, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(points)
end

function handleMouseDrag()
    if love.mouse.isDown(1) and (dragStart == nil or mouseReleased) then
        mouseReleased = false
        local x, y = love.mouse.getPosition()
        dragStart = { x, y }
    end

    if love.mouse.isDown(1) and not mouseReleased then
        local x, y = love.mouse.getPosition()
        dragEnd = { x, y }
    end

    if not love.mouse.isDown(1) and not mouseReleased then
        mouseReleased = true
    end
end

function getNextBulletPositionAndVelocityEuler(currentPositionX, currentPositionY, currentVelocityX, currentVelocityY, time)
    local newPositionX = currentPositionX + currentVelocityX * time
    local newPositionY = currentPositionY + currentVelocityY * time

    local newVelocityX = currentVelocityX
    local newVelocityY = currentVelocityY + GRAVITY_METER_PER_SEC * time

    return {
        position = { newPositionX, newPositionY },
        velocity = { newVelocityX, newVelocityY }
    }
end

function getNextBulletPositionAndVelocityBackEuler(currentPositionX, currentPositionY, currentVelocityX, currentVelocityY, time)
    local newVelocityX = currentVelocityX
    local newVelocityY = currentVelocityY + GRAVITY_METER_PER_SEC

    local newPositionX = currentPositionX + newVelocityX * time
    local newPositionY = currentPositionY + newVelocityY * time

    return {
        position = { newPositionX, newPositionY },
        velocity = { newVelocityX, newVelocityY }
    }
end

function getNextBulletPositionAndVelocityHeun(currentPositionX, currentPositionY, currentVelocityX, currentVelocityY, time)
    local accelerationFactorEulerX, accelerationFactorEulerY = 0, GRAVITY_METER_PER_SEC
    local accelerationFactorHeunX, accelerationFactorHeunY = 0, GRAVITY_METER_PER_SEC

    local dragX, dragY = calculateDrag(currentVelocityX, currentVelocityY)
    accelerationFactorEulerX = accelerationFactorEulerX + dragX
    accelerationFactorEulerY = accelerationFactorEulerY + dragY

    local eulsVelocityX = currentVelocityX + accelerationFactorEulerX * time
    local eulsVelocityY = currentVelocityY + accelerationFactorEulerY * time
    
    local newPositionX = currentPositionX + (currentVelocityX + eulsVelocityX) * time * 0.5
    local newPositionY = currentPositionY + (currentVelocityY + eulsVelocityY) * time * 0.5

    local dragX, dragY = calculateDrag(eulsVelocityX, eulsVelocityY)
    accelerationFactorHeunX = accelerationFactorHeunX + dragX
    accelerationFactorHeunY = accelerationFactorHeunY + dragY

    local newVelocityX = currentVelocityX + (accelerationFactorEulerX + accelerationFactorHeunX) * time * 0.5
    local newVelocityY = currentVelocityY + (accelerationFactorEulerY + accelerationFactorHeunY) * time * 0.5


    return {
        position = { newPositionX, newPositionY },
        velocity = { newVelocityX, newVelocityY }
    }
end

function calculateDrag(velocityX, velocityY)
    local dragCoef = 0.0055
    local normalizedX, normalizedY = normalize(velocityX, velocityY)
    local squareMagnitude = velocityX * velocityX + velocityY * velocityY
    local drag = squareMagnitude * dragCoef

    return drag * -normalizedX, drag * -normalizedY
end
