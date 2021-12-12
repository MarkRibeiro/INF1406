wificonf = {
  ssid = "Outer Heaven 2G",
  pwd = "m29e26m7",
  save = false,
  got_ip_cb = function (con)
                print (con.IP)
              end
}

wifi.sta.config(wificonf)
print("modo: ".. wifi.setmode(wifi.STATION))
