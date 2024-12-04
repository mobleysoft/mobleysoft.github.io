import * as THREE from "https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.module.min.js";

export function initBlackHoleAnimation() {
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 2000);
    const renderer = new THREE.WebGLRenderer({ canvas: document.getElementById("blackhole"), antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);

    // Black hole physics constants
    const c = 1; // Speed of light
    const G = 1; // Gravitational constant
    const M = 50; // Black hole mass
    const Rs = 2 * G * M / (c * c); // Schwarzschild radius

    // Accretion disk
    const diskGeometry = new THREE.PlaneGeometry(Rs * 10, Rs * 10, 100, 100);
    const diskMaterial = new THREE.ShaderMaterial({
        transparent: true,
        vertexShader: `...`, // Add vertex shader code here
        fragmentShader: `...`, // Add fragment shader code here
        uniforms: { time: { value: 0 }, Rs: { value: Rs } },
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide,
    });
    const accretionDisk = new THREE.Mesh(diskGeometry, diskMaterial);
    accretionDisk.rotation.x = Math.PI / 3;
    scene.add(accretionDisk);

    // Render loop
    function animate() {
        requestAnimationFrame(animate);
        diskMaterial.uniforms.time.value += 0.01;
        renderer.render(scene, camera);
    }
    animate();

    // Handle resizing
    window.addEventListener("resize", () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });
}
