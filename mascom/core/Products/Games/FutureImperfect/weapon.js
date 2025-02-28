// weapon.js
import { Mesh, BoxGeometry, MeshBasicMaterial, Vector3 } from './libs/three.module.js';
import { distance } from './utils.js';
import { pickupWeapon, getCurrentWeapon } from './player.js';

const weaponTypes = {
  'guided-rocket-launcher': 0xffa500,
  'thru-wall-sniper': 0x00ffff,
  'deployable-sentry-rifle': 0x800080,
  'ricochet-knives': 0xffff00
};

export function initWeapons(scene){
  const positions = [
    {name:'guided-rocket-launcher', pos: new Vector3(-49,1,0)},
    {name:'thru-wall-sniper', pos: new Vector3(49,1,0)},
    {name:'deployable-sentry-rifle', pos: new Vector3(0,1,-49)},
    {name:'ricochet-knives', pos: new Vector3(0,1,49)}
  ];
  return positions.map(w => {
    const weapon = new Mesh(new BoxGeometry(1,0.2,2), new MeshBasicMaterial({color:weaponTypes[w.name]}));
    weapon.position.copy(w.pos);
    weapon.name = w.name;
    scene.add(weapon);
    return weapon;
  });
}

export function updateWeapons(weapons, scene){}

export function checkWeaponPickup(player, weapons, scene){
  weapons.forEach((weapon, index) => {
    if(distance(player.position, weapon.position) <1){
      pickupWeapon(weapon.name);
      scene.remove(weapon);
      weapons.splice(index,1);
    }
  });
}

export function primaryFire(){
  const w = getCurrentWeapon();
  if(w){
    console.log(`Primary Fire with ${w}`);
  } else {
    console.log('No weapon equipped for Primary Fire');
  }
}

export function secondaryFire(){
  const w = getCurrentWeapon();
  if(w){
    console.log(`Secondary Fire with ${w}`);
  } else {
    console.log('No weapon equipped for Secondary Fire');
  }
}

export function specialFire(){
  const w = getCurrentWeapon();
  if(w){
    console.log(`Special Fire with ${w}`);
  } else {
    console.log('No weapon equipped for Special Fire');
  }
}

export function ultimateFire(){
  const w = getCurrentWeapon();
  if(w){
    console.log(`Ultimate Fire with ${w}`);
  } else {
    console.log('No weapon equipped for Ultimate Fire');
  }
}
