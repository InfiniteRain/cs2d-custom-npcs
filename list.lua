-- Add your NPCs in this file
-- NPC ID have to be a number!

---------------------------
-- Description of values --
---------------------------

-- name            - STRING - Name of the NPC
-- imagePath       - STRING - Path to the image for NPC
-- deathSound      - STRING - Path to the sound file which will be played when NPC dies
-- speed           - NUMBER - Moving speed of NPC (pixels per frame)
-- rotationSpeed   - NUMBER - Rotation speed of NPC (degree per frame)
-- behaviorType    - NUMBER - Type of NPC's behavior (0 - melee NPC, 1 - range NPC)
-- attackCoolDown  - NUMBER - Time between attacks of the NPC (in seconds)
-- health          - NUMBER - Health of an NPC
-- damage          - NUMBER - Damage dealt to a player by an NPC
-- hitbox          - NUMBER - Hitbox for an NPC (pixels) (will be centred) (one number for X and Y (square))

-- -- --> You will only need this values if NPC's behavior type is 1 (range) <-- -- --
-- bulletLength    - NUMBER - Length of a bullet of NPC
-- bulletSpreading - NUMBER - Bullet spreading
-- bulletOffSet    - NUMBER - Offset for a starting point of a bullet (pixels)
-- bulletSound     - STRING - Path to the sound file which will be played when NPC will shoot (path is relative to sfx folder)

-- -- --> You will only need this value if NPC's behavior type is 1 (melee) <-- -- --
-- slashSound      - STRING - Path to the sound file which will be played when NPC will attack (path is relative to sfx folder)

-- NOTE: STRING values has to be inside of quotes ("STRING" or 'STRING')

-------------
-- Pattern --
--[[---------
cnpc.list = {
	[<NPC ID>] = {
		name = "<NAME>";
		imagePath = "<PATH>";
		speed = <SPEED>;
		...
	};
	
	[<NPC ID>] = {
		name = "<NAME>";
		imagePath = "<PATH>";
		speed = <SPEED>;
		...
	};
}
---------]]--

cnpc.list = {
	[1] = {
		name = 'Knife Terrorist';
		imagePath = 'gfx/cnpc/terrorist2.png<m>';
		deathSound = 'player/die1.wav';
		speed = 3;
		rotationSpeed = 8;
		behaviorType = 0;
		attackCoolDown = 0.75;
		health = 100;
		damage = 45;
		hitbox = 32;
		
		slashSound = 'weapons/knife_slash.wav';
	};

	[2] = {
		name = 'AK47 Terrorist';
		imagePath = 'gfx/cnpc/terrorist.png<m>';
		deathSound = 'player/die1.wav';
		speed = 2;
		rotationSpeed = 7;
		behaviorType = 1;
		attackCoolDown = 0.75;
		health = 100;
		damage = 15;
		hitbox = 32;

		bulletLength = 350;
		bulletSpreading = 2;
		bulletOffset = 16;
		bulletSound = 'weapons/deagle.wav';
	}
}