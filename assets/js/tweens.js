import { Tween, Easing, update } from "../vendor/tween.esm.min.js";

import { deckCoord, tableCoord } from "./canvas";
import { playPlace1, playPlace2, playPlace3, playShove2, playShove3 } from "./sounds.js";

const HAND_SIZE = 6;

export const updateTweens = update;

export function tweenWiggle(sprite, endX, duration=150, distance=1, repeats=2) {
  const startX = sprite.x;

  const tweenReturn = new Tween(sprite)
    .to({ x: endX }, duration / 2)
    .easing(Easing.Quadratic.Out);

  sprite.x = startX - distance;

  return new Tween(sprite)
    .onStart(() => playPlace2())
    .to({ x: startX + distance }, duration / repeats)
    .easing(Easing.Quintic.InOut)
    .repeat(repeats)
    .yoyo(true)
    .chain(tweenReturn);
}

export function handTweens(width, height, handSprites) {
  const tweens = [];

  // start with the last card in the hand
  for (let i = HAND_SIZE-1; i >= 0; i--) {
    const sprite = handSprites[i];

    const x = sprite.x;
    const y = sprite.y;

    const coord = deckCoord(width, height, "no_round");
    sprite.x = coord.x;
    sprite.y = coord.y;

    const tween = new Tween(sprite)
      .onStart(() => playPlace1())
      .to({ x, y }, 650)
      .easing(Easing.Cubic.InOut);

    tweens.push(tween);
  }

  return tweens;
}

export function tweenDeck(width, height, deckSprite) {
  const {x} = deckCoord(width, height, "flip_2");

  return new Tween(deckSprite)
    .onStart(obj => {
      playShove3();
      obj.x = width / 2;
    })
    .to({ x }, 200)
    .easing(Easing.Quadratic.Out);
}

export function tweenTable(width, height, tableSprite) {
  // tableSprite.x = DECK_X;
  // tableSprite.y = DECK_Y + DECK_Y_OFFSET;
  const dCoord = deckCoord(width, height, "flip_2");
  const tCoord = tableCoord(width, height);

  tableSprite.x = dCoord.x;
  // tableSprite.y = deckCoord.y + DECK_Y_OFFSET;
  tableSprite.y = height / 2;

  return new Tween(tableSprite)
    // .to({ x: TABLE_CARD_X, y: TABLE_CARD_Y }, 400)
    .to({ x: tCoord.x, y: tCoord.y }, 400)
    .easing(Easing.Quadratic.Out);
}

export function tweenTakeDeck(pos, heldSprite, deckSprite) {
  // move deck to held coords
  const x = heldSprite.x;
  const y = heldSprite.y;

  // set held card to deck coord
  heldSprite.x = deckSprite.x;
  heldSprite.y = deckSprite.y;

  return new Tween(heldSprite)
    .onStart(() => playPlace3())
    .to({ x, y }, 750)
    .easing(Easing.Quadratic.InOut);
}

export function tweenTakeTable(pos, heldSprite, tableSprite) {
  // to coords
  const x = heldSprite.x;
  const y = heldSprite.y;

  // set held card to table coord
  heldSprite.x = tableSprite.x;
  heldSprite.y = tableSprite.y;

  return new Tween(heldSprite)
    .onStart(() => {
      playShove2();
      tableSprite.visible = false;
    })
    .to({ x, y }, 750)
    .easing(Easing.Quadratic.InOut);
}

export function tweenDiscard(pos, tableSprite, heldSprite) {
  const x = tableSprite.x;
  const y = tableSprite.y;

  tableSprite.x = heldSprite.x;
  tableSprite.y = heldSprite.y;

  return new Tween(tableSprite)
    .onStart(() => {
      playShove2();
      heldSprite.visible = false;
    })
    .to({ x, y, rotation: 0 }, 750)
    .easing(Easing.Quadratic.InOut);
}

export function tweenSwapTable(width, height, tableSprite, handSprite) {
  tableSprite.x = handSprite.x;
  tableSprite.y = handSprite.y;

  const {x, y} = tableCoord(width, height);

  return new Tween(tableSprite)
    .onStart(() => playShove2())
    .to({ x, y }, 800)
    .easing(Easing.Quadratic.InOut);
}

// export function tweenSwapHeld(pos, heldSprite, handSprite, tableSprite) {
//   const x = handSprite.x;
//   const y = handSprite.y;

//   tableSprite.x = x;
//   tableSprite.y = y;
//   tableSprite.rotation = rotationAt(pos);

//   const heldTween = new Tween(heldSprite)
//     .to({ x, y }, 500)
//     .easing(Easing.Quadratic.InOut)
//     .onComplete(obj => {
//       obj.visible = false;
//       handSprite.visible = true;
//     });

//   const tableTween = new Tween(tableSprite)
//     .to({ x: TABLE_CARD_X, y: TABLE_CARD_Y, rotation: 0 }, 750)
//     .easing(Easing.Quadratic.InOut)
//     .delay(200);

//   return [heldTween, tableTween];
// }

/**
The deck png has 5 pixels of cards below the top card.
This offset lets us place cards correctly on top of the deck.
*/
// const DECK_Y_OFFSET = -5;
