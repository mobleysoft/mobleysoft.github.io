<!DOCTYPE html>
<html>
<head>
    <title>Infinite Tunnel</title>
    <style>
        body { margin: 0; overflow: hidden; background: black; }
        canvas { width: 100vw; height: 100vh; display: block; }
    </style>
</head>
<body>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script>
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 3000);
        const renderer = new THREE.WebGLRenderer({ 
            antialias: true,
            alpha: true
        });
        renderer.setSize(window.innerWidth, window.innerHeight);
        document.body.appendChild(renderer.domElement);

        function createTunnel() {
            const geometry = new THREE.CylinderGeometry(
                20,             // radius
                20,             // radius
                2000,           // length
                36,            // more radial segments for smoother appearance
                150,           // more height segments for smoother motion
                true
            );

            const material = new THREE.MeshBasicMaterial({
                color: 0x00ffff,
                wireframe: true,
                side: THREE.BackSide,
                transparent: true,
                opacity: 0.4    // reduced opacity for softer look
            });

            const tunnel = new THREE.Mesh(geometry, material);
            tunnel.rotation.x = Math.PI / 2;
            return tunnel;
        }

        const tunnel1 = createTunnel();
        const tunnel2 = createTunnel();
        
        tunnel1.position.z = 0;
        tunnel2.position.z = -2000;
        
        scene.add(tunnel1);
        scene.add(tunnel2);

        camera.position.z = 500;
        camera.lookAt(0, 0, -1000);

        const speed = 0.75;  // reduced speed
        let cameraZ = 500;
        
        // Add smooth interpolation
        let currentSpeed = speed;
        const smoothFactor = 0.05;

        function lerp(start, end, factor) {
            return start + (end - start) * factor;
        }

        function animate() {
            requestAnimationFrame(animate);
            
            // Smooth speed transitions
            currentSpeed = lerp(currentSpeed, speed, smoothFactor);
            
            // Move camera with smoothed speed
            cameraZ -= currentSpeed;
            camera.position.z = cameraZ;

            if (cameraZ <= -1500) {
                cameraZ = 500;
                camera.position.z = cameraZ;
            }
            
            renderer.render(scene, camera);
        }

        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });

        animate();
    </script>
</body>
</html>
