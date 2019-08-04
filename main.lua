-- Custom NPCs script by Crystal Rain
-- Version: 1.0
-- Release date: 30.08.2013

-- The script might be a little bit complicated. It's recommended not to change anything.
-- In order to add/modify NPCs you have to edit 'sys/lua/cnpc/list.lua' file.

-- Credits: EngiN33R -> Helped me to solve a problems with angels and grammar.

-- Setting up a global table
cnpc = {
	-- Table for spawned NPCs
	spawnedNPCs = {};
	
	-- Table for non-hooked functions
	funcs = {
		-- Table for NPC based functions
		npc = {
			-- Function to spawn an NPC
			-- type - Type id of an NPC
			-- x    - X spawn position on the map (in pixels)
			-- y    - Y spawn position on the map (in pixels)
			-- rot  - Rotation to spawn with
			spawn = function(type, x, y, rot, health)
				if type == nil then print('\169255000000Error in function \'cnpc.funcs.npc.spawn\': \'type\' paramater is not specified!') return end
				if x == nil then print('\169255000000Error in function \'cnpc.funcs.npc.spawn\': \'x\' paramater is not specified!') return end
				if y == nil then print('\169255000000Error in function \'cnpc.funcs.npc.spawn\': \'y\' paramater is not specified!') return end
				if rot == nil then print('\169255000000Error in function \'cnpc.funcs.npc.spawn\': \'rot\' paramater is not specified!') return end
				if not cnpc.list[type] then if id == nil then print('\169255000000Error in function \'cnpc.funcs.npc.spawn\': NPC with type '.. type ..' does not exist!') return end return end
				
				local npcData = cnpc.list[type]
				local npc = {
					x = x;
					y = y;
					rot = rot;
					type = type;
					image = image(npcData.imagePath, 0, 0, 1);
					
					name = npcData.name;
					speed = npcData.speed;
					rotSpeed = npcData.rotationSpeed;
					behaviorType = npcData.behaviorType;
					attackCoolDown = npcData.attackCoolDown;
					health = health or npcData.health;
					damage = npcData.damage;
					data = npcData;

					lastAttack = os.clock();
					closestPlayer = 0;
					closestPlayerLastSeen = false;
					timerParams = false;
				}
				imagepos(npc.image, x, y, rot)
				imagehitzone(npc.image, 3, -npcData.hitbox/2, -npcData.hitbox/2, npcData.hitbox, npcData.hitbox)
				table.insert(cnpc.spawnedNPCs, npc)
			end;
			
			-- Function that removes/despawns the NPC
			-- id - The ID of spawned NPC (from cnpc.spawnedNPCs table)
			remove = function(id)
				if id == nil then print('\169255000000Error in function \'cnpc.funcs.npc.remove\': \'id\' paramater is not specified!') return end
				if not cnpc.spawnedNPCs[id] then print('\169255000000Error in function \'cnpc.funcs.npc.remove\': NPC with ID '.. id ..' does not exist!') return end
				
				local npc = cnpc.spawnedNPCs[id]
				freeimage(npc.image)
				if npc.timerParams ~= false then freetimer(npc.timerParams[1], npc.timerParams[2]) npc.timerParams = false end
				cnpc.spawnedNPCs[id] = nil
			end;
			
			-- Function that forces NPC to attack
			-- id - The ID of spawned NPC (from cncp.spawnedNPCs table)
			-- NOTE: TO USE THIS FUNCTION, NPC HAS TO HAVE THE CLOSEST PLAYER!
			attack = function(id)
				if id == nil then print('\169255000000Error in function \'cnpc.funcs.npc.shoot\': \'id\' paramater is not specified!') return end
				if not cnpc.spawnedNPCs[id] then print('\169255000000Error in function \'cnpc.funcs.npc.shoot\': NPC with ID '.. id ..' does not exist!') return end
				
				local npc = cnpc.spawnedNPCs[id]
				npc.lastAttack = os.clock()
				if npc.behaviorType == 0 then
					local health, armor = cnpc.funcs.math.calculateDamage(player(npc.closestPlayer, 'health'), player(npc.closestPlayer, 'armor'), npc.damage)
					local slashImage = image('gfx/knifeslash.bmp', 0, 0, 1)
					
					tween_rotate(npc.image, 62.5, npc.rot+35)
					timer(62.5, 'parse', 'lua "tween_rotate('.. npc.image ..', '.. (npc.attackCoolDown-0.0625)*1000 ..', '.. npc.rot ..')"')
					
					imagepos(slashImage, npc.x, npc.y, npc.rot)
					imageblend(slashImage, 1)
					tween_alpha(slashImage, 250, 0)
					timer(250, 'freeimage', slashImage)
					
					if health <= 0 then
						parse('customkill 0 "'.. npc.name ..'" '.. npc.closestPlayer)
					else
						parse('sethealth '.. npc.closestPlayer ..' '.. health)
						parse('setarmor '.. npc.closestPlayer ..' '.. armor)
					end
					
					for _, pl in pairs(player(0, 'tableliving')) do
						local x, y = player(pl, 'x'), player(pl, 'y')
						if x >= npc.x - 320 and y >= npc.y - 240 and x <= npc.x + 320 and y <= npc.y + 240 then
							parse('sv_sound2 '.. pl ..' "'.. npc.data.slashSound ..'"')	
							parse('sv_sound2 '.. pl ..' "player/hit'.. math.random(1, 3) ..'.wav"')
						end
					end
				elseif npc.behaviorType == 1 then
					local rot = npc.rot + math.random(-npc.data.bulletSpreading, npc.data.bulletSpreading)
					local startX, startY = cnpc.funcs.math.extendPosition(npc.x, npc.y, rot, npc.data.bulletOffset)
					local endX, endY = cnpc.funcs.math.extendPosition(startX, startY, rot, npc.data.bulletLength)
					local wallX, wallY = cnpc.funcs.math.wallOnLine(startX, startY, endX, endY)
					
					local bulletShot = {}
					local bulletFlash = image('gfx/sprites/flare3.bmp', startX, startY, 1)
					local distance
					if wallX == -1 then
						distance = cnpc.funcs.math.distance(startX, startY, endX, endY)
					else
						distance = cnpc.funcs.math.distance(startX, startY, wallX, wallY)
					end
					
					local x1, y1 = cnpc.funcs.math.extendPosition(startX, startY, rot, distance / 3)
					local x2, y2 = cnpc.funcs.math.extendPosition(startX, startY, rot, (distance / 3)*2)
					local x3, y3 = cnpc.funcs.math.extendPosition(startX, startY, rot, distance)
					bulletShot = {
						cnpc.funcs.draw.line(startX, startY, x1, y1);
						cnpc.funcs.draw.line(x1, y1, x2, y2);
						cnpc.funcs.draw.line(x2, y2, x3, y3);
					}
					
					for k, v in pairs(bulletShot) do
						imagealpha(v, (4-k)*0.22)
						imagecolor(v, 255, 255, 0)
						tween_alpha(v, 125, 0)
						timer(125, 'freeimage', v)
					end
					
					imageblend(bulletFlash, 1)
					imagecolor(bulletFlash, 255, 255, 0)
					imagealpha(bulletFlash, 0.25)
					tween_alpha(bulletFlash, 125, 0)
					timer(125, 'freeimage', bulletFlash)
					
					for _, pl in pairs(player(0, 'tableliving')) do
						local x, y = player(pl, 'x'), player(pl, 'y')
						if x >= npc.x - 320 and y >= npc.y - 240 and x <= npc.x + 320 and y <= npc.y + 240 then
							parse('sv_sound2 '.. pl ..' "'.. npc.data.bulletSound ..'"')
						end
						
						local lx, ly = npc.x, npc.y
						local ex, ey = math.sin(math.rad(npc.rot)), -math.cos(math.rad(npc.rot))
						for i = 0, distance do
							lx, ly = lx + ex, ly + ey
							if x >= lx - 6 and y >= ly - 6 and x <= lx + 6 and y <= ly + 6 then
								local health, armor = cnpc.funcs.math.calculateDamage(player(pl, 'health'), player(pl, 'armor'), npc.damage)
								if health <= 0 then
									parse('customkill 0 "'.. npc.name ..'" '.. npc.closestPlayer)
								else
									parse('sethealth '.. npc.closestPlayer ..' '.. health)
									parse('setarmor '.. npc.closestPlayer ..' '.. armor)
								end
								break
							end
						end
					end
				end
			end;
		};
		
		-- Table for math based function
		math = {
			-- Function that returns distance between two points (in pixels)
			-- x1 - X position of the first point
			-- y1 - Y position of the first point
			-- x2 - X position of the second point
			-- y2 - Y position of the second point
			distance = function(x1, y1, x2, y2)
				return math.sqrt((y1 - y2)^2 + (x1 - x2)^2)
			end;

			-- Function that returns an angle between first and second point
			-- x1 - X position of the first point
			-- y1 - Y position of the first point
			-- x2 - X position of the second point
			-- y2 - Y position of the second point
			getAngle = function(x1, y1, x2, y2)
				return -math.deg(math.atan2(x1 - x2, y1 - y2))
			end;

			-- Function that returns an extended position by dist pixels
			-- x    - X position
			-- x    - Y position
			-- dir  - Direction in which the position should be extended
			-- dist - Distance by which the position should be extended
			extendPosition = function(x, y, dir, dist)
				return x + math.sin(math.rad(dir)) * dist, y - math.cos(math.rad(dir)) * dist
			end;

			-- Function that returns calculated health and armor when player has got hit
			-- health - Player's health
			-- armor  - Player's armor
			-- damage - Damage by which the player got hit
			calculateDamage = function(health, armor, damage)
				damage = (damage < 1 and 1 or damage)
				local coveredDamage, uncoveredDamage
				local returnHealth, returnArmor
				
				if armor > 200 then
					if armor == 201 then
						return math.floor(health-(damage*(1-0.25))), armor
					elseif armor == 202 or armor == 204 then
						return math.floor(health-(damage*(1-0.5))), armor
					elseif armor == 203 then
						return math.floor(health-(damage*(1-0.75))), armor
					elseif armor == 205 then
						return math.floor(health-(damage*(1-0.95))), armor
					end
				end
				
				if damage >= armor then
					uncoveredDamage = damage - armor
					coveredDamage = armor
				else
					uncoveredDamage = 0
					coveredDamage = damage
				end
				returnHealth = health-(coveredDamage*(1.0-tonumber(game('mp_kevlar'))))-uncoveredDamage
				returnArmor = armor - coveredDamage

				return math.floor(returnHealth), returnArmor
			end;

			-- Function that returns the position of the closest wall from first point to second point
			-- Returns -1, -1 if there is no wall
			-- x1 - X position of the first point
			-- y1 - Y position of the first point
			-- x2 - X position of the second point
			-- y2 - Y position of the second point
			wallOnLine = function(x1, y1, x2, y2)
				local angle = cnpc.funcs.math.getAngle(x1, y1, x2, y2)
				local distance = math.floor(cnpc.funcs.math.distance(x1, y1, x2, y2))
				local increaseX, increaseY = cnpc.funcs.math.extendPosition(x1, y1, angle, 1)
				for i = 1, distance do
					x1, y1 = cnpc.funcs.math.extendPosition(x1, y1, angle, 1)
					if tile(math.floor(x1/32), math.floor(y1/32), 'wall') then
						return x1, y1
					end
				end
				return -1, -1
			end;
		};

		draw = {
			-- Draws a line 
			-- x1 - Starting X position
			-- y1 - Starting Y position
			-- x2 - Ending X position
			-- y2 - Ending Y position
			line = function(x1, y1, x2, y2, mode)
				mode = mode or 1
				local line = image('gfx/cnpc/1x1.png', 0, 0, mode)
				local angle, distance = cnpc.funcs.math.getAngle(x1, y1, x2, y2), cnpc.funcs.math.distance(x1, y1, x2, y2)
				local x, y = cnpc.funcs.math.extendPosition(x1, y1, angle, distance/2)
				imagepos(line, x, y, angle)
				imagescale(line, 1, distance)
				return line
			end
		}
	};
	
	-- Table for hooked functions
	hooks = {
		-- Always hook
		always = function()
			-- Scripting NPC's behavior
			for npcID, npc in pairs(cnpc.spawnedNPCs) do
				local lastClosest = npc.closestPlayer
				npc.closestPlayer = 0
				local lastDist = 240
				for _, pl in pairs(player(0, 'tableliving')) do
					local wallX, wallY = cnpc.funcs.math.wallOnLine(npc.x, npc.y, player(pl, 'x'), player(pl, 'y'))
					if wallX == -1 then
						local distance = cnpc.funcs.math.distance(npc.x, npc.y, player(pl, 'x'), player(pl, 'y'))
						if distance < lastDist then
							npc.closestPlayer = pl
							lastDist = distance
						end
					end
				end
				if npc.closestPlayer ~= 0 then
					if lastClosest ~= npc.closestPlayer then
						npc.closestPlayerLastSeen = {player(npc.closestPlayer, 'x'), player(npc.closestPlayer, 'y')}
					end
				end
			
				if npc.closestPlayer > 0 then
					local angle = math.floor(cnpc.funcs.math.getAngle(npc.x, npc.y, npc.closestPlayerLastSeen[1], npc.closestPlayerLastSeen[2]))
					if (npc.lastAttack + npc.attackCoolDown < os.clock() and npc.behaviorType == 0) or (npc.behaviorType > 0) then
						if not (npc.rot <= angle + npc.rotSpeed and npc.rot >= angle - npc.rotSpeed) then
							if npc.rot > angle then
								if math.abs(angle - npc.rot) % 360 > 180 then
									npc.rot = npc.rot + npc.rotSpeed
								else
									npc.rot = npc.rot - npc.rotSpeed
								end
							else
								if math.abs(angle - npc.rot) % 360 > 180 then
									npc.rot = npc.rot - npc.rotSpeed
								else
									npc.rot = npc.rot + npc.rotSpeed
								end
							end
							if angle == -180 and npc.rot == 180 then npc.rot = -180 end -- This will prevent NPCs from freezing
							if npc.rot > 180 then npc.rot = npc.rot - 360 end
							if npc.rot < -180 then npc.rot = npc.rot + 360 end
							imagepos(npc.image, npc.x, npc.y, npc.rot)
						else
							if npc.timerParams == false then
								npc.timerParams = {'parse', 'lua "cnpc.spawnedNPCs['.. npcID ..'].closestPlayerLastSeen = {'.. player(npc.closestPlayer, 'x') ..', '.. player(npc.closestPlayer, 'y') ..'} cnpc.spawnedNPCs['.. npcID ..'].timerParams = false"'}
								timer(62.5, 'parse', npc.timerParams[2])
							end
						end
					end
					
					if (npc.rot <= angle + npc.rotSpeed and npc.rot >= angle - npc.rotSpeed) then
						if not npc.rot == angle then
							npc.rot = angle
							imagepos(npc.image, npc.x, npc.y, npc.rot)
						end
						local distance = cnpc.funcs.math.distance(npc.x, npc.y, player(npc.closestPlayer, 'x'), player(npc.closestPlayer, 'y'))
						if npc.lastAttack + npc.attackCoolDown < os.clock() then
							if npc.behaviorType == 0 and not (distance < 20) then
								npc.x, npc.y = cnpc.funcs.math.extendPosition(npc.x, npc.y, npc.rot, npc.speed)
								imagepos(npc.image, npc.x, npc.y, npc.rot)
							elseif npc.behaviorType == 0 and (distance < 20) then
								cnpc.funcs.npc.attack(npcID)
							elseif npc.behaviorType == 1 and not (distance < 20) and npc.closestPlayer > 0 then
								cnpc.funcs.npc.attack(npcID)
							end
						end
					end
				elseif npc.closestPlayer == 0 and lastClosest == 0 then
					if npc.closestPlayerLastSeen ~= false then
						if not (math.floor(npc.x/32) == math.floor(npc.closestPlayerLastSeen[1]/32) and math.floor(npc.y/32) == math.floor(npc.closestPlayerLastSeen[2]/32)) then	
							local angle = math.floor(cnpc.funcs.math.getAngle(npc.x, npc.y, npc.closestPlayerLastSeen[1], npc.closestPlayerLastSeen[2]))
							if not (npc.rot <= angle + npc.rotSpeed and npc.rot >= angle - npc.rotSpeed) then
								if npc.rot > angle then
									if math.abs(angle - npc.rot) % 360 > 180 then
										npc.rot = npc.rot + npc.rotSpeed
									else
										npc.rot = npc.rot - npc.rotSpeed
									end
								else
									if math.abs(angle - npc.rot) % 360 > 180 then
										npc.rot = npc.rot - npc.rotSpeed
									else
										npc.rot = npc.rot + npc.rotSpeed
									end
								end
								if angle == -180 and npc.rot == 180 then npc.rot = -180 end -- This will prevent NPCs from freezing
								if npc.rot > 180 then npc.rot = npc.rot - 360 end
								if npc.rot < -180 then npc.rot = npc.rot + 360 end
								imagepos(npc.image, npc.x, npc.y, npc.rot)
							else
								if not npc.rot == angle then
									npc.rot = angle
									imagepos(npc.image, npc.x, npc.y, npc.rot)
								end
								
								local x, y = cnpc.funcs.math.extendPosition(npc.x, npc.y, npc.rot, npc.speed)
								if tile(math.floor((x-6)/ 32), math.floor((y-6) / 32), 'walkable') and tile(math.floor((x+6)/ 32), math.floor((y+6) / 32), 'walkable') and tile(math.floor((x-6) / 32), math.floor((y+6) / 32), 'walkable') and tile(math.floor((x+6) / 32), math.floor((y-6) / 32), 'walkable') then
									npc.x, npc.y = cnpc.funcs.math.extendPosition(npc.x, npc.y, npc.rot, npc.speed)
									imagepos(npc.image, npc.x, npc.y, npc.rot)
								end
							end
						end
					end
				end
			end
		end;
		
		-- Leave hook
		leave = function(id)
			-- Removing timer when closest player leaves the server
			for _, npc in pairs(cnpc.spawnedNPCs) do
				if npc.closestPlayer == id then
					if npc.timerParams ~= false then
						freetimer(npc.timeParams[1], npc.timeParams[2])
						npc.timerParams = false
					end
				end
			end
		end;
		
		-- Hitzone hook
		hitzone = function(imageid, playerid, objectid, weapon, impactx, impacty)
			-- NPC getting hit
			local npc, npcID
			for k, v in pairs(cnpc.spawnedNPCs) do
				if v.image == imageid then
					npc = v
					npcID = k
					break
				end
			end
			
			npc.health = npc.health - itemtype(player(playerid, 'weapontype'), 'dmg')
			if npc.health <= 0 then
				cnpc.funcs.npc.remove(npcID)
				for _, pl in pairs(player(0, 'tableliving')) do
					local x, y = player(pl, 'x'), player(pl, 'y')
					if x >= npc.x - 320 and y >= npc.y - 240 and x <= npc.x + 320 and y <= npc.y + 240 then
						parse('sv_sound2 '.. pl ..' "'.. npc.data.deathSound ..'"')
					end
				end
			end
		end;
		
		-- Trigger hook
		trigger = function(trigger, source)
			-- Spawning NPCs on trigger
			for x = 0, map('xsize') do
				for y = 0, map('ysize') do
					if entity(x, y, 'name') == trigger and entity(x, y, 'typename') == 'Env_Item' then
						local wordTable = {}
						for word in string.gmatch(entity(x, y, 'trigger'), '[^%s]+') do
							table.insert(wordTable, word)
						end
						if wordTable[1] == 'cnpc' then
							local id, health, rot, spawn = tonumber(wordTable[2]), tonumber(wordTable[3]), tonumber(wordTable[4]), tonumber(wordTable[5])
							local error = false
							
							-- Checking entity for the errors
							local parameters = {'id', 'health', 'rot', 'spawn'}
							for k, v in pairs(parameters) do
								if not wordTable[k+1] then
									print(k+1)
									error = '\169255000000Unable to spawn NPC using entity on tile \''.. x ..'|'.. y ..'\': \''.. v ..'\' parameter is not specified!'
								end
							end
							if not error then
								if not cnpc.list[id] then
									error = '\169255000000Unable to spawn NPC using entity on tile \''.. x ..'|'.. y ..'\': NPC with type '.. id ..' does not exist!'
								end
							end
							
							if not error then
								if spawn == 1 then
									cnpc.funcs.npc.spawn(id, x*32+16, y*32+16, rot, health == 0 and nil or health)
								end
							else
								print(error)
							end
						end
					end
				end
			end
		end;
		
		-- Startround hook
		startround = function()
			-- Despawning all the NPCs from the last round and spawning new
			freetimer()
			cnpc.spawnedNPCs = {}
			
			for x = 0, map('xsize') do
				for y = 0, map('ysize') do
					if entity(x, y, 'typename') == 'Env_Item' then
						local wordTable = {}
						for word in string.gmatch(entity(x, y, 'trigger'), '[^%s]+') do
							table.insert(wordTable, word)
						end
						
						if wordTable[1] == 'cnpc' then
							local id, health, rot, spawn = tonumber(wordTable[2]), tonumber(wordTable[3]), tonumber(wordTable[4]), tonumber(wordTable[5])
							local error = false
							
							-- Checking entity for the errors
							local parameters = {'id', 'health', 'rot', 'spawn'}
							for k, v in pairs(parameters) do
								if not wordTable[k+1] then
									error = '\169255000000Unable to spawn NPC using entity on tile \''.. x ..'|'.. y ..'\': \''.. v ..'\' parameter is not specified!'
								end
							end
							if not error then
								if not cnpc.list[id] then
									error = '\169255000000Unable to spawn NPC using entity on tile \''.. x ..'|'.. y ..'\': NPC with type '.. id ..' does not exist!'
								end
							end
							
							if not error then
								if spawn == 1 then
									cnpc.funcs.npc.spawn(id, x*32+16, y*32+16, rot, health == 0 and nil or health)
								end
							else
								print(error)
							end
						end
					end
				end
			end
		end;
		
		-- Parse hook
		parse = function(cmd)
			-- Creating console commands
			local wordTable = {}
			for word in string.gmatch(cmd, '[^%s]+') do
				table.insert(wordTable, word)
			end
			
			local parameters, error, successFunction, identifier
			if wordTable[1] == 'cnpc_spawn' then
				parameters = {'type', 'x', 'y', 'rot'}
				identifier = 'type'
				successFunction = function()
					cnpc.funcs.npc.spawn(tonumber(wordTable[2]), tonumber(wordTable[3]), tonumber(wordTable[4]), tonumber(wordTable[5]))
				end
			elseif wordTable[1] == 'cnpc_damage' then
				parameters = {'id', 'damage'}
				identifier = 'id'
				successFunction = function()
					local npc = cnpc.spawnedNPCs[tonumber(wordTable[2])]
					npc.health = npc.health - tonumber(wordTable[3])
					if npc.health <= 0 then
						cnpc.funcs.npc.remove(tonumber(wordTable[2]))
						for _, pl in pairs(player(0, 'tableliving')) do
							local x, y = player(pl, 'x'), player(pl, 'y')
							if x >= npc.x - 320 and y >= npc.y - 240 and x <= npc.x + 320 and y <= npc.y + 240 then
								parse('sv_sound2 '.. pl ..' "'.. npc.data.deathSound ..'"')
							end
						end
					end
				end
			elseif wordTable[1] == 'cnpc_despawn' then
				parameters = {'id'}
				identifier = 'id'
				successFunction = function()
					cnpc.funcs.npc.remove(tonumber(wordTable[2]))
				end
			end
			
			if parameters then
				for k, v in pairs(parameters) do
					if not wordTable[k+1] then
						error = '\169255000000Unable to execute \''.. wordTable[1] ..'\' command: \''.. v ..'\' parameter is not specified!'
					end
				end
				if not error then
					local i = tonumber(wordTable[2])
					if identifier == 'type' then
						if not cnpc.list[i] then
							error = '\169255000000Unable to execute \''.. wordTable[1] ..'\' command: NPC with type '.. i ..' does not exist!'
						end
					else
						if not cnpc.spawnedNPCs[i] then
							error = '\169255000000Unable to execute \''.. wordTable[1] ..'\' command: NPC with id '.. i ..' does not exist!'
						end
					end
				end
				
				if not error then
					successFunction()
				else
					print(error)
				end
				return 2
			end
		end;
	};
}

