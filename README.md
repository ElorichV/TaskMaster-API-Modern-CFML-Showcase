# TaskMaster API - Modern CFML REST Showcase 🚀

[![CFML](https://img.shields.io/badge/CFML-Script%20Syntax-0078D7.svg?style=flat-square&logo=codefactor)](https://lucee.org/)
[![Runtime](https://img.shields.io/badge/Lucee-5.4%20%7C%206.x-00B294.svg?style=flat-square)](https://lucee.org/)
[![Tooling](https://img.shields.io/badge/CommandBox-CLI%20Enabled-F25022.svg?style=flat-square)](https://www.ortussolutions.com/products/commandbox)
[![Security](https://img.shields.io/badge/OWASP-Secured-7FBA00.svg?style=flat-square)](#-seguridad-y-buenas-prácticas)
[![Status](https://img.shields.io/badge/Status-Completed-success.svg?style=flat-square)]()

API RESTful moderna construida con **CFML moderno (100% `cfscript`)** sobre el motor **Lucee / Adobe ColdFusion**. Diseñada desde la perspectiva de un desarrollador **Full Stack**, lista para integrarse de forma desacoplada con frontends en React, Angular, Vue o aplicaciones móviles.

---

## 📌 Tabla de Contenidos

- [Sobre el Proyecto](#-sobre-el-proyecto)
- [Stack Tecnológico](#-stack-tecnológico)
- [Arquitectura de la Aplicación](#-arquitectura-de-la-aplicación)
- [Seguridad y Buenas Prácticas](#-seguridad-y-buenas-prácticas)
- [Inicio Rápido (Setup Local)](#-inicio-rápido-setup-local)
- [Referencia de Endpoints](#-referencia-de-endpoints)
- [Consumo desde el Frontend (Ejemplo)](#-consumo-desde-el-frontend-ejemplo)
- [Pruebas Automatizadas](#-pruebas-automatizadas)
- [Próximos Pasos (Roadmap)](#-próximos-pasos-roadmap)

---

## 💡 Sobre el Proyecto

Muchos desarrolladores asocian CFML con código heredado basado en etiquetas XML (`<cfquery>`, `<cfset>`). El objetivo de **TaskMaster API** es demostrar que el **CFML moderno** es una tecnología robusta, rápida y orientada a objetos:

* **Sintaxis limpia y moderna**: 100% escrita en sintaxis Script (`component { ... }`, `function ...`).
* **Arquitectura por capas**: Separación clara entre controladores, servicios de negocio, repositorios de datos y modelos.
* **Plug & Play**: Cuenta con base de datos H2 embebida y auto-migración de tablas en el arranque, permitiendo clonar y levantar el proyecto con un solo comando sin configurar servidores externos.
* **Pensada para el Frontend**: Respuestas JSON consistentes, manejo de CORS preconfigurado y códigos de estado HTTP estándar (200, 201, 400, 401, 404, 422, 500).

---

## 🛠 Stack Tecnológico

* **Backend:** CFML Moderno (Script Syntax)
* **Motor CFML:** Lucee 5.4+ / 6.x (compatible con Adobe ColdFusion 2021+)
* **Gestor de Entorno / Servidor:** CommandBox CLI (Undertow embedded)
* **Base de Datos:** H2 Database (embebida para desarrollo local) / compatible con MySQL y PostgreSQL
* **Autenticación:** Tokens firmados HMAC-SHA256 (Stateless JWT)
* **Testing / Tooling:** PowerShell Test Suite, Postman / cURL ready

---

## 🏗 Arquitectura de la Aplicación

El proyecto sigue una estructura limpia y desacoplada, facilitando el mantenimiento y las pruebas:

```
TaskMaster-API-Modern-CFML-Showcase/
├── Application.cfc             # Ciclo de vida, headers de seguridad CORS/OWASP y control global de errores
├── index.cfm                   # Front Controller: punto de entrada y reescritura de URLs
├── server.json                 # Configuración de CommandBox (puerto 8080, rewrites, Lucee)
├── box.json                    # Manifiesto del proyecto y scripts de inicio
├── .env.example                # Plantilla de variables de configuración
│
├── controllers/                # CAPA DE CONTROLADORES
│   ├── BaseController.cfc      # Helpers comunes: parseo JSON, resolución de Auth, manejo de excepciones
│   ├── AuthController.cfc      # Login y consulta de perfil actual (/me)
│   ├── TaskController.cfc      # CRUD de tareas, paginación y filtros
│   └── HealthController.cfc    # Endpoint de diagnóstico y estado de la base de datos
│
├── services/                   # CAPA DE NEGOCIO
│   ├── AuthService.cfc         # Validación de credenciales y generación de JWT
│   └── TaskService.cfc         # Reglas de negocio de tareas, sanitización y permisos
│
├── repositories/               # CAPA DE ACCESO A DATOS (DAO)
│   ├── TaskRepository.cfc      # Consultas SQL 100% parametrizadas (PreparedStatement)
│   └── UserRepository.cfc      # Búsqueda y persistencia de usuarios
│
├── models/                     # MODELOS DE DOMINIO
│   └── Task.cfc                # Entidad Tarea (getters, setters y DTO toStruct)
│
├── core/                       # UTILIDADES CENTRALES
│   ├── Router.cfc              # Enrutador REST (métodos HTTP, parámetros de ruta :id)
│   ├── ResponseHandler.cfc     # Formateo JSON estándar (RFC 7807)
│   ├── Validator.cfc           # Validación estricta de esquemas y tipos de datos
│   ├── SecurityHelper.cfc      # Hashing con salt, verificación segura y tokens
│   └── DatabaseMigrator.cfc    # DDL inicial y datos de prueba automáticos (seeds)
│
└── test-api.ps1                # Script para pruebas E2E automatizadas
```

---

## 🛡 Seguridad y Buenas Prácticas

Como desarrollador Full Stack, la seguridad no es un agregado opcional:

1. **Cero SQL Injection (`PreparedStatement` estricto):**
   Ninguna consulta concatena valores. Todas utilizan `queryExecute()` con parámetros nombrados y tipos explícitos (`cfsqltype`):
   ```cfscript
   var sql = "SELECT * FROM tasks WHERE id = :id AND user_id = :user_id";
   var params = {
       id = { value = arguments.id, cfsqltype = "cf_sql_varchar" },
       user_id = { value = arguments.userId, cfsqltype = "cf_sql_varchar" }
   };
   var result = queryExecute(sql, params, { datasource = variables.datasource, returnType = "array" });
   ```

2. **Protección contra BOLA / IDOR:**
   Un usuario autenticado solo puede consultar, editar o borrar tareas que le pertenezcan (`user_id = :user_id`), impidiendo accesos no autorizados cambiando IDs en la URL.

3. **Almacenamiento Seguro de Contraseñas:**
   Hashing criptográfico mediante HMAC-SHA256 con salt de 32 bytes y comparación en tiempo constante (`constantTimeEquals`) para evitar ataques de temporización (Timing Attacks).

4. **Cabeceras HTTP OWASP:**
   Se inyectan cabeceras automáticas en todas las peticiones: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `X-XSS-Protection`, `Content-Security-Policy` y control de orígenes CORS.

5. **Respuestas Sanitizadas en Casos de Error:**
   Si ocurre una excepción no controlada, `Application.cfc` oculta los detalles internos del servidor o consultas SQL, registrando un `trackingId` en los logs del servidor y devolviendo un JSON seguro al cliente (RFC 7807).

---

## ⚡ Inicio Rápido (Setup Local)

### Requisitos Previos
* [CommandBox CLI](https://www.ortussolutions.com/products/commandbox) instalado.
* Java JDK 11 o superior.

### Pasos para Ejecutar

1. **Clonar y entrar al directorio del proyecto:**
   ```bash
   cd C:\Proyectos\TaskMaster-API-Modern-CFML-Showcase
   ```

2. **Configurar variables de entorno (opcional):**
   ```powershell
   Copy-Item .env.example .env
   ```

3. **Iniciar el servidor local:**
   ```bash
   box server start
   ```
   *CommandBox descargará el runtime de Lucee en segundo plano, levantará el servidor HTTP en el puerto `8080`, aplicará las reescrituras de URL e inicializará automáticamente la base de datos con datos de prueba.*

4. **Verificar que la API responde:**
   Abre en tu navegador o terminal: [http://localhost:8080/api/v1/health](http://localhost:8080/api/v1/health)

5. **Detener el servidor:**
   ```bash
   box server stop
   ```

---

## 📡 Referencia de Endpoints

### 🔑 Credenciales de Demostración Sembradas
* **Usuario:** `demo_user`
* **Contraseña:** `Password123!`

---

### Resumen de Rutas

| Método | Endpoint | Descripción | Requiere Auth |
|---|---|---|:---:|
| `GET` | `/api/v1/health` | Estado del servicio y base de datos | No |
| `POST` | `/api/v1/auth/login` | Iniciar sesión y obtener Bearer Token | No |
| `GET` | `/api/v1/auth/me` | Obtener datos del usuario autenticado | Sí |
| `GET` | `/api/v1/tasks` | Listar tareas (con filtros y paginación) | Sí |
| `GET` | `/api/v1/tasks/:id` | Obtener detalle de una tarea | Sí |
| `POST` | `/api/v1/tasks` | Crear una nueva tarea | Sí |
| `PUT` | `/api/v1/tasks/:id` | Actualizar una tarea existente | Sí |
| `DELETE` | `/api/v1/tasks/:id` | Eliminar una tarea | Sí |

---

### Ejemplos de Peticiones

#### 1. Iniciar Sesión (`POST /api/v1/auth/login`)
```bash
curl -X POST "http://localhost:8080/api/v1/auth/login" \
     -H "Content-Type: application/json" \
     -d '{
       "username": "demo_user",
       "password": "Password123!"
     }'
```
**Respuesta (`200 OK`):**
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

#### 2. Listar Tareas con Filtros (`GET /api/v1/tasks`)
Soporta parámetros de consulta: `status`, `priority`, `search`, `limit`, `offset`.
```bash
curl -X GET "http://localhost:8080/api/v1/tasks?priority=HIGH&status=PENDING" \
     -H "Authorization: Bearer <TU_TOKEN_AQUI>"
```

#### 3. Crear una Tarea (`POST /api/v1/tasks`)
```bash
curl -X POST "http://localhost:8080/api/v1/tasks" \
     -H "Authorization: Bearer <TU_TOKEN_AQUI>" \
     -H "Content-Type: application/json" \
     -d '{
       "title": "Diseñar componente Kanban en React",
       "description": "Consumir endpoints de TaskMaster API con TanStack Query y Tailwind CSS.",
       "priority": "HIGH",
       "status": "IN_PROGRESS"
     }'
```
**Respuesta (`201 Created`):**
```json
{
  "success": true,
  "status": 201,
  "message": "Task created successfully",
  "data": {
    "id": "c1388b3f-1d48-433b-8ea4-3a5cbf0a9a11",
    "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "title": "Diseñar componente Kanban en React",
    "description": "Consumir endpoints de TaskMaster API con TanStack Query y Tailwind CSS.",
    "status": "IN_PROGRESS",
    "priority": "HIGH",
    "dueDate": "",
    "createdAt": "2026-10-20T20:15:00Z",
    "updatedAt": "2026-10-20T20:15:00Z"
  }
}
```

---

## 💻 Consumo desde el Frontend (Ejemplo)

Al ser una API REST estándar con soporte CORS, integrarla en una aplicación frontend (React, Angular o Vue) es directo.

**Ejemplo de cliente con Axios / TypeScript:**

```typescript
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:8080/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para inyectar el Bearer Token automáticamente
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Servicio de Tareas
export const TaskService = {
  async getTasks(params?: { priority?: string; status?: string; search?: string }) {
    const response = await api.get('/tasks', { params });
    return response.data; // { success: true, data: [...], meta: { ... } }
  },

  async createTask(task: { title: string; description?: string; priority?: string }) {
    const response = await api.post('/tasks', task);
    return response.data.data;
  },

  async updateTaskStatus(id: string, status: 'PENDING' | 'IN_PROGRESS' | 'COMPLETED') {
    const response = await api.put(`/tasks/${id}`, { status });
    return response.data.data;
  },

  async deleteTask(id: string) {
    const response = await api.delete(`/tasks/${id}`);
    return response.data;
  }
};
```

---

## 🧪 Pruebas Automatizadas

El proyecto incluye un script de prueba de integración de extremo a extremo en PowerShell:

```powershell
# Con el servidor iniciado:
.\test-api.ps1
```

Este script valida:
1. `GET /health` (diagnóstico y base de datos activa).
2. `POST /auth/login` (autenticación y obtención de token).
3. `POST /tasks` (creación con verificación de cabecera `Location`).
4. `GET /tasks/:id` (lectura por ID).
5. `GET /tasks` con filtros (`?priority=HIGH`).
6. `PUT /tasks/:id` (actualización de estado).
7. `DELETE /tasks/:id` (eliminación segura).

---

## 🎯 Próximos Pasos (Roadmap)

- [ ] Agregar especificación OpenAPI / Swagger UI para documentación interactiva.
- [ ] Implementar contenedor Docker (`Dockerfile` y `docker-compose.yml`) con MySQL multi-stage.
- [ ] Crear frontend de muestra en React (Vite + Tailwind CSS + Lucide Icons).
- [ ] Agregar suite de pruebas unitarias con TestBox.

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Desarrollado con enfoque de código limpio y modernización de stacks backend en CFML.
