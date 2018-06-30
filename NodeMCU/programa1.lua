wificonf = {
  -- verificar ssid e senha
  ssid = "",
  pwd = "",
  save = false
}


wifi.sta.config(wificonf)
print("modo: ".. wifi.setmode(wifi.STATION))
print(wifi.sta.getip())
