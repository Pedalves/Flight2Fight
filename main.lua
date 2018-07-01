-- Renan da Fonte Simas dos Santos - 1412122
-- Pedro Ferreira - 1320981

local mqtt = require("ext/mqtt_library")

local init = false
local move_player1 = {left = "a", right = "d"} --Comandos pelo teclado para o player 1
local move_player2 = {left = "left", right = "right"} --Comandos pelo teclado para o player 2

local controle_right1 = false --alterado quando o botão direito do mqtt é pressionado
local controle_left1 = false --alterado quando o botão esquerdo do mqtt é pressionado

local controle_right2 = false --alterado quando o botão direito do mqtt é pressionado
local controle_left2 = false --alterado quando o botão esquerdo do mqtt é pressionado

local players = 0 --número de players conectados na sala
local kills = 0 --número de inimigos derrotados
-----------------------------------------------------------------------

--Função que gera um novo jogador 1 (pilot) e também uma nave
function newPilot()
  --Define posição de acordo com a resolução
  local screenX, screenY = love.graphics.getDimensions()
  local y = screenY - 40
  
  local x = love.graphics.getWidth()/2
  local speed = 200
  
  --local img = love.graphics.newImage("resources/plataform.png")
  return {
	width = 100,
	height = 20,
  
  --Função de update
  -- dt: tempo entre 2 updates do love
  update = function(self, dt)
			dir = 0 --guarda direção do movimento
			
			--Checa tecla pressionada
			if love.keyboard.isDown(move_player1.right) or controle_right1 then
				dir = 1
			elseif love.keyboard.isDown(move_player1.left) or controle_left1 then
				dir = -1
			end
      
			--Executa movimento
			x = x + (dir*speed*dt)
      
      self:checkPos()
      
		end,
  
  --Função que checa se o player está saindo da fase e corrige sua posição
  checkPos = function(self)
    if x > screenX - self.width then
      x = screenX - self.width --corrige posição
    elseif x < 0 then
      x = 0 --corrige posição
    end
  end,
  
  --Define como o player será desenhado na tela
  draw = function(self)
    love.graphics.setColor(0,0,1)
    love.graphics.rectangle("fill", x, y, self.width, self.height)
    love.graphics.setColor(255,255,255)
  end,
  
  sleep = 0,
  
  --Retorna posição atual do player
  getPosition = function()
    return x, y
  end
  }
end

-----------------------------------------------------------------------
--Função que gera tiros tanto do player quanto do inimigo
-- angle: angulo que o tiro irá percorrer
-- posX e posY: posições iniciais da onde o tiro irá partir
-- origin: objeto que disparou o tiro
-- colorR, colorG, colorB: cor do tiro
-- speedBase: velocidade base do tiro
-- target: alvo do tiro (pode ser "enemy", se o tiro der dano em inimigos, ou "player", se o tiro der dano no jogador)
function newBullet(angle, posX, posY, origin, colorR, colorG, colorB, speedBase, target) 
  return {
    speedY = speedBase*math.sin(angle); --velocidade vertical
    speedX = speedBase*math.cos(angle); --velocidade horizontal
    height = 10;
    width = 10;
    
    --posição inicial
    x = posX + origin.width/2;
    y = posY;
    
    --Função de update
    -- updateX: define se o tiro deve se mover horizontalmente
    -- dt: tempo entre 2 updates do love
    update = function(self, updateX, dt)
      --Tiro some se tiver colidido com alvo
      if(self:checkCollision(target)) then
        self.y = 100000;
      end
      
      --Atualiza posição
      self.y = self.y + self.speedY*dt
      if updateX then
        self.x = self.x + self.speedX*dt
      end
    end,
    
    --Função que checa se o tiro atingiu o alvo
    -- target: string indicando alvo do tiro
    checkCollision = function(self, target)
      if(target == "player") then
        playerX, playerY = player1.getPosition();
        if ((playerX <= self.x and (playerX + player1.width) >= self.x) and (playerY <= self.y and (playerY + player1.height) >= self.y)) then --Checa se o player e o tiro estão na mesma posição
          gameover = true;
          mqtt_client:publish("deadPlayer", "dead") --Envia mensagem para outro jogador indicando que o player morreu
          return true
        end
        
      elseif (target == "enemy") then
        for i = 1,#listEnemies do
          enemyX, enemyY = listEnemies[i].getPosition();
          if ((enemyX <= self.x and (enemyX + listEnemies[i].width) >= self.x) and (enemyY <= self.y and (enemyY + listEnemies[i].height) >= self.y)) then --Checa se o tiro e algum inimigo estão na mesma posição
            listEnemies[i]:damage(1); --Dá 1 de dano ao inimigo
            return true
          end
        end
      end
    end,
    
    --Define como o tiro será desenhado na tela
    draw = function(self)
      love.graphics.setColor(colorR,colorG,colorB)
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
      love.graphics.setColor(255,255,255)
    end
    }
