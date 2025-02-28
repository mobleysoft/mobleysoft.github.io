// utils.js
export function distance(p1, p2){
    return Math.sqrt((p1.x - p2.x)**2 + (p1.y - p2.y)**2 + (p1.z - p2.z)**2);
  }
  export function clamp(v, min, max){
    return Math.min(Math.max(v, min), max);
  }
  