local mqtt = require("mqtt_library")
local TAM = 600
local mudaestado
font1 = love.graphics.newFont(80)
font2 = love.graphics.newFont(50)

MAT_SIZE = 7
matText = love.graphics.newText(font2, "Entre sua matricula")
endText1 = love.graphics.newText(font2, "Voto computado")
voteText1 = love.graphics.newText(font2, "Qual o maior time")
voteText2 = love.graphics.newText(font2, "carioca?")
background = love.graphics.newImage("/Art/Background1.png")
botafogo = love.graphics.newImage( "/Art/Botafogo1.png" )
fluminense = love.graphics.newImage( "/Art/Fluminense1.png")
vasco = love.graphics.newImage( "/Art/Vasco1.png")
flamengo = love.graphics.newImage( "/Art/Flamengo1.png")
botoesImg = love.graphics.newImage( "/Art/botoes.png")
setaNormal = love.graphics.newImage( "/Art/setas1.png")
setaBaixo = love.graphics.newImage( "/Art/setas2.png")
setaCima = love.graphics.newImage( "/Art/setas3.png")

state = "Login"
  
local function mqttcb (topico, msg)
  mudaestado(msg)
end

function love.load ()
  love.window.setMode(TAM,TAM)
  mat = {}
  for i = 0, MAT_SIZE-1, 1 do
    mat[i] = 0
  end
  currentPosInMat = 0
  mqtt_client = mqtt.client.create("broker.hivemq.com", 1883, mqttcb)
  mqtt_client:connect("felipeMark")
  mqtt_client:subscribe({"nodelove1612043"})
  arrow = newArrow()
end

function mudaestado (i)
  i = tonumber(i)
  print(i)
  if state == "Login" then
    if i == 1 then
      arrow.left()
      if( currentPosInMat > 0 ) then
        currentPosInMat = currentPosInMat - 1
      end
      
    elseif i == 2 then
      currentPosInMat = currentPosInMat + 1
      arrow.right()
      if( currentPosInMat == MAT_SIZE ) then
        state = "Vote"
      end  

    elseif i == 3 then
      mat[currentPosInMat] = mat[currentPosInMat] - 1
      arrow.down()
      if( mat[currentPosInMat] < 0 ) then
        mat[currentPosInMat] = 9
      end
      
    elseif i == 4 then 
      mat[currentPosInMat] = mat[currentPosInMat] + 1
      arrow.up()
      if(mat[currentPosInMat] > 9) then
        mat[currentPosInMat] = 0
      end
      
    end
  elseif state == "Vote" then
    if (os.getenv"os" or ""):match"^Windows" then
      python = "Python"
    else
      python = "python3"
    end
    if i == 1 then 
      command = python .. " request_sender.py Botafogo " .. matToString()
      io.popen(command)
      vote = "Botafogo!"
      state = "End"
    elseif i == 2 then
      command = python .. " request_sender.py Fluminense " .. matToString()
      io.popen(command)
      vote = "Fluminense!"
      state = "End"
    elseif i == 3 then
      command = python .. " request_sender.py Vasco " .. matToString()
      io.popen(command)
      vote = "Vasco!"
      state = "End"
    elseif i == 4 then
      command = python .. " request_sender.py Flamengo " .. matToString()
      io.popen(command)
      vote = "Flamengo!"
      state = "End"
    end
    mat = {}
    for i = 0, MAT_SIZE-1, 1 do
      mat[i] = 0
    end
    currentPosInMat = 0
    arrow = newArrow()
  else
    if(state == "End") then
      state = "Login"
    end
  end
end

function love.update(dt)
  d1 = love.graphics.newText(font1, mat[0])
  d2 = love.graphics.newText(font1, mat[1])
  d3 = love.graphics.newText(font1, mat[2])
  d4 = love.graphics.newText(font1, mat[3])
  d5 = love.graphics.newText(font1, mat[4])
  d6 = love.graphics.newText(font1, mat[5])
  d7 = love.graphics.newText(font1, mat[6])
  arrow.updateImage(dt)
  mqtt_client:handler()
end

