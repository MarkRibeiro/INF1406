-- load mqtt module
local mqtt = require("mqtt")
local json = require("json")

-- create mqtt client
local client = mqtt.client{
	-- NOTE: this broker is not working sometimes; comment username = "..." below if you still want to use it
	-- uri = "test.mosquitto.org",
	uri = "mqtt.flespi.io",
	-- NOTE: more about flespi tokens: https://flespi.com/kb/tokens-access-keys-to-flespi-platform
	username = "Q9CcYotuwqKbYWOK19CafvAdYiD7UjHAi7B4jUoGbZFXLkyAhYynhZo57P3PYyd4",
    clean = true,
	id = "cliente"
}
client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("Falha na conexão com broker:", connack:reason_string(), connack)
			return
		end
		print("Conectado:", connack) -- successful connection

		-- subscribe to test topic and publish message after it
		assert(client:subscribe{ topic="inf1406-resps", callback=function(suback)
			print("Assinou:", suback)
            
            mensagem = {
                tipomsg = "insert",
                chave = "1", 
                topicoresp = "inf1406-resps",
                idpedido = "4",
                novovalor = "5"
            }

			-- publish test message
			assert(client:publish{
				topic = "inf1406-reqs",
				payload = json.encode(mensagem)
			})
            print("Enviei a mensagem\n")
		end})
	end,

	message = function(msg)
		assert(client:acknowledge(msg))

		print("Recebido:", msg)
		print("Desconectando...")
		assert(client:disconnect())
	end,

	error = function(err)
		print("Erro no cliente MQTT:", err)
	end,
}

print("Rodando ioloop")
mqtt.run_ioloop(client)

print("Terminado, ioloop parou")