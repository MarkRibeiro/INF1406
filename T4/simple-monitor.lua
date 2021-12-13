-- load mqtt module
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

-- create mqtt client
local client = mqtt.client{
	-- NOTE: this broker is not working sometimes; comment username = "..." below if you still want to use it
	-- uri = "test.mosquitto.org",
	uri = "mqtt.flespi.io",
	-- NOTE: more about flespi tokens: https://flespi.com/kb/tokens-access-keys-to-flespi-platform
	username = "Q9CcYotuwqKbYWOK19CafvAdYiD7UjHAi7B4jUoGbZFXLkyAhYynhZo57P3PYyd4",
    clean = true,
	id = "monitor"
}
print("created MQTT client", client)

client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("connection to broker failed:", connack:reason_string(), connack)
			return
		end
		print("connected:", connack) -- successful connection

		-- subscribe to test topic and publish message after it
		assert(client:subscribe{ topic="inf1406-monitor", callback=function(suback)
			print("subscribed:", suback)

			print("Enviei a mensagem\n")
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
		print("MQTT client error:", err)
	end,
}

print("running ioloop for it")
mqtt.run_ioloop(client)

print("done, ioloop is stopped")