// player.js
import { Mesh, SphereGeometry, MeshBasicMaterial, Vector3 } from './libs/three.module.js';

let velocityY = 0, isJumping = false, rotY =0, rotX =0, currentWeapon = null, weaponsOwned = [];

export function initPlayer(scene, camera){
  const player = new Mesh(new SphereGeometry(0.5,16,16), new MeshBasicMaterial({color:0x0000ff}));
  player.position.set(0,1,0);
  scene.add(player);
  camera.position.set(0,2.6,2);
  camera.lookAt(new Vector3(0,2.6,-1));
  return player;
}

export function updatePlayer(player, camera){
  if(player.position.y >1){
    velocityY -=0.05;
    player.position.y +=velocityY;
    if(player.position.y <=1){
      player.position.y =1;
      velocityY=0;
      isJumping=false;
    }
  }
  camera.position.set(player.position.x, player.position.y +1.6, player.position.z +2);
  camera.rotation.set(rotX, rotY, 0);
  camera.lookAt(player.position.x + Math.sin(rotY), player.position.y +1.6, player.position.z + Math.cos(rotY));
}

export function jump(){
  if(!isJumping){
    velocityY =1;
    isJumping=true;
    console.log('Jump');
  }
}

export function pickupWeapon(weaponName){
  weaponsOwned.push(weaponName);
  currentWeapon = weaponName;
  console.log(`Picked up ${weaponName}`);
}

export function getCurrentWeapon(){
  return currentWeapon;
}

export function switchWeapon(){
  if(weaponsOwned.length >0){
    currentWeapon = weaponsOwned[weaponsOwned.length -1];
    console.log(`Switched to ${currentWeapon}`);
  }
}

export function updateRotation(newRotY, newRotX){
  rotY = newRotY;
  rotX = newRotX;
}

export function getRotations(){
  return { rotY, rotX };
}
