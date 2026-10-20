/**
 * controllers/BaseController.cfc
 * Foundation for all REST API Controllers
 * 
 * Centralizes request payload parsing, authentication guards, and exception handling.
 */
component output="false" {

    property name="responseHandler" type="any";
    property name="authService" type="any";

    public BaseController function init(required any responseHandler, required any authService) {
        variables.responseHandler = arguments.responseHandler;
        variables.authService = arguments.authService;
        return this;
    }

    /**
     * Parses and deserializes incoming JSON body
     */
    public struct function getRequestBody() {
        var rawData = getHttpRequestData();
        var content = rawData.content;

        if (isBinary(content)) {
            content = charsetEncode(content, "utf-8");
        }

        if (!len(trim(content))) {
            return {};
        }

        if (!isJSON(content)) {
            variables.responseHandler.sendError(
                message = "Malformed JSON payload provided.",
                statusCode = 400,
                title = "Bad Request"
            );
        }

        return deserializeJSON(content);
    }

    /**
     * Resolves authenticated user from Bearer Token
     */
    public struct function getAuthenticatedUser() {
        var httpData = getHttpRequestData();
        var authHeader = "";

        // Normalize case across servlet containers
        if (structKeyExists(httpData.headers, "Authorization")) {
            authHeader = httpData.headers["Authorization"];
        } else if (structKeyExists(httpData.headers, "authorization")) {
            authHeader = httpData.headers["authorization"];
        }

        return variables.authService.authenticateRequest(authHeader);
    }

    /**
     * Standardized controller exception boundary
     */
    public void function handleException(required any e) {
        var errType = structKeyExists(arguments.e, "type") ? arguments.e.type : "Generic";

        switch (errType) {
            case "ValidationException":
                var errors = [];
                if (structKeyExists(arguments.e, "extendedInfo") && isJSON(arguments.e.extendedInfo)) {
                    errors = deserializeJSON(arguments.e.extendedInfo);
                }
                variables.responseHandler.sendValidationError(
                    errors = errors,
                    message = arguments.e.message
                );
                break;

            case "UnauthorizedException":
            case "AuthException":
                variables.responseHandler.sendUnauthorized(arguments.e.message);
                break;

            case "ForbiddenException":
                variables.responseHandler.sendForbidden(arguments.e.message);
                break;

            case "ResourceNotFoundException":
                variables.responseHandler.sendNotFound(arguments.e.message);
                break;

            default:
                // Log full internal exception details securely to server console
                var trackingId = createUUID();
                systemOutput("[API Error #" & trackingId & "] " & arguments.e.message & " | Stack: " & (arguments.e.stackTrace ?: ""), true);
                
                variables.responseHandler.sendInternalError(
                    message = "An unexpected error occurred while processing your request.",
                    trackingId = trackingId
                );
                break;
        }
    }
}
