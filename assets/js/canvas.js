import { OutlineFilter } from "../vendor/pixi-filters.mjs";

const CARD_IMG_WIDTH = 242;
const CARD_IMG_HEIGHT = 338;

const CARD_SCALE = 0.29;

const CARD_WIDTH = CARD_IMG_WIDTH * CARD_SCALE;
const CARD_HEIGHT = CARD_IMG_HEIGHT * CARD_SCALE;

const DECK_TABLE_OFFSET = 4; // px between deck and table cards

// export const CENTER_X = window.innerWidth / 2;
// export const CENTER_Y = window.innerHeight / 2;

// export const DECK_X = CENTER_X - CARD_WIDTH / 2 - DECK_TABLE_OFFSET;
// export const DECK_Y = CENTER_Y;

// export const TABLE_CARD_X = CENTER_X + CARD_WIDTH / 2 + DECK_TABLE_OFFSET;
// export const TABLE_CARD_Y = CENTER_Y;

const HAND_X_PAD = 3;
const HAND_Y_PAD = 10;

const DOWN_CARD = "2B";
const JOKER_CARD = "jk";

const HOVER_CURSOR_STYLE = "url('/images/cursor-click.png'),auto";

const BG_COLOR = "forestgreen";

export const PLAYER_TURN_COLOR = "#00ff00";
export const NOT_PLAYER_TURN_COLOR = "#ff77ff";

const PLAYABLE_FILTER = new OutlineFilter(3, 0x00ffff, 0.5);

const RANKS = "KA23456789TJQ".split("");
const SUITS = "CDHS".split("");

const CARD_PATHS = makeCardPaths();

function makeCardPaths() {
  const paths = [cardPath(DOWN_CARD), cardPath(JOKER_CARD)];
  
  for (const rank of RANKS) {
    for (const suit of SUITS) {
      paths.push(cardPath(rank + suit));
    }
  }

  return paths;
}

export function cardPath(name) {
  return `/images/cards/${name}.svg`;
}

export async function bgLoadTextures() {
  return PIXI.Assets.backgroundLoad(CARD_PATHS);
}

export async function loadTextures() {
  return PIXI.Assets.load(CARD_PATHS);
}

export function makeRenderer(width, height, backgroundColor = BG_COLOR) {
  const renderer = new PIXI.Renderer({
    width,
    height,
    backgroundColor,
    resolution: window.devicePixelRatio || 1,
    autoDensity: true,
    // antialias: true,
  });

  renderer.events.cursorStyles.hover = HOVER_CURSOR_STYLE;
  return renderer;
}

export function makeContainer() {
  return new PIXI.Container();
}

// sprites

function makeCardSprite(texture, x = 0, y = 0, rotation = 0) {
  const sprite = PIXI.Sprite.from(texture);

  sprite.anchor.set(0.5);
  sprite.scale.set(CARD_SCALE, CARD_SCALE);
  sprite.x = x;
  sprite.y = y;
  sprite.rotation = rotation;

  return sprite;  
}

export function makeDeckSprite(width, height, textures, gameState) {
  const texture = textures[cardPath(DOWN_CARD)];
  const {x, y} = deckCoord(width, height, gameState);
  return makeCardSprite(texture, x, y);
}

export function makeTableSprite(width, height, textures, card) {
  const texture = textures[cardPath(card)]
  const {x, y} = tableCoord(width, height);
  return makeCardSprite(texture, x, y);
}

export function makeHandSprites(width, height, textures, hand, pos) {
  const sprites = [];

  hand.forEach((card, i) => {
    const name = card["face_up?"] ? card.name : DOWN_CARD;
    const texture = textures[cardPath(name)];
    const coord = handCardCoord(width, height, pos, i);
    const sprite = makeCardSprite(texture, coord.x, coord.y, coord.rotation);
    sprites.push(sprite);
  });

  return sprites;
}

export function makeHeldSprite(width, height, textures, cardName, pos, showCard = true) {
  const card = showCard ? cardName : DOWN_CARD;
  const texture = textures[cardPath(card)];
  const coord = heldCardCoord(width, height, pos);
  return makeCardSprite(texture, coord.x, coord.y, coord.rotation);
}

// text

