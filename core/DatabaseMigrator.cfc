/**
 * core/DatabaseMigrator.cfc
 * Automated Schema Migration & Database Seed Engine
 * 
 * Ensures database tables and indexes exist on startup, and provisions
 * a deterministic development dataset with securely hashed credentials.
 */
component output="false" {

    property name="datasource" type="string";
    property name="securityHelper" type="any";

    public DatabaseMigrator function init(required string datasource, required any securityHelper) {
        variables.datasource = arguments.datasource;
        variables.securityHelper = arguments.securityHelper;
        return this;
    }

    /**
     * Executes migrations and seeds
     */
    public void function run() {
        try {
            createTables();
            seedDefaultUserAndTasks();
        } catch (any e) {
            // Log migration error without crashing boot if tables already exist
            systemOutput("[DatabaseMigrator] Notice/Warning during migration: " & e.message, true);
        }
    }

    /**
     * Creates schema tables and performance indexes
     */
    private void function createTables() {
        // 1. Users Table
        queryExecute("
            CREATE TABLE IF NOT EXISTS users (
                id VARCHAR(36) PRIMARY KEY,
                username VARCHAR(50) NOT NULL UNIQUE,
                email VARCHAR(100) NOT NULL UNIQUE,
                password_hash VARCHAR(255) NOT NULL,
                password_salt VARCHAR(64) NOT NULL,
                role VARCHAR(20) NOT NULL,
                created_at TIMESTAMP NOT NULL
            )
        ", {}, { datasource = variables.datasource });

        // 2. Tasks Table
        queryExecute("
            CREATE TABLE IF NOT EXISTS tasks (
                id VARCHAR(36) PRIMARY KEY,
                user_id VARCHAR(36) NOT NULL,
                title VARCHAR(200) NOT NULL,
                description VARCHAR(1000),
                status VARCHAR(20) NOT NULL,
                priority VARCHAR(20) NOT NULL,
                due_date TIMESTAMP,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL
            )
        ", {}, { datasource = variables.datasource });

        // 3. Create Indexes (Ignore failure if index already exists in DBMS)
        try {
            queryExecute("CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id)", {}, { datasource = variables.datasource });
            queryExecute("CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status)", {}, { datasource = variables.datasource });
        } catch (any ignored) {
            // Some DBMS don't support IF NOT EXISTS on index creation
        }
    }

    /**
     * Seeds initial demo user and tasks if users table is empty
     */
    private void function seedDefaultUserAndTasks() {
        var userCountQuery = queryExecute("SELECT COUNT(*) AS total FROM users", {}, { datasource = variables.datasource });
        if (userCountQuery.total > 0) {
            return; // Already seeded
        }

        var demoUserId = "a1b2c3d4-e5f6-7890-abcd-ef1234567890";
        var demoCreds = variables.securityHelper.hashPassword("Password123!");
        var nowTimestamp = now();

        // 1. Insert Demo User (100% Parameterized)
        queryExecute("
            INSERT INTO users (id, username, email, password_hash, password_salt, role, created_at)
            VALUES (:id, :username, :email, :password_hash, :password_salt, :role, :created_at)
        ", {
            id = { value = demoUserId, cfsqltype = "cf_sql_varchar" },
            username = { value = "demo_user", cfsqltype = "cf_sql_varchar" },
            email = { value = "demo@taskmaster.local", cfsqltype = "cf_sql_varchar" },
            password_hash = { value = demoCreds.hash, cfsqltype = "cf_sql_varchar" },
            password_salt = { value = demoCreds.salt, cfsqltype = "cf_sql_varchar" },
            role = { value = "ADMIN", cfsqltype = "cf_sql_varchar" },
            created_at = { value = nowTimestamp, cfsqltype = "cf_sql_timestamp" }
        }, { datasource = variables.datasource });

        // 2. Insert Showcase Seed Tasks
        var seedTasks = [
            {
                "id": "e9f42c12-70b1-4d1a-8bb8-123456789001",
                "title": "Review CFML Security & OWASP Guidelines",
                "description": "Ensure zero string concatenation in SQL queries and enforce cfqueryparam everywhere.",
                "status": "COMPLETED",
                "priority": "CRITICAL"
            },
            {
                "id": "e9f42c12-70b1-4d1a-8bb8-123456789002",
                "title": "Implement REST Routing Engine",
                "description": "Construct pure script-based router matching HTTP methods and parameter extraction.",
                "status": "COMPLETED",
                "priority": "HIGH"
            },
            {
                "id": "e9f42c12-70b1-4d1a-8bb8-123456789003",
                "title": "Configure CommandBox Server & Rewrites",
                "description": "Ensure server.json and box.json provide seamless one-click local server startup.",
                "status": "IN_PROGRESS",
                "priority": "MEDIUM"
            },
            {
                "id": "e9f42c12-70b1-4d1a-8bb8-123456789004",
                "title": "Deploy TaskMaster Showcase to Staging",
                "description": "Verify containerization and automated verification loop across all endpoints.",
                "status": "PENDING",
                "priority": "HIGH"
            }
        ];

        for (var t in seedTasks) {
            queryExecute("
                INSERT INTO tasks (id, user_id, title, description, status, priority, due_date, created_at, updated_at)
                VALUES (:id, :user_id, :title, :description, :status, :priority, :due_date, :created_at, :updated_at)
            ", {
                id = { value = t.id, cfsqltype = "cf_sql_varchar" },
                user_id = { value = demoUserId, cfsqltype = "cf_sql_varchar" },
                title = { value = t.title, cfsqltype = "cf_sql_varchar" },
                description = { value = t.description, cfsqltype = "cf_sql_varchar" },
                status = { value = t.status, cfsqltype = "cf_sql_varchar" },
                priority = { value = t.priority, cfsqltype = "cf_sql_varchar" },
                due_date = { value = dateAdd("d", 7, nowTimestamp), cfsqltype = "cf_sql_timestamp" },
                created_at = { value = nowTimestamp, cfsqltype = "cf_sql_timestamp" },
                updated_at = { value = nowTimestamp, cfsqltype = "cf_sql_timestamp" }
            }, { datasource = variables.datasource });
        }
    }
}
