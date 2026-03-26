const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.static(path.join(__dirname, 'public')));

// User data storage (in production, use a database)
const users = new Map(); // username -> {password, level, keys, xp, inventory, stats}
const sessions = new Map(); // socket.id -> {username}

// Game state
const rooms = new Map(); // roomId -> {players, gameState, scores, etc.}
const MAX_PLAYERS_PER_ROOM = 10;

// Per-match tracking data: socketId -> { kills, damage, roundsWon, weaponsUsed, meleeKills, sniperKills, matchesPlayed }
const matchTracking = new Map();

// ============== WEAPON SHOP CONFIG ==============
const weaponPrices = {
    // Default (free)
    AssaultRifle: { price: 0, levelReq: 1 },
    Handgun: { price: 0, levelReq: 1 },
    Fists: { price: 0, levelReq: 1 },
    Grenade: { price: 0, levelReq: 1 },
    // Cheap (5 keys, level 1)
    SMG: { price: 5, levelReq: 1 },
    Knife: { price: 5, levelReq: 1 },
    Medkit: { price: 5, levelReq: 1 },
    Shorty: { price: 5, levelReq: 1 },
    Uzi: { price: 5, levelReq: 1 },
    Slingshot: { price: 5, levelReq: 1 },
    Daggers: { price: 5, levelReq: 1 },
    Trowel: { price: 5, levelReq: 1 },
    // Medium (15 keys, level 3)
    Shotgun: { price: 15, levelReq: 3 },
    Bow: { price: 15, levelReq: 3 },
    BurstRifle: { price: 15, levelReq: 3 },
    Revolver: { price: 15, levelReq: 3 },
    FlareGun: { price: 15, levelReq: 3 },
    Katana: { price: 15, levelReq: 3 },
    BattleAxe: { price: 15, levelReq: 3 },
    Flashbang: { price: 15, levelReq: 3 },
    FreezeRay: { price: 15, levelReq: 3 },
    // Expensive (30 keys, level 5)
    Sniper: { price: 30, levelReq: 5 },
    Crossbow: { price: 30, levelReq: 5 },
    RPG: { price: 30, levelReq: 5 },
    Minigun: { price: 30, levelReq: 5 },
    EnergyRifle: { price: 30, levelReq: 5 },
    Gunblade: { price: 30, levelReq: 5 },
    Chainsaw: { price: 30, levelReq: 5 },
    Scythe: { price: 30, levelReq: 5 },
    RiotShield: { price: 30, levelReq: 5 },
    Molotov: { price: 30, levelReq: 5 },
    // Premium (50 keys, level 8)
    Flamethrower: { price: 50, levelReq: 8 },
    GrenadeLauncher: { price: 50, levelReq: 8 },
    PaintballGun: { price: 50, levelReq: 8 },
    Exogun: { price: 50, levelReq: 8 },
    JumpPad: { price: 50, levelReq: 8 }
};

// ============== TASK DEFINITIONS ==============
const taskDefinitions = [
    { id: 'kill5', name: 'Get 5 kills', description: 'Eliminate 5 enemies', target: 5, stat: 'kills', rewardKeys: 5, rewardXP: 50 },
    { id: 'winMatch', name: 'Win a match', description: 'Win a full match', target: 1, stat: 'matchWins', rewardKeys: 10, rewardXP: 100 },
    { id: 'sniper3', name: 'Get 3 headshots', description: 'Get 3 kills with Sniper', target: 3, stat: 'sniperKills', rewardKeys: 8, rewardXP: 80 },
    { id: 'play3', name: 'Play 3 matches', description: 'Complete 3 matches', target: 3, stat: 'matchesPlayed', rewardKeys: 5, rewardXP: 50 },
    { id: 'damage500', name: 'Deal 500 damage', description: 'Deal 500 total damage', target: 500, stat: 'damage', rewardKeys: 5, rewardXP: 50 },
    { id: 'win3rounds', name: 'Win 3 rounds', description: 'Win 3 rounds in any match', target: 3, stat: 'roundsWon', rewardKeys: 8, rewardXP: 75 },
    { id: 'meleeKill', name: 'Get a kill with melee', description: 'Eliminate someone with a melee weapon', target: 1, stat: 'meleeKills', rewardKeys: 5, rewardXP: 40 },
    { id: 'use3weapons', name: 'Use 3 different weapons', description: 'Use 3 different weapons in a match', target: 3, stat: 'weaponsUsed', rewardKeys: 5, rewardXP: 50 }
];