-- Adding hooks
addhook('always', 'cnpc.hooks.always')
addhook('leave', 'cnpc.hooks.leave')
addhook('hitzone', 'cnpc.hooks.hitzone')
addhook('trigger', 'cnpc.hooks.trigger')
addhook('startround', 'cnpc.hooks.startround')
addhook('parse', 'cnpc.hooks.parse')

-- Loading up a custom NPC list
dofile('sys/lua/cnpc/list.lua')

-- Checking NPC list for the errors
print('\169255255255Checking NPC list for critical errors...')
local errors = 0
for npcType, npc in pairs(cnpc.list) do
	local error = false
	for _, value in pairs({'name', 'imagePath', 'deathSound', 'speed', 'rotationSpeed', 'behaviorType', 'attackCoolDown', 'health', 'damage', 'hitbox'}) do
		if npc[value] == nil then
			print('\169255000000Error in type '.. npcType ..': Value \''.. value ..'\' is not specified! Excluding the NPC from the list.')
			cnpc.list[npcType] = nil
			error = true
			errors = errors + 1
			break
		end
	end
	if not error then
		local parameters =  {[0] = {'slashSound'}, [1] = {'bulletLength', 'bulletSpreading', 'bulletOffset', 'bulletSound'}}
		for _, value in pairs(parameters[npc.behaviorType]) do
			if npc[value] == nil then
				print('\169255000000Error in checking type '.. npcType ..': Value \''.. value ..'\' is not specified! Excluding the NPC from the list.')
				cnpc.list[npcType] = nil
				error = true
				errors = errors + 1
				break
			end
		end
	end
end
print(errors == 0 and '\169255255255No errors was found in the NPC list.' or '\169255000000'.. errors ..' error(s) have occured during the check! See messages above for more information!')

-- Executing "startround" hook
cnpc.hooks.startround()