export function makePlayerText(width, height, player, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  const style = new PIXI.TextStyle({
    fill: NOT_PLAYER_TURN_COLOR,
    fontFamily: "monospace",
  });

  const points = player.score === 1 || player.score === -1 ? "pt" : "pts";
  const content = `${player.username}(${player.score}${points})`;
  const text = new PIXI.Text(content, style);

  switch (player.position) {
    case "bottom":
      text.x = width / 2;
      text.y = height - 5;
      text.anchor.set(0.5, 1.0);
      break;

    case "top":
      text.x = width / 2;
      text.y = 5;
      text.anchor.set(0.5, 0.0);
      break;

    case "left":
      text.x = CARD_HEIGHT;
      text.y = height / 2 - CARD_HEIGHT * 2;
      text.anchor.set(0.5, 0.0);
      break;

    case "right":
      text.x = width - CARD_HEIGHT - yPad;
      text.y = height / 2 - CARD_HEIGHT * 2;
      text.anchor.set(0.5, 0.0);
      break;
      
    default:
      throw new Error(`invalid pos: ${pos}`);
  }

  return text;
}

export function makeRoundText(roundNum) {
  const style = new PIXI.TextStyle({
    fill: NOT_PLAYER_TURN_COLOR,
    fontFamily: "monospace",
  });

  const content = `Round ${roundNum}`;
  const text = new PIXI.Text(content, style);
  text.x = 5;
  text.y = 5;
  return text;
}

export function makeTurnText(turn) {
  const style = new PIXI.TextStyle({
    fill: NOT_PLAYER_TURN_COLOR,
    fontFamily: "monospace",
  });

  const content = `Turn ${turn}`;
  const text = new PIXI.Text(content, style);
  text.anchor.set(0.0, 0.0);
  text.x = 5;
  text.y = 35;
  return text;
}

export function makeOverText(width, height, winnerName) {
  const style = new PIXI.TextStyle({
    fontFamily: "monospace",
    fontSize: 90,
    fill: "#4488ff",
    stroke: "#000000",
    strokeThickness: 4,
    dropShadow: true,
    // dropShadowColor: "#ffffff",
    dropShadowBlur: 2,
    align: "center",
    wordWrap: true,
  });

  const content = `${winnerName} wins!`.toUpperCase();
  const text = new PIXI.Text(content, style);
  text.x = width / 2;
  text.y = height / 2;
  text.anchor.set(0.5, 0.5);

  // let bgRect = new PIXI.Graphics();
  // bgRect.beginFill(0x0088ff);
  // bgRect.drawRect(CENTER_X-200, CENTER_Y-60, 400, 120);

  const container = new PIXI.Container();
  // container.addChild(bgRect);
  container.addChild(text);

  return container;
}

// interactive

export function makePlayable(sprite, callback) {
  sprite.eventMode = "static";
  sprite.cursor = "hover"
  sprite.filters = [PLAYABLE_FILTER];
  sprite.removeAllListeners();
  sprite.on("pointerdown", event => callback(event.currentTarget));
}

export function makeUnplayable(sprite) {
  sprite.eventMode = "none";
  sprite.cursor = "default";
  sprite.filters = [];
  sprite.removeAllListeners();
}

// coords

export function deckCoord(width, height, state) {
  const x = state === "no_round"
    ? width / 2
    : width / 2 - CARD_WIDTH / 2 - DECK_TABLE_OFFSET

  return {
    x,
    y: height / 2,
  }
}

export function tableCoord(width, height) {
  return {
    x: width / 2 + CARD_WIDTH / 2 + DECK_TABLE_OFFSET,
    y: height / 2,
  }
}

export function heldCardCoord(width, height, pos, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x, y;

  switch (pos) {
    case "bottom":
      x = width / 2 + CARD_WIDTH * 2.4;
      y = height - CARD_HEIGHT - yPad - 30;
      break;

    case "top":
      x = width / 2 - CARD_WIDTH * 1.5;
      y = CARD_HEIGHT + 1.3 * yPad + 30;
      break;

    case "left":
      x = CARD_WIDTH + yPad + 5;
      y = height / 2 + CARD_HEIGHT * 1.5 + xPad;
      break;

    case "right":
      x = width - CARD_WIDTH - yPad - 5;
      y = height / 2 + CARD_HEIGHT * 1.5 + xPad;
      break;

    default:
      throw new Error(`invalid pos: ${pos}`);
  }

  return {x, y, rotation: 0};
}

export function handCardCoord(width, height, pos, index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  switch (pos) {
    case "bottom":
      return handCardBottomCoord(width, height, index, xPad, yPad);
    case "top":
      return handCardTopCoord(width, height, index, xPad, yPad);
    case "left":
      return handCardLeftCoord(width, height, index, xPad, yPad);
    case "right":
      return handCardRightCoord(width, height, index, xPad, yPad);
    default:
      throw new Error(`invalid position: ${pos}`);
  }
}

