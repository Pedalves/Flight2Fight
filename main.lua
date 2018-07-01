-- Renan da Fonte Simas dos Santos - 1412122
-- Pedro Ferreira - 1320981

local mqtt = require("ext/mqtt_library")

local init = false
local move_player1 = {left = "a", right = "d"}
local move_player2 = {left = "left", right = "right"}

local controle_right1 = false
local controle_left1 = false

local controle_right2 = false
local controle_left2 = false

local players = 2

-----------------------------------------------------------------------

function newPilot()
  local screenX, screenY = love.graphics.getDimensions()
  local y = screenY - 40
  
  local x = love.graphics.getWidth()/2
  local speed = 200
  
  --local img = love.graphics.newImage("resources/plataform.png")
  return {
	width = 100,
	height = 20,
  
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
    
  checkPos = function(self)
    if x > screenX - self.width then
      x = screenX - self.width
    elseif x < 0 then
      x = 0
    end
  end,
    
  draw = function(self)
    love.graphics.setColor(0,0,1)
    love.graphics.rectangle("fill", x, y, self.width, self.height)
    love.graphics.setColor(255,255,255)
    --love.graphics.draw(img, x , y - 2*self.height, 0, 1/15, 1/10)
  end,
  
  sleep = 0,
  
  getPosition = function()
    return x, y
  end
  }
end

-----------------------------------------------------------------------

function newBullet(angle, posX, posY, origin, colorR, colorG, colorB, speedBase, target) 
  return {
    speedY = speedBase*math.sin(angle);
    speedX = speedBase*math.cos(angle);
    height = 10;
    width = 10;
    x = posX + origin.width/2;
    y = posY;
    
    update = function(self, updateX, dt)
      if(self:checkCollision(target)) then
        self.y = 100000;
      end
      self.y = self.y + self.speedY*dt
      if updateX then
        self.x = self.x + self.speedX*dt
      end
    end,
    
    checkCollision = function(self, target)
      if(target == "player") then
        playerX, playerY = player1.getPosition();
        if ((playerX <= self.x and (playerX + player1.width) >= self.x) and (playerY <= self.y and (playerY + player1.height) >= self.y)) then
          gameover = true;
          return true
        end
        
      elseif (target == "enemy") then
        for i = 1,#listEnemies do
          enemyX, enemyY = listEnemies[i].getPosition();
          if ((enemyX <= self.x and (enemyX + listEnemies[i].width) >= self.x) and (enemyY <= self.y and (enemyY + listEnemies[i].height) >= self.y)) then
            listEnemies[i]:Damage(1);
            return true
          end
        end
      end
    end,
    
    draw = function(self)
      love.graphics.setColor(colorR,colorG,colorB)
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
      love.graphics.setColor(255,255,255)
    end
    }
end

-----------------------------------------------------------------------

function newShooter(pilot)
  local screenX, screenY = love.graphics.getDimensions()
  local x, y = pilot.getPosition()
  
  local angle = -math.pi/2;
  local speed = 0.5;
  
  local bullets = {};
  local bulletPos = 0;
  local timeLeftToTrySpawnBullet = 0.5;
  
  --local img = love.graphics.newImage("resources/plataform.png")
  return {
	width = 50,
	height = 10,
  
  spawnBullet = function (self)
    bullets[bulletPos] = newBullet(angle, x, y, pilot, 1, 0, 0, 200, "enemy")
    bulletPos = bulletPos + 1;
  end,
    
  
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
      
      self:checkPos()
      
      x, y = pilot.getPosition()
      
      timeLeftToTrySpawnBullet = timeLeftToTrySpawnBullet - dt;
      if(self:isActive() and timeLeftToTrySpawnBullet <= 0) then
        timeLeftToTrySpawnBullet = 0.5;
        self:spawnBullet();
      end
      
      for i = 1, #bullets do
        bullets[i]:update(true, dt);
      end
      
		end,
    
  checkPos = function(self)
    if angle > -  math.pi/4 then
      angle = - math.pi/4
    elseif angle < - 3 * math.pi/4 then
      angle = - 3 * math.pi/4
    end
  end,
    
  draw = function(self)
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
    --love.graphics.draw(img, x , y - 2*self.height, 0, 1/15, 1/10)
  end,
  
  sleep = 0,
  
  getPosition = function()
    return x, y
  end,
  
  isActive = function(self)
      if(os.clock() >= self.sleep) then
        return true
      end
      return false
    end
	}
end

-----------------------------------------------------------------------

