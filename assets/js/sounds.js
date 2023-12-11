import {Howl} from "../vendor/howler.min.js";

const soundPlace1 = new Howl({
  src: ['/audio/cardPlace1.wav'],
  volume: 0.7,
});

export function playPlace1() {
  soundPlace1.play();
}

const soundPlace2 = new Howl({
  src: ['/audio/cardPlace2.wav'],
  volume: 0.4,
});

export function playPlace2() {
  soundPlace2.play();
}

const soundPlace3 = new Howl({
  src: ['/audio/cardPlace3.wav'],
  volume: 0.4,
});

export function playPlace3() {
  soundPlace3.play();
}

const soundShove2 = new Howl({
  src: ['/audio/cardShove2.wav'],
  volume: 0.2,
});

export function playShove2() {
  soundShove2.play();
}

const soundShove3 = new Howl({
  src: ['/audio/cardShove3.wav'],
  volume: 0.2,
});

export function playShove3() {
  soundShove3.play();
}

const soundDreamy = new Howl({
  src: ["/audio/zapsplat_multimedia_game_sound_harp_glissando_ascending_warm_dreamy_101779.mp3"],
  volume: 0.2,
});

export function playDreamy() {
  soundDreamy.play();
}

const soundCute = new Howl({
  src: ["/audio/zapsplat_multimedia_game_sound_harp_glissando_ascending_cute_fun_001_101830.mp3"],
  volume: 0.2,
});

export function playCute() {
  soundCute.play();
}

const soundArcade1 = new Howl({
  src: ["/audio/arcade_game_tone_001.mp3"],
  volume: 0.2,
});

export function playArcade1() {
  soundArcade1.play();
}

const soundArcade2 = new Howl({
  src: ["/audio/arcade_game_tone_002.mp3"],
  volume: 0.2,
});

export function playArcade2() {
  soundArcade2.play();
}