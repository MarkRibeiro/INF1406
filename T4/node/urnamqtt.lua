local meuid = "1612043"
local m = mqtt.Client("noemi_melhor_prof" .. meuid, 120)
local led1 = 0
local led2 = 6
local sw1 = 3
local sw2 = 4
local sw3 = 5
local sw4 = 8
local mqttClient
local dbtmr
local tol = 500

gpio.mode(led1, gpio.OUTPUT)
gpio.mode(led2, gpio.OUTPUT)

gpio.write(led1, gpio.LOW);
gpio.write(led2, gpio.LOW);

gpio.mode(sw1, gpio.INT,gpio.PULLUP)
gpio.mode(sw2, gpio.INT,gpio.PULLUP)
gpio.mode(sw3, gpio.INT,gpio.PULLUP)
gpio.mode(sw4, gpio.INT,gpio.PULLUP)

function publica(c, i)
  c:publish("nodelove1612043",i,0,0)  
end

function novaInscricao (c)
  local msgsrec = 0
  function novamsg (c, t, m)
  end
  c:on("message", novamsg)
end

function conectado (client)
  client:subscribe("lovenode1612043", 0, novaInscricao)
  mqttClient = client
end 

function reestabelece ()
  gpio.trig(sw1, "down", function() buttonReleased("1") end)
  gpio.trig(sw2, "down", function() buttonReleased("2") end)
  gpio.trig(sw3, "down", function() buttonReleased("3") end)
  gpio.trig(sw4, "down", function() buttonReleased("4") end)
end

function buttonReleased (m)
  gpio.trig(sw1)
  gpio.trig(sw2)
  gpio.trig(sw3)
  gpio.trig(sw4)
  dbtmr:register(tol, tmr.ALARM_AUTO, reestabelece)
  dbtmr:start()
  publica(mqttClient, m)
end

m:connect("broker.hivemq.com", 1883, false, 
             conectado,
             function(client, reason) print("failed reason: "..reason) end)
           
dbtmr = tmr.create()
gpio.trig(sw1, "down", function() buttonReleased("1") end)
gpio.trig(sw2, "down", function() buttonReleased("2") end)
gpio.trig(sw3, "down", function() buttonReleased("3") end)
gpio.trig(sw4, "down", function() buttonReleased("4") end)


