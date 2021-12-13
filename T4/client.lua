-- Alunos: Mark Ribeiro e Nagib Suaid
-- Matriculas: 1612043 e 1710839

local mqtt = require("mqtt")
local json = require("json")

if #arg<4 then
	print("Numero de argumentos não corresponde ao desejado")
	print("Favor repetir o comando da seguinte forma:")
	print("> lua5.3 client.lua <id> <tipomsg> <chave> <idpedido> <novovalor>(opcional)")
	os.exit()
end

local client = mqtt.client{

	uri = "mqtt.flespi.io",
	username = "Q9CcYotuwqKbYWOK19CafvAdYiD7UjHAi7B4jUoGbZFXLkyAhYynhZo57P3PYyd4",
	clean = true,
	id = arg[1]
}
client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("Falha na conexão com broker:", connack:reason_string(), connack)
			return
		end
		print("Conectado:", connack)
		assert(client:subscribe{ topic="inf1406-resp"..arg[1], callback=function(suback)
			print("Assinou:", suback)

			local mensagem = {
				tipomsg = arg[2],
				chave = arg[3],
				topicoresp = "inf1406-resp"..arg[1],
				idpedido = arg[4],
				novovalor = arg[5]
			}

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