/**
 * core/Validator.cfc
 * Robust Schema & Input Validation Engine
 * 
 * Enforces Zero-Trust boundary validation before payloads reach the service layer.
 */
component output="false" {

    public Validator function init() {
        return this;
    }

    /**
     * Validates a struct payload against a set of rules
     * @rules struct of field definitions: { fieldName = { required = boolean, type = string, minLength = n, maxLength = n, in = [..], pattern = "..." } }
     * @return struct with isValid: boolean, errors: array of structs
     */
    public struct function validate(required struct payload, required struct rules) {
        var result = {
            "isValid": true,
            "errors": []
        };

        for (var fieldName in arguments.rules) {
            var rule = arguments.rules[fieldName];
            var exists = structKeyExists(arguments.payload, fieldName) && !isNull(arguments.payload[fieldName]);
            var rawValue = exists ? arguments.payload[fieldName] : "";

            // Check Required
            if (structKeyExists(rule, "required") && rule.required) {
                if (!exists || (isSimpleValue(rawValue) && len(trim(toString(rawValue))) == 0)) {
                    result.isValid = false;
                    arrayAppend(result.errors, {
                        "field": fieldName,
                        "rule": "required",
                        "message": "Field '#fieldName#' is required."
                    });
                    continue; // Skip further checks if missing and required
                }
            }

            // If field is optional and not provided, continue to next field
            if (!exists || (isSimpleValue(rawValue) && len(trim(toString(rawValue))) == 0)) {
                continue;
            }

            // Check Data Type
            if (structKeyExists(rule, "type")) {
                var valType = lCase(rule.type);
                var typeValid = true;

                switch (valType) {
                    case "string":
                        typeValid = isSimpleValue(rawValue);
                        break;
                    case "numeric":
                    case "integer":
                        typeValid = isNumeric(rawValue);
                        break;
                    case "boolean":
                        typeValid = isBoolean(rawValue);
                        break;
                    case "date":
                        typeValid = isDate(rawValue);
                        break;
                    case "uuid":
                        typeValid = isValid("uuid", rawValue) || isValid("guid", rawValue);
                        break;
                    case "email":
                        typeValid = isValid("email", rawValue);
                        break;
                    case "array":
                        typeValid = isArray(rawValue);
                        break;
                    case "struct":
                        typeValid = isStruct(rawValue);
                        break;
                }

                if (!typeValid) {
                    result.isValid = false;
                    arrayAppend(result.errors, {
                        "field": fieldName,
                        "rule": "type",
                        "message": "Field '#fieldName#' must be of type '#rule.type#'."
                    });
                    continue;
                }
            }

            // Check Minimum Length (for strings)
            if (structKeyExists(rule, "minLength") && isSimpleValue(rawValue)) {
                if (len(trim(rawValue)) < rule.minLength) {
                    result.isValid = false;
                    arrayAppend(result.errors, {
                        "field": fieldName,
                        "rule": "minLength",
                        "message": "Field '#fieldName#' must be at least #rule.minLength# characters."
                    });
                }
            }

            // Check Maximum Length (for strings)
            if (structKeyExists(rule, "maxLength") && isSimpleValue(rawValue)) {
                if (len(trim(rawValue)) > rule.maxLength) {
                    result.isValid = false;
                    arrayAppend(result.errors, {
                        "field": fieldName,
                        "rule": "maxLength",
                        "message": "Field '#fieldName#' cannot exceed #rule.maxLength# characters."
                    });
                }
            }

            // Check Enum membership (in)
            if (structKeyExists(rule, "in") && isArray(rule.in)) {
                var stringValue = uCase(trim(rawValue));
                var matchFound = false;
                for (var allowedOption in rule.in) {
                    if (uCase(allowedOption) == stringValue) {
                        matchFound = true;
                        break;
                    }
                }
                if (!matchFound) {
                    result.isValid = false;
                    arrayAppend(result.errors, {
                        "field": fieldName,
                        "rule": "in",
                        "message": "Field '#fieldName#' must be one of: [#arrayToList(rule.in, ', ')#]."
                    });
                }
            }

            // Check Regex Pattern
            if (structKeyExists(rule, "pattern") && isSimpleValue(rawValue)) {
                if (!reFind(rule.pattern, rawValue)) {
                    result.isValid = false;
                    arrayAppend(result.errors, {
                        "field": fieldName,
                        "rule": "pattern",
                        "message": structKeyExists(rule, "patternMessage") ? rule.patternMessage : "Field '#fieldName#' does not match the required pattern."
                    });
                }
            }
        }

        return result;
    }

    /**
     * Sanitizes string input to prevent XSS and control character injection
     */
    public string function sanitizeString(required string input) {
        var cleaned = trim(arguments.input);
        // Strip null bytes and non-printable characters
        cleaned = reReplace(cleaned, "[\x00-\x08\x0B\x0C\x0E-\x1F]", "", "all");
        return cleaned;
    }
}