// ============== XP / LEVELING ==============
function xpNeededForLevel(level) {
    return level * 100;
}

function getTotalXPForLevel(level) {
    // Total XP needed to reach this level from 0
    let total = 0;
    for (let l = 1; l < level; l++) {
        total += xpNeededForLevel(l);
    }
    return total;
}

function addXP(user, amount, socket) {
    user.xp += amount;
    let leveled = false;
    // Check for level up(s)
    while (user.xp >= getTotalXPForLevel(user.level) + xpNeededForLevel(user.level)) {
        user.level++;
        user.keys += 5; // Bonus keys per level
        leveled = true;
        if (socket) {
            socket.emit('levelUp', { level: user.level, keys: user.keys, xp: user.xp });
        }
    }
    return leveled;
}

// Assign 3 random tasks to a user
function assignTasks(user) {
    const shuffled = [...taskDefinitions].sort(() => Math.random() - 0.5);
    const selected = shuffled.slice(0, 3);
    user.tasks = selected.map(t => ({
        ...t,
        progress: 0,
        claimed: false
    }));
}

// Weapon database (same as client)
const weapons = {
    // === PRIMARY WEAPONS ===
    AssaultRifle: { name: 'Assault Rifle', type: 'primary', damage: 15, fireRate: 80, maxAmmo: 30, speed: 20, color: '#6366f1' },
    Shotgun: { name: 'Shotgun', type: 'primary', damage: 12, fireRate: 700, maxAmmo: 8, speed: 12, color: '#f59e0b', count: 6 },
    Sniper: { name: 'Sniper', type: 'primary', damage: 120, fireRate: 1200, maxAmmo: 5, speed: 35, color: '#ef4444' },
    SMG: { name: 'SMG', type: 'primary', damage: 10, fireRate: 50, maxAmmo: 40, speed: 22, color: '#22c55e' },
    Bow: { name: 'Bow', type: 'primary', damage: 50, fireRate: 1000, maxAmmo: 1, speed: 15, color: '#a855f7', special: 'doublejump' },
    BurstRifle: { name: 'Burst Rifle', type: 'primary', damage: 18, fireRate: 600, maxAmmo: 15, speed: 22, color: '#3b82f6', burst: 3 },
    Crossbow: { name: 'Crossbow', type: 'primary', damage: 75, fireRate: 1000, maxAmmo: 1, speed: 18, color: '#92400e' },
    RPG: { name: 'RPG', type: 'primary', damage: 100, fireRate: 1500, maxAmmo: 1, speed: 10, color: '#dc2626', explosive: true, splash: 50 },
    Minigun: { name: 'Minigun', type: 'primary', damage: 8, fireRate: 50, maxAmmo: 300, speed: 18, color: '#737373', spinup: 800 },
    Flamethrower: { name: 'Flamethrower', type: 'primary', damage: 5, fireRate: 30, maxAmmo: 100, speed: 8, color: '#f97316', burn: true, dps: 85 },
    GrenadeLauncher: { name: 'Grenade Launcher', type: 'primary', damage: 80, fireRate: 600, maxAmmo: 6, speed: 12, color: '#854d0e', explosive: true, splash: 40 },
    EnergyRifle: { name: 'Energy Rifle', type: 'primary', damage: 20, fireRate: 300, maxAmmo: 999, speed: 25, color: '#06b6d4', bounce: 2 },
    Gunblade: { name: 'Gunblade', type: 'primary', damage: 45, fireRate: 750, maxAmmo: 12, speed: 14, color: '#e11d48', meleeDamage: 35 },
    PaintballGun: { name: 'Paintball Gun', type: 'primary', damage: 18, fireRate: 150, maxAmmo: 16, speed: 16, color: '#d946ef', blind: true },

    // === SECONDARY WEAPONS ===
    Handgun: { name: 'Handgun', type: 'secondary', damage: 20, fireRate: 250, maxAmmo: 12, speed: 18, color: '#aaa' },
    Exogun: { name: 'Exogun', type: 'secondary', damage: 25, fireRate: 300, maxAmmo: 10, speed: 16, color: '#a855f7' },
    Revolver: { name: 'Revolver', type: 'secondary', damage: 40, fireRate: 400, maxAmmo: 6, speed: 20, color: '#b45309', fan: true },
    Shorty: { name: 'Shorty', type: 'secondary', damage: 12, fireRate: 120, maxAmmo: 2, speed: 10, color: '#78716c', count: 10 },
    Uzi: { name: 'Uzi', type: 'secondary', damage: 9, fireRate: 60, maxAmmo: 25, speed: 20, color: '#525252' },
    FlareGun: { name: 'Flare Gun', type: 'secondary', damage: 15, fireRate: 800, maxAmmo: 2, speed: 14, color: '#fb923c', burn: true, dot: 50 },
    Slingshot: { name: 'Slingshot', type: 'secondary', damage: 30, fireRate: 500, maxAmmo: 1, speed: 22, color: '#a16207' },

    // === MELEE WEAPONS ===
    Fists: { name: 'Fists', type: 'melee', damage: 25, fireRate: 500, maxAmmo: 0, speed: 0, color: '#22c55e', special: 'doublejump' },
    Knife: { name: 'Knife', type: 'melee', damage: 35, fireRate: 400, maxAmmo: 0, speed: 0, color: '#aaa' },
    Daggers: { name: 'Daggers', type: 'melee', damage: 20, fireRate: 300, maxAmmo: 0, speed: 5, color: '#22d3ee', speedboost: true },
    Katana: { name: 'Katana', type: 'melee', damage: 45, fireRate: 500, maxAmmo: 0, speed: 0, color: '#f43f5e', reflect: true },
    BattleAxe: { name: 'Battle Axe', type: 'melee', damage: 60, fireRate: 800, maxAmmo: 0, speed: 0, color: '#7c2d12' },
    Chainsaw: { name: 'Chainsaw', type: 'melee', damage: 15, fireRate: 100, maxAmmo: 0, speed: 0, color: '#facc15', speedboost: true, dps: 150 },
    Scythe: { name: 'Scythe', type: 'melee', damage: 55, fireRate: 700, maxAmmo: 0, speed: 0, color: '#7c3aed' },
    RiotShield: { name: 'Riot Shield', type: 'melee', damage: 20, fireRate: 600, maxAmmo: 0, speed: 0, color: '#2563eb', block: true },
    Trowel: { name: 'Trowel', type: 'melee', damage: 30, fireRate: 450, maxAmmo: 0, speed: 0, color: '#65a30d', build: true },

    // === UTILITY ===
    Grenade: { name: 'Grenade', type: 'utility', damage: 80, fireRate: 1500, maxAmmo: 2, speed: 12, color: '#ef4444', explosive: true },
    Medkit: { name: 'Medkit', type: 'utility', heal: 50, fireRate: 3000, maxAmmo: 2, color: '#4ade80' },
    Flashbang: { name: 'Flashbang', type: 'utility', damage: 0, fireRate: 2000, maxAmmo: 2, speed: 14, color: '#fef08a', blind: true, duration: 3000 },
    FreezeRay: { name: 'Freeze Ray', type: 'utility', damage: 10, fireRate: 200, maxAmmo: 50, speed: 10, color: '#7dd3fc', slow: 0.5 },
    JumpPad: { name: 'Jump Pad', type: 'utility', damage: 0, fireRate: 5000, maxAmmo: 3, speed: 0, color: '#34d399', launch: true },
    Molotov: { name: 'Molotov', type: 'utility', damage: 15, fireRate: 2000, maxAmmo: 1, speed: 12, color: '#ea580c', burn: true, zone: true, duration: 5000 }
};

