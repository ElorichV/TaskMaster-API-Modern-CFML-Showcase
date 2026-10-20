<cfscript>
/**
 * index.cfm
 * Front Controller & Request Gateway
 * 
 * Intercepts rewritten REST requests and routes them through the Application Router.
 */

// 1. Resolve normalized request path
requestUri = cgi.path_info;

if (!len(trim(requestUri)) || requestUri == "/index.cfm") {
    if (structKeyExists(cgi, "request_uri") && len(trim(cgi.request_uri))) {
        requestUri = listFirst(cgi.request_uri, "?");
        requestUri = replace(requestUri, "/index.cfm", "");
    }
}

if (!len(trim(requestUri))) {
    requestUri = "/";
}

// 2. Dispatch request to Router
application.router.dispatch(
    httpMethod = cgi.request_method,
    pathInfo = requestUri,
    queryParams = url
);
</cfscript>
