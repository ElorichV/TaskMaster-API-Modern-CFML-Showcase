# TaskMaster API - Modern CFML (Lucee / ColdFusion) Showcase

[![CFML](https://img.shields.io/badge/CFML-Script%20Syntax-blue.svg)](https://lucee.org/)
[![Engine](https://img.shields.io/badge/Lucee-5.4%20%7C%206.x-green.svg)](https://lucee.org/)
[![ColdFusion](https://img.shields.io/badge/Adobe%20ColdFusion-2021%2B-orange.svg)](https://www.adobe.com/products/coldfusion-family.html)
[![CommandBox](https://img.shields.io/badge/CommandBox-Compatible-yellow.svg)](https://www.ortussolutions.com/products/commandbox)
[![OWASP](https://img.shields.io/badge/Security-OWASP%20Hardened-red.svg)](#seguridad-innegociable-zero-tolerance-appsec)

> Caso de estudio de nivel **Senior Backend Architect** en **CFML Moderno** (Lucee / Adobe ColdFusion). Implementación completa en **100% sintaxis Script (`cfscript`)**, desacoplamiento de capas (Clean Architecture / Separación de Responsabilidades), prevención absoluta de SQL Injection mediante consultas 100% parametrizadas, autenticación JWT stateless, validación rigurosa de entradas y respuestas JSON estandarizadas (RFC 7807).

---

## Índice

1. [Arquitectura y Principios de Diseño](#arquitectura-y-principios-de-diseño)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Seguridad Innegociable (Zero-Tolerance AppSec)](#seguridad-innegociable-zero-tolerance-appsec)
4. [Inicio Rápido con CommandBox](#inicio-rápido-con-commandbox)
5. [Colección Completa de Endpoints](#colección-completa-de-endpoints)
   - [Health Check](#1-health-check)
   - [Autenticación](#2-autenticación)
   - [Gestión de Tareas (CRUD)](#3-gestión-de-tareas-crud)
6. [Manejo de Errores y Códigos HTTP](#manejo-de-errores-y-códigos-http)
7. [Script de Verificación Automatizado](#script-de-verificación-automatizado)

---

## Arquitectura y Principios de Diseño

El proyecto implementa una arquitectura desacoplada en capas inspirada en **Clean Architecture** y patrones empresariales modernos:

```
           [ Cliente HTTP / API Consumer ]
                          │
                          ▼
            [ Router & Rewrites (index.cfm) ]
                          │
                          ▼
    ┌──────────────────────────────────────────────┐
    │              REST Controllers                │  <-- controllers/
    │  - Extracción de Headers / Request Body      │
    │  - Manejo de Códigos de Estado HTTP          │
    │  - Formateo de Respuestas JSON Uniformes     │
    └─────────────────────┬────────────────────────┘
                          │
                          ▼
    ┌──────────────────────────────────────────────┐
    │             Servicios de Dominio             │  <-- services/
    │  - Reglas de Negocio e Invariantes           │
    │  - Orquestación de Autenticación             │
    │  - Validación de Schemas (core/Validator)    │
    └─────────────────────┬────────────────────────┘
                          │
                          ▼
    ┌──────────────────────────────────────────────┐
    │         Repositorios / Data Access           │  <-- repositories/
    │  - Consultas SQL 100% Parametrizadas         │
    │  - Zero SQL Injection (PreparedStatement)    │
    │  - Filtrado y Paginación Determinista        │
    └─────────────────────┬────────────────────────┘
                          │
                          ▼
    ┌──────────────────────────────────────────────┐
    │          Modelos & Entidades de Datos        │  <-- models/
    │  - Encapsulación & Serialización DTO         │
    └──────────────────────────────────────────────┘
```

### Características Modernas de CFML:
* **Script Syntax Exclusivo (`cfscript`)**: Ausencia total de tags legacy (`<cfcomponent>`, `<cffunction>`, `<cfset>`, `<cfquery>`). Toda la base de código utiliza `component { ... }`, `function ...`, constructores `init()` e inyección de dependencias.
* **Stateless REST**: Configuración explícita en `Application.cfc` con `this.sessionManagement = false` y `this.setClientCookies = false`.
* **Autonomía Operativa**: Base de datos H2 embebida auto-migrada y auto-poblada al primer arranque (`core/DatabaseMigrator.cfc`). No requiere instalar MySQL/Postgres para desarrollo local.

---

## Estructura del Proyecto

```
TaskMaster-API-Modern-CFML-Showcase-/
├── .env.example               # Plantilla de variables de entorno (DB, Secret, Port)
├── .gitignore                 # Exclusiones seguras para CommandBox, engines y secretos
├── box.json                   # Manifiesto de paquete CommandBox
├── server.json                # Configuración del servidor Lucee, puerto 8080 y URL rewrites
├── Application.cfc            # Ciclo de vida, headers de seguridad OWASP y captura global de errores
├── index.cfm                  # Front Controller que delega al Router
│
├── core/
│   ├── Router.cfc             # Enrutador RESTful con soporte para métodos HTTP y path params (:id)
│   ├── ResponseHandler.cfc    # Envoltorio JSON uniforme y RFC 7807 Problem Details
│   ├── Validator.cfc          # Motor de validación de inputs y tipos de datos
│   ├── SecurityHelper.cfc     # Criptografía HMAC-SHA256, hashing con salt y JWT stateless
│   └── DatabaseMigrator.cfc   # DDL automático y seeds para demo user y tareas
│
├── controllers/
│   ├── BaseController.cfc     # Controlador base con parsing seguro de JSON y control de excepciones
│   ├── HealthController.cfc   # Diagnóstico de servidor, latencia de DB y versión de runtime
│   ├── AuthController.cfc     # Endpoint de login y perfil de usuario autenticado
│   └── TaskController.cfc     # CRUD completo de tareas con filtrado y paginación
│
├── services/
│   ├── AuthService.cfc        # Lógica de validación de credenciales y emisión de tokens
│   └── TaskService.cfc        # Reglas de negocio, sanitización y autorización de propiedad
│
├── repositories/
│   ├── UserRepository.cfc     # DAO de usuarios con consultas 100% parametrizadas
│   └── TaskRepository.cfc     # DAO de tareas con parámetros tipados (:named_params)
│
├── models/
│   └── Task.cfc               # Entidad de dominio con getters/setters y exportación a Struct
│
├── test-api.ps1               # Script de pruebas automatizadas E2E en PowerShell
└── README.md                  # Documentación de arquitectura y referencia de API
```

---

## Seguridad Innegociable (Zero-Tolerance AppSec)

En conformidad con las directivas de la skill **`security-review`** y las directrices de seguridad OWASP:

### 1. Prevención Absoluta de SQL Injection
No existe concatenación de cadenas en ninguna consulta SQL del proyecto. Todas las consultas utilizan la función nativa `queryExecute()` vinculando parámetros tipados con su respectivo `cfsqltype`:

```cfscript
// Ejemplo extraído de repositories/TaskRepository.cfc
var sql = "
    SELECT id, user_id, title, description, status, priority, due_date, created_at, updated_at
    FROM tasks
    WHERE id = :id AND user_id = :user_id
";

var params = {
    id = { value = arguments.id, cfsqltype = "cf_sql_varchar" },
    user_id = { value = arguments.userId, cfsqltype = "cf_sql_varchar" }
};

var records = queryExecute(sql, params, { datasource = variables.datasource, returnType = "array" });
```

### 2. Mitigación de BOLA / IDOR (Broken Object Level Authorization)
Ninguna consulta permite acceder a un registro únicamente por su `id`. Cada operación (lectura, modificación, eliminación) incluye la cláusula obligatoria `AND user_id = :user_id` extraída directamente de las credenciales firmadas del token JWT, impidiendo que un usuario acceda o modifique tareas ajenas.

### 3. Hashing Seguro y Prevención de Ataques de Tiempo
* Las contraseñas se almacenan con salt criptográfico de 32 bytes (`java.security.SecureRandom`) y hash HMAC-SHA256.
* La verificación de contraseñas y firmas de token utiliza **comparación en tiempo constante** (`constantTimeEquals`) para anular vulnerabilidades de timing attack.

### 4. Cabeceras HTTP de Seguridad
En cada petición procesada por `Application.cfc`, se inyectan cabeceras de endurecimiento:
* `X-Content-Type-Options: nosniff`
* `X-Frame-Options: DENY`
* `X-XSS-Protection: 1; mode=block`
* `Referrer-Policy: strict-origin-when-cross-origin`
* `Content-Security-Policy: default-src 'none'; frame-ancestors 'none';`

### 5. Blindaje de Errores e Información Interna
El método global `onError` de `Application.cfc` y `BaseController.cfc` interceptan todas las excepciones. **Nunca se exponen trazas de pila (stack traces), rutas de servidor ni detalles SQL al cliente**. Las fallas imprevistas generan un código de seguimiento único (`trackingId`) y devuelven un error HTTP 500 estándar compatible con **RFC 7807**.

---

## Inicio Rápido con CommandBox

### Requisitos Previos
* **CommandBox CLI** instalado ([ortussolutions.com/products/commandbox](https://www.ortussolutions.com/products/commandbox)) o disponible vía terminal:
  ```bash
  box version
  ```
* **Java JDK 11 o superior** configurado en el sistema.

### Instrucciones de Arranque

1. **Clonar o ubicarse en el directorio del proyecto:**
   ```powershell
   cd c:\Proyectos\TaskMaster-API-Modern-CFML-Showcase-
   ```

2. **Copiar plantilla de variables de entorno (opcional):**
   ```powershell
   Copy-Item .env.example .env
   ```

3. **Iniciar el Servidor Embebido:**
   ```powershell
   box server start
   ```
   *CommandBox descargará automáticamente el runtime Lucee especificado en `server.json`, configurará el servidor HTTP en el puerto `8080`, habilitará las reglas de URL rewrite y creará la base de datos embebida con los datos iniciales de prueba.*

4. **Comprobar estado del servidor:**
   ```powershell
   box server status
   ```

5. **Detener el servidor cuando finalice la sesión:**
   ```powershell
   box server stop
   ```

---

## Colección Completa de Endpoints

### Credenciales de Demostración Sembradas
* **Usuario:** `demo_user`
* **Contraseña:** `Password123!`

---

### 1. Health Check

#### `GET /api/v1/health`
Retorna el estado operativo del servicio, runtime CFML y prueba de conectividad a la base de datos.

* **Headers:** No requeridos.
* **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "message": "Health check executed successfully",
    "data": {
      "status": "HEALTHY",
      "environment": "development",
      "server": {
        "cfmlEngine": "Lucee",
        "cfmlVersion": "5.4.6.9",
        "os": "Windows 11"
      },
      "components": {
        "database": {
          "status": "UP",
          "datasource": "taskmaster_db",
          "latencyMs": 4
        }
      }
    },
    "meta": {
      "timestamp": "2026-10-20T17:05:00Z",
      "version": "1.0.0"
    }
  }
  ```

---

### 2. Autenticación

#### `POST /api/v1/auth/login`
Autentica credenciales y emite un token de acceso JWT Bearer.

* **Headers:** `Content-Type: application/json`
* **Cuerpo de Petición:**
  ```json
  {
    "username": "demo_user",
    "password": "Password123!"
  }
  ```
* **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "message": "Authentication successful",
    "data": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tokenType": "Bearer",
      "expiresIn": 7200,
      "user": {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "username": "demo_user",
        "email": "demo@taskmaster.local",
        "role": "ADMIN"
      }
    }
  }
  ```

#### `GET /api/v1/auth/me`
Retorna la información del usuario autenticado a partir del token.

* **Headers:** `Authorization: Bearer <TOKEN>`
* **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "message": "Authenticated user profile retrieved",
    "data": {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "username": "demo_user",
      "email": "demo@taskmaster.local",
      "role": "ADMIN"
    }
  }
  ```

---

### 3. Gestión de Tareas (CRUD)

Todos los endpoints de tareas requieren la cabecera:
`Authorization: Bearer <TOKEN>`

#### `GET /api/v1/tasks`
Lista tareas del usuario con soporte de filtros opcionales.

* **Parámetros Query:**
  * `status`: `PENDING`, `IN_PROGRESS`, `COMPLETED`, `ARCHIVED`
  * `priority`: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`
  * `search`: Búsqueda parcial en título y descripción
  * `limit`: Cantidad máxima de registros (default: 20, max: 100)
  * `offset`: Desplazamiento para paginación (default: 0)

* **Ejemplo cURL:**
  ```bash
  curl -X GET "http://localhost:8080/api/v1/tasks?priority=HIGH&status=PENDING" \
       -H "Authorization: Bearer <TOKEN>"
  ```

* **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "message": "Tasks retrieved successfully",
    "data": [
      {
        "id": "e9f42c12-70b1-4d1a-8bb8-123456789004",
        "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "title": "Deploy TaskMaster Showcase to Staging",
        "description": "Verify containerization and automated verification loop across all endpoints.",
        "status": "PENDING",
        "priority": "HIGH",
        "dueDate": "2026-10-27T17:00:00Z",
        "createdAt": "2026-10-20T17:00:00Z",
        "updatedAt": "2026-10-20T17:00:00Z"
      }
    ],
    "meta": {
      "total": 4,
      "count": 1,
      "limit": 20,
      "offset": 0
    }
  }
  ```

---

#### `GET /api/v1/tasks/:id`
Obtiene los detalles de una tarea específica por su ID.

* **Ejemplo cURL:**
  ```bash
  curl -X GET "http://localhost:8080/api/v1/tasks/e9f42c12-70b1-4d1a-8bb8-123456789001" \
       -H "Authorization: Bearer <TOKEN>"
  ```

* **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "message": "Task retrieved successfully",
    "data": {
      "id": "e9f42c12-70b1-4d1a-8bb8-123456789001",
      "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "title": "Review CFML Security & OWASP Guidelines",
      "description": "Ensure zero string concatenation in SQL queries and enforce cfqueryparam everywhere.",
      "status": "COMPLETED",
      "priority": "CRITICAL",
      "dueDate": "2026-10-27T17:00:00Z",
      "createdAt": "2026-10-20T17:00:00Z",
      "updatedAt": "2026-10-20T17:00:00Z"
    }
  }
  ```

---

#### `POST /api/v1/tasks`
Crea una nueva tarea para el usuario autenticado.

* **Headers:**
  * `Authorization: Bearer <TOKEN>`
  * `Content-Type: application/json`

* **Cuerpo de Petición:**
  ```json
  {
    "title": "Configurar pipeline de CI/CD para Lucee",
    "description": "Implementar ejecución de pruebas unitarias y análisis estático con CommandBox en GitHub Actions.",
    "priority": "HIGH",
    "status": "IN_PROGRESS",
    "dueDate": "2026-11-01T12:00:00Z"
  }
  ```

* **Respuesta Exitosa (`201 Created`):**
  * *Cabecera Location:* `/api/v1/tasks/f47ac10b-58cc-4372-a567-0e02b2c3d479`
  ```json
  {
    "success": true,
    "status": 201,
    "message": "Task created successfully",
    "data": {
      "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "title": "Configurar pipeline de CI/CD para Lucee",
      "description": "Implementar ejecución de pruebas unitarias y análisis estático con CommandBox en GitHub Actions.",
      "status": "IN_PROGRESS",
      "priority": "HIGH",
      "dueDate": "2026-11-01T12:00:00Z",
      "createdAt": "2026-10-20T17:10:00Z",
      "updatedAt": "2026-10-20T17:10:00Z"
    }
  }
  ```

---

#### `PUT /api/v1/tasks/:id`
Actualiza campos de una tarea existente.

* **Cuerpo de Petición:**
  ```json
  {
    "status": "COMPLETED",
    "priority": "CRITICAL"
  }
  ```

* **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "message": "Task updated successfully",
    "data": {
      "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "status": "COMPLETED",
      "priority": "CRITICAL",
      "updatedAt": "2026-10-20T17:15:00Z"
    }
  }
  ```

---

#### `DELETE /api/v1/tasks/:id`
Elimina la tarea especificada.

* **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "message": "Task deleted successfully",
    "data": {
      "deletedId": "f47ac10b-58cc-4372-a567-0e02b2c3d479"
    }
  }
  ```

---

## Manejo de Errores y Códigos HTTP

La API respeta estrictamente la semántica HTTP y las especificaciones RFC 7807 (Problem Details):

| Código HTTP | Significado | Condición |
|---|---|---|
| **`200 OK`** | Éxito | Recuperación o actualización exitosa de recursos. |
| **`201 Created`** | Creado | Recurso creado satisfactoriamente con cabecera `Location`. |
| **`204 No Content`** | Sin Contenido | Eliminación o acción sin cuerpo de respuesta. |
| **`400 Bad Request`** | Petición Inválida | JSON malformado o sintaxis de solicitud no parseable. |
| **`401 Unauthorized`** | No Autorizado | Token JWT ausente, expirado o con firma inválida. |
| **`403 Forbidden`** | Prohibido | Permisos insuficientes para el recurso solicitado. |
| **`404 Not Found`** | No Encontrado | La URI o el recurso consultado no existe o no pertenece al usuario. |
| **`405 Method Not Allowed`** | Método No Permitido | Método HTTP (ej. PATCH) no soportado para la ruta indicada. |
| **`422 Unprocessable Entity`** | Error de Validación | El JSON es válido sintácticamente pero incumple reglas de negocio. |
| **`500 Internal Server Error`** | Error Interno | Excepción inesperada del servidor (detalles sanitizados al cliente). |

### Estructura de Respuesta de Validación (`422 Unprocessable Entity`):
```json
{
  "success": false,
  "status": 422,
  "title": "Unprocessable Entity",
  "message": "Task payload validation failed",
  "detail": "Task payload validation failed",
  "errors": [
    {
      "field": "title",
      "rule": "minLength",
      "message": "Field 'title' must be at least 3 characters."
    },
    {
      "field": "priority",
      "rule": "in",
      "message": "Field 'priority' must be one of: [LOW, MEDIUM, HIGH, CRITICAL]."
    }
  ],
  "timestamp": "2026-10-20T17:20:00Z"
}
```

---

## Script de Verificación Automatizado

El proyecto incluye un script de prueba de extremo a extremo en PowerShell (`test-api.ps1`) que valida la salud del servicio, login, generación del token, creación de tareas, filtrado, actualización y eliminación:

```powershell
# Una vez iniciado el servidor con 'box server start'
.\test-api.ps1
```

---

## Licencia

Este proyecto fue desarrollado bajo arquitectura moderna CFML como caso de estudio de ingeniería backend de alto rendimiento y seguridad. Licencia MIT.
