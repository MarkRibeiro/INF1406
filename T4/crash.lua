-- Alunos: Mark Ribeiro e Nagib Suaid
-- Matriculas: 1612043 e 1710839

local mqtt = require("mqtt")
local json = require("json")

if #arg<1 then
	print("Numero de argumentos não corresponde ao desejado")
	print("Favor repetir o comando da seguinte forma:")
	print("> lua5.3 crash.lua <serverid>")
	os.exit()
end

local client = mqtt.client{

	uri = "mqtt.flespi.io",
	username = "Q9CcYotuwqKbYWOK19CafvAdYiD7UjHAi7B4jUoGbZFXLkyAhYynhZo57P3PYyd4",
	clean = true,
	id = "crasher"
}
client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("Falha na conexão com broker:", connack:reason_string(), connack)
			return
		end
		print("Conectado:", connack)
        assert(client:publish{
            topic = "inf1406-test",
            payload = arg[1],
        })
        assert(client:disconnect())
	end,

	error = function(err)
		print("Erro no cliente MQTT:", err)
	end,
}

print("Rodando ioloop")
mqtt.run_ioloop(client)

print("Terminado, ioloop parou")