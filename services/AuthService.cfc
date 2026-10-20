/**
 * services/AuthService.cfc
 * Authentication & Credential Verification Service
 * 
 * Orchestrates secure user authentication and stateless JWT issuance.
 */
component output="false" {

    property name="userRepository" type="any";
    property name="securityHelper" type="any";
    property name="validator" type="any";

    public AuthService function init(
        required any userRepository,
        required any securityHelper,
        required any validator
    ) {
        variables.userRepository = arguments.userRepository;
        variables.securityHelper = arguments.securityHelper;
        variables.validator = arguments.validator;
        return this;
    }

    /**
     * Authenticates user credentials and issues a signed JWT token
     */
    public struct function login(required string username, required string password) {
        // 1. Validate inputs
        if (!len(trim(arguments.username)) || !len(trim(arguments.password))) {
            throw(type = "ValidationException", message = "Username and password are required.");
        }

        // 2. Fetch user by username (Parameterized query)
        var user = variables.userRepository.findByUsername(trim(arguments.username));
        if (isNull(user)) {
            // Mitigate enumeration: return generic message
            throw(type = "AuthException", message = "Invalid username or password.");
        }

        // 3. Verify password hash using constant-time comparison
        var isPasswordValid = variables.securityHelper.verifyPassword(
            arguments.password,
            user.password_hash,
            user.password_salt
        );

        if (!isPasswordValid) {
            throw(type = "AuthException", message = "Invalid username or password.");
        }

        // 4. Generate signed JWT token
        var tokenPayload = {
            "sub": user.id,
            "username": user.username,
            "email": user.email,
            "role": user.role
        };

        var jwtToken = variables.securityHelper.generateToken(tokenPayload, 120);

        return {
            "accessToken": jwtToken,
            "tokenType": "Bearer",
            "expiresIn": 7200,
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "role": user.role
            }
        };
    }

    /**
     * Resolves authenticated user payload from Authorization Bearer header
     */
    public struct function authenticateRequest(string authorizationHeader = "") {
        if (!len(trim(arguments.authorizationHeader))) {
            throw(type = "UnauthorizedException", message = "Authorization header is missing.");
        }

        if (!reFindNoCase("^Bearer\s+[A-Za-z0-9\-\._~\+\/]+=*", arguments.authorizationHeader)) {
            throw(type = "UnauthorizedException", message = "Invalid Authorization header format. Expected 'Bearer <token>'.");
        }

        var token = trim(reReplaceNoCase(arguments.authorizationHeader, "^Bearer\s+", ""));

        try {
            return variables.securityHelper.verifyToken(token);
        } catch (any e) {
            throw(type = "UnauthorizedException", message = "Invalid or expired token: " & e.message);
        }
    }
}
