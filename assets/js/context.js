import { 
  loadTextures, cardPath, handCardCoord, makeRenderer, makeContainer, makePlayable, makeUnplayable,
  makeDeckSprite, makeTableSprite, makeHandSprites, makeHeldSprite,  makePlayerText,
  PLAYER_TURN_COLOR, NOT_PLAYER_TURN_COLOR, makeRoundText, makeTurnText, makeOverText,
} from "./canvas";

import { 
  updateTweens, handTweens, tweenWiggle, 
  tweenDeck, tweenTable, tweenTakeDeck, tweenTakeTable, tweenDiscard, tweenSwapTable 
} from "./tweens";

import { playArcade1, playCute, playDreamy } from "./sounds";

const HAND_SIZE = 6;

function rotate(arr, n) {
  return arr.slice(n).concat(arr.slice(0, n));
}

function sortByScore(players) {
  return [...players].sort((a, b) => a.score - b.score);
}

function initSprites() {
  return {
    hands: { bottom: [], left: [], top: [], right: [], },
    table: [],
    players: {},
  }
}

export class GameContext {
  constructor(game, parentEl, pushEvent) {
    this.game = game;
    this.parentEl = parentEl;
    this.pushEvent = pushEvent;

    this.stage = makeContainer();
    this.renderer = makeRenderer(this.parentEl.clientWidth, this.parentEl.clientHeight);
    this.sprites = initSprites();

    loadTextures().then(textures => {
      this.textures = textures;

      // Clear prev children. Otherwise, if the websocket conn is dropped and reconnected it will draw the canvas twice.
      this.parentEl.replaceChildren();
      this.parentEl.appendChild(this.renderer.view);

      this.addSprites();
      requestAnimationFrame(time => this.draw(time));

      window.addEventListener("resize", () => this.resize());
    });
  }

  draw(time) {
    requestAnimationFrame(time => this.draw(time));
    updateTweens(time);
    this.renderer.render(this.stage);
  }

  // sprites

  addSprites() {
    this.addRoundText();
    this.addTurnText();
    this.addDeck();

    if (this.game.state !== "no_round") {
      this.addTableCards();

      for (const player of this.game.players) {
        this.addHand(player);
        this.addPlayerText(player);

        if (player.heldCard) {
          this.addHeldCard(player);
        }
      }
    } else {
      this.game.players.forEach(p => this.addPlayerText(p));
    }

    if (this.game.state === "game_over" || this.game.state === "round_over") {
      const winnerName = this.findWinner().username;
      this.addOverText(winnerName);
    }
  }

  addDeck() {
    const sprite = makeDeckSprite(
      this.parentEl.clientWidth,
      this.parentEl.clientHeight,
      this.textures, 
      this.game.state
    );
    
    this.sprites.deck = sprite;
    this.stage.addChild(sprite);

    if (this.isPlayable(this.game, "deck")) {
      makePlayable(sprite, () => this.onDeckClick(this.game.playerId));
    }
  }

  addTableCards() {
    const card0 = this.game.tableCards[0];
    const card1 = this.game.tableCards[1];

    // add the second card first, so it's on bottom
    if (card1) {
      this.addTableCard(card1);
    }

    if (card0) {
      this.addTableCard(card0);

      if (this.isPlayable(this.game, "table")) {
        makePlayable(this.sprites.table[0], () => this.onTableClick(this.game.playerId));
      }
    }
  }

  addTableCard(card) {
    const sprite = makeTableSprite(
      this.parentEl.clientWidth,
      this.parentEl.clientHeight,
      this.textures,
      card
    );
    
    this.sprites.table.unshift(sprite);
    this.stage.addChild(sprite);
  }

  addHand(player) {
    const sprites = makeHandSprites(
      this.parentEl.clientWidth,
      this.parentEl.clientHeight,
      this.textures, 
      player.hand, 
      player.position
    );

    const belongsToUser = player.id === this.game.playerId;

    sprites.forEach((sprite, i) => {
      if (belongsToUser && this.isPlayable(this.game, `hand_${i}`)) {
        makePlayable(sprite, () => this.onHandClick(player.id, i));
      }

      this.sprites.hands[player.position][i] = sprite;
      this.stage.addChild(sprite);
    });
  }

