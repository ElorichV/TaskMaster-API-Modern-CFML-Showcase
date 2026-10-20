/**
 * Application.cfc
 * Modern CFML Application Lifecycle & Security Configuration
 * 
 * Configures stateless REST architecture, programmatic embedded datasource,
 * OWASP security headers, and global exception containment.
 */
component output="false" {

    // 1. Application Identity & Stateless REST Settings
    this.name = "TaskMaster_API_" & hash(getCurrentTemplatePath());
    this.applicationTimeout = createTimeSpan(1, 0, 0, 0);
    this.sessionManagement = false;
    this.clientManagement = false;
    this.setClientCookies = false;
    this.scriptProtect = "all";

    // 2. Programmatic Datasource Configuration (Defaults to embedded H2 for zero-config run)
    var dbName = (structKeyExists(server, "system") && structKeyExists(server.system, "environment") && structKeyExists(server.system.environment, "DB_NAME"))
        ? server.system.environment.DB_NAME
        : "taskmaster_db";

    this.datasource = dbName;
    
    // Provide embedded H2 configuration when running on Lucee
    this.datasources = {};
    this.datasources[dbName] = {
        type: "h2",
        database: expandPath("./data/taskmaster_db"),
        username: "sa",
        password: ""
    };

    /**
     * Application Initialization
     */
    public boolean function onApplicationStart() {
        // Ensure data directory exists for embedded DB
        var dataDir = expandPath("./data");
        if (!directoryExists(dataDir)) {
            directoryCreate(dataDir);
        }

        // 1. Instantiate Core Helpers
        application.responseHandler = new core.ResponseHandler();
        application.validator = new core.Validator();
        application.securityHelper = new core.SecurityHelper();

        // 2. Run Database Migrations & Seeds
        application.migrator = new core.DatabaseMigrator(this.datasource, application.securityHelper);
        application.migrator.run();

        // 3. Instantiate Repositories
        application.userRepository = new repositories.UserRepository(this.datasource);
        application.taskRepository = new repositories.TaskRepository(this.datasource);

        // 4. Instantiate Services
        application.authService = new services.AuthService(
            application.userRepository,
            application.securityHelper,
            application.validator
        );
        application.taskService = new services.TaskService(
            application.taskRepository,
            application.validator
        );

        // 5. Instantiate Controllers
        var healthController = new controllers.HealthController(
            application.responseHandler,
            application.authService,
            this.datasource
        );
        var authController = new controllers.AuthController(
            application.responseHandler,
            application.authService
        );
        var taskController = new controllers.TaskController(
            application.responseHandler,
            application.authService,
            application.taskService
        );

        // 6. Configure REST Router
        application.router = new core.Router(application.responseHandler);

        // System & Diagnostics
        application.router.addRoute("GET", "/", healthController, "check");
        application.router.addRoute("GET", "/api/v1/health", healthController, "check");

        // Authentication Endpoints
        application.router.addRoute("POST", "/api/v1/auth/login", authController, "login");
        application.router.addRoute("GET", "/api/v1/auth/me", authController, "me");

        // Task Endpoints
        application.router.addRoute("GET", "/api/v1/tasks", taskController, "index");
        application.router.addRoute("GET", "/api/v1/tasks/:id", taskController, "show");
        application.router.addRoute("POST", "/api/v1/tasks", taskController, "create");
        application.router.addRoute("PUT", "/api/v1/tasks/:id", taskController, "update");
        application.router.addRoute("DELETE", "/api/v1/tasks/:id", taskController, "delete");

        return true;
    }

    /**
     * Pre-request Hook: Security Headers & CORS Enforcement
     */
    public boolean function onRequestStart(required string targetPage) {
        // Developer reload trigger
        if (structKeyExists(url, "reinit") || structKeyExists(url, "reload")) {
            onApplicationStart();
        }

        // Apply Hardened OWASP Security Headers
        cfheader(name = "X-Content-Type-Options", value = "nosniff");
        cfheader(name = "X-Frame-Options", value = "DENY");
        cfheader(name = "X-XSS-Protection", value = "1; mode=block");
        cfheader(name = "Referrer-Policy", value = "strict-origin-when-cross-origin");
        cfheader(name = "Content-Security-Policy", value = "default-src 'none'; frame-ancestors 'none';");
        cfheader(name = "Access-Control-Allow-Origin", value = "*");
        cfheader(name = "Access-Control-Allow-Headers", value = "Content-Type, Authorization, X-Requested-With");
        cfheader(name = "Access-Control-Allow-Methods", value = "GET, POST, PUT, DELETE, OPTIONS");

        return true;
    }

    /**
     * Global Exception Barrier: Prevents raw stack trace exposure (RFC 7807 compliance)
     */
    public void function onError(required any exception, string eventName = "") {
        var trackingId = createUUID();
        
        // Log to server console
        var errMsg = structKeyExists(arguments.exception, "message") ? arguments.exception.message : "Fatal error";
        var errDetail = structKeyExists(arguments.exception, "detail") ? arguments.exception.detail : "";
        systemOutput("[CRITICAL ERROR #" & trackingId & " in " & arguments.eventName & "] " & errMsg & " | " & errDetail, true);

        // Use response handler if initialized, otherwise direct JSON output
        cfheader(statuscode = 500);
        cfcontent(type = "application/json; charset=utf-8", reset = true);
        
        var payload = {
            "success": false,
            "status": 500,
            "title": "Internal Server Error",
            "message": "An unhandled server exception occurred. Ref: #" & trackingId,
            "trackingId": trackingId,
            "timestamp": dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss'Z'")
        };

        writeOutput(serializeJSON(payload));
        abort;
    }
}