end

-----------------------------------------------------------------------

--Função que gera um novo jogador 2 (shooter)
function newShooter(pilot)
  local screenX, screenY = love.graphics.getDimensions()
  local x, y = pilot.getPosition()
  
  local angle = -math.pi/2; -- ângulo dos tiros disparados
  local speed = 0.5; --velocidade base dos tiros
  
  local bullets = {}; --lista de tiros disparados pelo player
  local bulletPos = 0; --índice do último tiro disparado, no vetor de tiros
  local timeLeftToTrySpawnBullet = 0.5; --tempo entre os tiros
  
  --local img = love.graphics.newImage("resources/plataform.png")
  return {
	width = 50,
	height = 10,
  
  --Função responsável por instanciar tiros disparados
  spawnBullet = function (self)
    --Cria um novo tiro e o adiciona na última posição da lista de tiros
    bullets[bulletPos] = newBullet(angle, x, y, pilot, 1, 0, 0, 200, "enemy")
    bulletPos = bulletPos + 1;
  end,
    
  --Função de update
  -- dt: tempo entre 2 updates do love
  update = function(self, dt)
			dir = 0 --guarda direção do movimento
			
			--Checa tecla pressionada
			if love.keyboard.isDown(move_player2.right) or controle_right2 then
				dir = 1
			elseif love.keyboard.isDown(move_player2.left) or controle_left2 then
				dir = -1
			end
      
			--Executa movimento
			angle = angle + dir*speed*math.pi*dt
      
      self:checkPos() --Checa se o ângulo está dentro dos limites e o corrige caso necessário
      
      x, y = pilot.getPosition()
      
      --Atira
      timeLeftToTrySpawnBullet = timeLeftToTrySpawnBullet - dt; --Atualiza contador de tempo entre os tiros
      if(timeLeftToTrySpawnBullet <= 0) then
        timeLeftToTrySpawnBullet = 0.5; --Reinicia o contador de tempo entre os tiros
        self:spawnBullet();
      end
      
      for i = 1, #bullets do
        bullets[i]:update(true, dt); --Atualiza cada tiro
      end
      
		end,
    
  --Função que checa se o ângulo do shooter está dentro dos limties e a corrige caso necessário  
  checkPos = function(self)
    if angle > -  math.pi/4 then
      angle = - math.pi/4
    elseif angle < - 3 * math.pi/4 then
      angle = - 3 * math.pi/4
    end
  end,
    
  --Função que desenha na tela
  draw = function(self)
    --Desenha cada tiro disparado
    for i = 1, #bullets do
      bullets[i]:draw();
    end
    
    love.graphics.push()
    love.graphics.setColor(0,0,1)
    love.graphics.translate(x + self.width/2 + 20, y + 10)
    
    love.graphics.rotate(angle)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    love.graphics.setColor(255,255,255)
    love.graphics.pop()
  end,
  
  sleep = 0,
  
  --Retorna a posição do jogador 2
  getPosition = function()
    return x, y
  end
	}
end

