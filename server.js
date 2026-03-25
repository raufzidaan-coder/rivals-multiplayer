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
            data.forEach(user => users.set(user.username, user));
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
        created: Date.now()
    };
    
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
        
        socket.to(currentRoom.id).emit('playerHit', {
            target: data.target,
            damage: data.damage,
            attacker: currentUser.username
        });
    });
    
    // Kill event
    socket.on('kill', (data) => {
        if (!currentRoom) return;
        
        io.to(currentRoom.id).emit('playerKilled', {
            victim: data.target,
            killer: currentUser.username
        });
        
        // Check win condition
        const redAlive = currentRoom.players.filter(p => p.team === 'red' && p.alive).length;
        const blueAlive = currentRoom.players.filter(p => p.team === 'blue' && p.alive).length;
        
        if (redAlive === 0) {
            currentRoom.scores.blue++;
            io.to(currentRoom.id).emit('roundEnd', { winner: 'blue', scores: currentRoom.scores });
            
            if (currentRoom.scores.blue >= 5) {
                endGame(currentRoom, 'blue');
            } else {
                startRound(currentRoom);
            }
        } else if (blueAlive === 0) {
            currentRoom.scores.red++;
            io.to(currentRoom.id).emit('roundEnd', { winner: 'red', scores: currentRoom.scores });
            
            if (currentRoom.scores.red >= 5) {
                endGame(currentRoom, 'red');
            } else {
                startRound(currentRoom);
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
        
        currentRoom = null;
    }
    
    function startGame(room) {
        room.gameState = 'playing';
        room.scores = { red: 0, blue: 0 };
        room.round = 1;
        
        // Reset player states and set spawn positions
        room.players.forEach(p => {
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
        
        // Update stats
        room.players.forEach(p => {
            const user = users.get(p.username);
            if (user) {
                if (p.team === winner) {
                    user.wins++;
                } else {
                    user.losses++;
                }
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
