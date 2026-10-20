/**
 * services/TaskService.cfc
 * Business Logic Engine for Task Lifecycle
 * 
 * Enforces business domain invariants, input validation, and user ownership rules.
 */
component output="false" {

    property name="taskRepository" type="any";
    property name="validator" type="any";

    public TaskService function init(required any taskRepository, required any validator) {
        variables.taskRepository = arguments.taskRepository;
        variables.validator = arguments.validator;
        return this;
    }

    /**
     * Lists tasks for user with pagination and filters
     */
    public struct function listTasks(required string userId, struct filters = {}) {
        var repoResult = variables.taskRepository.getAll(arguments.userId, arguments.filters);
        
        var formattedTasks = [];
        for (var row in repoResult.items) {
            var taskEntity = new models.Task(row);
            arrayAppend(formattedTasks, taskEntity.toStruct());
        }

        return {
            "items": formattedTasks,
            "meta": {
                "total": repoResult.total,
                "count": arrayLen(formattedTasks),
                "limit": repoResult.limit,
                "offset": repoResult.offset
            }
        };
    }

    /**
     * Retrieves single task by ID scoped to user
     */
    public struct function getTaskById(required string id, required string userId) {
        var rawTask = variables.taskRepository.getById(arguments.id, arguments.userId);
        
        if (isNull(rawTask)) {
            throw(type = "ResourceNotFoundException", message = "Task with ID '#arguments.id#' was not found.");
        }

        return new models.Task(rawTask).toStruct();
    }

    /**
     * Creates a new task with strict schema validation
     */
    public struct function createTask(required string userId, required struct payload) {
        // 1. Validation Schema
        var rules = {
            "title": { "required": true, "type": "string", "minLength": 3, "maxLength": 200 },
            "description": { "required": false, "type": "string", "maxLength": 1000 },
            "status": { "required": false, "type": "string", "in": ["PENDING", "IN_PROGRESS", "COMPLETED", "ARCHIVED"] },
            "priority": { "required": false, "type": "string", "in": ["LOW", "MEDIUM", "HIGH", "CRITICAL"] },
            "dueDate": { "required": false, "type": "date" }
        };

        var validation = variables.validator.validate(arguments.payload, rules);
        if (!validation.isValid) {
            var errorException = new core.ResponseHandler(); // create custom carrier or throw
            throw(type = "ValidationException", message = "Task payload validation failed", extendedInfo = serializeJSON(validation.errors));
        }

        // 2. Prepare Domain Model
        var newId = createUUID();
        var taskData = {
            "id": newId,
            "userId": arguments.userId,
            "title": variables.validator.sanitizeString(arguments.payload.title),
            "description": structKeyExists(arguments.payload, "description") ? variables.validator.sanitizeString(arguments.payload.description) : "",
            "status": structKeyExists(arguments.payload, "status") ? uCase(trim(arguments.payload.status)) : "PENDING",
            "priority": structKeyExists(arguments.payload, "priority") ? uCase(trim(arguments.payload.priority)) : "MEDIUM",
            "dueDate": structKeyExists(arguments.payload, "dueDate") ? arguments.payload.dueDate : nullValue()
        };

        // 3. Persist via Repository
        variables.taskRepository.create(taskData);

        return getTaskById(newId, arguments.userId);
    }

    /**
     * Updates an existing task
     */
    public struct function updateTask(required string id, required string userId, required struct payload) {
        // 1. Ensure task exists and belongs to user
        var existingTask = getTaskById(arguments.id, arguments.userId);

        // 2. Validation Schema
        var rules = {
            "title": { "required": false, "type": "string", "minLength": 3, "maxLength": 200 },
            "description": { "required": false, "type": "string", "maxLength": 1000 },
            "status": { "required": false, "type": "string", "in": ["PENDING", "IN_PROGRESS", "COMPLETED", "ARCHIVED"] },
            "priority": { "required": false, "type": "string", "in": ["LOW", "MEDIUM", "HIGH", "CRITICAL"] },
            "dueDate": { "required": false, "type": "date" }
        };

        var validation = variables.validator.validate(arguments.payload, rules);
        if (!validation.isValid) {
            throw(type = "ValidationException", message = "Task update validation failed", extendedInfo = serializeJSON(validation.errors));
        }

        // 3. Merge Updates
        var updatedData = {
            "id": arguments.id,
            "userId": arguments.userId,
            "title": structKeyExists(arguments.payload, "title") ? variables.validator.sanitizeString(arguments.payload.title) : existingTask.title,
            "description": structKeyExists(arguments.payload, "description") ? variables.validator.sanitizeString(arguments.payload.description) : existingTask.description,
            "status": structKeyExists(arguments.payload, "status") ? uCase(trim(arguments.payload.status)) : existingTask.status,
            "priority": structKeyExists(arguments.payload, "priority") ? uCase(trim(arguments.payload.priority)) : existingTask.priority,
            "dueDate": structKeyExists(arguments.payload, "dueDate") ? arguments.payload.dueDate : (len(existingTask.dueDate) ? existingTask.dueDate : nullValue())
        };

        variables.taskRepository.update(updatedData);

        return getTaskById(arguments.id, arguments.userId);
    }

    /**
     * Deletes task scoped to user
     */
    public void function deleteTask(required string id, required string userId) {
        // Verify existence first
        getTaskById(arguments.id, arguments.userId);

        var deleted = variables.taskRepository.delete(arguments.id, arguments.userId);
        if (!deleted) {
            throw(type = "ResourceNotFoundException", message = "Task with ID '#arguments.id#' could not be deleted.");
        }
    }
}
