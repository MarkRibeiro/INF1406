-- load mqtt library
local mqtt = require("mqtt")

-- create MQTT client, flespi tokens info: https://flespi.com/kb/tokens-access-keys-to-flespi-platform
local client = mqtt.client{ uri = "mqtt.flespi.io", username = os.getenv("FLESPI_TOKEN"), clean = true }

-- assign MQTT client event handlers
client:on{
    connect = function(connack)
        if connack.rc ~= 0 then
            print("connection to broker failed:", connack:reason_string(), connack)
            return
        end

        -- connection established, now subscribe to test topic and publish a message after
        assert(client:subscribe{ topic="luamqtt/#", qos=1, callback=function()
            assert(client:publish{ topic = "luamqtt/simpletest", payload = "hello" })
        end})
    end,

    message = function(msg)
        assert(client:acknowledge(msg))

        -- receive one message and disconnect
        print("received message", msg)
        client:disconnect()
    end,
}

-- run ioloop for client
mqtt.run_ioloop(client)