  addHeldCard(player) {
    const belongsToUser = player.id === this.game.playerId;

    const sprite = makeHeldSprite(
      this.parentEl.clientWidth,
      this.parentEl.clientHeight,
      this.textures, 
      player.heldCard, 
      player.position, 
      belongsToUser
    );
    
    this.sprites.held = sprite;
    this.stage.addChild(sprite);

    if (this.isPlayable(this.game, "held")) {
      if (this.sprites.table[0]) {
        makePlayable(this.sprites.table[0], () => this.onTableClick(player.id));
      } else {
        // makePlayable(this.sprites.held, () => this.onHeldClick(player.id));
      }
    }

  }

  addPlayerText(player) {
    const text = makePlayerText(
      this.parentEl.clientWidth,
      this.parentEl.clientHeight,
      player
    );
    
    this.stage.addChild(text);
    this.sprites.players[player.position] = text;

    if (player.canAct) {
      text.style.fill = PLAYER_TURN_COLOR;
    }
  }

  updatePlayerTexts(game) {
    for (const player of game.players) {
      const sprite = this.sprites.players[player.position];
      const points = player.score == 1 || player.score == -1 ? "pt" : "pts";
      const color = player.canAct ? PLAYER_TURN_COLOR : NOT_PLAYER_TURN_COLOR;
      
      sprite.text = `${player.username}(${player.score}${points})`;
      sprite.style.fill = color;
    }
  }

  addRoundText() {
    const text = makeRoundText(this.game.roundNum);
    this.stage.addChild(text);
    this.sprites.round = text;
  }

  addTurnText() {
    const text = makeTurnText(this.game.turn);
    this.stage.addChild(text);
    this.sprites.turn = text;
  }

  updateTurnText(game) {
    this.sprites.turn.text = `Turn ${game.turn}`;
  }

  addOverText(winnerName) {
    const sprite = makeOverText(
      this.parentEl.clientWidth, 
      this.parentEl.clientHeight, 
      winnerName
    );

    sprite.eventMode = "static";
    sprite.cursor = "hover"
    sprite.on("pointerdown", event => event.target.visible = false);

    this.stage.addChild(sprite);
    this.sprites.over = sprite;
  }

  // server events

  onGameStart(game) {
    this.game = game;

    const roundSprite = this.sprites.round;
    roundSprite.text = `Round ${game.roundNum}`;

    let hands = [];

    const firstPlayerIndex = game.players.findIndex(p => p.id == game.firstPlayerId);
    if (firstPlayerIndex == null) throw new Error("first player not found on game start");

    const players = rotate(game.players, firstPlayerIndex);

    const clientWidth = this.parentEl.clientWidth;
    const clientHeight = this.parentEl.clientHeight;

    for (let i = players.length-1; i >= 0; i--) {
      const player = players[i];
      this.addHand(player);

      const playerSprite = this.sprites.players[player.position];
      playerSprite.style.fill = PLAYER_TURN_COLOR;

      const tween = handTweens(clientWidth, clientHeight, this.sprites.hands[player.position]);
      hands.push(tween);
    };

    hands.reverse();
    hands.forEach((tweens, i) => {
      tweens.reverse();

      tweens.forEach((tween, j) => {
        const delay = (HAND_SIZE-1-j) * 150 + i * 1000;
        tween.delay(delay)
          .start();

        // start tweening the deck after dealing the first row to the last player
        if (i === game.players.length-1 && j === 2) {
          tween.onComplete(() => {
            tweenDeck(clientWidth, clientHeight, this.sprites.deck)
              .start()
              .onComplete(() => {
                this.addTableCards();

                tweenTable(clientWidth, clientHeight, this.sprites.table[0])
                  .start();
              });
          });
        }
      });
    });
  }

