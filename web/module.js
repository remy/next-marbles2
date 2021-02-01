/** @returns {HTMLElement} */
const $ = (s) => document.querySelector(s);

/** @type {HTMLCanvasElement} */
const canvas = $('canvas');

/** @type {CanvasRenderingContext2D} */
const ctx = canvas.getContext('2d');

// setup size
canvas.width = 160;
canvas.height = 160;

function makeBlock(colour) {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  canvas.width = 16;
  canvas.height = 16;
  ctx.fillStyle = colour;
  ctx.fillRect(0, 0, 15, 15);
  return ctx.getImageData(0, 0, 16, 16);
}

let seed = Uint16Array.of(1234);
function rnd() {
  let xs = Uint16Array.of(seed[0]);

  xs[0] ^= xs[0] << 7;
  xs[0] ^= xs[0] >> 9;
  xs[0] ^= xs[0] << 8;

  seed = Uint16Array.of(xs[0]);

  return 1 << (xs[0] & 3);
  return (Math.random() * 4) | 0;
}

const red = makeBlock('red');
const green = makeBlock('#00ff00');
const blue = makeBlock('cyan');
const yellow = makeBlock('yellow');

const blocks = { 1: red, 2: green, 4: blue, 8: yellow };

const grid = [];
for (let index = 0; index < 100; index++) {
  const x = index % 10;
  const y = (index / 10) | 0;
  ctx.putImageData(blocks[rnd()], x * 16, y * 16);
}

// async function getData() {
//   const data = await Promise.all(
//     ['marbles.pal', 'marbles.spr'].map(async (file) => {
//       const res = await fetch(`/assets/${file}`);
//       const data = await res.arrayBuffer();
//       console.log('got it: ' + data.byteLength);
//     })
//   );
// }

// getData();
