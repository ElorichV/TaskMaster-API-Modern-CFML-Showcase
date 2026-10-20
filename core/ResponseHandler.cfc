/**
 * core/ResponseHandler.cfc
 * Standardized JSON Response Formatter & RFC 7807 Problem Details Helper
 * 
 * Ensures every API response adheres to a predictable, secure contract
 * without leaking server internals, file paths, or raw stack traces.
 */
component output="false" {

    public ResponseHandler function init() {
        return this;
    }

    /**
     * Send standard 200 OK success response
     */
    public void function sendSuccess(
        any data = {},
        string message = "Operation completed successfully",
        numeric statusCode = 200,
        struct meta = {}
    ) {
        var payload = {
            "success": true,
            "status": arguments.statusCode,
            "message": arguments.message,
            "data": arguments.data,
            "meta": structIsEmpty(arguments.meta) ? {
                "timestamp": dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss'Z'"),
                "version": "1.0.0"
            } : arguments.meta
        };

        this.renderJson(payload, arguments.statusCode);
    }

    /**
     * Send 201 Created response with optional Location header
     */
    public void function sendCreated(
        any data = {},
        string message = "Resource created successfully",
        string location = ""
    ) {
        if (len(trim(arguments.location))) {
            cfheader(name = "Location", value = arguments.location);
        }
        this.sendSuccess(
            data = arguments.data,
            message = arguments.message,
            statusCode = 201
        );
    }

    /**
     * Send 204 No Content response
     */
    public void function sendNoContent() {
        cfheader(statuscode = 204, statustext = "No Content");
        abort;
    }

    /**
     * Send standard error response adhering to RFC 7807 / standard JSON envelope
     */
    public void function sendError(
        required string message,
        numeric statusCode = 400,
        array errors = [],
        string title = "Bad Request",
        string detail = ""
    ) {
        var payload = {
            "success": false,
            "status": arguments.statusCode,
            "title": arguments.title,
            "message": arguments.message,
            "detail": len(trim(arguments.detail)) ? arguments.detail : arguments.message,
            "errors": arguments.errors,
            "timestamp": dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss'Z'")
        };

        this.renderJson(payload, arguments.statusCode);
    }

    /**
     * Send 404 Not Found
     */
    public void function sendNotFound(string message = "The requested resource was not found") {
        this.sendError(
            message = arguments.message,
            statusCode = 404,
            title = "Not Found"
        );
    }

    /**
     * Send 401 Unauthorized
     */
    public void function sendUnauthorized(string message = "Authentication is required to access this resource") {
        cfheader(name = "WWW-Authenticate", value = "Bearer realm=""TaskMaster API""");
        this.sendError(
            message = arguments.message,
            statusCode = 401,
            title = "Unauthorized"
        );
    }

    /**
     * Send 403 Forbidden
     */
    public void function sendForbidden(string message = "You do not have permission to perform this action") {
        this.sendError(
            message = arguments.message,
            statusCode = 403,
            title = "Forbidden"
        );
    }

    /**
     * Send 422 Unprocessable Entity for validation failures
     */
    public void function sendValidationError(required array errors, string message = "Validation failed for the request payload") {
        this.sendError(
            message = arguments.message,
            statusCode = 422,
            title = "Unprocessable Entity",
            errors = arguments.errors
        );
    }

    /**
     * Send 500 Internal Server Error (Masks sensitive internal errors)
     */
    public void function sendInternalError(
        string message = "An internal server error occurred. Please contact system administrator.",
        string trackingId = ""
    ) {
        var errorId = len(trim(arguments.trackingId)) ? arguments.trackingId : createUUID();
        
        var payload = {
            "success": false,
            "status": 500,
            "title": "Internal Server Error",
            "message": arguments.message,
            "trackingId": errorId,
            "timestamp": dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss'Z'")
        };

        this.renderJson(payload, 500);
    }

    /**
     * Internal JSON renderer with proper headers and encoding
     */
    public void function renderJson(required any data, numeric statusCode = 200) {
        cfheader(statuscode = arguments.statusCode);
        cfcontent(type = "application/json; charset=utf-8", reset = true);
        writeOutput(serializeJSON(arguments.data));
        abort;
    }
}
