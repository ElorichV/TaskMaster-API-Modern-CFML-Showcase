import type {
  ApiErrorEnvelope,
  ApiSuccess,
  ApiTraceLog,
  HealthData,
  HttpMethod,
  LoginData,
  Task,
  TaskPayload,
  TaskQuery,
  TaskStatus,
  User,
  ValidationErrorItem,
} from '../types/api';

const BASE = import.meta.env.VITE_API_BASE_URL ?? '/api/v1';
const DEMO_TOKEN =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkZW1vLXVzZXItaWQiLCJyb2xlIjoiVVNFUiJ9.demo_signature';

export const DEMO_USER: User = {
  id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  username: 'demo_user',
  email: 'demo@taskmaster.local',
  role: 'ADMIN',
};

export interface Session {
  token: string;
  user: User;
}

type Listener = (log: ApiTraceLog) => void;
const listeners = new Set<Listener>();

export function onTrace(fn: Listener): () => void {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

let simulateMode = false;
export function setSimulateMode(v: boolean): void {
  simulateMode = v;
}
export function getSimulateMode(): boolean {
  return simulateMode;
}

/* ---------------- Mock in-memory backend (mirrors CFML responses) ---------------- */

const mockTasks: Task[] = [
  {
    id: 'tsk-1001',
    title: 'Configurar pipeline CI/CD en GitHub Actions',
    description: 'Workflow con lint, tests y despliegue a staging.',
    status: 'IN_PROGRESS',
    priority: 'HIGH',
    dueDate: '2026-11-30',
    createdAt: '2026-11-20T14:00:00Z',
    updatedAt: '2026-11-24T09:12:00Z',
  },
  {
    id: 'tsk-1002',
    title: 'Revisar headers OWASP en respuestas',
    description: 'Verificar X-Content-Type-Options, X-Frame-Options y CSP.',
    status: 'PENDING',
    priority: 'CRITICAL',
    dueDate: '2026-11-28',
    createdAt: '2026-11-21T10:30:00Z',
    updatedAt: '2026-11-21T10:30:00Z',
  },
  {
    id: 'tsk-1003',
    title: 'Documentar endpoints con OpenAPI',
    description: 'Generar swagger.json desde los controladores CFML.',
    status: 'PENDING',
    priority: 'MEDIUM',
    dueDate: null,
    createdAt: '2026-11-22T16:45:00Z',
    updatedAt: '2026-11-22T16:45:00Z',
  },
  {
    id: 'tsk-1004',
    title: 'Migrar datasource a variable de entorno',
    description: 'Evitar credenciales hardcodeadas en Application.cfc.',
    status: 'COMPLETED',
    priority: 'HIGH',
    dueDate: '2026-11-24',
    createdAt: '2026-11-18T08:00:00Z',
    updatedAt: '2026-11-24T18:20:00Z',
  },
  {
    id: 'tsk-1005',
    title: 'Archivar tareas legacy del sprint 12',
    description: 'Limpieza de backlog.',
    status: 'ARCHIVED',
    priority: 'LOW',
    dueDate: null,
    createdAt: '2026-11-10T12:00:00Z',
    updatedAt: '2026-11-15T12:00:00Z',
  },
];

const OWASP_HEADERS: Record<string, string> = {
  'Content-Type': 'application/json; charset=utf-8',
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
  'Referrer-Policy': 'no-referrer',
  'X-API-Version': 'v1',
};

function now(): string {
  return new Date().toISOString();
}

function ok<T>(data: T, status = 200, message?: string): ApiSuccess<T> {
  return { success: true, status, message, data, meta: { timestamp: now(), version: '1.0.0' } };
}

function err(status: number, title: string, message: string, errors?: ValidationErrorItem[]): ApiErrorEnvelope {
  return { success: false, status, title, message, detail: message, errors, timestamp: now() };
}

function validateTaskPayload(body: TaskPayload): ValidationErrorItem[] {
  const errors: ValidationErrorItem[] = [];
  if (body.title !== undefined) {
    if (typeof body.title !== 'string' || body.title.trim().length < 3) {
      errors.push({ field: 'title', rule: 'minLength', message: "Field 'title' must be at least 3 characters." });
    } else if (body.title.length > 200) {
      errors.push({ field: 'title', rule: 'maxLength', message: "Field 'title' must be at most 200 characters." });
    }
  }
  if (body.description !== undefined && body.description.length > 1000) {
    errors.push({ field: 'description', rule: 'maxLength', message: "Field 'description' must be at most 1000 characters." });
  }
  const validStatus: TaskStatus[] = ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED'];
  if (body.status !== undefined && !validStatus.includes(body.status as TaskStatus)) {
    errors.push({ field: 'status', rule: 'in', message: `Field 'status' must be one of: [${validStatus.join(', ')}].` });
  }
  const validPriority = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
  if (body.priority !== undefined && !validPriority.includes(body.priority)) {
    errors.push({ field: 'priority', rule: 'in', message: `Field 'priority' must be one of: [${validPriority.join(', ')}].` });
  }
  return errors;
}

function requireAuth(session: Session | null): ApiErrorEnvelope | null {
  if (!session) return err(401, 'Unauthorized', 'Missing or invalid Bearer token.');
  return null;
}

function mockDispatch(
  method: HttpMethod,
  path: string,
  body: unknown,
  session: Session | null,
  query: string,
): { status: number; payload: ApiSuccess<unknown> | ApiErrorEnvelope } {
  const authError = requireAuth(session);
  const parts = path.split('/').filter(Boolean);
  const isTaskById = parts[0] === 'tasks' && parts.length === 2;

  if (path === 'health' && method === 'GET') {
    const data: HealthData = {
      status: 'HEALTHY',
      environment: 'development',
      server: { cfmlEngine: 'Lucee (simulated)', cfmlVersion: '6.0.0', os: 'Windows' },
      components: { database: { status: 'UP', datasource: 'taskmaster_db', latencyMs: 4 } },
    };
    return { status: 200, payload: ok(data, 200, 'Service is healthy') };
  }

  if (path === 'auth/login' && method === 'POST') {
    const creds = body as { username?: string; password?: string };
    if (creds.username === 'demo_user' && creds.password === 'Password123!') {
      const data: LoginData = { accessToken: DEMO_TOKEN, tokenType: 'Bearer', expiresIn: 7200, user: DEMO_USER };
      return { status: 200, payload: ok(data, 200, 'Authentication successful') };
    }
    return { status: 401, payload: err(401, 'Unauthorized', 'Invalid credentials.') };
  }

  if (path === 'auth/me' && method === 'GET') {
    if (authError) return { status: 401, payload: authError };
    return { status: 200, payload: ok(DEMO_USER) };
  }

  if (parts[0] !== 'tasks') {
    return { status: 404, payload: err(404, 'Not Found', `Route not found: ${method} /${path}`) };
  }

  if (authError) return { status: 401, payload: authError };

  if (method === 'GET' && !isTaskById) {
    const params = new URLSearchParams(query.replace(/^\?/, ''));
    let filtered = [...mockTasks];
    const status = params.get('status');
    const priority = params.get('priority');
    const search = params.get('search')?.toLowerCase();
    if (status) filtered = filtered.filter((t) => t.status === status);
    if (priority) filtered = filtered.filter((t) => t.priority === priority);
    if (search) {
      filtered = filtered.filter(
        (t) => t.title.toLowerCase().includes(search) || t.description.toLowerCase().includes(search),
      );
    }
    const offset = Number(params.get('offset') ?? 0);
    const limit = Number(params.get('limit') ?? 100);
    const page = filtered.slice(offset, offset + limit);
    const payload = ok(page);
    payload.meta = { ...payload.meta, total: filtered.length, count: page.length, limit, offset };
    return { status: 200, payload };
  }
  if (method === 'GET' && isTaskById) {
    const task = mockTasks.find((t) => t.id === parts[1]);
    if (!task) return { status: 404, payload: err(404, 'Not Found', `Task '${parts[1]}' not found.`) };
    return { status: 200, payload: ok(task) };
  }
  if (method === 'POST') {
    const payload = body as TaskPayload;
    const errors = validateTaskPayload(payload);
    if (!payload.title || payload.title.trim().length === 0) {
      errors.push({ field: 'title', rule: 'required', message: "Field 'title' is required." });
    }
    if (errors.length > 0) {
      return { status: 422, payload: err(422, 'Unprocessable Entity', 'Task payload validation failed', errors) };
    }
    const task: Task = {
      id: `tsk-${Math.floor(1000 + Math.random() * 9000)}`,
      title: payload.title!.trim(),
      description: payload.description ?? '',
      status: (payload.status as TaskStatus) ?? 'PENDING',
      priority: (payload.priority as Task['priority']) ?? 'MEDIUM',
      dueDate: payload.dueDate ?? null,
      createdAt: now(),
      updatedAt: now(),
    };
    mockTasks.unshift(task);
    return { status: 201, payload: ok(task, 201, 'Task created successfully') };
  }
  if (method === 'PUT' && isTaskById) {
    const task = mockTasks.find((t) => t.id === parts[1]);
    if (!task) return { status: 404, payload: err(404, 'Not Found', `Task '${parts[1]}' not found.`) };
    const payload = body as TaskPayload;
    const errors = validateTaskPayload(payload);
    if (errors.length > 0) {
      return { status: 422, payload: err(422, 'Unprocessable Entity', 'Task payload validation failed', errors) };
    }
    if (payload.title !== undefined) task.title = payload.title.trim();
    if (payload.description !== undefined) task.description = payload.description;
    if (payload.status !== undefined) task.status = payload.status as TaskStatus;
    if (payload.priority !== undefined) task.priority = payload.priority as Task['priority'];
    if (payload.dueDate !== undefined) task.dueDate = payload.dueDate;
    task.updatedAt = now();
    return { status: 200, payload: ok(task, 200, 'Task updated successfully') };
  }
  if (method === 'DELETE' && isTaskById) {
    const idx = mockTasks.findIndex((t) => t.id === parts[1]);
    if (idx === -1) return { status: 404, payload: err(404, 'Not Found', `Task '${parts[1]}' not found.`) };
    mockTasks.splice(idx, 1);
    return { status: 200, payload: ok({ deletedId: parts[1] }, 200, 'Task deleted successfully') };
  }
  return { status: 404, payload: err(404, 'Not Found', `Route not found: ${method} /${path}`) };
}

/* ---------------- SQL preview (educational, mirrors CFML queryExecute) ---------------- */

function sqlPreview(method: HttpMethod, path: string, body: unknown, query: string): string {
  const parts = path.split('/').filter(Boolean);
  if (path === 'auth/login') {
    return `-- UserRepository.cfc & SecurityHelper.cfc
qry = queryExecute(
  "SELECT id, username, email, password_hash, password_salt, role, created_at
   FROM users WHERE LOWER(username) = LOWER(:username)",
  { username = { value = :username, cfsqltype = "cf_sql_varchar" } },
  { datasource = "taskmaster_db" }
);
-- HMAC-SHA256 + constantTimeEquals(computedHash, storedHash) -> JWT HS256`;
  }
  if (path === 'auth/me') {
    return `-- Auth middleware: JWT.verify( Authorization Bearer )
qry = queryExecute(
  "SELECT id, username, email, role FROM users WHERE id = :id",
  { id = { value = token.sub, cfsqltype = "cf_sql_varchar" } },
  { datasource = "taskmaster_db" }
);`;
  }
  if (parts[0] === 'tasks') {
    const idClause = 'WHERE id = :id AND user_id = :uid';
    const tenant = '  uid = { value = token.sub, cfsqltype = "cf_sql_varchar" }, -- BOLA/IDOR tenant isolation';
    if (method === 'GET' && parts.length === 2) {
      return `-- TaskRepository.cfc :: findById
qry = queryExecute(
  "SELECT * FROM tasks ${idClause}",
  { id = { value = :id, cfsqltype = "cf_sql_varchar" },
${tenant} },
  { datasource = "taskmaster_db" }
);`;
    }
    if (method === 'GET') {
      return `-- TaskRepository.cfc :: findAll (filters)
qry = queryExecute(
  "SELECT * FROM tasks WHERE user_id = :uid
   ${query.includes('status=') ? 'AND status = :status' : ''}
   ${query.includes('priority=') ? 'AND priority = :priority' : ''}
   ${query.includes('search=') ? 'AND (title LIKE :search OR description LIKE :search)' : ''}
   ORDER BY created_at DESC LIMIT :limit OFFSET :offset",
  { uid = { value = token.sub, cfsqltype = "cf_sql_varchar" },
    status = { value = :status, cfsqltype = "cf_sql_varchar" },
    priority = { value = :priority, cfsqltype = "cf_sql_varchar" },
    search = { value = "%#search#%", cfsqltype = "cf_sql_varchar" },
    limit = { value = :limit, cfsqltype = "cf_sql_integer" },
    offset = { value = :offset, cfsqltype = "cf_sql_integer" } },
  { datasource = "taskmaster_db" }
);`;
    }
    if (method === 'POST') {
      return `-- TaskRepository.cfc :: create
qry = queryExecute(
  "INSERT INTO tasks (id, user_id, title, description, status, priority, due_date, created_at, updated_at)
   VALUES (:id, :uid, :title, :description, :status, :priority, :dueDate, now(), now())",
  { id = { value = createUUID(), cfsqltype = "cf_sql_varchar" },
${tenant},
    title = { value = :title, cfsqltype = "cf_sql_varchar" },
    description = { value = :description, cfsqltype = "cf_sql_varchar", null = len(:description) EQ 0 },
    status = { value = :status, cfsqltype = "cf_sql_varchar" },
    priority = { value = :priority, cfsqltype = "cf_sql_varchar" },
    dueDate = { value = :dueDate, cfsqltype = "cf_sql_date", null = NOT isDate(:dueDate) } },
  { datasource = "taskmaster_db" }
);`;
    }
    if (method === 'PUT') {
      const b = (body ?? {}) as TaskPayload;
      const sets = (['title', 'description', 'status', 'priority', 'dueDate'] as const)
        .filter((f) => b[f] !== undefined)
        .map((f) => `${f === 'dueDate' ? 'due_date' : f} = :${f}`)
        .join(', ');
      return `-- TaskRepository.cfc :: update
qry = queryExecute(
  "UPDATE tasks SET ${sets || 'updated_at = now()'}, updated_at = now() ${idClause}",
  {${tenant},
    ${sets ? '-- bound fields: ' + sets.replace(/ = :/g, ' (:').replace(/, /g, '), ') + ')' : '-- no fields provided'} },
  { datasource = "taskmaster_db" }
);`;
    }
    if (method === 'DELETE') {
      return `-- TaskRepository.cfc :: delete
qry = queryExecute(
  "DELETE FROM tasks ${idClause}",
  { id = { value = :id, cfsqltype = "cf_sql_varchar" },
${tenant} },
  { datasource = "taskmaster_db" }
);`;
    }
  }
  return '-- No SQL executed for this route.';
}

/* ---------------- Telemetry + transport ---------------- */

function maskToken(token: string): string {
  if (token.length <= 16) return token;
  return `${token.slice(0, 12)}…${token.slice(-6)}`;
}

function buildCurl(method: HttpMethod, relativeEndpoint: string, headers: Record<string, string>, body: unknown): string {
  const base = BASE.startsWith('/') ? `http://localhost:8080${BASE}` : BASE;
  const headerFlags = Object.entries(headers)
    .map(([k, v]) => `-H "${k}: ${v}"`)
    .join(' ');
  const dataFlag = body != null ? ` -d '${JSON.stringify(body)}'` : '';
  return `curl -X ${method} "${base}${relativeEndpoint}" ${headerFlags}${dataFlag}`;
}

async function request<T>(
  method: HttpMethod,
  path: string,
  opts: { body?: unknown; session?: Session | null; query?: string } = {},
): Promise<{ status: number; data: T }> {
  const relativeEndpoint = `/${path}${opts.query ?? ''}`;
  const endpoint = `${BASE}${relativeEndpoint}`;
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (opts.session) headers['Authorization'] = `Bearer ${opts.session.token}`;

  const traceHeaders = { ...headers };
  if (opts.session) traceHeaders['Authorization'] = `Bearer ${maskToken(opts.session.token)}`;

  const started = performance.now();
  const logBase = {
    id: crypto.randomUUID(),
    timestamp: now(),
    method,
    endpoint: relativeEndpoint,
    requestHeaders: traceHeaders,
    requestBody: opts.body != null ? JSON.stringify(opts.body, null, 2) : null,
    curlCommand: buildCurl(method, relativeEndpoint, traceHeaders, opts.body),
    sqlPreview: sqlPreview(method, path, opts.body, opts.query ?? ''),
  };

  if (!simulateMode) {
    try {
      const res = await fetch(endpoint, {
        method,
        headers,
        body: opts.body != null ? JSON.stringify(opts.body) : undefined,
      });
      const json = await res.json();
      const responseHeaders: Record<string, string> = {};
      res.headers.forEach((v, k) => {
        responseHeaders[k] = v;
      });
      emit({ ...logBase, statusCode: res.status, durationMs: Math.round(performance.now() - started), source: 'LIVE', responseHeaders, responseBody: JSON.stringify(json, null, 2) });
      return { status: res.status, data: json as T };
    } catch {
      // Network error -> seamless simulated fallback
    }
  }

  await new Promise((r) => setTimeout(r, 30 + Math.random() * 120));
  const { status, payload } = mockDispatch(method, path, opts.body, opts.session ?? null, opts.query ?? '');
  emit({
    ...logBase,
    statusCode: status,
    durationMs: Math.round(performance.now() - started),
    source: 'SIMULATED',
    responseHeaders: OWASP_HEADERS,
    responseBody: JSON.stringify(payload, null, 2),
  });
  return { status, data: payload as T };
}

function emit(log: ApiTraceLog): void {
  listeners.forEach((fn) => fn(log));
}

/* ---------------- Public API ---------------- */

export const api = {
  health: () => request<ApiSuccess<HealthData>>('GET', 'health'),
  login: (username: string, password: string) =>
    request<ApiSuccess<LoginData>>('POST', 'auth/login', { body: { username, password } }),
  me: (session: Session) => request<ApiSuccess<User>>('GET', 'auth/me', { session }),
  listTasks: (session: Session, q: TaskQuery = {}) => {
    const params = new URLSearchParams();
    if (q.status) params.set('status', q.status);
    if (q.priority) params.set('priority', q.priority);
    if (q.search) params.set('search', q.search);
    if (q.limit) params.set('limit', String(q.limit));
    if (q.offset) params.set('offset', String(q.offset));
    const qs = params.toString();
    return request<ApiSuccess<Task[]>>('GET', 'tasks', { session, query: qs ? `?${qs}` : '' });
  },
  createTask: (session: Session, body: TaskPayload) =>
    request<ApiSuccess<Task>>('POST', 'tasks', { session, body }),
  updateTask: (session: Session, id: string, body: TaskPayload) =>
    request<ApiSuccess<Task>>('PUT', `tasks/${id}`, { session, body }),
  deleteTask: (session: Session, id: string) =>
    request<ApiSuccess<{ deletedId: string }>>('DELETE', `tasks/${id}`, { session }),
};
