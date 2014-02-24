---------------------------------------------------------------------------------------
-- Project: CoronaBlitz 2 -- Energy
-- Name of Game: Buzz
-- Date: February 22nd 2013
-- Version: 1.0
--
-- Code type: CoronaBlitz
-- Author: Tyraziel (Andrew Potozniak)
--
-- Copyright (c) 2014 Andrew Potozniak
--
-- Released with the following license -
-- CC BY-NC-SA 3.0
-- http://creativecommons.org/licenses/by-nc-sa/3.0/
-- http://creativecommons.org/licenses/by-nc-sa/3.0/legalcode
---------------------------------------------------------------------------------------

--Setup some defaults
display.setStatusBar( display.HiddenStatusBar )
--system.activate( "multitouch" )

local physics = require( "physics" )

--physics.setDrawMode( "hybrid" )  --overlays collision outlines on normal display objects
--physics.setDrawMode( "normal" )  --the default Corona renderer, with no collision outlines
--physics.setDrawMode( "debug" )   --shows collision engine outlines only

--Setup the onExit Listener
local onSystem = function( event )
  if event.type == "applicationExit" then
    if system.getInfo( "environment" ) == "device" then
      -- prevents iOS 4+ multi-tasking crashes
      os.exit()
    end
  end
end
Runtime:addEventListener( "system", onSystem )

--Main Group
local mainGroup = display.newGroup()
local hudGroup = display.newGroup()

local gameState = {gameOver = false, paused = true, win = false, endGame = false, begin = true, canRestart = false}
local gameTimer = {lastTime = 0, endTTL = 500}
local gateCreator = {minTTL = 750, maxTTL = 2500, currentTTL = 500, minSize = 64, maxSize = 128, poleSize = 32}
local energyCreator = {minTTL = 1000, maxTTL = 5000, currentTTL = 500, minEnergy = 10, maxEnergy = 50}
local score = { highScore = {points = 0, text = {}}, currentScore = {points = 0, text = {}}}
local gameInfo = {movedX = 0, movedY = 0}
local trickStack = {}
local gates = {}
local energy = {}
local player = {}
local infoText
local infoText2
local gameOverText
local energyBar
local hitBox = {image = {}, ttl = 250}

local createGate
local createEngery

local initGame = function()
  physics.start()
  physics.setGravity(0, 8) --3
  gameState = {gameOver = false, paused = false, win = false, endGame = false, begin = false, canRestart = false}
  gameTimer = {lastTime = 0, endTTL = 500}
  gateTimer = {minTTL = 250, maxTTL = 1000, currentTTL = 500}
  gameInfo = {movedX = 0, movedY = 0}
  trickStack = {}
  gates = {}
  energy = {}
  player = {}

  player.image = display.newRoundedRect(150, display.contentHeight / 2, 16, 16, 4)
  player.image:setFillColor(128, 128, 0)
  physics.addBody( player.image, "dynamic", { isSensor=true })
  player.image.what = "Player"
  player.image.player = player
  player.energy = 500
  player.speed = 100

  mainGroup:insert(player.image)

  hitBox.image = display.newRect( display.contentWidth/2, display.contentHeight/2, 480, 320 )
  hitBox.image:setFillColor(1, 0, 0)

  --score.highscore = infoText = display.newText("High Score: ", display.contentWidth/2, display.contentHeight / 2, native.systemFont, 24)
  score.currentScore.text = display.newText("Score: "..score.currentScore.points, 20, 10, native.systemFont, 16)
  score.highScore.text = display.newText("High Score: "..score.highScore.points, 420, 10, native.systemFont, 16)
  --score.currentScore.anchorX = 0.0;
  
  energyBar = display.newRoundedRect( display.contentWidth / 2, 310, player.energy, 10, 3 )

  gateCreator.currentTTL = math.random(gateCreator.minTTL, gateCreator.maxTTL)
  energyCreator.currentTTL = math.random(energyCreator.minTTL, energyCreator.maxTTL)
end

