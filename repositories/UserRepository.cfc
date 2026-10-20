/**
 * repositories/UserRepository.cfc
 * Data Access Object for User Entity
 * 
 * Strict enforcement of parameterized queries (Zero SQL Injection)
 */
component output="false" {

    property name="datasource" type="string";

    public UserRepository function init(required string datasource) {
        variables.datasource = arguments.datasource;
        return this;
    }

    /**
     * Finds a user by username
     */
    public any function findByUsername(required string username) {
        var sql = "
            SELECT id, username, email, password_hash, password_salt, role, created_at
            FROM users
            WHERE LOWER(username) = LOWER(:username)
        ";

        var params = {
            username = { value = arguments.username, cfsqltype = "cf_sql_varchar" }
        };

        var qry = queryExecute(sql, params, { datasource = variables.datasource, returnType = "array" });

        return arrayLen(qry) ? qry[1] : nullValue();
    }

    /**
     * Finds a user by ID
     */
    public any function findById(required string id) {
        var sql = "
            SELECT id, username, email, role, created_at
            FROM users
            WHERE id = :id
        ";

        var params = {
            id = { value = arguments.id, cfsqltype = "cf_sql_varchar" }
        };

        var qry = queryExecute(sql, params, { datasource = variables.datasource, returnType = "array" });

        return arrayLen(qry) ? qry[1] : nullValue();
    }

    /**
     * Inserts a new user record
     */
    public void function create(required struct user) {
        var sql = "
            INSERT INTO users (id, username, email, password_hash, password_salt, role, created_at)
            VALUES (:id, :username, :email, :password_hash, :password_salt, :role, :created_at)
        ";

        var params = {
            id = { value = arguments.user.id, cfsqltype = "cf_sql_varchar" },
            username = { value = arguments.user.username, cfsqltype = "cf_sql_varchar" },
            email = { value = arguments.user.email, cfsqltype = "cf_sql_varchar" },
            password_hash = { value = arguments.user.password_hash, cfsqltype = "cf_sql_varchar" },
            password_salt = { value = arguments.user.password_salt, cfsqltype = "cf_sql_varchar" },
            role = { value = arguments.user.role, cfsqltype = "cf_sql_varchar" },
            created_at = { value = now(), cfsqltype = "cf_sql_timestamp" }
        };

        queryExecute(sql, params, { datasource = variables.datasource });
    }
}
