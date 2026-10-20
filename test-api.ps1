# ==============================================================================
# TaskMaster API - Endpoints Verification Script (PowerShell)
# Tests the complete RESTful lifecycle: Auth -> Create -> Get -> List -> Update -> Delete
# ==============================================================================

param (
    [string]$BaseUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Title)
    Write-Host "`n>>> [STEP] $Title" -ForegroundColor Cyan
}

try {
    # 1. Health Check
    Write-Step "1. Testing Health Check (GET $BaseUrl/api/v1/health)"
    $health = Invoke-RestMethod -Uri "$BaseUrl/api/v1/health" -Method Get
    Write-Host "Status: $($health.status) | Engine: $($health.data.server.cfmlEngine) $($health.data.server.cfmlVersion) | DB: $($health.data.components.database.status)" -ForegroundColor Green

    # 2. Authentication
    Write-Step "2. Testing Authentication (POST $BaseUrl/api/v1/auth/login)"
    $loginBody = @{
        username = "demo_user"
        password = "Password123!"
    } | ConvertTo-Json

    $authResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $authResponse.data.accessToken
    Write-Host "Authenticated successfully! User: $($authResponse.data.user.username) | Role: $($authResponse.data.user.role)" -ForegroundColor Green

    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    # 3. Create Task
    Write-Step "3. Testing Create Task (POST $BaseUrl/api/v1/tasks)"
    $createBody = @{
        title       = "Automated E2E Verification Task"
        description = "Task created by automated verification script."
        priority    = "HIGH"
        status      = "IN_PROGRESS"
    } | ConvertTo-Json

    $createResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/tasks" -Method Post -Body $createBody -Headers $headers
    $createdTask = $createResponse.data
    $taskId = $createdTask.id
    Write-Host "Created Task ID: $taskId | Title: $($createdTask.title)" -ForegroundColor Green

    # 4. Get Task By ID
    Write-Step "4. Testing Get Task by ID (GET $BaseUrl/api/v1/tasks/$taskId)"
    $getTaskResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/tasks/$taskId" -Method Get -Headers $headers
    Write-Host "Retrieved Task: $($getTaskResponse.data.title) [Status: $($getTaskResponse.data.status)]" -ForegroundColor Green

    # 5. List Tasks with Filters
    Write-Step "5. Testing List Tasks (GET $BaseUrl/api/v1/tasks?priority=HIGH)"
    $listResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/tasks?priority=HIGH" -Method Get -Headers $headers
    Write-Host "Total High Priority Tasks: $($listResponse.meta.count) / Total: $($listResponse.meta.total)" -ForegroundColor Green

    # 6. Update Task
    Write-Step "6. Testing Update Task (PUT $BaseUrl/api/v1/tasks/$taskId)"
    $updateBody = @{
        status   = "COMPLETED"
        priority = "CRITICAL"
    } | ConvertTo-Json

    $updateResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/tasks/$taskId" -Method Put -Body $updateBody -Headers $headers
    Write-Host "Updated Task Status: $($updateResponse.data.status) | Priority: $($updateResponse.data.priority)" -ForegroundColor Green

    # 7. Delete Task
    Write-Step "7. Testing Delete Task (DELETE $BaseUrl/api/v1/tasks/$taskId)"
    $deleteResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/tasks/$taskId" -Method Delete -Headers $headers
    Write-Host "Task Deleted: $($deleteResponse.message)" -ForegroundColor Green

    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host "ALL REST API TESTS PASSED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
}
catch {
    Write-Host "`n[ERROR] Test failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Response Body: $($reader.ReadToEnd())" -ForegroundColor Yellow
    }
}
