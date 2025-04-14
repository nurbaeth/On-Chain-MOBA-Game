// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Chain1v1 {
    struct Hero {
        string name;
        uint256 health;
        uint256 damage;
        uint256 cooldown; // in blocks
        uint256 lastAttackBlock;
        uint256 wins;
    }

    address public player1;
    address public player2;

    mapping(address => Hero) public heroes;
    address public currentTurn;

    bool public gameStarted;

    modifier onlyPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "Not a player");
        _;
    }

    modifier isTurn() {
        require(msg.sender == currentTurn, "Not your turn");
        _;
    }

    modifier gameInProgress() {
        require(gameStarted, "Game not started");
        _;
    }

    function joinGame(string memory _name) external {
        require(!gameStarted, "Game already started");

        if (player1 == address(0)) {
            player1 = msg.sender;
            heroes[msg.sender] = Hero(_name, 100, 20, 1, 0, 0);
        } else if (player2 == address(0)) {
            require(msg.sender != player1, "Already joined");
            player2 = msg.sender;
            heroes[msg.sender] = Hero(_name, 100, 20, 1, 0, 0);
            gameStarted = true;
            currentTurn = player1;
        }
    }

    function attack() external onlyPlayers isTurn gameInProgress {
        Hero storage attacker = heroes[msg.sender];
        address opponentAddr = msg.sender == player1 ? player2 : player1;
        Hero storage defender = heroes[opponentAddr];

        require(block.number > attacker.lastAttackBlock + attacker.cooldown, "Cooldown not finished");
        require(defender.health > 0, "Opponent already defeated");

        if (defender.health <= attacker.damage) {
            defender.health = 0;
            attacker.wins += 1;
            gameStarted = false;
        } else {
            defender.health -= attacker.damage;
        }

        attacker.lastAttackBlock = block.number;
        currentTurn = opponentAddr;
    }

    function getHero(address _player) external view returns (Hero memory) {
        return heroes[_player];
    }

    function resetGame() external {
        require(!gameStarted, "Game still in progress");
        require(msg.sender == player1 || msg.sender == player2, "Not a player");

        heroes[player1].health = 100;
        heroes[player2].health = 100;
        heroes[player1].lastAttackBlock = 0;
        heroes[player2].lastAttackBlock = 0;

        currentTurn = player1;
        gameStarted = true;
    }
}
