import { useState } from 'react';
import { Pencil, Plus, Search, Trash2, Zap } from 'lucide-react';
import type { Task, TaskPriority, TaskStatus } from '../types/api';

const STATUSES: (TaskStatus | 'ALL')[] = ['ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED'];
const PRIORITIES: (TaskPriority | 'ALL')[] = ['ALL', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
const COLUMNS: TaskStatus[] = ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED'];

const priorityBadge: Record<TaskPriority, string> = {
  CRITICAL: 'bg-rose-500/15 text-rose-400 border-rose-500/30',
  HIGH: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  MEDIUM: 'bg-blue-500/15 text-blue-400 border-blue-500/30',
  LOW: 'bg-slate-500/15 text-slate-400 border-slate-500/30',
};

const columnAccent: Record<TaskStatus, string> = {
  PENDING: 'text-slate-300',
  IN_PROGRESS: 'text-blue-400',
  COMPLETED: 'text-emerald-400',
  ARCHIVED: 'text-slate-500',
};

interface Props {
  tasks: Task[];
  authenticated: boolean;
  onSearch: (q: { search: string; status: TaskStatus | 'ALL'; priority: TaskPriority | 'ALL' }) => void;
  onNewTask: () => void;
  onEditTask: (task: Task) => void;
  onDeleteTask: (task: Task) => void;
  onStatusChange: (task: Task, status: TaskStatus) => void;
  onForce422: () => void;
}

export function TaskBoard({
  tasks,
  authenticated,
  onSearch,
  onNewTask,
  onEditTask,
  onDeleteTask,
  onStatusChange,
  onForce422,
}: Props) {
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<TaskStatus | 'ALL'>('ALL');
  const [priority, setPriority] = useState<TaskPriority | 'ALL'>('ALL');

  const emit = (s = search, st = status, p = priority) => onSearch({ search: s, status: st, priority: p });

  return (
    <section aria-label="Task board" className="flex h-full flex-col gap-4 p-4">
      <div className="flex flex-wrap items-center gap-2">
        <label className="relative flex-1 min-w-48">
          <span className="sr-only">Buscar tareas</span>
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-slate-500" aria-hidden />
          <input
            type="search"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              emit(e.target.value);
            }}
            placeholder="Buscar por título o descripción…"
            className="w-full rounded-md border border-slate-700 bg-slate-900 py-2 pl-8 pr-3 text-sm text-slate-100 placeholder-slate-500"
          />
        </label>
        <label className="sr-only" htmlFor="status-filter">Filtrar por estado</label>
        <select
          id="status-filter"
          value={status}
          onChange={(e) => {
            const v = e.target.value as TaskStatus | 'ALL';
            setStatus(v);
            emit(search, v, priority);
          }}
          className="rounded-md border border-slate-700 bg-slate-900 px-2 py-2 text-sm text-slate-200"
        >
          {STATUSES.map((s) => (
            <option key={s} value={s}>{s === 'ALL' ? 'Estado: Todos' : s}</option>
          ))}
        </select>
        <label className="sr-only" htmlFor="priority-filter">Filtrar por prioridad</label>
        <select
          id="priority-filter"
          value={priority}
          onChange={(e) => {
            const v = e.target.value as TaskPriority | 'ALL';
            setPriority(v);
            emit(search, status, v);
          }}
          className="rounded-md border border-slate-700 bg-slate-900 px-2 py-2 text-sm text-slate-200"
        >
          {PRIORITIES.map((p) => (
            <option key={p} value={p}>{p === 'ALL' ? 'Prioridad: Todas' : p}</option>
          ))}
        </select>
        <button
          type="button"
          onClick={onNewTask}
          disabled={!authenticated}
          className="inline-flex items-center gap-1.5 rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-500 disabled:opacity-40"
        >
          <Plus className="h-4 w-4" aria-hidden /> Nueva Tarea
        </button>
        <button
          type="button"
          onClick={onForce422}
          disabled={!authenticated}
          className="inline-flex items-center gap-1.5 rounded-md border border-amber-500/40 bg-amber-500/10 px-3 py-2 text-sm text-amber-300 hover:bg-amber-500/20 disabled:opacity-40"
        >
          <Zap className="h-4 w-4" aria-hidden /> Forzar Error 422
        </button>
      </div>

      <div className="grid flex-1 grid-cols-1 gap-3 overflow-auto scrollbar-thin sm:grid-cols-2 xl:grid-cols-4">
        {COLUMNS.map((col) => {
          const colTasks = tasks.filter((t) => t.status === col);
          return (
            <div key={col} className="flex flex-col gap-2 rounded-lg border border-slate-800 bg-slate-900/50 p-3">
              <h2 className={`text-xs font-semibold tracking-wider ${columnAccent[col]}`}>
                {col} <span className="text-slate-500">({colTasks.length})</span>
              </h2>
              {colTasks.length === 0 && (
                <p className="rounded border border-dashed border-slate-800 p-3 text-xs text-slate-600">Sin tareas</p>
              )}
              {colTasks.map((task) => (
                <article key={task.id} className="rounded-md border border-slate-800 bg-slate-900 p-3 shadow-sm">
                  <div className="mb-1.5 flex items-start justify-between gap-2">
                    <h3 className="text-sm font-medium text-slate-100">{task.title}</h3>
                    <span className={`shrink-0 rounded border px-1.5 py-0.5 text-[10px] font-semibold ${priorityBadge[task.priority]}`}>
                      {task.priority}
                    </span>
                  </div>
                  {task.description && <p className="mb-2 text-xs text-slate-400">{task.description}</p>}
                  {task.dueDate && <p className="mb-2 text-[11px] text-slate-500">Vence: {task.dueDate}</p>}
                  <div className="flex items-center gap-1.5">
                    <label className="sr-only" htmlFor={`st-${task.id}`}>Cambiar estado</label>
                    <select
                      id={`st-${task.id}`}
                      value={task.status}
                      onChange={(e) => onStatusChange(task, e.target.value as TaskStatus)}
                      disabled={!authenticated}
                      className="flex-1 rounded border border-slate-700 bg-slate-800 px-1.5 py-1 text-[11px] text-slate-200 disabled:opacity-50"
                    >
                      {COLUMNS.map((s) => (
                        <option key={s} value={s}>{s}</option>
                      ))}
                    </select>
                    <button
                      type="button"
                      onClick={() => onEditTask(task)}
                      disabled={!authenticated}
                      aria-label={`Editar ${task.title}`}
                      className="rounded border border-slate-700 p-1.5 text-slate-300 hover:bg-slate-700 disabled:opacity-40"
                    >
                      <Pencil className="h-3.5 w-3.5" aria-hidden />
                    </button>
                    <button
                      type="button"
                      onClick={() => onDeleteTask(task)}
                      disabled={!authenticated}
                      aria-label={`Eliminar ${task.title}`}
                      className="rounded border border-rose-500/30 p-1.5 text-rose-400 hover:bg-rose-500/10 disabled:opacity-40"
                    >
                      <Trash2 className="h-3.5 w-3.5" aria-hidden />
                    </button>
                  </div>
                </article>
              ))}
            </div>
          );
        })}
      </div>
    </section>
  );
}