// Load users from file
function loadUsers() {
    try {
        if (fs.existsSync('users.json')) {
            const data = JSON.parse(fs.readFileSync('users.json', 'utf8'));
            data.forEach(user => {
                // Migration: ensure new fields exist on old users
                if (!user.tasks) user.tasks = [];
                if (user.xp === undefined) user.xp = 0;
                if (user.level === undefined) user.level = 1;
                if (user.keys === undefined) user.keys = 10;
                users.set(user.username, user);
            });
        }
    } catch (e) {
        console.log('No saved users yet');
    }
}

// Save users to file
function saveUsers() {
    const data = Array.from(users.values());
    fs.writeFileSync('users.json', JSON.stringify(data, null, 2));
}

// Create new user
function createUser(username, password) {
    if (users.has(username)) {
        return { success: false, message: 'Username taken' };
    }

    const user = {
        username,
        password, // In production, hash this!
        level: 1,
        keys: 10, // Starting keys
        xp: 0,
        wins: 0,
        losses: 0,
        kills: 0,
        deaths: 0,
        inventory: ['AssaultRifle', 'Handgun', 'Fists', 'Grenade'],
        equipped: {
            primary: 'AssaultRifle',
            secondary: 'Handgun',
            melee: 'Fists',
            utility: 'Grenade'
        },
        tasks: [],
        created: Date.now()
    };

    // Assign initial tasks
    assignTasks(user);

    users.set(username, user);
    saveUsers();
    return { success: true, user };
}

