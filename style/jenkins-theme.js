
window.addEventListener('load', function () {
    const header = document.getElementById('page-header');
    if (header) {
        
        // Create the container div
        const customTextContainer = document.createElement('div');
        customTextContainer.textContent = '🚀 JKL - Local Jenkins Example 🚀';
        customTextContainer.style.position = 'absolute';
        customTextContainer.style.top = '50%';
        customTextContainer.style.left = '50%';
        customTextContainer.style.transform = 'translate(-50%, -50%)';
        customTextContainer.style.color = 'white';
        customTextContainer.style.fontSize = '20px';
        customTextContainer.style.fontWeight = 'bold';
        customTextContainer.style.pointerEvents = 'none';

        // Append it to the header
        header.style.position = 'relative'; 
        header.appendChild(customTextContainer);
    }
});

