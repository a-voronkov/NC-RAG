module.exports = {
    // Base URL path for Node-RED
    httpRoot: '/nodered',
    
    // UI settings  
    ui: { path: '/nodered/ui' },
    
    // Enable internal authentication
    adminAuth: {
        type: "credentials",
        users: [{
            username: "admin",
            password: "$2y$08$hUKXnOEmu9xHp48TbLdc2.7VqE1fhtxpwyW4/HRNupGn8Cikb23ta",
            permissions: "*"
        }]
    },
    
    // Other settings
    uiPort: process.env.PORT || 1880,
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,
    debugMaxLength: 1000,
    
    // Function settings
    functionGlobalContext: {},
    
    // Logging
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    },
    
    // Export settings
    externalModules: {},
    
    // Editor settings
    editorTheme: {
        projects: {
            enabled: false
        },
        header: {
            title: "Node-RED - Nextcloud Integration",
            url: "https://ncrag.voronkov.club/nodered"
        }
    }
}