// Verify user
function verifyUser(username, password) {
    const user = users.get(username);
    if (!user || user.password !== password) {
        return null;
    }
    return user;
}

// Generate room ID
function generateRoomId() {
    return Math.random().toString(36).substring(2, 8).toUpperCase();
}

// Create new room
function createRoom(mode, hostUsername) {
    const roomId = generateRoomId();
    const room = {
        id: roomId,
        mode: mode, // '1v1', '2v2', '5v5'
        host: hostUsername,
        players: [],
        gameState: 'lobby', // lobby, playing, roundEnd
        map: 'arena',
        scores: { red: 0, blue: 0 },
        round: 1,
        time: 120,
        spectators: [],
        maxPlayers: mode === '1v1' ? 2 : mode === '2v2' ? 4 : 10
    };

    rooms.set(roomId, room);
    return room;
}

// Initialize match tracking for a player
function initMatchTracking(socketId) {
    matchTracking.set(socketId, {
        kills: 0,
        damage: 0,
        roundsWon: 0,
        weaponsUsed: new Set(),
        meleeKills: 0,
        sniperKills: 0,
        matchesPlayed: 0
    });
}

// Update task progress for a user
function updateTaskProgress(user, stat, amount) {
    if (!user.tasks) return;
    let updated = false;
    user.tasks.forEach(task => {
        if (task.stat === stat && !task.claimed) {
            task.progress = Math.min(task.target, task.progress + amount);
            updated = true;
        }
    });
    return updated;
}