  onRoundStart(game) {
    if (this.sprites.over) {
      this.sprites.over.visible = false;
    }

    this.game = game;
    this.removeSprites();

    this.addDeck();
    this.sprites.deck.x = this.parentEl.clientWidth / 2;

    this.addRoundText();
    this.addTurnText();

    for (const player of this.game.players) {
      this.addPlayerText(player);
    }

    this.onGameStart(game);
  }

  onRoundOver() {
    playDreamy();

    confetti({
      particleCount: 100,
      spread: 70,
      origin: {y: 0.6},
    });

    const winnerName = this.findWinner().username;
    this.addOverText(winnerName);
  }

  onGameOver() {
    playCute();

    confetti({
      particleCount: 100,
      spread: 70,
      origin: {y: 0.6},
    });

    const players = sortByScore(this.game.players);
    const winnerName = players[0].username;
    this.addOverText(winnerName);
  }

  onGameEvent(game, event) {
    switch (event.action) {
      case "flip":
        this.onFlip(game, event);
        break;

      case "take_deck":
        this.onTakeDeck(game, event);
        break;

      case "take_table":
        this.onTakeTable(game, event);
        break;

      case "discard":
        this.onDiscard(game, event);
        break;

      case "swap":
        this.onSwap(game, event);
        break;

      default:
        throw new Error(`event does not have a valid action: ${event}`);
    }

    this.updatePlayerTexts(game);
    this.updateTurnText(game);
    this.game = game;
  }

  onFlip(game, event) {
    const playerIndex = game.players.findIndex(p => p.id === event.player_id);
    const player = game.players[playerIndex];
    if (!player) throw new Error("player is null on flip");

    // check if the other card in the same column is face up and matches the flipped card
    const rank = player.hand[event.hand_index].name[0];
    const colIndex = (event.hand_index + (HAND_SIZE / 2)) % HAND_SIZE;
    const colCard = player.hand[colIndex];
    const colRank = colCard["face_up?"] ? colCard.name[0] : null;

    if (rank === colRank || rank === "j") {
      playArcade1();
    }

    // const oldPlayer = this.game.players[playerIndex];
    // if (player.score >= oldPlayer.score + 10) {
    //   playArcade2();
    // }

    // get the sprite we need to update
    const handSprites = this.sprites.hands[player.position];
    const handSprite = handSprites[event.hand_index];
   
    // update the sprite's texture
    const cardName = player.hand[event.hand_index]["name"];
    handSprite.texture = this.textures[cardPath(cardName)];

    // wiggle the sprite
    const coord = handCardCoord(
      this.parentEl.clientWidth,
      this.parentEl.clientHeight,
      player.position,
      event.hand_index
    );

    tweenWiggle(handSprite, coord.x)
      .start();

    handSprites.forEach((sprite, i) => {
      if (!this.isPlayable(game, `hand_${i}`)) {
        makeUnplayable(sprite);
      }
    });

    if (this.isPlayable(game, "deck")) {
      makePlayable(this.sprites.deck, () => this.onDeckClick(game.playerId));
    }

    // a player could flip a hand card before the table card is drawn so we also need to check if it exists
    if (this.sprites.table[0] && this.isPlayable(game, "table")) {
      makePlayable(this.sprites.table[0], () => this.onTableClick(game.playerId));
    }
  }

  onTakeDeck(game, event) {
    const player = game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on take deck");

    this.addHeldCard(player);
    
    tweenTakeDeck(player.position, this.sprites.held, this.sprites.deck)
      .start();

    if (player.id === game.playerId) {
      makeUnplayable(this.sprites.deck);

      if (this.sprites.table[0]) {
        makePlayable(this.sprites.table[0], () => this.onTableClick(game.playerId));
      }

      const handSprites = this.sprites.hands[player.position];
      handSprites.forEach((sprite, i) => {
        makePlayable(sprite, () => this.onHandClick(player.id, i));
      });
    }
  }

  onTakeTable(game, event) {
    const player = game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on take table");

    this.addHeldCard(player);
    
    tweenTakeTable(player.position, this.sprites.held, this.sprites.table.shift())
      .start();

    if (player.id === game.playerId) {
      makeUnplayable(this.sprites.deck);

      if (this.sprites.table[0]) {
        makePlayable(this.sprites.table[0], () => this.onTableClick(player.id));
      } else {
        // makePlayable(this.sprites.held, () => this.onHeldClick(player.id));
      }

      const handSprites = this.sprites.hands[player.position];
      handSprites.forEach((sprite, index) => {
        makePlayable(sprite, () => this.onHandClick(player.id, index));
      });
    }
  }