-----------------------------------------------------------------------
--Função que cria um novo inimigo
-- init_y: posição y inicial
-- init_health: vida inicial
-- id: id pelo qual será referenciado pelas mensagens do mqtt
function newEnemy(init_y, init_health, id)
  local y = init_y
  local speed = 20; --velocidade
  local x = math.random(1,love.graphics.getWidth() - 100) --posição x
  local dir = math.random(-1,1); --direção inicial
  local bullets = {} --lista de tiros disparados por esse inimigo
  local bulletPos = 0 --índice do último tiro disparado, no vetor de tiros
  local timeLeftToTrySpawnBullet = 3; --tempo entre os tiros
  local health = init_health --vida
  local enemyId = id --id pelo qual será referenciado pelas mensagens do mqtt
  
  local img = love.graphics.newImage("resources/enemy.png") --imagem do inimigo no jogo
  return {
	width = 100,
	height = 10,
  -- Função que instancia os tiros do inimigo
  spawnBullet = function (self)
    --Gera o tiro e o guarda na última posição da lista de tiros
    bullets[bulletPos] = newBullet(math.pi/4, x, y, self, 0, 1, 0, 200, "player")
    bulletPos = bulletPos + 1;
  end,
  
  --Função de update
  -- dt: tempo entre 2 updates do love
    update = function (self, dt)
        --Define direcao
        if dir >= 0 then
          dir = 1;
        else
          dir = -1;
        end
        
        local _, height = love.graphics.getDimensions( )
        x = x+(speed*dt*dir*10) --Atualiza posição x
        
        --atirar
        timeLeftToTrySpawnBullet = timeLeftToTrySpawnBullet - dt; --Atualiza o contador de tempo entre os tiros
        if(timeLeftToTrySpawnBullet <= 0) then
          timeLeftToTrySpawnBullet = 3; --Reinicia o contador de tempo entre os tiros
          self:spawnBullet();
        end
        
        --Atualiza os tiros
        for i = 1, #bullets do
          bullets[i]:update(false, dt);
        end
        
        --checando limites
        if x <= 0 then
          x = 0;
          dir = dir * -1;
        else if x >= love.graphics.getWidth() - 100 then
          x = love.graphics.getWidth() - 100;
          dir = dir * -1;
        end
      end
    end,
  
    --Função que desenha o inimigo na tela
    draw = function(self)
      major, minor, revision, codename = love.getVersion()
      --Dependendo da versão do love utilizada, desenha o inimigo de forma diferente
      if minor == 9 then
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("fill", x, y, self.width, self.height)
        love.graphics.setColor(255,255,255)
      else
        love.graphics.draw(img, x , y - 2*self.height, 0, 1/5, 1/8)
      end
      
      --Desenha os tiros disparados pelo inimigo
      for i = 1, #bullets do
        bullets[i]:draw();
      end
    end,
    
    sleep = 0,
    
    --Função que retorna posição atual do inimigo
    getPosition = function()
      return x, y
    end,
    
    --Função a ser chamada quando o inimigo for atingido
    -- amount: quantidade de dano que o inimigo sofrerá
    damage = function(self, amount)
      health = health - 1;
      -- Checa se inimigo foi derrotado
      if(health <= 0) then
        y = 1000
        mqtt_client:publish("deadEnemy", enemyId) --Informa o outro jogador que o inimigo morreu
        kills = kills + 1; --incrementa contador de inimigos abatidos
        health = 10
      end
    end
  }
end

-----------------------------------------------------------------------

function love.load()
  --Configurando propriedades do jogo no Löve
  love.window.setTitle("Flight2Fight")
  love.window.setMode( 1000, 700)
  
  --Configurando MQTT
  mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttcb)
  mqtt_client:connect("GM" .. os.time())
  mqtt_client:subscribe({"apertou-tecla","deadPlayer","deadEnemy"})
  
	gameover = nil --checa se player perdeu o jogo
	gravity = 500
  
  --Importa recursos
  gameovertextfont = love.graphics.newFont("resources/PressStart2P-Regular.ttf")
  background = love.graphics.newImage("resources/background.jpg")
	
	math.randomseed(1) --seed a ser usada pelo gerador de números aleatórios
  listEnemies = {} --lista de inimigos em jogo
  
  --Inicializa inimigos
  for i = 1, 5 do
		listEnemies[i] = newEnemy(i * 80, 3, i)
	end
  
  --Inicializa jogadores
  player1 = newPilot()
  player2 = newShooter(player1)
  
