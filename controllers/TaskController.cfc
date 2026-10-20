/**
 * controllers/TaskController.cfc
 * REST Controller for Task Resources
 * 
 * Implements full RESTful CRUD interface with strict authorization and JSON responses.
 */
component extends="BaseController" output="false" {

    property name="taskService" type="any";

    public TaskController function init(
        required any responseHandler,
        required any authService,
        required any taskService
    ) {
        super.init(arguments.responseHandler, arguments.authService);
        variables.taskService = arguments.taskService;
        return this;
    }

    /**
     * GET /api/v1/tasks
     * Retrieves tasks list with optional status/priority/search filtering
     */
    public void function index(struct queryParams = {}) {
        try {
            var currentUser = getAuthenticatedUser();
            var tasksResult = variables.taskService.listTasks(currentUser.sub, arguments.queryParams);

            variables.responseHandler.sendSuccess(
                data = tasksResult.items,
                message = "Tasks retrieved successfully",
                statusCode = 200,
                meta = tasksResult.meta
            );
        } catch (any e) {
            handleException(e);
        }
    }

    /**
     * GET /api/v1/tasks/:id
     * Retrieves specific task by identifier
     */
    public void function show(required string id) {
        try {
            var currentUser = getAuthenticatedUser();
            var task = variables.taskService.getTaskById(arguments.id, currentUser.sub);

            variables.responseHandler.sendSuccess(
                data = task,
                message = "Task retrieved successfully"
            );
        } catch (any e) {
            handleException(e);
        }
    }

    /**
     * POST /api/v1/tasks
     * Creates a new task
     */
    public void function create() {
        try {
            var currentUser = getAuthenticatedUser();
            var payload = getRequestBody();

            var createdTask = variables.taskService.createTask(currentUser.sub, payload);

            variables.responseHandler.sendCreated(
                data = createdTask,
                message = "Task created successfully",
                location = "/api/v1/tasks/" & createdTask.id
            );
        } catch (any e) {
            handleException(e);
        }
    }

    /**
     * PUT /api/v1/tasks/:id
     * Updates an existing task
     */
    public void function update(required string id) {
        try {
            var currentUser = getAuthenticatedUser();
            var payload = getRequestBody();

            var updatedTask = variables.taskService.updateTask(arguments.id, currentUser.sub, payload);

            variables.responseHandler.sendSuccess(
                data = updatedTask,
                message = "Task updated successfully"
            );
        } catch (any e) {
            handleException(e);
        }
    }

    /**
     * DELETE /api/v1/tasks/:id
     * Removes a task
     */
    public void function delete(required string id) {
        try {
            var currentUser = getAuthenticatedUser();
            variables.taskService.deleteTask(arguments.id, currentUser.sub);

            variables.responseHandler.sendSuccess(
                data = { "deletedId": arguments.id },
                message = "Task deleted successfully"
            );
        } catch (any e) {
            handleException(e);
        }
    }
}
