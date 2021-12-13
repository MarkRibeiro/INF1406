-- Alunos: Mark Ribeiro e Nagib Suaid
-- Matriculas: 1612043 e 1710839

local mqtt = require("mqtt")
local json = require("json")

local data = {}
local request_log = {}
local last_heartbeat = {}
local timeout = 6

local ownid = tonumber(arg[1])
local totalservers = tonumber(arg[2])

if #arg<2 then
    print("Numero de argumentos não corresponde ao desejado")
    print("Favor repetir o comando da seguinte forma:")
    print("> lua5.3 simple-server.lua <ownid> <totalservers>")
    os.exit()
end

local function sleep(n)
	os.execute("sleep " .. tonumber(n))
end

local function handle_request (client,payload)
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
	else
		response = json.encode({
			value = data[chave],
			status = "OK",
			id = idpedido
		})
	end
	return response
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

local client = mqtt.client{
	uri = "mqtt.flespi.io",
	username = "IiVHCfKm0DFQRZuyGhf8zolxbmi1nhYTnHpOKZYAtue8hzuLGAH3OSoO3uDeBrYN",
	clean = true,
	id = "servidor"..ownid
}

client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("Falha na conexão com broker:", connack:reason_string(), connack)
			return
		end
		print("Conectado:", connack)

		assert(client:subscribe{ topic="inf1406-reqs", callback=function(suback)
			print("Assinou:", suback)
		end})
		assert(client:subscribe{ topic="inf1406-monitor", callback=function(suback)
			print("Assinou:", suback)
		end})
		assert(client:subscribe{ topic="inf1406-test", callback=function(suback)
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

			local payload = json.decode(msg.payload)
			request_log[payload] = os.time()
			clean_log()
			local count = 0
			for i=1, #(payload.chave) do
				count = count + string.byte(payload.chave, i)
			end
			local response = handle_request(client,payload)
			if (count % totalservers) == ownid then
				assert(client:publish{
					topic = payload.topicoresp,
					payload = response
				})
			elseif (count % totalservers) == ((ownid-1) % totalservers) then
				local last_seen = last_heartbeat[ownid-1] or os.time()
				if (os.time() - last_seen) > timeout then
					local to_remove = {}
					for request, timestamp in pairs(request_log) do
						if timestamp > last_seen then
							handle_request(client,request)
							to_remove[#to_remove+1] = request
						end
					end
					for _, value in ipairs(to_remove) do
						request_log[value] = nil
					end
				end
			end

		elseif msg.topic == "inf1406-monitor" then
			local payload = json.decode(msg.payload)
			if payload.id == "monitor" then
				last_heartbeat = payload
				assert(client:publish{
					topic = "inf1406-monitor",
					payload = json.encode({
						id = "servidor",
						timestamp = os.time(),
					})
				})
			end
		elseif msg.topic == "inf1406-test" then
			if tonumber(msg.payload) == ownid then
				sleep(15)
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