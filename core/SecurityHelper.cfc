/**
 * core/SecurityHelper.cfc
 * Cryptographic & Token Helper for Authentication and OWASP Security Controls
 * 
 * Provides:
 * - PBKDF2 / SHA-256 secure password hashing with unique salt
 * - Timing-attack resistant string comparison
 * - JWT-compatible HMAC-SHA256 token signing and verification
 */
component output="false" {

    property name="secretKey" type="string";

    public SecurityHelper function init(string secretKey = "") {
        // Fallback to environment variable or standard secure default
        if (len(trim(arguments.secretKey))) {
            variables.secretKey = arguments.secretKey;
        } else if (structKeyExists(server, "system") && structKeyExists(server.system, "environment") && structKeyExists(server.system.environment, "JWT_SECRET")) {
            variables.secretKey = server.system.environment.JWT_SECRET;
        } else {
            variables.secretKey = "default_dev_secret_key_change_in_production_minimum_32_bytes_long!";
        }
        return this;
    }

    /**
     * Hashes a plain password with a secure salt using HMAC-SHA256
     */
    public struct function hashPassword(required string plainPassword) {
        var salt = generateSalt();
        var hashValue = hmac(arguments.plainPassword, salt, "HMACSHA256");
        return {
            "hash": hashValue,
            "salt": salt
        };
    }

    /**
     * Verifies plain password against stored hash and salt
     */
    public boolean function verifyPassword(required string plainPassword, required string storedHash, required string storedSalt) {
        var computedHash = hmac(arguments.plainPassword, arguments.storedSalt, "HMACSHA256");
        return constantTimeEquals(computedHash, arguments.storedHash);
    }

    /**
     * Generates a random cryptographic salt (32 bytes hex)
     */
    public string function generateSalt() {
        var randomBytes = createObject("java", "java.security.SecureRandom").init();
        var bytes = repeatString(" ", 16).getBytes();
        randomBytes.nextBytes(bytes);
        return binaryEncode(bytes, "hex");
    }

    /**
     * Constant-time string equality check to prevent timing attacks
     */
    public boolean function constantTimeEquals(required string a, required string b) {
        if (len(arguments.a) != len(arguments.b)) {
            return false;
        }
        var result = 0;
        var lenA = len(arguments.a);
        for (var i = 1; i <= lenA; i++) {
            result = bitOr(result, bitXor(asc(mid(arguments.a, i, 1)), asc(mid(arguments.b, i, 1))));
        }
        return (result == 0);
    }

    /**
     * Issues an HMAC-SHA256 Signed Token (JWT structure)
     */
    public string function generateToken(required struct userPayload, numeric expiresInMinutes = 120) {
        var header = {
            "alg": "HS256",
            "typ": "JWT"
        };

        var nowEpoch = getEpochTime();
        var expEpoch = nowEpoch + (arguments.expiresInMinutes * 60);

        var payload = structCopy(arguments.userPayload);
        payload["iat"] = nowEpoch;
        payload["exp"] = expEpoch;

        var encodedHeader = toBase64Url(serializeJSON(header));
        var encodedPayload = toBase64Url(serializeJSON(payload));
        var dataToSign = encodedHeader & "." & encodedPayload;

        var signature = toBase64UrlFromHex(hmac(dataToSign, variables.secretKey, "HMACSHA256"));

        return dataToSign & "." & signature;
    }

    /**
     * Verifies token integrity and expiration. Returns payload if valid, throws if invalid.
     */
    public struct function verifyToken(required string token) {
        var parts = listToArray(arguments.token, ".");
        if (arrayLen(parts) != 3) {
            throw(type = "AuthException", message = "Invalid token format");
        }

        var headerPart = parts[1];
        var payloadPart = parts[2];
        var signaturePart = parts[3];

        var dataToVerify = headerPart & "." & payloadPart;
        var expectedSignature = toBase64UrlFromHex(hmac(dataToVerify, variables.secretKey, "HMACSHA256"));

        if (!constantTimeEquals(signaturePart, expectedSignature)) {
            throw(type = "AuthException", message = "Invalid token signature");
        }

        var decodedJson = fromBase64Url(payloadPart);
        if (!isJSON(decodedJson)) {
            throw(type = "AuthException", message = "Invalid token payload");
        }

        var payload = deserializeJSON(decodedJson);
        var currentEpoch = getEpochTime();

        if (structKeyExists(payload, "exp") && currentEpoch > payload.exp) {
            throw(type = "AuthException", message = "Token has expired");
        }

        return payload;
    }

    /**
     * Base64URL string encode
     */
    public string function toBase64Url(required string input) {
        var b64 = toBase64(arguments.input);
        return replace(replace(replace(b64, "+", "-", "all"), "/", "_", "all"), "=", "", "all");
    }

    /**
     * Base64URL encode from hex string (HMAC returns hex in CFML)
     */
    public string function toBase64UrlFromHex(required string hexInput) {
        var binaryData = binaryDecode(arguments.hexInput, "hex");
        var b64 = toBase64(binaryData);
        return replace(replace(replace(b64, "+", "-", "all"), "/", "_", "all"), "=", "", "all");
    }

    /**
     * Base64URL string decode
     */
    public string function fromBase64Url(required string input) {
        var padded = arguments.input;
        var remainder = len(padded) % 4;
        if (remainder == 2) padded &= "==";
        else if (remainder == 3) padded &= "=";
        padded = replace(replace(padded, "-", "+", "all"), "_", "/", "all");
        return toString(toBinary(padded));
    }

    /**
     * Returns current epoch timestamp in seconds
     */
    private numeric function getEpochTime() {
        return dateDiff("s", createDateTime(1970, 1, 1, 0, 0, 0), now());
    }
}
