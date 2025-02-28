// enemy.js
import { Mesh, SphereGeometry, MeshBasicMaterial, Vector3 } from './libs/three.module.js';
import { distance } from './utils.js';

export function initEnemies(scene){
  const positions = [
    new Vector3(10,1,10),
    new Vector3(-10,1,-10),
    new Vector3(10,1,-10),
    new Vector3(-10,1,10)
  ];
  return positions.map(pos => {
    const enemy = new Mesh(new SphereGeometry(0.5,16,16), new MeshBasicMaterial({color:0xff0000}));
    enemy.position.copy(pos);
    scene.add(enemy);
    return enemy;
  });
}

export function updateEnemies(enemies, player){
  enemies.forEach(enemy => {
    const dir = new Vector3().subVectors(player.position, enemy.position).normalize();
    enemy.position.addScaledVector(dir, 0.02);
  });
}