  onDiscard(game, event) {
    const player = game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on discard");

    this.addTableCard(game.tableCards[0]);

    tweenDiscard(player.position, this.sprites.table[0], this.sprites.held)
      .start();

    this.sprites.held = null;

    this.sprites.hands[player.position].forEach((sprite, i) => {
      if (!this.isPlayable(game, `hand_${i}`)) {
        makeUnplayable(sprite);
      }

      // if the game is over, flip all the player's cards
      if (game.isFlipped) {
        const name = player.hand[i].name;
        sprite.texture = this.textures[cardPath(name)];
      }
    });

    if (this.isPlayable(game, "deck")) {
      makePlayable(this.sprites.deck, () => this.onDeckClick(game.playerId));
    }

    if (this.isPlayable(game, "table")) {
      makePlayable(this.sprites.table[0], () => this.onTableClick(game.playerId));
    }

    if (this.sprites.table[1]) {
      makeUnplayable(this.sprites.table[1]);
    }
  }

  onSwap(game, event) {
    const player = game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on swap");

    if (this.sprites.table[0]) {
      makeUnplayable(this.sprites.table[0]);
    }

    // add table card
    this.addTableCard(game.tableCards[0]);

    // change hand card texture
    const index = event.hand_index;
    const card = player.hand[index].name;

    const handSprites = this.sprites.hands[player.position];
    const handSprite = handSprites[index];
    const path = cardPath(card);
    handSprite.texture = this.textures[path];

    tweenSwapTable(
      this.parentEl.clientWidth,
      this.parentEl.clientHeight,
      this.sprites.table[0],
      handSprite
    )
      .start();

    // remove held card
    this.sprites.held.visible = false
    this.sprites.held = null;

    const rank = player.hand[event.hand_index].name[0];
    const colIndex = (event.hand_index + (HAND_SIZE / 2)) % HAND_SIZE;
    const colCard = player.hand[colIndex];
    const colRank = colCard["face_up?"] ? colCard.name[0] : null;

    if (rank === colRank) {
      playArcade1();
    }

    // if this is the last round, flip all the player's cards
    if (game.isFlipped) {
      handSprites.forEach((sprite, i) => {
        const card = player.hand[i].name;
        const path = cardPath(card);
        sprite.texture = this.textures[path];
      });
    }

    // if this is the current user's action make their hand unplayable
    if (player.id === game.playerId) {
      for (const sprite of handSprites) {
        makeUnplayable(sprite);
      }
    }

    if (this.isPlayable(game, "deck")) {
      makePlayable(this.sprites.deck, () => this.onDeckClick(game.playerId));
    }

    if (this.isPlayable(game, "table")) {
      makePlayable(this.sprites.table[0], () => this.onTableClick(game.playerId));
    }
  }

  // client events

  onHandClick(playerId, handIndex) {
    this.pushEvent("card-click", { playerId, handIndex, place: "hand" });
  }

  onDeckClick(playerId) {
    this.pushEvent("card-click", { playerId, place: "deck" });
  }

  onTableClick(playerId) {
    this.pushEvent("card-click", { playerId, place: "table" });
  }

  onHeldClick(playerId) {
    this.pushEvent("card-click", { playerId, place: "held" });
  }

  // util

  isPlayable(game, place) {
    return game.playableCards.includes(place);
  }

  findWinner() {
    const players = sortByScore(this.game.players);
    return players[0];
  }

  removeSprites() {
    while (this.stage.children[0]) {
      this.stage.removeChild(this.stage.children[0])
    }

    this.sprites = initSprites();
  }

  resize() {
    this.renderer.resize(this.parentEl.clientWidth, this.parentEl.clientHeight);
    // TODO
    this.removeSprites();
    this.addSprites();
  }
}
