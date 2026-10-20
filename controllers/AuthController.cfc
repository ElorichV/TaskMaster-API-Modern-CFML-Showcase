/**
 * controllers/AuthController.cfc
 * Authentication Endpoints Controller
 */
component extends="BaseController" output="false" {

    public AuthController function init(required any responseHandler, required any authService) {
        super.init(arguments.responseHandler, arguments.authService);
        return this;
    }

    /**
     * POST /api/v1/auth/login
     * Authenticates user credentials and returns JWT bearer token
     */
    public void function login() {
        try {
            var body = getRequestBody();
            var username = structKeyExists(body, "username") ? trim(body.username) : "";
            var password = structKeyExists(body, "password") ? body.password : "";

            var authResult = variables.authService.login(username, password);

            variables.responseHandler.sendSuccess(
                data = authResult,
                message = "Authentication successful"
            );
        } catch (any e) {
            handleException(e);
        }
    }

    /**
     * GET /api/v1/auth/me
     * Returns details of currently authenticated user
     */
    public void function me() {
        try {
            var currentUser = getAuthenticatedUser();

            variables.responseHandler.sendSuccess(
                data = {
                    "id": currentUser.sub,
                    "username": currentUser.username,
                    "email": currentUser.email,
                    "role": currentUser.role
                },
                message = "Authenticated user profile retrieved"
            );
        } catch (any e) {
            handleException(e);
        }
    }
}