function newEnemy(init_y, init_health)
  local y = init_y
  local speed = math.random(20,20);
  local x = math.random(1,love.graphics.getWidth() - 100)
  local dir = math.random(-1,1);
  local bullets = {}
  local bulletPos = 0
  local timeLeftToTrySpawnBullet = 0.5;
  local health = init_health
  
  local img = love.graphics.newImage("resources/enemy.png")
  return {
	width = 100,
	height = 10,
  spawnBullet = function (self)
    bullets[bulletPos] = newBullet(math.pi/4, x, y, self, 0, 1, 0, 200, "player")
    bulletPos = bulletPos + 1;
    wait(1/1000, self)
  end,
  
    update = function (self, dt)
        --Define direcao
        
        if dir >= 0 then
          dir = 1;
        else
          dir = -1;
        end
        
        local _, height = love.graphics.getDimensions( )
        x = x+(speed*dt*dir*10)
        if health < 0 then
          y = init_y
          x = math.random(1,love.graphics.getWidth() - 100)
          health = init_health;
          --speed = math.random(20,20);
        end
        
        --atirar
        timeLeftToTrySpawnBullet = timeLeftToTrySpawnBullet - dt;
        if(timeLeftToTrySpawnBullet <= 0) then
          timeLeftToTrySpawnBullet = 0.5;
          if (math.random(1,6) == 1) then
            self:spawnBullet();
          end 
        end
        
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
  
    draw = function(self)
      major, minor, revision, codename = love.getVersion()
      if minor == 9 then
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("fill", x, y, self.width, self.height)
        love.graphics.setColor(255,255,255)
      else
        love.graphics.draw(img, x , y - 2*self.height, 0, 1/5, 1/8)
      end
      
      for i = 1, #bullets do
        bullets[i]:draw();
      end
    end,
    
    sleep = 0,
    
    isActive = function(self)
      if(os.clock() >= self.sleep) then
        return true
      end
      return false
    end,
    
    getPosition = function()
      return x, y
    end,
    
    Damage = function(self, amount)
      health = health - 1;
      if(health <= 0) then
        y = 1000
      end
    end
  }
end

-----------------------------------------------------------------------

function love.load()
  love.window.setTitle("Flight2Fight")
  
  love.window.setMode( 1000, 700)
  
  mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttcb)
  mqtt_client:connect("GM" .. os.time())
  mqtt_client:subscribe({"apertou-tecla"})
  
	gameover = nil
	gravity = 500
  gameovertextfont = love.graphics.newFont("resources/PressStart2P-Regular.ttf")
  
  background = love.graphics.newImage("resources/background.jpg")
	
	math.randomseed(1)
  listEnemies = {}
  
  for i = 1, 5 do
		listEnemies[i] = newEnemy(i * 80, 3)
	end
  
  player1 = newPilot()
  player2 = newShooter(player1)
  
end

-----------------------------------------------------------------------

function love.keypressed(key)
  if gameover ~= nil then
    if key == 'space' or key == ' ' then
        love.event.quit("restart")
    end
  end
end

-----------------------------------------------------------------------

function love.update(dt)
  mqtt_client:handler()
  
  if players == 2 then
    init = true
  end
  
  if (init and gameover == nil) then
    --Atualiza players
    player1:update(dt)
    player2:update(dt)
    
    --Atualiza inimigos
    for i = 1,#listEnemies do
      if(listEnemies[i]:isActive()) then
        listEnemies[i]:update(dt)      
      end
    end
  end
end

-----------------------------------------------------------------------

function love.draw()
	local sx = love.graphics.getWidth() / background:getWidth()
	local sy = love.graphics.getHeight() / background:getHeight()
	if gameover == nil then
		love.graphics.draw(background, 0, 0, 0, sx, sy)
    
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
    
  else
    love.graphics.setFont(gameovertextfont)
    love.graphics.draw(background, 0, 0, 0, sx, sy)
    love.graphics.setColor(0,0,0)
		love.graphics.print("GAME OVER", love.graphics.getWidth()/6, love.graphics.getHeight()/4, 0, 5, 5)
    love.graphics.print("Press SPACE to start a new game", love.graphics.getWidth()/4, love.graphics.getHeight()/1.2, 0, 1, 1)
    love.graphics.setColor(255,255,255)
	end
end

-----------------------------------------------------------------------

function wait(segundos, meublip)
    cur = os.clock()
    meublip.sleep = cur+segundos
    coroutine.yield()
end

-----------------------------------------------------------------------

function mqttcb(topic, message)
  print("Received from topic: " .. topic .. " - message:" .. message)
  if message == 'newPlayer' then
    players = players + 1
  end
  
  if message == 'l1' then
    controle_left1 = not controle_left1
    controle_right1 = false
  elseif message == 'r1' then
    controle_right1 = not controle_right1
    controle_left1 = false
  end
  
  if message == 'l2' then
    controle_left2 = not controle_left2
    controle_right2 = false
  elseif message == 'r2' then
    controle_right2 = not controle_right2
    controle_left2 = false
  end
end
