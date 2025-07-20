// Custom JavaScript for ESPHome Garage Door Interface

document.addEventListener('DOMContentLoaded', function() {
    console.log('Garage Door Interface - JavaScript Loaded');
    
    // Initialize interface enhancements
    initializeInterface();
    
    // Auto-refresh functionality
    startAutoRefresh();
    
    // Add custom event listeners
    addCustomEventListeners();
});

function initializeInterface() {
    // Add loading states to buttons
    enhanceButtons();
    
    // Add status indicators
    addStatusIndicators();
    
    // Enhance mobile experience
    enhanceMobileExperience();
    
    // Add confirmation dialogs for critical actions
    addConfirmationDialogs();
}

function enhanceButtons() {
    const buttons = document.querySelectorAll('button');
    
    buttons.forEach(button => {
        // Add click effect
        button.addEventListener('click', function(e) {
            // Add ripple effect
            createRipple(e, this);
            
            // Add loading state
            if (!this.classList.contains('no-loading')) {
                addLoadingState(this);
            }
        });
        
        // Add hover effects
        button.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-2px)';
        });
        
        button.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });
}

function createRipple(event, element) {
    const circle = document.createElement('span');
    const diameter = Math.max(element.clientWidth, element.clientHeight);
    const radius = diameter / 2;
    
    circle.style.width = circle.style.height = `${diameter}px`;
    circle.style.left = `${event.clientX - element.offsetLeft - radius}px`;
    circle.style.top = `${event.clientY - element.offsetTop - radius}px`;
    circle.classList.add('ripple');
    
    // Add ripple styles if not already added
    if (!document.querySelector('.ripple-styles')) {
        const style = document.createElement('style');
        style.className = 'ripple-styles';
        style.textContent = `
            .ripple {
                position: absolute;
                border-radius: 50%;
                background-color: rgba(255, 255, 255, 0.6);
                transform: scale(0);
                animation: ripple-animation 0.6s linear;
                pointer-events: none;
            }
            
            @keyframes ripple-animation {
                to {
                    transform: scale(4);
                    opacity: 0;
                }
            }
        `;
        document.head.appendChild(style);
    }
    
    const ripple = element.querySelector('.ripple');
    if (ripple) {
        ripple.remove();
    }
    
    element.appendChild(circle);
}

function addLoadingState(button) {
    const originalText = button.textContent;
    const originalHTML = button.innerHTML;
    
    button.disabled = true;
    button.innerHTML = '<span class="loading"></span> Executando...';
    
    // Remove loading state after 2 seconds
    setTimeout(() => {
        button.disabled = false;
        button.innerHTML = originalHTML;
        
        // Show success feedback
        showSuccessMessage(button);
    }, 2000);
}

function showSuccessMessage(button) {
    const message = document.createElement('div');
    message.className = 'message success';
    message.textContent = 'Comando executado com sucesso!';
    message.style.position = 'fixed';
    message.style.top = '20px';
    message.style.right = '20px';
    message.style.zIndex = '1000';
    message.style.minWidth = '250px';
    
    document.body.appendChild(message);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
        message.remove();
    }, 3000);
}

function addStatusIndicators() {
    // Add WiFi status indicator
    const wifiElements = document.querySelectorAll('[data-entity*="wifi"]');
    wifiElements.forEach(element => {
        element.classList.add('wifi-signal');
    });
    
    // Add online status to entities
    const entities = document.querySelectorAll('.entity');
    entities.forEach(entity => {
        if (!entity.classList.contains('unavailable')) {
            entity.classList.add('status-online');
        } else {
            entity.classList.add('status-offline');
        }
    });
}

function enhanceMobileExperience() {
    // Add touch-friendly enhancements
    if ('ontouchstart' in window) {
        document.body.classList.add('touch-device');
        
        // Add touch styles
        const style = document.createElement('style');
        style.textContent = `
            .touch-device button {
                min-height: 44px;
                min-width: 44px;
            }
            
            .touch-device .entity {
                margin-bottom: 15px;
            }
        `;
        document.head.appendChild(style);
    }
    
    // Add swipe gesture for refresh
    let startY = 0;
    let isRefreshing = false;
    
    document.addEventListener('touchstart', function(e) {
        startY = e.touches[0].clientY;
    });
    
    document.addEventListener('touchmove', function(e) {
        if (window.pageYOffset === 0 && e.touches[0].clientY > startY + 100 && !isRefreshing) {
            isRefreshing = true;
            refreshData();
        }
    });
}

