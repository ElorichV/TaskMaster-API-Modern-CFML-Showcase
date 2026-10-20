/**
 * models/Task.cfc
 * Domain Entity representing a Task in the system
 * 
 * Implements encapsulation and clean state representation.
 */
component accessors="true" output="false" {

    property name="id" type="string";
    property name="userId" type="string";
    property name="title" type="string";
    property name="description" type="string";
    property name="status" type="string";
    property name="priority" type="string";
    property name="dueDate" type="string";
    property name="createdAt" type="string";
    property name="updatedAt" type="string";

    public Task function init(struct data = {}) {
        if (!structIsEmpty(arguments.data)) {
            populate(arguments.data);
        }
        return this;
    }

    /**
     * Populates entity properties from struct
     */
    public Task function populate(required struct data) {
        if (structKeyExists(arguments.data, "id")) setId(arguments.data.id);
        if (structKeyExists(arguments.data, "user_id")) setUserId(arguments.data.user_id);
        else if (structKeyExists(arguments.data, "userId")) setUserId(arguments.data.userId);

        if (structKeyExists(arguments.data, "title")) setTitle(arguments.data.title);
        if (structKeyExists(arguments.data, "description")) setDescription(arguments.data.description ?: "");
        if (structKeyExists(arguments.data, "status")) setStatus(arguments.data.status);
        if (structKeyExists(arguments.data, "priority")) setPriority(arguments.data.priority);
        
        if (structKeyExists(arguments.data, "due_date") && !isNull(arguments.data.due_date)) {
            setDueDate(isDate(arguments.data.due_date) ? dateTimeFormat(arguments.data.due_date, "yyyy-mm-dd'T'HH:nn:ss'Z'") : arguments.data.due_date);
        } else if (structKeyExists(arguments.data, "dueDate") && !isNull(arguments.data.dueDate)) {
            setDueDate(isDate(arguments.data.dueDate) ? dateTimeFormat(arguments.data.dueDate, "yyyy-mm-dd'T'HH:nn:ss'Z'") : arguments.data.dueDate);
        }

        if (structKeyExists(arguments.data, "created_at")) {
            setCreatedAt(isDate(arguments.data.created_at) ? dateTimeFormat(arguments.data.created_at, "yyyy-mm-dd'T'HH:nn:ss'Z'") : arguments.data.created_at);
        }
        if (structKeyExists(arguments.data, "updated_at")) {
            setUpdatedAt(isDate(arguments.data.updated_at) ? dateTimeFormat(arguments.data.updated_at, "yyyy-mm-dd'T'HH:nn:ss'Z'") : arguments.data.updated_at);
        }

        return this;
    }

    /**
     * Converts entity to an API-friendly struct
     */
    public struct function toStruct() {
        return {
            "id": getId() ?: "",
            "userId": getUserId() ?: "",
            "title": getTitle() ?: "",
            "description": getDescription() ?: "",
            "status": getStatus() ?: "PENDING",
            "priority": getPriority() ?: "MEDIUM",
            "dueDate": getDueDate() ?: "",
            "createdAt": getCreatedAt() ?: "",
            "updatedAt": getUpdatedAt() ?: ""
        };
    }
}
