const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 2000);
        const renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        document.body.appendChild(renderer.domElement);

        // Physics constants
        const c = 1; // Speed of light
        const G = 1; // Gravitational constant
        const M = 50; // Black hole mass
        const Rs = 2 * G * M / (c * c); // Schwarzschild radius

        // Improved accretion disk with relativistic effects
        const diskGeometry = new THREE.PlaneGeometry(Rs * 10, Rs * 10, 100, 100);
        const diskMaterial = new THREE.ShaderMaterial({
            transparent: true,
            vertexShader: `
                varying vec2 vUv;
                varying float vDist;
                void main() {
                    vUv = uv;
                    vec4 worldPos = modelMatrix * vec4(position, 1.0);
                    vDist = length(worldPos.xz);
                    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
                }
            `,
            fragmentShader: `
                varying vec2 vUv;
                varying float vDist;
                uniform float time;
                uniform float Rs;
                
                vec3 doppler_shift(vec3 color, float velocity) {
                    float gamma = 1.0 / sqrt(1.0 - velocity * velocity);
                    float doppler = gamma * (1.0 - velocity);
                    
                    // Approximate relativistic color shift
                    return color * vec3(
                        clamp(1.0/doppler, 0.0, 2.0),
                        clamp(1.0/sqrt(doppler), 0.0, 2.0),
                        clamp(sqrt(doppler), 0.0, 2.0)
                    );
                }
                
                void main() {
                    float r = vDist;
                    float v = sqrt(Rs/(2.0 * r)); // Keplerian orbital velocity
                    
                    vec3 baseColor = vec3(1.0, 0.6, 0.2);
                    vec3 shiftedColor = doppler_shift(baseColor, v);
                    
                    float intensity = smoothstep(Rs, Rs * 5.0, r) * 
                                    (1.0 - smoothstep(Rs * 5.0, Rs * 8.0, r));
                    
                    float pattern = sin(r * 20.0 - time * 2.0) * 0.5 + 0.5;
                    
                    gl_FragColor = vec4(shiftedColor * intensity * pattern, 
                                      intensity * 0.8);
                }
            `,
            uniforms: {
                time: { value: 0 },
                Rs: { value: Rs }
            },
            blending: THREE.AdditiveBlending,
            side: THREE.DoubleSide
        });

        const accretionDisk = new THREE.Mesh(diskGeometry, diskMaterial);
        accretionDisk.rotation.x = Math.PI / 3;
        scene.add(accretionDisk);

        // Event horizon with gravitational lensing
        const horizonGeometry = new THREE.IcosahedronGeometry(Rs, 4);
        const horizonMaterial = new THREE.ShaderMaterial({
            vertexShader: `
                varying vec3 vPosition;
                varying vec3 vNormal;
                void main() {
                    vPosition = position;
                    vNormal = normal;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
                }
            `,
            fragmentShader: `
                varying vec3 vPosition;
                varying vec3 vNormal;
                uniform float time;
                
                float hexagonalPattern(vec3 p) {
                    vec2 h = vec2(1.0, sqrt(3.0));
                    vec2 a = vec2(p.x + p.y/2.0, p.y) * 3.0;
                    vec2 g = floor(a);
                    vec2 f = fract(a);
                    vec2 v = vec2((f.x + f.y/2.0) * 2.0 - 1.0, f.y - 0.5);
                    return step(abs(v.x) + abs(v.y), 1.0);
                }
                
                void main() {
                    vec3 viewDir = normalize(vPosition);
                    float fresnel = pow(1.0 - abs(dot(viewDir, vNormal)), 2.0);
                    
                    float pattern = hexagonalPattern(vPosition + vec3(time * 0.1));
                    vec3 color = mix(
                        vec3(0.8, 0.3, 0.1),  // Inner color
                        vec3(1.0, 0.6, 0.2),  // Outer color
                        pattern
                    );
                    
                    gl_FragColor = vec4(color, fresnel * 0.9);
                }
            `,
            uniforms: {
                time: { value: 0 }
            },
            transparent: true,
            blending: THREE.AdditiveBlending
        });

        const horizon = new THREE.Mesh(horizonGeometry, horizonMaterial);
        scene.add(horizon);

        // Particle system with relativistic trajectories
        const particleCount = 10000;
        const particles = new Float32Array(particleCount * 3);
        const velocities = new Float32Array(particleCount * 3);

        const particleGeometry = new THREE.BufferGeometry();
        particleGeometry.setAttribute('position', new THREE.BufferAttribute(particles, 3));

        const particleMaterial = new THREE.PointsMaterial({
            size: 0.1,
            color: 0xffaa00,
            transparent: true,
            opacity: 0.6,
            blending: THREE.AdditiveBlending
        });

        function initParticle(index) {
            const r = Rs * (3 + Math.random() * 5);
            const theta = Math.random() * Math.PI * 2;
            
            particles[index * 3] = r * Math.cos(theta);
            particles[index * 3 + 1] = (Math.random() - 0.5) * Rs;
            particles[index * 3 + 2] = r * Math.sin(theta);
            
            // Initialize with Keplerian orbital velocity
            const v = Math.sqrt(G * M / r);
            velocities[index * 3] = -v * Math.sin(theta);
            velocities[index * 3 + 1] = 0;
            velocities[index * 3 + 2] = v * Math.cos(theta);
        }

        for(let i = 0; i < particleCount; i++) {
            initParticle(i);
        }

        const particleSystem = new THREE.Points(particleGeometry, particleMaterial);
        scene.add(particleSystem);

        // Camera setup within safe distance
        camera.position.z = Rs * 2.5;
        let time = 0;

        function animate() {
            requestAnimationFrame(animate);
            time += 0.01;

            // Update shaders
            horizonMaterial.uniforms.time.value = time;
            diskMaterial.uniforms.time.value = time;

            // Update particles with relativistic corrections
            for(let i = 0; i < particleCount; i++) {
                const idx = i * 3;
                const x = particles[idx];
                const y = particles[idx + 1];
                const z = particles[idx + 2];
                
                const r = Math.sqrt(x * x + z * z);
                
                if (r < Rs * 1.1) {
                    initParticle(i);
                    continue;
                }
                
                // Calculate gravitational acceleration with relativistic corrections
                const accel = G * M / (r * r);
                const theta = Math.atan2(z, x);
                
                // Update velocities with frame dragging effect near horizon
                const frameDrag = Math.max(0, (Rs * 2 - r) / (Rs * 2)) * 0.1;
                velocities[idx] += (-accel * Math.cos(theta) + frameDrag * Math.sin(theta));
                velocities[idx + 2] += (-accel * Math.sin(theta) - frameDrag * Math.cos(theta));
                
                // Update positions
                particles[idx] += velocities[idx];
                particles[idx + 1] += velocities[idx + 1];
                particles[idx + 2] += velocities[idx + 2];
            }
            
            particleGeometry.attributes.position.needsUpdate = true;

            // Camera movement with proper time dilation
            const camRadius = Rs * 2.5;
            const timeDilation = Math.sqrt(1 - Rs/camRadius);
            const dilatedTime = time * timeDilation;
            
            camera.position.x = camRadius * Math.cos(dilatedTime * 0.1);
            camera.position.y = camRadius * Math.sin(dilatedTime * 0.15);
            camera.position.z = camRadius * Math.cos(dilatedTime * 0.2);
            camera.lookAt(0, 0, 0);

            renderer.render(scene, camera);
        }

        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });

        animate();