function love.draw ()
  love.graphics.draw(background, 0, 0)
  
  if state == "Login" then
    love.graphics.draw(matText, 300-matText:getWidth()/2, 100)
    love.graphics.rectangle("line", (550/8)*1, 300, 50, 75)
    love.graphics.draw(d1, (550/8)*1, 292)
    love.graphics.rectangle("line", (550/8)*2, 300, 50, 75)
    love.graphics.draw(d2, (550/8)*2, 292)
    love.graphics.rectangle("line", (550/8)*3, 300, 50, 75)
    love.graphics.draw(d3, (550/8)*3, 292)
    love.graphics.rectangle("line", (550/8)*4, 300, 50, 75)
    love.graphics.draw(d4, (550/8)*4, 292)
    love.graphics.rectangle("line", (550/8)*5, 300, 50, 75)
    love.graphics.draw(d5, (550/8)*5, 292)
    love.graphics.rectangle("line", (550/8)*6, 300, 50, 75)
    love.graphics.draw(d6, (550/8)*6, 292)
    love.graphics.rectangle("line", (550/8)*7, 300, 50, 75)
    love.graphics.draw(d7, (550/8)*7, 292)
    love.graphics.draw(botoesImg, 200, 400, 0, 1, 1)
    arrow.draw()
  end
  
  if state == "Vote" then
    love.graphics.draw(voteText1, 300-voteText1:getWidth()/2, 75)
    love.graphics.draw(voteText2, 300-voteText2:getWidth()/2, 125)
    love.graphics.draw(botafogo, 20, 250, 0, 1.5, 1.5)
    love.graphics.draw(fluminense, 430, 250, 0, 1.5, 1.5)
    love.graphics.draw(vasco, 100, 450, 0, 1.5, 1.5)
    --love.graphics.draw(flamengo, 530, 560, 3.2, 1.5, 1.5)
    love.graphics.draw(flamengo, 350, 450, 0, 1.5, 1.5)
  end
  
  if state == "End" then
    endText2 = love.graphics.newText(font2, "no ".. vote)
    love.graphics.draw(endText1, 300-endText1:getWidth()/2, 225)
    love.graphics.draw(endText2, 300-endText2:getWidth()/2, 275)
  end
end

function love.quit()
  os.exit()
end

--[[
function love.keypressed(key)
  if state == "Login" then
    if key == "up" then 
      arrow.up()
      if( mat[currentPosInMat] < 9 ) then
        mat[currentPosInMat] = mat[currentPosInMat] + 1
      end
    elseif key == "down" then
      arrow.down()
      if( mat[currentPosInMat] > 0 ) then
        mat[currentPosInMat] = mat[currentPosInMat] - 1
      end
    elseif key == "left" then
      arrow.left()
      if( currentPosInMat > 0 ) then
        currentPosInMat = currentPosInMat - 1
      end
    elseif key == "right" then
      currentPosInMat = currentPosInMat + 1
      arrow.right()
      if( currentPosInMat == MAT_SIZE ) then
        state = "Vote"
      end
    end
  end
  if state == "Vote" then
    local arch
    if (os.getenv"os" or ""):match"^Windows" then
      python = "Python"
    else
      python = "Python3"
    end
    if key == "b" then 
      command = python .. " request_sender.py Botafogo " .. matToString()
      io.popen(command)
      state = "End"
    elseif key == "v" then
      command = python .. " request_sender.py Vasco " .. matToString()
      io.popen(command)
      state = "End"
    elseif key == "f" then
      command = python .. " request_sender.py Fluminense " .. matToString()
      io.popen(command)
      state = "End"
    elseif key == "m" then
      command = python .. " request_sender.py Flamengo " .. matToString()
      io.popen(command)
      state = "End"
    end
  end
end
--]]

function newArrow()
  local xPos = 550/8
  local yPos = 215
  digitSize = 550/8
  local currentImage = setaNormal
  local aceso = false
  
  function resetImage()
    while true do
      local tempoAceso = 0.5
      while tempoAceso > 0 do
        dt = coroutine.yield()
        tempoAceso = tempoAceso - dt
      end
      tempoAceso = 0.5
      currentImage = setaNormal
      aceso = false
    end
  end
  
  local restartCoroutine = coroutine.create(resetImage)
  
  --[[
  function blinkAfterClick(arrow)
    if( arrow == "up" ) then
      currentImage = setaCima
    else
      currentImage = setaBaixo
    end
    aceso = true
  end
  --]]
  
  function blinkAfterClickNode(arrow)
    if( arrow == "4" ) then
      currentImage = setaCima
    else
      currentImage = setaBaixo
    end
    aceso = true
  end
  
  return {
    draw = function ()
      love.graphics.draw(currentImage, xPos, yPos, 0, 50/41)
    end
    ,
    left = function ()
      if( not ( xPos == digitSize)  ) then -- se não for o primeiro digito, pode andar à esquerda
        xPos = xPos - digitSize
      end
    end
    ,
    right = function ()
      if( not ( xPos == (digitSize)*7 ) ) then -- se não for o último digito, pode andar à direita
        xPos = xPos + digitSize
      end
    end
    ,
    up = function ()
      --blinkAfterClick("up")
      blinkAfterClickNode("4")
    end
    ,
    down = function ()
      --blinkAfterClick("down")
      blinkAfterClickNode("3")
    end
    ,
    updateImage = function(dt)
      if( aceso ) then
        coroutine.resume(restartCoroutine, dt) 
      end
    end
  }
end

function matToString()
  local matAsString = tostring(mat[0])
  for digit = 1,MAT_SIZE-1,1 do
    matAsString = matAsString .. tostring(mat[digit])
  end
  return matAsString
end