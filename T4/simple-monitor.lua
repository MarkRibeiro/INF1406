-- Alunos: Mark Ribeiro e Nagib Suaid
-- Matriculas: 1612043 e 1710839

local mqtt = require("mqtt")
local json = require("json")

local timestamps = {
	id = "monitor",
}

local function sleep(n)
	os.execute("sleep " .. tonumber(n))
end

local function send_heartbeat(client)
	assert(client:publish{
		topic = "inf1406-monitor",
		payload = json.encode(timestamps)
	})
end


local client = mqtt.client{
	uri = "mqtt.flespi.io",
	username = "Q9CcYotuwqKbYWOK19CafvAdYiD7UjHAi7B4jUoGbZFXLkyAhYynhZo57P3PYyd4",
    clean = true,
	id = "monitor"
}
client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("Falha na conexão com broker:", connack:reason_string(), connack)
			return
		end
		print("Conectado:", connack)

		assert(client:subscribe{ topic="inf1406-monitor", callback=function(suback)
			print("Assinou:", suback)
		end})

		send_heartbeat(client)
	end,

	message = function(msg)
		assert(client:acknowledge(msg))
		local rcv = json.decode(msg.payload)
		if rcv.id == "monitor" then
			sleep(3)
			send_heartbeat(client)
		else
			timestamps[rcv.id] = rcv.timestamp
		end

	end,

	error = function(err)
		print("Erro no cliente MQTT:", err)
	end,
}

print("Rodando ioloop")
mqtt.run_ioloop(client)

print("Terminado, ioloop parou")