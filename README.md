# RIVALS Multiplayer

A fast-paced multiplayer browser-based game featuring real-time combat, skill-based gameplay, and diverse weapon systems. Built with **Express.js** and **Socket.io** for seamless multiplayer experiences.

## Features

- **Real-Time Multiplayer Combat** - Play against other players in live game rooms
- **Diverse Weapon System** - Choose from 8+ unique weapons with different mechanics:
  - Assault Rifle, Shotgun, Sniper, SMG
  - Handgun, Exogun
  - Melee weapons (Fists, Knife)
- **Skill-Based Gameplay** - Master weapon mechanics, movement, and strategy
- **Room-Based Matchmaking** - Join or create game rooms (up to 10 players per room)
- **User Progression System** - Level up, gain XP, and unlock new content
- **Inventory & Stats Tracking** - Track your performance and loadouts

## Tech Stack

- **Backend**: Node.js, Express.js
- **Real-Time Communication**: Socket.io
- **Frontend**: HTML5 Canvas, Vanilla JavaScript
- **Data Storage**: JSON (file-based in current version)

## Getting Started

### Prerequisites

- Node.js v14+ installed
- npm package manager

### Installation

1. Clone the repository:
```bash
git clone https://github.com/raufzidaan-coder/rivals-multiplayer.git
cd rivals-multiplayer
```

2. Install dependencies:
```bash
npm install
```

3. Start the server:
```bash
npm start
```

4. Open your browser and navigate to:
```
http://localhost:3000
```

## How to Play

1. **Create Account** - Sign up with a username and password
2. **Join Room** - Enter an existing room or create a new one
3. **Select Weapon** - Choose your primary and secondary weapons
4. **Battle** - Engage in combat with other players
5. **Level Up** - Earn XP from matches to increase your level

## Game Mechanics

- **Weapons**: Each weapon has unique damage, fire rate, ammo capacity, and projectile speed
- **Movement**: Navigate the game arena and use positioning to your advantage
- **Scoring**: Earn points for eliminating opponents
- **Inventory**: Manage your equipment and upgrades

## Project Structure

```
rivals-multiplayer/
├── server.js           # Main Express server & Socket.io logic
├── package.json        # Dependencies configuration
├── public/             # Frontend assets
│   └── index.html      # Game client
├── users.json          # User data storage
└── README.md           # This file
```

## API Events

### Client → Server
- `register` - Create a new user account
- `login` - Authenticate user
- `join_room` - Join a game room
- `player_move` - Update player position
- `shoot` - Fire weapon
- `select_weapon` - Change active weapon

### Server → Client
- `player_joined` - New player joined the room
- `player_moved` - Another player moved
- `hit` - Player was shot
- `room_state` - Game state update
- `game_over` - Match ended

## Future Enhancements

- [ ] Database integration (MongoDB, PostgreSQL)
- [ ] Persistent user profiles and rankings
- [ ] Advanced matchmaking system
- [ ] More weapons and game modes
- [ ] Mobile support
- [ ] Spectator mode
- [ ] Clan/Team system
- [ ] Anti-cheat measures

## Contributing

Contributions are welcome! Feel free to submit pull requests or report issues.

## License

MIT License - feel free to use this project for your own purposes.

## Author

Created by **raufzidaan-coder**

---

**Enjoy the game and have fun battling!** 🎮🔫
