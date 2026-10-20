/**
 * core/Router.cfc
 * RESTful Request Router and Dispatcher
 * 
 * Supports dynamic path parameters (:id), HTTP method matching,
 * CORS preflight requests, and route dispatching.
 */
component output="false" {

    property name="routes" type="array";
    property name="responseHandler" type="any";

    public Router function init(required any responseHandler) {
        variables.routes = [];
        variables.responseHandler = arguments.responseHandler;
        return this;
    }

    /**
     * Registers a route definition
     */
    public Router function addRoute(
        required string method,
        required string pattern,
        required any controller,
        required string action
    ) {
        // Convert pattern like "/api/v1/tasks/:id" to regex "^/api/v1/tasks/([^/]+)$"
        var paramNames = [];
        var regexPattern = arguments.pattern;

        var matches = reMatch(":[a-zA-Z0-9_]+", arguments.pattern);
        for (var paramMatch in matches) {
            arrayAppend(paramNames, right(paramMatch, len(paramMatch) - 1));
            regexPattern = replace(regexPattern, paramMatch, "([^/]+)");
        }

        regexPattern = "^" & regexPattern & "$";

        arrayAppend(variables.routes, {
            "httpMethod": uCase(arguments.method),
            "originalPattern": arguments.pattern,
            "regexPattern": regexPattern,
            "paramNames": paramNames,
            "controller": arguments.controller,
            "action": arguments.action
        });

        return this;
    }

    /**
     * Dispatches request to the appropriate controller action
     */
    public void function dispatch(required string httpMethod, required string pathInfo, struct queryParams = {}) {
        var cleanMethod = uCase(trim(arguments.httpMethod));
        var cleanPath = trim(arguments.pathInfo);

        // Normalize empty or root path
        if (!len(cleanPath)) {
            cleanPath = "/";
        }

        // Handle CORS Preflight OPTIONS
        if (cleanMethod == "OPTIONS") {
            cfheader(name = "Access-Control-Allow-Origin", value = "*");
            cfheader(name = "Access-Control-Allow-Methods", value = "GET, POST, PUT, DELETE, OPTIONS");
            cfheader(name = "Access-Control-Allow-Headers", value = "Content-Type, Authorization, X-Requested-With");
            cfheader(statuscode = 200, statustext = "OK");
            abort;
        }

        var pathMatched = false;

        for (var route in variables.routes) {
            // Check URI regex match
            var matchInfo = reFind(route.regexPattern, cleanPath, 1, true);

            if (matchInfo.pos[1] > 0) {
                pathMatched = true;

                // Check HTTP method match
                if (route.httpMethod == cleanMethod || route.httpMethod == "ANY") {
                    // Extract route params
                    var extractedArgs = {};

                    // Add query params
                    for (var qk in arguments.queryParams) {
                        extractedArgs[qk] = arguments.queryParams[qk];
                    }

                    // Extract captured parameters (:id)
                    var paramCount = arrayLen(route.paramNames);
                    for (var i = 1; i <= paramCount; i++) {
                        var groupIndex = i + 1;
                        if (arrayLen(matchInfo.pos) >= groupIndex && matchInfo.len[groupIndex] > 0) {
                            var paramValue = mid(cleanPath, matchInfo.pos[groupIndex], matchInfo.len[groupIndex]);
                            extractedArgs[route.paramNames[i]] = paramValue;
                        }
                    }

                    // Invoke controller method
                    var controllerObj = route.controller;
                    var actionMethod = route.action;

                    // If action accepts argument collection
                    invoke(controllerObj, actionMethod, extractedArgs);
                    return;
                }
            }
        }

        if (pathMatched) {
            variables.responseHandler.sendError(
                message = "HTTP Method '#cleanMethod#' is not supported for URI: '#cleanPath#'.",
                statusCode = 405,
                title = "Method Not Allowed"
            );
        } else {
            variables.responseHandler.sendNotFound(
                message = "The requested endpoint '#cleanPath#' does not exist."
            );
        }
    }
}