// Socket.IO connection
io.on('connection', (socket) => {
    console.log('Player connected:', socket.id);

    let currentUser = null;
    let currentRoom = null;

    // Register
    socket.on('register', (data, callback) => {
        console.log('Register attempt:', data.username);
        const result = createUser(data.username, data.password);
        console.log('Register result:', result);
        callback(result);
    });

    // Login
    socket.on('login', (data, callback) => {
        console.log('Login attempt:', data.username);
        const user = verifyUser(data.username, data.password);
        if (user) {
            currentUser = user;
            sessions.set(socket.id, user.username);
            // Assign tasks if none exist or refresh them on login
            if (!user.tasks || user.tasks.length === 0) {
                assignTasks(user);
                saveUsers();
            }
            console.log('Login success:', data.username);
            callback({ success: true, user });
        } else {
            console.log('Login failed for:', data.username);
            callback({ success: false, message: 'Invalid credentials' });
        }
    });

    // Logout
    socket.on('logout', () => {
        if (currentRoom) {
            leaveRoom(socket);
        }
        currentUser = null;
        sessions.delete(socket.id);
    });

    // ============== SHOP EVENTS ==============
    socket.on('getShop', (callback) => {
        if (!currentUser) return;
        const shopData = {};
        for (const [weaponKey, shopInfo] of Object.entries(weaponPrices)) {
            const wep = weapons[weaponKey];
            shopData[weaponKey] = {
                name: wep ? wep.name : weaponKey,
                type: wep ? wep.type : 'unknown',
                damage: wep ? (wep.damage || 0) : 0,
                fireRate: wep ? (wep.fireRate || 0) : 0,
                price: shopInfo.price,
                levelReq: shopInfo.levelReq,
                owned: currentUser.inventory.includes(weaponKey),
                canAfford: currentUser.keys >= shopInfo.price,
                meetsLevel: currentUser.level >= shopInfo.levelReq
            };
        }
        callback({
            shop: shopData,
            keys: currentUser.keys,
            level: currentUser.level,
            xp: currentUser.xp,
            xpNeeded: getTotalXPForLevel(currentUser.level) + xpNeededForLevel(currentUser.level)
        });
    });

    socket.on('buyWeapon', (weaponKey, callback) => {
        if (!currentUser) {
            callback({ success: false, message: 'Not logged in' });
            return;
        }
        const shopInfo = weaponPrices[weaponKey];
        if (!shopInfo) {
            callback({ success: false, message: 'Unknown weapon' });
            return;
        }
        if (currentUser.inventory.includes(weaponKey)) {
            callback({ success: false, message: 'Already owned' });
            return;
        }
        if (currentUser.level < shopInfo.levelReq) {
            callback({ success: false, message: `Need level ${shopInfo.levelReq}` });
            return;
        }
        if (currentUser.keys < shopInfo.price) {
            callback({ success: false, message: 'Not enough keys' });
            return;
        }
        currentUser.keys -= shopInfo.price;
        currentUser.inventory.push(weaponKey);
        saveUsers();
        callback({ success: true, keys: currentUser.keys, inventory: currentUser.inventory });
    });

    // ============== TASK EVENTS ==============
    socket.on('getTasks', (callback) => {
        if (!currentUser) return;
        callback({
            tasks: currentUser.tasks || [],
            keys: currentUser.keys,
            level: currentUser.level,
            xp: currentUser.xp,
            xpNeeded: getTotalXPForLevel(currentUser.level) + xpNeededForLevel(currentUser.level)
        });
    });

    socket.on('claimTask', (taskId, callback) => {
        if (!currentUser) {
            callback({ success: false, message: 'Not logged in' });
            return;
        }
        const task = (currentUser.tasks || []).find(t => t.id === taskId);
        if (!task) {
            callback({ success: false, message: 'Task not found' });
            return;
        }
        if (task.claimed) {
            callback({ success: false, message: 'Already claimed' });
            return;
        }
        if (task.progress < task.target) {
            callback({ success: false, message: 'Task not complete' });
            return;
        }
        task.claimed = true;
        currentUser.keys += task.rewardKeys;
        addXP(currentUser, task.rewardXP, socket);
        saveUsers();
        callback({
            success: true,
            keys: currentUser.keys,
            xp: currentUser.xp,
            level: currentUser.level,
            xpNeeded: getTotalXPForLevel(currentUser.level) + xpNeededForLevel(currentUser.level)
        });
    });

    socket.on('refreshTasks', (callback) => {
        if (!currentUser) return;
        // Only allow refresh if all tasks are claimed
        const allClaimed = (currentUser.tasks || []).every(t => t.claimed);
        if (allClaimed) {
            assignTasks(currentUser);
            saveUsers();
            callback({ success: true, tasks: currentUser.tasks });
        } else {
            callback({ success: false, message: 'Complete all current tasks first' });
        }
    });

    // Create room
    socket.on('createRoom', (mode, callback) => {
        if (!currentUser) {
            callback({ success: false, message: 'Not logged in' });
            return;
        }

        const room = createRoom(mode, currentUser.username);
        room.players.push({
            username: currentUser.username,
            socketId: socket.id,
            team: 'blue',
            ready: true,
            loadout: currentUser.equipped
        });

        currentRoom = room;
        socket.join(room.id);
        callback({ success: true, room });

        // Notify others
        io.to(room.id).emit('roomUpdate', room);
    });

    // Join room
    socket.on('joinRoom', (roomId, callback) => {
        if (!currentUser) {
            callback({ success: false, message: 'Not logged in' });
            return;
        }

        const room = rooms.get(roomId);
        if (!room) {
            callback({ success: false, message: 'Room not found' });
            return;
        }

        if (room.players.length >= room.maxPlayers) {
            callback({ success: false, message: 'Room full' });
            return;
        }

        if (room.gameState !== 'lobby') {
            callback({ success: false, message: 'Game already started' });
            return;
        }

        // Assign team
        const redCount = room.players.filter(p => p.team === 'red').length;
        const blueCount = room.players.filter(p => p.team === 'blue').length;
        const team = redCount <= blueCount ? 'red' : 'blue';

        room.players.push({
            username: currentUser.username,
            socketId: socket.id,
            team: team,
            ready: false,
            loadout: currentUser.equipped
        });

        currentRoom = room;
        socket.join(room.id);

        callback({ success: true, room });
        io.to(room.id).emit('roomUpdate', room);
    });

    // Leave room
    socket.on('leaveRoom', () => {
        leaveRoom(socket);
    });

    // Set ready
    socket.on('setReady', (ready) => {
        if (!currentRoom || !currentUser) return;

        const player = currentRoom.players.find(p => p.username === currentUser.username);
        if (player) {
            player.ready = ready;
            io.to(currentRoom.id).emit('roomUpdate', currentRoom);

            // Check if all ready and enough players
            const allReady = currentRoom.players.every(p => p.ready);
            const minPlayers = currentRoom.mode === '1v1' ? 2 : currentRoom.mode === '2v2' ? 4 : 10;
            if (allReady && currentRoom.players.length >= minPlayers) {
                startGame(currentRoom);
            }
        }
    });

    // Set loadout
    socket.on('setLoadout', (loadout, callback) => {
        if (!currentUser) return;

        // Validate weapons
        for (const key in loadout) {
            const weapon = loadout[key];
            if (weapon && !currentUser.inventory.includes(weapon)) {
                callback({ success: false, message: `You don't own ${weapon}` });
                return;
            }
        }

        currentUser.equipped = loadout;

        // Update room if in one
        if (currentRoom) {
            const player = currentRoom.players.find(p => p.username === currentUser.username);
            if (player) {
                player.loadout = loadout;
                io.to(currentRoom.id).emit('roomUpdate', currentRoom);
            }
        }

        callback({ success: true });
    });

    // Switch team
    socket.on('switchTeam', (callback) => {
        if (!currentRoom || !currentUser) return;

        const player = currentRoom.players.find(p => p.username === currentUser.username);
        if (player) {
            player.team = player.team === 'red' ? 'blue' : 'red';
            io.to(currentRoom.id).emit('roomUpdate', currentRoom);
        }
    });

    // Player input / movement sync
    socket.on('playerUpdate', (data) => {
        if (!currentRoom || currentRoom.gameState !== 'playing') return;

        // Broadcast to other players in room
        socket.to(currentRoom.id).emit('playerMoved', {
            username: currentUser.username,
            ...data
        });
    });

    // Shoot event
    socket.on('shoot', (data) => {
        if (!currentRoom || currentRoom.gameState !== 'playing') return;

        // Track weapon used
        const tracking = matchTracking.get(socket.id);
        if (tracking && data.weaponKey) {
            tracking.weaponsUsed.add(data.weaponKey);
        }

        socket.to(currentRoom.id).emit('bulletFired', {
            username: currentUser.username,
            ...data
        });
    });

    // Hit event
    socket.on('hit', (data) => {
        if (!currentRoom || currentRoom.gameState !== 'playing') return;

        // Update stats
        const targetUser = users.get(data.target);
        if (targetUser) {
            targetUser.deaths++;
        }
        currentUser.kills++;

        // Track damage for tasks
        const tracking = matchTracking.get(socket.id);
        if (tracking) {
            tracking.damage += (data.damage || 0);
            if (data.weaponKey) {
                tracking.weaponsUsed.add(data.weaponKey);
            }
        }

        // Update task progress for damage
        updateTaskProgress(currentUser, 'damage', data.damage || 0);

        socket.to(currentRoom.id).emit('playerHit', {
            target: data.target,
            damage: data.damage,
            attacker: currentUser.username
        });
    });

    // Kill event
    socket.on('kill', (data) => {
        if (!currentRoom) return;

        // Mark player as dead
        const victim = currentRoom.players.find(p => p.username === data.target);
        if (victim) victim.alive = false;

        // Track kills
        const tracking = matchTracking.get(socket.id);
        if (tracking) {
            tracking.kills++;
            // Check weapon type for melee/sniper kills
            if (data.weaponKey) {
                const wep = weapons[data.weaponKey];
                if (wep && wep.type === 'melee') {
                    tracking.meleeKills++;
                }
                if (data.weaponKey === 'Sniper') {
                    tracking.sniperKills++;
                }
                tracking.weaponsUsed.add(data.weaponKey);
            }
        }

        // Update task progress for kills
        updateTaskProgress(currentUser, 'kills', 1);
        if (data.weaponKey) {
            const wep = weapons[data.weaponKey];
            if (wep && wep.type === 'melee') {
                updateTaskProgress(currentUser, 'meleeKills', 1);
            }
            if (data.weaponKey === 'Sniper') {
                updateTaskProgress(currentUser, 'sniperKills', 1);
            }
        }

        // XP for kills
        addXP(currentUser, 10, socket);

        io.to(currentRoom.id).emit('playerKilled', {
            victim: data.target,
            killer: currentUser.username
        });

        // Check win condition
        const redAlive = currentRoom.players.filter(p => p.team === 'red' && p.alive).length;
        const blueAlive = currentRoom.players.filter(p => p.team === 'blue' && p.alive).length;

        if (redAlive === 0) {
            currentRoom.scores.blue++;

            // Award round win XP and tracking to blue team
            currentRoom.players.forEach(p => {
                if (p.team === 'blue') {
                    const pUser = users.get(p.username);
                    const pTracking = matchTracking.get(p.socketId);
                    if (pUser) {
                        addXP(pUser, 25, io.sockets.sockets.get(p.socketId));
                        updateTaskProgress(pUser, 'roundsWon', 1);
                    }
                    if (pTracking) pTracking.roundsWon++;
                }
            });

            io.to(currentRoom.id).emit('roundEnd', { winner: 'blue', scores: currentRoom.scores, round: currentRoom.round });

            if (currentRoom.scores.blue >= 5) {
                setTimeout(() => endGame(currentRoom, 'blue'), 3000);
            } else {
                setTimeout(() => startRound(currentRoom), 3000);
            }
        } else if (blueAlive === 0) {
            currentRoom.scores.red++;

            // Award round win XP and tracking to red team
            currentRoom.players.forEach(p => {
                if (p.team === 'red') {
                    const pUser = users.get(p.username);
                    const pTracking = matchTracking.get(p.socketId);
                    if (pUser) {
                        addXP(pUser, 25, io.sockets.sockets.get(p.socketId));
                        updateTaskProgress(pUser, 'roundsWon', 1);
                    }
                    if (pTracking) pTracking.roundsWon++;
                }
            });

            io.to(currentRoom.id).emit('roundEnd', { winner: 'red', scores: currentRoom.scores, round: currentRoom.round });

            if (currentRoom.scores.red >= 5) {
                setTimeout(() => endGame(currentRoom, 'red'), 3000);
            } else {
                setTimeout(() => startRound(currentRoom), 3000);
            }
        }
    });

    // Get room list
    socket.on('getRooms', (callback) => {
        const roomList = Array.from(rooms.values())
            .filter(r => r.gameState === 'lobby')
            .map(r => ({
                id: r.id,
                mode: r.mode,
                players: r.players.length,
                maxPlayers: r.maxPlayers,
                host: r.host
            }));
        callback(roomList);
    });

    // Get user data
    socket.on('getUserData', (callback) => {
        if (currentUser) {
            callback(currentUser);
        }
    });

    // Disconnect
    socket.on('disconnect', () => {
        console.log('Player disconnected:', socket.id);

        if (currentRoom) {
            leaveRoom(socket);
        }

        matchTracking.delete(socket.id);
        sessions.delete(socket.id);
    });

    // Helper functions
    function leaveRoom(socket) {
        if (!currentRoom || !currentUser) return;

        const playerIndex = currentRoom.players.findIndex(p => p.username === currentUser.username);
        if (playerIndex !== -1) {
            currentRoom.players.splice(playerIndex, 1);
        }

        socket.leave(currentRoom.id);

        if (currentRoom.players.length === 0) {
            rooms.delete(currentRoom.id);
        } else {
            // If host left, assign new host
            if (currentRoom.host === currentUser.username && currentRoom.players.length > 0) {
                currentRoom.host = currentRoom.players[0].username;
            }

            io.to(currentRoom.id).emit('roomUpdate', currentRoom);
        }

        matchTracking.delete(socket.id);
        currentRoom = null;
    }

    function startGame(room) {
        room.gameState = 'playing';
        room.scores = { red: 0, blue: 0 };
        room.round = 1;

        // Initialize match tracking for all players
        room.players.forEach(p => {
            initMatchTracking(p.socketId);
            p.alive = true;
            p.health = 100;
            p.position = getSpawnPosition(room, p.team);
        });

        io.to(room.id).emit('gameStart', {
            map: room.map,
            mode: room.mode,
            players: room.players
        });

        // Send round start with positions
        io.to(room.id).emit('roundStart', {
            round: room.round,
            time: room.time,
            positions: room.players.map(p => ({ username: p.username, position: p.position }))
        });
    }

    function startRound(room) {
        room.round++;
        room.time = 120;

        // Respawn all players
        room.players.forEach(p => {
            p.alive = true;
            p.health = 100;
            p.position = getSpawnPosition(room, p.team);
        });

        io.to(room.id).emit('roundStart', {
            round: room.round,
            time: room.time,
            positions: room.players.map(p => ({ username: p.username, position: p.position }))
        });
    }

    function endGame(room, winner) {
        room.gameState = 'ended';

        // Calculate and send rewards to each player
        room.players.forEach(p => {
            const user = users.get(p.username);
            const tracking = matchTracking.get(p.socketId);
            const pSocket = io.sockets.sockets.get(p.socketId);
            if (!user) return;

            const isWinner = p.team === winner;
            if (isWinner) {
                user.wins++;
            } else {
                user.losses++;
            }

            // Calculate rewards
            let xpEarned = 15; // match participation
            let keysEarned = 2; // match participation
            const breakdown = {
                participation: { xp: 15, keys: 2 },
                roundWins: { xp: 0, keys: 0 },
                matchWin: { xp: 0, keys: 0 },
                kills: { xp: 0, keys: 0 }
            };

            // Round wins already awarded incrementally, but include in breakdown
            if (tracking) {
                breakdown.roundWins.xp = tracking.roundsWon * 25;
                // kills XP already awarded incrementally
                breakdown.kills.xp = tracking.kills * 10;

                // Weapons used task
                updateTaskProgress(user, 'weaponsUsed', tracking.weaponsUsed.size);
            }

            if (isWinner) {
                xpEarned += 50;
                keysEarned += 5;
                breakdown.matchWin = { xp: 50, keys: 5 };
                updateTaskProgress(user, 'matchWins', 1);
            }

            // Apply participation rewards (round/kill XP already given incrementally)
            addXP(user, 15, pSocket); // participation XP
            user.keys += keysEarned;

            // Match played task
            updateTaskProgress(user, 'matchesPlayed', 1);
            if (tracking) tracking.matchesPlayed++;

            // Send rewards breakdown to player
            if (pSocket) {
                pSocket.emit('matchRewards', {
                    xpEarned: xpEarned + (tracking ? tracking.roundsWon * 25 + tracking.kills * 10 : 0),
                    keysEarned,
                    breakdown,
                    newXP: user.xp,
                    newKeys: user.keys,
                    newLevel: user.level,
                    xpNeeded: getTotalXPForLevel(user.level) + xpNeededForLevel(user.level),
                    tasks: user.tasks,
                    isWinner
                });
            }
        });

        saveUsers();

        io.to(room.id).emit('gameEnd', {
            winner: winner,
            scores: room.scores
        });
    }

    function getSpawnPosition(room, team) {
        const mapSize = 100;
        const side = team === 'red' ? -1 : 1;
        return {
            x: side * (mapSize / 4),
            y: 2,
            z: -mapSize / 4
        };
    }
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
    console.log(`RIVALS Server running on port ${PORT}`);
    loadUsers();
});
