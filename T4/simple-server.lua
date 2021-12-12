-- load mqtt module
local mqtt = require("mqtt")

-- create mqtt client
local client = mqtt.client{
	-- NOTE: this broker is not working sometimes; comment username = "..." below if you still want to use it
	-- uri = "test.mosquitto.org",
	uri = "mqtt.flespi.io",
	-- NOTE: more about flespi tokens: https://flespi.com/kb/tokens-access-keys-to-flespi-platform
	username = "IiVHCfKm0DFQRZuyGhf8zolxbmi1nhYTnHpOKZYAtue8hzuLGAH3OSoO3uDeBrYN",
	clean = true,
	id = "mark1",
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
		assert(client:subscribe{ topic="inf1406-reqs", callback=function(suback)
			print("subscribed:", suback)
		end})
	end,

	message = function(msg)
		print("Recebi algo\n")
		assert(client:acknowledge(msg))

		print("received:", msg)
	end,

	error = function(err)
		print("MQTT client error:", err)
	end,
}

print("running ioloop for it")
mqtt.run_ioloop(client)

print("done, ioloop is stopped")