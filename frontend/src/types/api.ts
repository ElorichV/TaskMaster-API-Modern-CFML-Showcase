export type TaskStatus = 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'ARCHIVED';
export type TaskPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
export type TraceSource = 'LIVE' | 'SIMULATED';

export interface Task {
  id: string;
  title: string;
  description: string;
  status: TaskStatus;
  priority: TaskPriority;
  dueDate: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface User {
  id: string;
  username: string;
  email: string;
  role: string;
}

export interface ApiMeta {
  timestamp?: string;
  version?: string;
  total?: number;
  count?: number;
  limit?: number;
  offset?: number;
}

export interface ApiSuccess<T> {
  success: true;
  status: number;
  message?: string;
  data: T;
  meta?: ApiMeta;
}

export interface ValidationErrorItem {
  field: string;
  rule: string;
  message: string;
}

export interface ApiErrorEnvelope {
  success: false;
  status: number;
  title: string;
  message: string;
  detail?: string;
  errors?: ValidationErrorItem[];
  timestamp: string;
}

export interface HealthData {
  status: string;
  environment: string;
  server: { cfmlEngine: string; cfmlVersion: string; os: string };
  components: { database: { status: string; datasource: string; latencyMs: number } };
}

export interface LoginData {
  accessToken: string;
  tokenType: 'Bearer';
  expiresIn: number;
  user: User;
}

export interface TaskPayload {
  title?: string;
  description?: string;
  status?: TaskStatus | string;
  priority?: TaskPriority | string;
  dueDate?: string;
}

export interface TaskQuery {
  status?: TaskStatus;
  priority?: TaskPriority;
  search?: string;
  limit?: number;
  offset?: number;
}

export interface ApiTraceLog {
  id: string;
  timestamp: string;
  method: HttpMethod;
  endpoint: string;
  statusCode: number;
  durationMs: number;
  source: TraceSource;
  requestHeaders: Record<string, string>;
  requestBody: string | null;
  responseHeaders: Record<string, string>;
  responseBody: string;
  curlCommand: string;
  sqlPreview: string;
}