local destroyGame = function()
  --clean up gates
  --display.remove( object )
  physics.stop()

  infoText2:removeSelf()
  gameOverText:removeSelf()
  gameOverText.isVisible = false
  score.currentScore.text:removeSelf()
  score.highScore.text:removeSelf()
  energyBar:removeSelf()
  hitBox.image:removeSelf()

  if(#gates > 0) then
    for i=#gates, 1, -1 do
      if(gates[i] ~= nil) then
        gates[i]:cleanUp()
        table.remove(gates, i)
      end
    end        
  end

  if(#energy > 0) then
    for i=#energy, 1, -1 do
      if(energy[i] ~= nil) then
        energy[i]:cleanUp()
        table.remove(energy, i)
      end
    end        
  end

  gateCreator.currentTTL = math.random(gateCreator.minTTL, gateCreator.maxTTL)

  player.image:removeSelf()
  player.image = nil
  mainGroup.x = 0

  if (score.currentScore.points > score.highScore.points) then
    score.highScore.points = score.currentScore.points
  end

  score.currentScore.points = 0

end

local collideWithEnergy = function(self, event )
  if ( event.phase == "began" ) then
    print( self.what .. ": collision began with " .. event.other.what)
    self.obj.scheduledToRemove = true

    if(event.other.what == "Player") then
      event.other.player.energy = event.other.player.energy + self.obj.energy
    end

  elseif ( event.phase == "ended" ) then
    print( self.what .. ": collision ended with " .. event.other.what )

  end
end

local collideWithGate = function( self, event )
  if ( event.phase == "began" ) then
    print( self.what .. ": collision began with " .. event.other.what)

    if(event.other.what == "Player" and self.what == "Line") then
      self.gate.top:setFillColor(0, 0, 1)
      self.gate.bottom:setFillColor(1, 0, 0)
      self.gate.timesPassed = self.gate.timesPassed + 1
      score.currentScore.points = score.currentScore.points + 1 + ((self.gate.timesPassed - 1) * 10)
      event.other.player.speed = event.other.player.speed + 20
    elseif(event.other.what == "Player") then
      event.other.player.speed = event.other.player.speed / 2
      event.other.player.energy = event.other.player.energy - 100
      hitBox.ttl = 250
    end

  elseif ( event.phase == "ended" ) then
    print( self.what .. ": collision ended with " .. event.other.what )

  end
end

createGate = function(x, y, size)
  local newGate = {}

  newGate.top = display.newRoundedRect(0, 0, gateCreator.poleSize, gateCreator.poleSize, 4 )
  newGate.bottom = display.newRoundedRect(0, 0, gateCreator.poleSize, gateCreator.poleSize, 4 )
  newGate.line = display.newRect( 0, 0, 8, size - 32 )

  newGate.top:setFillColor(0, 0, .5)
  newGate.bottom:setFillColor(.5, 0, 0)
  newGate.line:setFillColor(.5, .5, 0, 0) ----SET THIS TO .5 for debugging

  newGate.top.x = x
  newGate.top.y = y - size/2
  newGate.bottom.x = x
  newGate.bottom.y = y + size/2
  newGate.line.x = x + 5
  newGate.line.y = y
  newGate.line.startX = x

  newGate.top.what = "Top Gate"
  newGate.bottom.what = "Bottom Gate"
  newGate.line.what = "Line"

  mainGroup:insert(newGate.top)
  mainGroup:insert(newGate.bottom)
  mainGroup:insert(newGate.line)

  physics.addBody( newGate.top, "static", { isSensor=true })
  physics.addBody( newGate.bottom, "static", { isSensor=true })
  physics.addBody( newGate.line, "static", { isSensor=true })

  newGate.top.collision = collideWithGate
  newGate.bottom.collision = collideWithGate
  newGate.line.collision = collideWithGate

  newGate.top:addEventListener( "collision", newGate.top )
  newGate.bottom:addEventListener( "collision", newGate.bottom )
  newGate.line:addEventListener( "collision", newGate.line )

  newGate.timesPassed = 0

  newGate.line.gate = newGate

  newGate.cleanUp = function(self)
    self.line:removeSelf()
    self.line = nil
    self.top:removeSelf()
    self.top = nil
    self.bottom:removeSelf()
    self.bottom = nil
  end

  return newGate

end

createEnergy = function(x, y, energy)
  local newEnergy = {}

  newEnergy.image = display.newCircle( 0, 0, 4 + ((energy / 10) * 2) )

  newEnergy.image:setFillColor(.5, .5, .5)
  
  newEnergy.image.x = x
  newEnergy.image.y = y
  newEnergy.image.startX = x

  newEnergy.image.what = "Energy"

  mainGroup:insert(newEnergy.image)

  physics.addBody( newEnergy.image, "static", { isSensor=true })

  newEnergy.image.collision = collideWithEnergy

  newEnergy.image:addEventListener( "collision", newEnergy.image )

  newEnergy.energy = energy

  newEnergy.cleanUp = function(self)
    self.image:removeSelf()
    self.image = nil
  end

  newEnergy.scheduledToRemove = false
  newEnergy.image.obj = newEnergy

  return newEnergy
end

local gameLoop = function(event)
  local timeSinceLastCall = event.time - gameTimer.lastTime
  local secondsElapsed = timeSinceLastCall / 1000
  local millisElapsed = timeSinceLastCall
  
  gameTimer.lastTime = event.time
  
  if(not gameState.endGame) then
    if(hitBox.ttl <= 0)then
      hitBox.image.alpha = 0
    else
      hitBox.ttl = hitBox.ttl - millisElapsed
      hitBox.image.alpha = hitBox.ttl / 250.0
    end

    if(not gameState.gameOver) then
      if(not gameState.paused) then
        --MAIN GAME LOOP
        mainGroup.x = mainGroup.x - secondsElapsed*player.speed
        gameInfo.movedX = gameInfo.movedX + secondsElapsed*player.speed
        player.image.x = player.image.x + secondsElapsed*player.speed

        score.currentScore.text.text = "Score: "..score.currentScore.points
        score.highScore.text.text = "High Score: "..score.highScore.points
        energyBar.xScale = player.energy / 500.0      

        gateCreator.currentTTL = gateCreator.currentTTL - millisElapsed

        if(gateCreator.currentTTL <= 0) then
          --gateCreator.currentTTL = gateCreator.currentTTL + math.random(gateCreator.minTTL, gateCreator.maxTTL)
          gateCreator.currentTTL = math.random(gateCreator.minTTL, gateCreator.maxTTL)
          table.insert(gates, createGate(gameInfo.movedX+600,math.random(100,220), math.random(gateCreator.minSize,gateCreator.maxSize)))
        end

        energyCreator.currentTTL = energyCreator.currentTTL - millisElapsed

        if(energyCreator.currentTTL <= 0) then
          energyCreator.currentTTL = math.random(energyCreator.minTTL, energyCreator.maxTTL)
          table.insert(energy, createEnergy(gameInfo.movedX+600,math.random(50,270), math.random(energyCreator.minEnergy,energyCreator.maxEnergy)))
        end

        if(#gates > 0) then
          for i=#gates, 1, -1 do
            if(gates[i] ~= nil) then
              if(gates[i].line.startX < gameInfo.movedX - 50) then
                if(gates[i].timesPassed == 0) then
                  gameState.paused = true
                  gameState.gameOver = true
                end
                gates[i]:cleanUp()
                table.remove(gates, i)
              end  
            end
          end
        end

        if(#energy > 0) then
          for i=#energy, 1, -1 do
            if(energy[i] ~= nil) then
              if(energy[i].image.startX < gameInfo.movedX - 50 or energy[i].scheduledToRemove) then
                energy[i]:cleanUp()
                table.remove(energy, i)
              end
            end
          end
        end

        if(player.image.y < 0 or player.image.y > 320 or player.energy <= 0) then
          gameState.paused = true
          gameState.gameOver = true
          if(player.energy <= 0) then
            energyBar.isVisible = false

          end
        end


      end
    else -- GAMEOVER
      physics.pause()
      
      if(gameTimer.endTTL == 500) then

        if(gameState.win) then
          infoText = display.newText("YOU WIN!", display.contentWidth/2, display.contentHeight / 2, native.systemFont, 64)
          infoText:setFillColor(0,255,64)
        else
          gameOverText = display.newText("GAME OVER!", display.contentWidth/2, display.contentHeight / 2, native.systemFont, 50)
          gameOverText:setFillColor(1,0,0)
        
        end
      end

      gameTimer.endTTL = gameTimer.endTTL - millisElapsed
      if(gameTimer.endTTL < 0 and not gameState.canRestart) then
        gameState.canRestart = true
        gameState.endGame = true
        infoText2 = display.newText("Touch anywhere to Re-Start!", display.contentWidth/2, display.contentHeight / 2 + 40, native.systemFont, 16)
        infoText2:setFillColor(1,1,1)
      end
    end
  end
end

--Global Touch Event
local globalTouch = function(event)
  local t = event.target
  local phase = event.phase

  if(phase == "began") then
    if(gameState.begin) then
      gameState.paused = false
      infoText:removeSelf()
      infoText = nil
      gameState.begin = false
      initGame()
    else
      if(not gameState.paused and not gameState.gameOver) then
        player.image:applyLinearImpulse( 0, -0.025, player.image.x, player.image.y )  --- -0.0125
        player.energy = player.energy - 15
      elseif(gameState.canRestart) then
        destroyGame()
        initGame()
      end
    end
  elseif(phase == "moved") then
  
  elseif(phase == "ended") then

  end
  
  return true
end

infoText = display.newText("Touch anywhere to Start!", display.contentWidth/2, display.contentHeight / 2, native.systemFont, 24)
infoText:setFillColor(255,255,255)

Runtime:addEventListener("touch", globalTouch)

Runtime:addEventListener( "enterFrame", gameLoop )