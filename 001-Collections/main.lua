---------------------------------------------------------------------------------------
-- Project: CoronaBlitz 1 -- Collections
-- Name of Game: Tyraziel's Pastries
-- Date: August 22nd 2013
-- Version: 1.0
--
-- Code type: CoronaBlitz
-- Author: Tyraziel (Andrew Potozniak)
--
-- Copyright (c) 2013 Andrew Potozniak
--
-- Released with the following license -
-- CC BY-NC-SA 3.0
-- http://creativecommons.org/licenses/by-nc-sa/3.0/
-- http://creativecommons.org/licenses/by-nc-sa/3.0/legalcode
---------------------------------------------------------------------------------------

--Setup some defaults
display.setStatusBar( display.HiddenStatusBar )
--system.activate( "multitouch" )

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

local gameState = {gameOver = false, paused = true, win = false, endGame = false, begin = true, cookiesMoving = false, removingCookies = false}
local gameTimer = {lastTime = 0}
local cookieGrid = {}
local numberToColor = {{r=255,g=0,b=0},{r=0,g=0,b=255},{r=0,g=255,b=0},{r=126,g=0,b=255},{r=255,g=255,b=0},{r=126,g=126,b=126}}
local swipeTouch = {started = false, startX = 0, startY = 0, endingX = 0, endingY = 0, ended = true, activateCookieMove = false, threshold = 40, cookieX = 0, cookieY = 0, move=""}
local startText
local startGridX = 150
local startGridY = 65
local cookieSize = 45
local cookieSpacing = 5
local cookieVel = 700
local cookieRemoveTTL = 250
local cookieRemoveTTLStatic = 250
local updateCookieLocation
local checkForLine

local printCookieGrid = function()
  print("THE GRID:")
  for i=1,5 do
  	  print (cookieGrid[i][1].number.."-"..cookieGrid[i][2].number.."-"..cookieGrid[i][3].number.."-"..cookieGrid[i][4].number.."-"..cookieGrid[i][5].number)
  end
  print("")
end

local initCookie = function()
  	local cookie = {}
  	cookie.number = math.random(6)
  	cookie.image = display.newRect(0, 0, cookieSize, cookieSize)
  	cookie.image:setFillColor(numberToColor[cookie.number].r, numberToColor[cookie.number].g, numberToColor[cookie.number].b)
  	cookie.image.strokeWidth = cookieSpacing
  	cookie.image:setStrokeColor(0, 0, 0)
  	cookie.velX = 0
  	cookie.velY = 0
  	cookie.removeMe = false
  	return cookie
end

local createCookieGrid = function()
  for i=1,5 do
  	cookieGrid[i] = {}
  	for j=1,5 do
  	  cookieGrid[i][j] = initCookie()
  	  --cookieGrid[i][j].number = math.random(6)
  	  --cookieGrid[i][j].image = display.newRect(0, 0, cookieSize, cookieSize)
  	  --cookieGrid[i][j].image:setFillColor(numberToColor[cookieGrid[i][j].number].r, numberToColor[cookieGrid[i][j].number].g, numberToColor[cookieGrid[i][j].number].b)
  	  --cookieGrid[i][j].image.strokeWidth = cookieSpacing
  	  --cookieGrid[i][j].image:setStrokeColor(0, 0, 0)
  	  --cookieGrid[i][j].velX = 0
  	  --cookieGrid[i][j].velY = 0
  	  --cookieGrid[i][j].removeMe = false
  	end
  end
  printCookieGrid()
  updateCookieLocation()
end

updateCookieLocation = function()
  for i=1,5 do
  	for j=1,5 do
  	  cookieGrid[i][j].image.x = startGridX + cookieSize * (j-1)
  	  cookieGrid[i][j].image.y = startGridY + cookieSize * (i-1)
  	end
  end
  printCookieGrid()
end

checkForLine = function()
  --Check Rows
  for i=1,5 do
    if(cookieGrid[i][1].number == cookieGrid[i][2].number and 
       cookieGrid[i][1].number == cookieGrid[i][3].number and 
       cookieGrid[i][1].number == cookieGrid[i][4].number and 
       cookieGrid[i][1].number == cookieGrid[i][5].number) then
       print("VALID ROW: " ..i)
       gameState.removingCookies = true
  	   cookieGrid[i][1].velX = cookieVel
  	   cookieGrid[i][1].removeMe = true
  	   cookieGrid[i][2].velX = cookieVel
  	   cookieGrid[i][2].removeMe = true
  	   cookieGrid[i][3].velX = cookieVel
  	   cookieGrid[i][3].removeMe = true
  	   cookieGrid[i][4].velX = cookieVel
  	   cookieGrid[i][4].removeMe = true
  	   cookieGrid[i][5].velX = cookieVel
  	   cookieGrid[i][5].removeMe = true
    end
  end

  --Check Columns
  for j=1,5 do
    if(cookieGrid[1][j].number == cookieGrid[2][j].number and 
       cookieGrid[1][j].number == cookieGrid[3][j].number and 
       cookieGrid[1][j].number == cookieGrid[4][j].number and 
       cookieGrid[1][j].number == cookieGrid[5][j].number) then
       print("VALID COLUMN: " ..j)
       gameState.removingCookies = true
  	   cookieGrid[1][j].velY = cookieVel
  	   cookieGrid[1][j].removeMe = true
  	   cookieGrid[2][j].velY = cookieVel
  	   cookieGrid[2][j].removeMe = true
  	   cookieGrid[3][j].velY = cookieVel
  	   cookieGrid[3][j].removeMe = true
  	   cookieGrid[4][j].velY = cookieVel
  	   cookieGrid[4][j].removeMe = true
  	   cookieGrid[5][j].velY = cookieVel
  	   cookieGrid[5][j].removeMe = true
    end
  end
