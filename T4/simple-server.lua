-- load mqtt module
local mqtt = require("mqtt")
local json = require("json")

local data = {}
local request_log = {}
local timeout = 6

local function handle_request (client,msg)
	local payload = json.decode(msg.payload)
	local tipomsg = payload.tipomsg
	local chave = payload.chave
	local topicoresp = payload.topicoresp
	local idpedido = payload.idpedido
	local novovalor = payload.novovalor
	local response

	if tipomsg == "I" then
		data[chave] = novovalor
		response = json.encode({
			status = "OK",
			id = idpedido
		})
	else --consulta
		response = json.encode({
			value = data[chave],
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

local function clean_log()
	local old_entries = {}
	local time = os.time()
	for k,v in pairs(request_log) do
		if time - v > timeout then
			old_entries[#old_entries+1] = k
		end
	end
	for _,v in ipairs(old_entries) do
		request_log[v] = nil
	end
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

client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("Falha na conexão com broker:", connack:reason_string(), connack)
			return
		end
		print("Conectado:", connack) -- successful connection

		-- subscribe to test topic and publish message after it
		assert(client:subscribe{ topic="inf1406-reqs", callback=function(suback)
			print("Assinou:", suback)
		end})
		assert(client:subscribe{ topic="inf1406-monitor", callback=function(suback)
			print("Assinou:", suback)
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

		print("Recebido:", msg.payload)
		if msg.topic == "inf1406-reqs" then
			request_log[msg.payload] = os.time()
			clean_log()

			--TODO handle only if key's hash mod n = id
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
		print("Erro no cliente MQTT:", err)
	end,
}

print("Rodando ioloop")
mqtt.run_ioloop(client)

print("Terminado, ioloop parou")