function addConfirmationDialogs() {
    // Add confirmation for garage door actions
    const garageDoorButtons = document.querySelectorAll('.cover button');
    
    garageDoorButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            const action = this.textContent.toLowerCase();
            
            if (action.includes('abrir') || action.includes('fechar') || action.includes('acionar')) {
                const confirmed = confirm(`Tem certeza que deseja ${action} o portão da garagem?`);
                
                if (!confirmed) {
                    e.preventDefault();
                    e.stopPropagation();
                    return false;
                }
            }
        });
    });
}

function startAutoRefresh() {
    // Refresh data every 30 seconds
    setInterval(() => {
        refreshData();
    }, 30000);
    
    // Also refresh when page becomes visible again
    document.addEventListener('visibilitychange', function() {
        if (!document.hidden) {
            refreshData();
        }
    });
}

function refreshData() {
    // This function would typically fetch new data from the ESPHome device
    console.log('Refreshing data...');
    
    // Add visual feedback
    const loadingIndicator = document.createElement('div');
    loadingIndicator.className = 'loading-indicator';
    loadingIndicator.innerHTML = '<div class="loading"></div> Atualizando...';
    loadingIndicator.style.position = 'fixed';
    loadingIndicator.style.top = '20px';
    loadingIndicator.style.left = '50%';
    loadingIndicator.style.transform = 'translateX(-50%)';
    loadingIndicator.style.background = 'rgba(0, 0, 0, 0.8)';
    loadingIndicator.style.color = 'white';
    loadingIndicator.style.padding = '10px 20px';
    loadingIndicator.style.borderRadius = '10px';
    loadingIndicator.style.zIndex = '1000';
    
    document.body.appendChild(loadingIndicator);
    
    // Simulate refresh delay
    setTimeout(() => {
        loadingIndicator.remove();
        
        // In a real implementation, you would fetch new data here
        // and update the interface accordingly
        updateLastRefreshTime();
    }, 1000);
}

function updateLastRefreshTime() {
    let timeElement = document.querySelector('.last-refresh');
    
    if (!timeElement) {
        timeElement = document.createElement('div');
        timeElement.className = 'last-refresh';
        timeElement.style.textAlign = 'center';
        timeElement.style.fontSize = '0.8em';
        timeElement.style.color = '#666';
        timeElement.style.marginTop = '20px';
        document.querySelector('.container, .content').appendChild(timeElement);
    }
    
    const now = new Date();
    timeElement.textContent = `Última atualização: ${now.toLocaleTimeString()}`;
}

function addCustomEventListeners() {
    // Add keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        // Space bar or Enter to trigger garage door
        if (e.code === 'Space' || e.code === 'Enter') {
            if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
                e.preventDefault();
                const garageButton = document.querySelector('.cover button');
                if (garageButton) {
                    garageButton.click();
                }
            }
        }
        
        // R key to refresh
        if (e.code === 'KeyR' && e.ctrlKey) {
            e.preventDefault();
            refreshData();
        }
    });
    
    // Add error handling for failed requests
    window.addEventListener('error', function(e) {
        console.error('JavaScript Error:', e);
        showErrorMessage('Ocorreu um erro. Tente recarregar a página.');
    });
}

function showErrorMessage(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'message error';
    errorDiv.textContent = message;
    errorDiv.style.position = 'fixed';
    errorDiv.style.top = '20px';
    errorDiv.style.right = '20px';
    errorDiv.style.zIndex = '1000';
    errorDiv.style.minWidth = '250px';
    
    document.body.appendChild(errorDiv);
    
    setTimeout(() => {
        errorDiv.remove();
    }, 5000);
}

// Utility function to format time
function formatTime(date) {
    return date.toLocaleTimeString('pt-BR', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
}

// Add some helpful console messages for debugging
console.log('🏠 ESP32 Garage Controller Interface');
console.log('📱 Keyboard shortcuts:');
console.log('   - Space/Enter: Trigger garage door');
console.log('   - Ctrl+R: Refresh data');
console.log('🔄 Auto-refresh: Every 30 seconds');
console.log('📡 WebSocket connection: ' + (typeof(WebSocket) !== 'undefined' ? 'Available' : 'Not available'));