end

-----------------------------------------------------------------------

function love.keypressed(key)
  --Se o jogo tiver acabado, espaço reinicia o jogo
  if gameover ~= nil or victory ~= nil then
    if key == 'space' or key == ' ' then
        love.event.quit("restart")
    end
  end
end

-----------------------------------------------------------------------

function love.update(dt)
  --Atualiza mqtt
  mqtt_client:handler()
  
  --Checa se os dois jogadores se conectaram
  if players == 2 then
    init = true
  end
  
  if (init and gameover == nil) then
    --Atualiza players
    player1:update(dt)
    player2:update(dt)
    
    --Atualiza inimigos
    for i = 1,#listEnemies do
      listEnemies[i]:update(dt)      
    end
  end
  
  --Checa se condição de vitória foi atingida
  if (kills == 5) then
    victory = true;
  end
end

-----------------------------------------------------------------------

function love.draw()
	local sx = love.graphics.getWidth() / background:getWidth()
	local sy = love.graphics.getHeight() / background:getHeight()
	if gameover == nil then
		love.graphics.draw(background, 0, 0, 0, sx, sy) --Desenha o fundo
    
    if victory ~= nil then
      drawResultScreen("VICTORY") --desenha tela de vitória
    end
    
    --Se o jogo ainda não tiver iniciado, desenha tela de espera pelos jogadores se conectarem
    if init == false then
      love.graphics.setColor(0,0,0)
      love.graphics.print("Waiting for " .. 2 - players .. " players", love.graphics.getWidth()/6, love.graphics.getHeight()/4, 0, 5, 5)
      love.graphics.setColor(255,255,255)
    end
    
    --Desenha players
		player1:draw()
    player2:draw()
    
    --Desenha inimigos
    for i = 1,#listEnemies do
			listEnemies[i]:draw()
		end
    
  --Se os jogadores perderam, desenha tela de Game Over
  else
    drawResultScreen("GAME OVER")
	end
end

-----------------------------------------------------------------------
--Função que é chamada para desenhar a tela de vitória e de game over
-- text: string contendo o que deve estar escrito na tela (por exemplo: "GAME OVER")
function drawResultScreen(text)
    --Configura recursos
    love.graphics.setFont(gameovertextfont)
    love.graphics.draw(background, 0, 0, 0, sx, sy)
    love.graphics.setColor(0,0,0)
    
    --Imprime textos
		love.graphics.print(text, love.graphics.getWidth()/6, love.graphics.getHeight()/4, 0, 5, 5)
    love.graphics.print("Press SPACE to start a new game", love.graphics.getWidth()/4, love.graphics.getHeight()/1.2, 0, 1, 1)
    love.graphics.setColor(255,255,255)
end

-----------------------------------------------------------------------
--Função que controla o recebimento de mensagens via mqtt
function mqttcb(topic, message)
  --Termina o jogo quando recebe mensagem informando que players morreram
  if message == 'dead' then
    gameover = true
  end
  
  --Remove inimigo do jogo quando recebe mensagem dizendo que o mesmo foi derrotado
  if topic == 'deadEnemy' then
    listEnemies[tonumber(message)]:damage(3)
  end
  
  --Atualiza contador de players quando recebe mensagem indicando que um player se conectou
  if message == 'newPlayer' then
    players = players + 1
  end
  
  --Mensagens informando se botões do nodeMCU do player 1 foram pressionados
  if message == 'l1' then
    controle_left1 = not controle_left1
    controle_right1 = false
  elseif message == 'r1' then
    controle_right1 = not controle_right1
    controle_left1 = false
  end
  
  --Mensagens informando se botões do nodeMCU do player 2 foram pressionados
  if message == 'l2' then
    controle_left2 = not controle_left2
    controle_right2 = false
  elseif message == 'r2' then
    controle_right2 = not controle_right2
    controle_left2 = false
  end
end
