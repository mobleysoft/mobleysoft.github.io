    const overlay = document.getElementById('overlay');
    let idleTimer;

    // Function to show the overlay with smooth fade-in
    function showOverlay() {
        overlay.classList.add('visible'); // Add the "visible" class to fade in
        resetIdleTimer(); // Restart the idle timer
    }

    // Function to hide the overlay with smooth fade-out
    function hideOverlay() {
        // Reduce opacity to 0 smoothly before removing the class
        overlay.style.opacity = 0; // Trigger the CSS transition
        overlay.style.pointerEvents = "none"; // Disable interactions
        setTimeout(() => {
            overlay.classList.remove('visible'); // Fully hide after transition
        }, 3000); // Match the CSS transition duration (3 seconds)
    }

    // Reset the idle timer on user interaction
    function resetIdleTimer() {
        clearTimeout(idleTimer); // Clear any existing timer
        idleTimer = setTimeout(hideOverlay, 3000); // Start a 3-second timer for fade-out
        // Ensure overlay is immediately interactive
        overlay.style.pointerEvents = "auto";
        overlay.style.opacity = 1; // Start fading in
    }

    // Event listeners for user interaction
    document.addEventListener('mousemove', showOverlay);
    document.addEventListener('click', showOverlay);
    document.addEventListener('keypress', showOverlay);

    // Start with overlay hidden
    hideOverlay();