end

local gameLoop = function(event)
  local timeSinceLastCall = event.time - gameTimer.lastTime
  local secondsElapsed = timeSinceLastCall / 1000
  local millisElapsed = timeSinceLastCall
  
  gameTimer.lastTime = event.time
  
  if(not gameState.endGame) then
    if(not gameState.gameOver) then
      if(not gameState.paused) then
        if(swipeTouch.activateCookieMove and not gameState.cookiesMoving and not gameState.removingCookies) then
          gameState.cookiesMoving = true

          if(swipeTouch.cookieX < 1) then swipeTouch.cookieX = 1 end
          if(swipeTouch.cookieX > 5) then swipeTouch.cookieX = 5 end
          if(swipeTouch.cookieY < 1) then swipeTouch.cookieY = 1 end
          if(swipeTouch.cookieY > 5) then swipeTouch.cookieY = 5 end

          if(swipeTouch.move == "ROW") then
          	if(swipeTouch.direction < 0) then
              local tempCookie = cookieGrid[swipeTouch.cookieY][5]
          	  cookieGrid[swipeTouch.cookieY][5] = cookieGrid[swipeTouch.cookieY][4]
          	  cookieGrid[swipeTouch.cookieY][4] = cookieGrid[swipeTouch.cookieY][3]
          	  cookieGrid[swipeTouch.cookieY][3] = cookieGrid[swipeTouch.cookieY][2]
          	  cookieGrid[swipeTouch.cookieY][2] = cookieGrid[swipeTouch.cookieY][1]
          	  cookieGrid[swipeTouch.cookieY][1] = tempCookie
          	else
              local tempCookie = cookieGrid[swipeTouch.cookieY][1]
          	  cookieGrid[swipeTouch.cookieY][1] = cookieGrid[swipeTouch.cookieY][2]
          	  cookieGrid[swipeTouch.cookieY][2] = cookieGrid[swipeTouch.cookieY][3]
          	  cookieGrid[swipeTouch.cookieY][3] = cookieGrid[swipeTouch.cookieY][4]
          	  cookieGrid[swipeTouch.cookieY][4] = cookieGrid[swipeTouch.cookieY][5]
          	  cookieGrid[swipeTouch.cookieY][5] = tempCookie              
          	end

          elseif(swipeTouch.move == "COLUMN") then
          	if(swipeTouch.direction < 0) then
          	  local tempCookie = cookieGrid[5][swipeTouch.cookieX]
          	  cookieGrid[5][swipeTouch.cookieX] = cookieGrid[4][swipeTouch.cookieX]
          	  cookieGrid[4][swipeTouch.cookieX] = cookieGrid[3][swipeTouch.cookieX]
          	  cookieGrid[3][swipeTouch.cookieX] = cookieGrid[2][swipeTouch.cookieX]
          	  cookieGrid[2][swipeTouch.cookieX] = cookieGrid[1][swipeTouch.cookieX]
          	  cookieGrid[1][swipeTouch.cookieX] = tempCookie
          	else
              local tempCookie = cookieGrid[1][swipeTouch.cookieX]
          	  cookieGrid[1][swipeTouch.cookieX] = cookieGrid[2][swipeTouch.cookieX]
          	  cookieGrid[2][swipeTouch.cookieX] = cookieGrid[3][swipeTouch.cookieX]
          	  cookieGrid[3][swipeTouch.cookieX] = cookieGrid[4][swipeTouch.cookieX]
          	  cookieGrid[4][swipeTouch.cookieX] = cookieGrid[5][swipeTouch.cookieX]
          	  cookieGrid[5][swipeTouch.cookieX] = tempCookie
          	end
          end
		  updateCookieLocation()
		  checkForLine()
		  swipeTouch.activateCookieMove = false
          gameState.cookiesMoving = false
          printCookieGrid()
        end
        if(gameState.removingCookies) then
          --slide cookies out
          for i=1,5 do
  	        for j=1,5 do
  	          cookieGrid[i][j].image.x = cookieGrid[i][j].image.x + cookieGrid[i][j].velX * secondsElapsed
  	          cookieGrid[i][j].image.y = cookieGrid[i][j].image.y + cookieGrid[i][j].velY * secondsElapsed
  	        end
  	      end
  	      cookieRemoveTTL = cookieRemoveTTL - millisElapsed
  	      if(cookieRemoveTTL < 0) then
  	      	gameState.removingCookies = false
  	      	cookieRemoveTTL = cookieRemoveTTLStatic

            for i=1,5 do
  	          for j=1,5 do
  	          	if(cookieGrid[i][j].removeMe) then
  	          	  display.remove(cookieGrid[i][j].image)
  	          	  cookieGrid[i][j] = initCookie()
  	          	end
  	          end
  	        end
  	        checkForLine()
  	      	updateCookieLocation()

  	      end

        end
      end
    else -- GAMEOVER

      if(gameState.win) then
        local winText = display.newText("YOU WIN!", 100, 115, native.systemFont, 64)
        winText:setTextColor(0,255,64)
      else
      end
      gameState.endGame = true

      local gameOverText = display.newText("GAME OVER!", 50, 115, native.systemFont, 64)
	  gameOverText:setTextColor(255,255,0)
	  gameOverText.isVisible = false
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
      display.remove(startText)
      startText = nil
      gameState.begin = false
      createCookieGrid()
    else
      if(not swipeTouch.activateCookieMove and not swipeTouch.started and not gameState.cookiesMoving and not gameState.removingCookies) then
        swipeTouch.started = true
        swipeTouch.startX = event.x
        swipeTouch.startY = event.y
        swipeTouch.endingX = event.x
  	    swipeTouch.endingY = event.y
  	  end
    end
  elseif(phase == "moved") then
  	if(swipeTouch.started and not swipeTouch.activateCookieMove and not gameState.cookiesMoving and not gameState.removingCookies) then
  	  swipeTouch.endingX = event.x
  	  swipeTouch.endingY = event.y
  	  if((math.abs(swipeTouch.startX - swipeTouch.endingX)) > swipeTouch.threshold) then
  	    swipeTouch.cookieX = math.ceil((swipeTouch.startX - startGridX - (cookieSize+cookieSpacing)/ 2) / (cookieSize + cookieSpacing)) + 1
  	    swipeTouch.cookieY = math.ceil((swipeTouch.startY - startGridY - (cookieSize+cookieSpacing)/ 2) / (cookieSize + cookieSpacing)) + 1
  	    swipeTouch.move = "ROW"
  	    swipeTouch.direction = swipeTouch.startX - swipeTouch.endingX
  	    print("ROW MOVE")
  	    print(swipeTouch.cookieX, swipeTouch.cookieY)
  	    swipeTouch.activateCookieMove = true
  	    swipeTouch.started = false
  	    swipeTouch.startX = 0
        swipeTouch.startY = 0
        swipeTouch.endingX = 0
  	    swipeTouch.endingY = 0
  	  elseif((math.abs(swipeTouch.startY - swipeTouch.endingY)) > swipeTouch.threshold) then
  	    swipeTouch.cookieX = math.ceil((swipeTouch.startX - startGridX - (cookieSize+cookieSpacing)/ 2) / (cookieSize + cookieSpacing)) + 1
  	    swipeTouch.cookieY = math.ceil((swipeTouch.startY - startGridY - (cookieSize+cookieSpacing)/ 2) / (cookieSize + cookieSpacing)) + 1
  	    swipeTouch.move = "COLUMN"
  	    swipeTouch.direction = swipeTouch.startY - swipeTouch.endingY
  	    print("COLUMN MOVE")
  	    print(swipeTouch.cookieX, swipeTouch.cookieY)
  	    swipeTouch.activateCookieMove = true
  	    swipeTouch.started = false
  	    swipeTouch.startX = 0
        swipeTouch.startY = 0
        swipeTouch.endingX = 0
  	    swipeTouch.endingY = 0
  	  end
  	end
  	if(not swipeTouch.started and not swipeTouch.activateCookieMove and not gameState.cookiesMoving and not gameState.removingCookies) then
	  swipeTouch.started = true
      swipeTouch.startX = event.x
      swipeTouch.startY = event.y
      swipeTouch.endingX = event.x
  	  swipeTouch.endingY = event.y
  	end
  
  elseif(phase == "ended") then
    swipeTouch.started = false
    swipeTouch.activateCookieMove = false
  end
  
  return true
end

startText = display.newText("Touch anywhere to Start!", 25, 135, native.systemFont, 36)
startText:setTextColor(255,255,255)

Runtime:addEventListener("touch", globalTouch)

Runtime:addEventListener( "enterFrame", gameLoop )