/**
 * controllers/HealthController.cfc
 * Health Check & System Diagnostics Controller
 */
component extends="BaseController" output="false" {

    property name="datasource" type="string";

    public HealthController function init(
        required any responseHandler,
        required any authService,
        required string datasource
    ) {
        super.init(arguments.responseHandler, arguments.authService);
        variables.datasource = arguments.datasource;
        return this;
    }

    /**
     * GET /api/v1/health
     * Returns service health and verifies database connectivity
     */
    public void function check() {
        var dbStatus = "UP";
        var dbLatencyMs = 0;
        var startTick = getTickCount();

        try {
            queryExecute("SELECT 1 AS probe", {}, { datasource = variables.datasource });
            dbLatencyMs = getTickCount() - startTick;
        } catch (any e) {
            dbStatus = "DOWN";
        }

        var healthData = {
            "status": (dbStatus == "UP") ? "HEALTHY" : "DEGRADED",
            "environment": server.system.environment.ENVIRONMENT ?: "development",
            "server": {
                "cfmlEngine": server.coldfusion.productname ?: "Lucee",
                "cfmlVersion": server.coldfusion.productversion ?: "unknown",
                "os": server.os.name ?: "unknown"
            },
            "components": {
                "database": {
                    "status": dbStatus,
                    "datasource": variables.datasource,
                    "latencyMs": dbLatencyMs
                }
            }
        };

        var httpStatusCode = (dbStatus == "UP") ? 200 : 503;
        variables.responseHandler.sendSuccess(
            data = healthData,
            message = "Health check executed successfully",
            statusCode = httpStatusCode
        );
    }
}
