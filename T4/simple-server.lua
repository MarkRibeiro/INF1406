-- load mqtt module
local mqtt = require("mqtt")
local json = require("json")
local llthreads = require("llthreads2")
local data = {}

local function handle_request (client,msg)
	local payload = json.decode(msg.payload)
	local tipomsg = payload.tipomsg
	local chave = payload.chave
	local topicoresp = payload.topicoresp
	local idpedido = payload.idpedido
	local novovalor = payload.novovalor
	local response

	if tipomsg == "insert" then
		data.chave = novovalor
		response = json.encode({
			status = "OK",
			id = idpedido
		})
	else --consulta
		response = json.encode({
			value = data.chave,
			status = "OK",
			id = idpedido
		})
	end

	-- publish test message
	assert(client:publish{
		topic = topicoresp,
		payload = response
	})
end

-- create mqtt client
local client = mqtt.client{
	-- NOTE: this broker is not working sometimes; comment username = "..." below if you still want to use it
	-- uri = "test.mosquitto.org",
	uri = "mqtt.flespi.io",
	-- NOTE: more about flespi tokens: https://flespi.com/kb/tokens-access-keys-to-flespi-platform
	username = "IiVHCfKm0DFQRZuyGhf8zolxbmi1nhYTnHpOKZYAtue8hzuLGAH3OSoO3uDeBrYN",
	clean = true,
	id = "servidor"
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
		assert(client:subscribe{ topic="inf1406-monitor", callback=function(suback)
			print("subscribed:", suback)
		end})

		assert(client:publish{
			topic = "inf1406-monitor",
			payload = json.encode({
				id = "servidor",
				timestamp = os.time(),
			})
		})
	end,

	message = function(msg)

		assert(client:acknowledge(msg))

		print("received:", msg.payload)
		if msg.topic == "inf1406-reqs" then
			handle_request(client,msg)

		elseif msg.topic == "inf1406-monitor" then

			if json.decode(msg.payload).id == "monitor" then
				assert(client:publish{
					topic = "inf1406-monitor",
					payload = json.encode({
						id = "servidor",
						timestamp = os.time(),
					})
				})
			end
		end
	end,

	error = function(err)
		print("MQTT client error:", err)
	end,
}

print("running ioloop for it")
mqtt.run_ioloop(client)

print("done, ioloop is stopped")