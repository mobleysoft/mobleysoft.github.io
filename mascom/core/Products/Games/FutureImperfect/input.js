// input.js
import { jump, switchWeapon, updateRotation } from './player.js';
import { primaryFire, secondaryFire, specialFire, ultimateFire } from './weapon.js';

const keys = {};
let rotY =0, rotX =0;

export function handleInput(player){
  if(keys['w']){ player.position.z -=0.2; }
  if(keys['s']){ player.position.z +=0.2; }
  if(keys['a']){ player.position.x -=0.2; }
  if(keys['d']){ player.position.x +=0.2; }
  if(keys[' ']){ jump(); keys[' '] = false; }
  if(keys['j']){ primaryFire(); keys['j'] = false; }
  if(keys['i']){ secondaryFire(); keys['i'] = false; }
  if(keys['o']){ specialFire(); keys['o'] = false; }
  if(keys[';']){ ultimateFire(); keys[';'] = false; }
  if(keys['shift']){ switchWeapon(); keys['shift'] = false; }
}

export function handleKeyDown(e){
  keys[e.key.toLowerCase()] = true;
}

export function handleKeyUp(e){
  keys[e.key.toLowerCase()] = false;
}

export function handleMouseMove(e){
  if(document.pointerLockElement){
    rotY -= e.movementX *0.002;
    rotX -= e.movementY *0.002;
    rotX = Math.max(-Math.PI/2, Math.min(Math.PI/2, rotX));
    updateRotation(rotY, rotX);
  }
}

document.addEventListener('keydown', handleKeyDown);
document.addEventListener('keyup', handleKeyUp);
document.addEventListener('mousemove', handleMouseMove);
