import * as THREE from "https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.module.min.js";

export function initBlackHoleAnimation() {
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 2000);
    const renderer = new THREE.WebGLRenderer({ canvas: document.getElementById("blackhole"), antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);

    const vertexShader = `
        varying vec2 vUv;
        varying float vDist;
        void main() {
            vUv = uv;
            vec4 worldPos = modelMatrix * vec4(position, 1.0);
            vDist = length(worldPos.xz);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    `;

    const fragmentShader = `
        varying vec2 vUv;
        varying float vDist;
        uniform float time;
        uniform float Rs;
        
        vec3 doppler_shift(vec3 color, float velocity) {
            float gamma = 1.0 / sqrt(1.0 - velocity * velocity);
            float doppler = gamma * (1.0 - velocity);
            
            return color * vec3(
                clamp(1.0 / doppler, 0.0, 2.0),
                clamp(1.0 / sqrt(doppler), 0.0, 2.0),
                clamp(sqrt(doppler), 0.0, 2.0)
            );
        }
        
        void main() {
            float r = vDist;
            float v = sqrt(Rs / (2.0 * r)); // Keplerian orbital velocity
            
            vec3 baseColor = vec3(1.0, 0.6, 0.2);
            vec3 shiftedColor = doppler_shift(baseColor, v);
            
            float intensity = smoothstep(Rs, Rs * 5.0, r) * 
                              (1.0 - smoothstep(Rs * 5.0, Rs * 8.0, r));
            
            float pattern = sin(r * 20.0 - time * 2.0) * 0.5 + 0.5;
            
            gl_FragColor = vec4(shiftedColor * intensity * pattern, 
                                intensity * 0.8);
        }
    `;

    const accretionDisk = new THREE.Mesh(
        new THREE.PlaneGeometry(100, 100, 100, 100),
        new THREE.ShaderMaterial({
            transparent: true,
            vertexShader,
            fragmentShader,
            uniforms: {
                time: { value: 0 },
                Rs: { value: 2 }, // Schwarzschild radius
            },
        })
    );

    scene.add(accretionDisk);

    camera.position.z = 10;

    function animate() {
        requestAnimationFrame(animate);
        renderer.render(scene, camera);
    }

    animate();
}
