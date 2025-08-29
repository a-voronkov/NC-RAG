/**
 * Node-RED Configuration for Nextcloud Integration
 * 
 * This configuration file sets up Node-RED to work behind Traefik reverse proxy
 * with custom authentication and webhook handling for Nextcloud events.
 */

module.exports = {
    // Base URL paths for Node-RED when running behind reverse proxy
    // This must match the Traefik routing configuration
    httpAdminRoot: '/nodered',
    httpNodeRoot: '/nodered',
    
    // UI settings for Node-RED dashboard
    ui: { 
        path: '/nodered/ui' 
    },
    
    // Enable built-in authentication system
    // This provides security for the Node-RED editor interface
    adminAuth: {
        type: "credentials",
        users: [{
            username: "admin",
            // Bcrypt hashed password - change this in production!
            // Default password: "admin" (hashed with bcrypt)
            password: "$2y$08$hUKXnOEmu9xHp48TbLdc2.7VqE1fhtxpwyW4/HRNupGn8Cikb23ta",
            permissions: "*"
        }]
    },
    
    // Server configuration
    uiPort: process.env.PORT || 1880,
    
    // HTTPS configuration - disabled since we're behind Traefik proxy
    https: null,
    
    // Credential encryption key - change this in production!
    credentialSecret: process.env.WEBHOOK_SECRET || "changeme-credential-secret",
    
    // Connection retry settings
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,
    
    // Debug message truncation
    debugMaxLength: 1000,
    
    // Global context for function nodes
    functionGlobalContext: {
        // Add any global variables or modules here
    },
    
    // Logging configuration
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    },
    
    // External module settings
    externalModules: {
        // Configuration for external npm modules
    },
    
    // Editor theme and customization
    editorTheme: {
        // Disable projects feature for simplicity
        projects: {
            enabled: false
        },
        // Custom header for the Node-RED editor
        header: {
            title: "Node-RED - Nextcloud Integration",
            url: "https://ncrag.voronkov.club/nodered"
        },
        // Additional theme customizations can be added here
        palette: {
            // Palette configuration
        },
        menu: {
            // Menu customizations
        }
    },
    
    // Security settings - disabled for HTTP nodes
    httpNodeAuth: null,
    
    // CORS settings for API access
    httpNodeCors: {
        origin: "*",
        methods: "GET,PUT,POST,DELETE"
    }
}