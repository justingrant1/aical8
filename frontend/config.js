// CalendarAI Frontend Configuration
window.CalendarAIConfig = {
    // API Configuration - automatically detect environment
    API_BASE_URL: (() => {
        const hostname = window.location.hostname;
        
        // Production detection
        if (hostname !== 'localhost' && hostname !== '127.0.0.1') {
            // Update this with your actual Railway backend URL after deployment
            return 'https://aical8-backend.railway.app/api/v1';
        }
        
        // Development
        return 'http://localhost:3000/api/v1';
    })(),
    
    // OAuth Configuration
    OAUTH_CONFIG: {
        gmail_scope: 'https://www.googleapis.com/auth/gmail.readonly',
        redirect_uri: 'postmessage' // For popup-based OAuth
    },
    
    // Feature Flags
    FEATURES: {
        realTimeSync: true,
        aiAnalysis: true,
        notifications: true
    },
    
    // Environment Detection
    ENVIRONMENT: window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' 
        ? 'development' 
        : 'production'
};

// Global API helper function
window.apiCall = async (endpoint, options = {}) => {
    const url = `${window.CalendarAIConfig.API_BASE_URL}${endpoint}`;
    
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        },
        credentials: 'include'
    };
    
    const config = { ...defaultOptions, ...options };
    
    try {
        const response = await fetch(url, config);
        
        if (!response.ok) {
            throw new Error(`API Error: ${response.status} ${response.statusText}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('API Call Failed:', error);
        throw error;
    }
};

// Initialize configuration
console.log('CalendarAI Config loaded:', window.CalendarAIConfig);
