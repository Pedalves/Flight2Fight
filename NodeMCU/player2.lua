local meuid = "player2" --id do player no mqtt
local m = mqtt.Client("clientid " .. meuid, 120) --configura mqtt

--Publica no mqtt que botão da esquerda foi pressionado
function publica(c)
  c:publish("apertou-tecla", "l2",0,0, 
            function(client) print("mandou!") end)
end

--Publica no mqtt que botão da direita foi pressionado
function publica2(c)
  c:publish("apertou-tecla", "r2",0,0, 
            function(client) print("mandou!") end)
end

--Envia mensagem quando se conecta ao mqtt
function newPlayer(c)
  c:publish("apertou-tecla", "newPlayer",0,0, 
            function(client) print("mandou!") end)
end

--Imprime mensagens recebidas
function novaInscricao (c)
  local msgsrec = 0
  function novamsg (c, t, m)
    print ("mensagem ".. msgsrec .. ", topico: ".. t .. ", dados: " .. m)
    msgsrec = msgsrec + 1
  end
  c:on("message", novamsg)
end

--Se inscreve no canal do jogo
function conectado (client)
  client:subscribe("puc-rio-inf1805", 0, novaInscricao)
  newPlayer(client)
end 

--Conectando ao mqtt
m:connect("test.mosquitto.org", 1883, 0, 
             conectado,
             function(client, reason) print("failed reason: "..reason) end)

--Configura botões
sw1 = 1
sw2 = 2

gpio.mode(sw1,gpio.INT,gpio.PULLUP)
gpio.trig(sw1, "down", function(level, timestamp) publica(m) end)

gpio.mode(sw2,gpio.INT,gpio.PULLUP)
gpio.trig(sw2, "down", function(level, timestamp) publica2(m) end)