function handCardBottomCoord(width, height, index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  switch (index) {
    case 0:
      x = width / 2 - CARD_WIDTH - xPad;
      y = height - CARD_HEIGHT * 1.5 - yPad * 1.3 - 30;
      break;

    case 1:
      x = width / 2;
      y = height - CARD_HEIGHT * 1.5 - yPad * 1.3 - 30;
      break;

    case 2:
      x = width / 2 + CARD_WIDTH + xPad;
      y = height - CARD_HEIGHT * 1.5 - yPad * 1.3 - 30;
      break;

    case 3:
      x = width / 2 - CARD_WIDTH - xPad;
      y = height - CARD_HEIGHT / 2 - yPad - 30;
      break;

    case 4:
      x = width / 2;
      y = height - CARD_HEIGHT / 2 - yPad - 30;
      break;

    case 5:
      x = width / 2 + CARD_WIDTH + xPad;
      y = height - CARD_HEIGHT / 2 - yPad - 30;
      break;

    default:
      throw new Error(`index ${index} out of range`);
  }

  return {x, y, rotation: 0};
}

function handCardTopCoord(width, _height, index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  switch (index) {
    case 0:
      x = width / 2 + CARD_WIDTH + xPad;
      y = CARD_HEIGHT * 1.5 + yPad * 1.3 + 30;
      break;

    case 1:
      x = width / 2;
      y = CARD_HEIGHT * 1.5 + yPad * 1.3 + 30;
      break;

    case 2:
      x = width / 2 - CARD_WIDTH - xPad;
      y = CARD_HEIGHT * 1.5 + yPad * 1.3 + 30;
      break;

    case 3:
      x = width / 2 + CARD_WIDTH + xPad;
      y = CARD_HEIGHT / 2 + yPad + 30;
      break;

    case 4:
      x = width / 2;
      y = CARD_HEIGHT / 2 + yPad + 30;
      break;

    case 5:
      x = width / 2 - CARD_WIDTH - xPad;
      y = CARD_HEIGHT / 2 + yPad + 30;
      break;
  }

  return {x, y, rotation: 0};
}

function handCardLeftCoord(_width, height, index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  switch (index) {
    case 0:
      x = CARD_WIDTH * 1.5 + yPad * 1.3;
      y = height / 2 - CARD_HEIGHT - xPad;
      break;

    case 1:
      x = CARD_WIDTH * 1.5 + yPad * 1.3;
      y = height / 2;
      break;

    case 2:
      x = CARD_WIDTH * 1.5 + yPad * 1.3;
      y = height / 2 + CARD_HEIGHT + xPad;
      break;

    case 3:
      x = CARD_WIDTH / 2 + yPad;
      y = height / 2 - CARD_HEIGHT - xPad;
      break;

    case 4:
      x = CARD_WIDTH / 2 + yPad;
      y = height / 2;
      break;

    case 5:
      x = CARD_WIDTH / 2 + yPad;
      y = height / 2 + CARD_HEIGHT + xPad;
      break;
  }

  return {x, y, rotation: 0};
}

function handCardRightCoord(width, height, index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  switch (index) {
    case 0:
      x = width - CARD_WIDTH * 1.5 - yPad * 1.3;
      y = height / 2 + CARD_HEIGHT + xPad;
      break;

    case 1:
      x = width - CARD_WIDTH * 1.5 - yPad * 1.3;
      y = height / 2;
      break;

    case 2:
      x = width - CARD_WIDTH * 1.5 - yPad * 1.3;
      y = height / 2 - CARD_HEIGHT - xPad;
      break;

    case 3:
      x = width - CARD_WIDTH / 2 - yPad;
      y = height / 2 + CARD_HEIGHT + xPad;
      break;

    case 4:
      x = width - CARD_WIDTH / 2 - yPad;
      y = height / 2;
      break;

    case 5:
      x = width - CARD_WIDTH / 2 - yPad;
      y = height / 2 - CARD_HEIGHT - xPad;
      break;
  }

  return {x, y, rotation: 0};
}

// export const DISCARD_FILTER = new OutlineFilter(3, 0xff5500, 0.5);

// function toRadians(degrees) {
//   return degrees * (Math.PI / 180);
// }

// export function rotationAt(pos) {
//   return pos === "left" || pos === "right"
//     ? toRadians(90)
//     : 0;
// }
