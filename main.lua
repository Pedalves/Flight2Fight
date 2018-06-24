-- Renan da Fonte Simas dos Santos - 1412122
-- Pedro Ferreira - 1320981

local mqtt = require("ext/mqtt_library")

local init = false
local move_player1 = {left = "a", right = "d"}
local move_player2 = {left = "left", right = "right"}

local controle_right = false
local controle_left = false

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
			if love.keyboard.isDown(move_player1.right) or controle_right then
				dir = 1
			elseif love.keyboard.isDown(move_player1.left) or controle_left then
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

function newBullet(angle, posX, posY, pilot) 
  return {
    speedY = math.sin(angle);
    speedX = math.cos(angle);
    height = 10;
    width = 10;
    x = posX + pilot.width/2;
    y = posY;
    
    update = function(self)
      self.y = self.y + self.speedY;
      self.x = self.x + self.speedX;
    end,
    
    draw = function(self)
      love.graphics.setColor(1,0,0)
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
  local speed = 0.001;
  
  local bullets = {};
  
  --local img = love.graphics.newImage("resources/plataform.png")
  return {
	width = 50,
	height = 10,
  
  spawnBullet = coroutine.wrap (function (self)
      local i = 0;
      while 1 do
        bullets[i] = newBullet(angle, x, y, pilot)
        i = i + 1;
        wait(1/10, self)
       
      end
    end),
    
  
  update = function(self, dt)
			dir = 0 --guarda direção do movimento
			
			--Checa tecla pressionada
			if love.keyboard.isDown(move_player2.right) or controle_right then
				dir = 1
			elseif love.keyboard.isDown(move_player2.left) or controle_left then
				dir = -1
			end
      
			--Executa movimento
			angle = angle + dir*speed*math.pi
      
      self:checkPos()
      
      x, y = pilot.getPosition()
      
      if(self:isActive()) then
        self:spawnBullet();
      end
      
      for i = 1, #bullets do
        bullets[i]:update();
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
  print(init_health);
  local y = init_y
  local speed = math.random(10,30)
  local x = math.random(1,love.graphics.getWidth() - 100)
  local dir = 0;
  
  local img = love.graphics.newImage("resources/enemy.png")
  return {
	width = 100,
  health = init_health,
	height = 10,
    update = coroutine.wrap (function (self)
      if health == nil then
        health = init_health;
      end
      
      --Define direcao
      dir = math.random(-1,1);
      
      if dir >= 0 then
        dir = 1;
      else
        dir = -1;
      end
      
      while 1 do        
        local _, height = love.graphics.getDimensions( )
        x = x+(speed*dir/20)
        if health <= 0 then
          y = init_y
          x = math.random(1,love.graphics.getWidth() - 100)
          health = init_health;
          speed = math.random(10,30);
        end
        
        if x <= 0 then
          x = 0;
          dir = dir * -1;
        else if x >= love.graphics.getWidth() - 100 then
          x = love.graphics.getWidth() - 100;
          dir = dir * -1;
        end
        wait(1/1000, self);
      end
    end
    end
    ),
    
    draw = function(self)
      major, minor, revision, codename = love.getVersion()
      if minor == 9 then
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("fill", x, y, self.width, self.height)
        love.graphics.setColor(255,255,255)
      else
        love.graphics.draw(img, x , y - 2*self.height, 0, 1/15, 1/10)
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
	end
  }
end

-----------------------------------------------------------------------

function love.load()
  love.window.setTitle("Flight2Fight")
  
  mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttcb)
  mqtt_client:connect("cliente love 1")
  mqtt_client:subscribe({"apertou-tecla"})
  
	gameover = nil
	gravity = 500
  gameovertextfont = love.graphics.newFont("resources/PressStart2P-Regular.ttf")
  
  background = love.graphics.newImage("resources/background.jpg")
	
	math.randomseed(os.time())
  listEnemies = {}
  
  for i = 1, 5 do
		listEnemies[i] = newEnemy(i * 100, 3)
	end
  
  player1 = newPilot()
  player2 = newShooter(player1)
  
end

-----------------------------------------------------------------------

function love.keypressed(key)
	init = true
end

-----------------------------------------------------------------------

function love.update(dt)
    mqtt_client:handler()
  
  if (init and gameover == nil) then
    --Atualiza players
    player1:update(dt)
    player2:update(dt)
    
    --Atualiza inimigos
    for i = 1,#listEnemies do
      if(listEnemies[i]:isActive()) then
        listEnemies[i]:update()      
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

    --Desenha players
		player1:draw()
    player2:draw()
    
    --Desenha inimigos
    for i = 1,#listEnemies do
			listEnemies[i]:draw()
		end
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
  if message == 'l' then
    controle_left = not controle_left
    controle_right = false
  elseif message == 'r' then
    controle_right = not controle_right
    controle_left = false
  end
end
