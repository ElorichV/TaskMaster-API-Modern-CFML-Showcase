/**
 * repositories/TaskRepository.cfc
 * Data Access Object for Tasks
 * 
 * Implements Repository Pattern with 100% Parameterized queries.
 * Enforces User-Tenancy filtering on all operations to prevent BOLA / IDOR vulnerabilities.
 */
component output="false" {

    property name="datasource" type="string";

    public TaskRepository function init(required string datasource) {
        variables.datasource = arguments.datasource;
        return this;
    }

    /**
     * Retrieves paginated tasks filtered by user and criteria
     */
    public struct function getAll(required string userId, struct filters = {}) {
        var baseSql = "
            FROM tasks
            WHERE user_id = :user_id
        ";

        var params = {
            user_id = { value = arguments.userId, cfsqltype = "cf_sql_varchar" }
        };

        // Filter: Status
        if (structKeyExists(arguments.filters, "status") && len(trim(arguments.filters.status))) {
            baseSql &= " AND status = :status";
            params["status"] = { value = uCase(trim(arguments.filters.status)), cfsqltype = "cf_sql_varchar" };
        }

        // Filter: Priority
        if (structKeyExists(arguments.filters, "priority") && len(trim(arguments.filters.priority))) {
            baseSql &= " AND priority = :priority";
            params["priority"] = { value = uCase(trim(arguments.filters.priority)), cfsqltype = "cf_sql_varchar" };
        }

        // Filter: Full-text like search
        if (structKeyExists(arguments.filters, "search") && len(trim(arguments.filters.search))) {
            baseSql &= " AND (LOWER(title) LIKE :search OR LOWER(description) LIKE :search)";
            params["search"] = { value = "%" & lCase(trim(arguments.filters.search)) & "%", cfsqltype = "cf_sql_varchar" };
        }

        // 1. Get total count
        var countSql = "SELECT COUNT(*) AS total " & baseSql;
        var countResult = queryExecute(countSql, params, { datasource = variables.datasource });
        var totalRecords = countResult.total;

        // 2. Fetch paginated records
        var limit = (structKeyExists(arguments.filters, "limit") && isNumeric(arguments.filters.limit) && arguments.filters.limit > 0) ? min(val(arguments.filters.limit), 100) : 20;
        var offset = (structKeyExists(arguments.filters, "offset") && isNumeric(arguments.filters.offset) && arguments.filters.offset >= 0) ? val(arguments.filters.offset) : 0;

        var dataSql = "
            SELECT id, user_id, title, description, status, priority, due_date, created_at, updated_at
            " & baseSql & "
            ORDER BY created_at DESC
            LIMIT :limit OFFSET :offset
        ";

        params["limit"] = { value = limit, cfsqltype = "cf_sql_integer" };
        params["offset"] = { value = offset, cfsqltype = "cf_sql_integer" };

        var records = queryExecute(dataSql, params, { datasource = variables.datasource, returnType = "array" });

        return {
            "items": records,
            "total": totalRecords,
            "limit": limit,
            "offset": offset
        };
    }

    /**
     * Retrieves single task by ID scoped to authenticated user
     */
    public any function getById(required string id, required string userId) {
        var sql = "
            SELECT id, user_id, title, description, status, priority, due_date, created_at, updated_at
            FROM tasks
            WHERE id = :id AND user_id = :user_id
        ";

        var params = {
            id = { value = arguments.id, cfsqltype = "cf_sql_varchar" },
            user_id = { value = arguments.userId, cfsqltype = "cf_sql_varchar" }
        };

        var records = queryExecute(sql, params, { datasource = variables.datasource, returnType = "array" });

        return arrayLen(records) ? records[1] : nullValue();
    }

    /**
     * Creates a new task
     */
    public void function create(required struct taskData) {
        var sql = "
            INSERT INTO tasks (id, user_id, title, description, status, priority, due_date, created_at, updated_at)
            VALUES (:id, :user_id, :title, :description, :status, :priority, :due_date, :created_at, :updated_at)
        ";

        var hasDueDate = structKeyExists(arguments.taskData, "dueDate") && !isNull(arguments.taskData.dueDate) && isDate(arguments.taskData.dueDate);

        var params = {
            id = { value = arguments.taskData.id, cfsqltype = "cf_sql_varchar" },
            user_id = { value = arguments.taskData.userId, cfsqltype = "cf_sql_varchar" },
            title = { value = arguments.taskData.title, cfsqltype = "cf_sql_varchar" },
            description = { value = arguments.taskData.description ?: "", cfsqltype = "cf_sql_varchar", null = len(arguments.taskData.description ?: "") == 0 },
            status = { value = arguments.taskData.status, cfsqltype = "cf_sql_varchar" },
            priority = { value = arguments.taskData.priority, cfsqltype = "cf_sql_varchar" },
            due_date = { value = hasDueDate ? parseDateTime(arguments.taskData.dueDate) : now(), cfsqltype = "cf_sql_timestamp", null = !hasDueDate },
            created_at = { value = now(), cfsqltype = "cf_sql_timestamp" },
            updated_at = { value = now(), cfsqltype = "cf_sql_timestamp" }
        };

        queryExecute(sql, params, { datasource = variables.datasource });
    }

    /**
     * Updates an existing task scoped to user
     */
    public boolean function update(required struct taskData) {
        var hasDueDate = structKeyExists(arguments.taskData, "dueDate") && !isNull(arguments.taskData.dueDate) && isDate(arguments.taskData.dueDate);

        var sql = "
            UPDATE tasks
            SET title = :title,
                description = :description,
                status = :status,
                priority = :priority,
                due_date = :due_date,
                updated_at = :updated_at
            WHERE id = :id AND user_id = :user_id
        ";

        var params = {
            id = { value = arguments.taskData.id, cfsqltype = "cf_sql_varchar" },
            user_id = { value = arguments.taskData.userId, cfsqltype = "cf_sql_varchar" },
            title = { value = arguments.taskData.title, cfsqltype = "cf_sql_varchar" },
            description = { value = arguments.taskData.description ?: "", cfsqltype = "cf_sql_varchar", null = len(arguments.taskData.description ?: "") == 0 },
            status = { value = arguments.taskData.status, cfsqltype = "cf_sql_varchar" },
            priority = { value = arguments.taskData.priority, cfsqltype = "cf_sql_varchar" },
            due_date = { value = hasDueDate ? parseDateTime(arguments.taskData.dueDate) : now(), cfsqltype = "cf_sql_timestamp", null = !hasDueDate },
            updated_at = { value = now(), cfsqltype = "cf_sql_timestamp" }
        };

        var result = queryExecute(sql, params, { datasource = variables.datasource, result = "updateInfo" });

        return structKeyExists(updateInfo, "recordCount") && updateInfo.recordCount > 0;
    }

    /**
     * Deletes a task scoped to user
     */
    public boolean function delete(required string id, required string userId) {
        var sql = "
            DELETE FROM tasks
            WHERE id = :id AND user_id = :user_id
        ";

        var params = {
            id = { value = arguments.id, cfsqltype = "cf_sql_varchar" },
            user_id = { value = arguments.userId, cfsqltype = "cf_sql_varchar" }
        };

        var result = queryExecute(sql, params, { datasource = variables.datasource, result = "deleteInfo" });

        return structKeyExists(deleteInfo, "recordCount") && deleteInfo.recordCount > 0;
    }
}
