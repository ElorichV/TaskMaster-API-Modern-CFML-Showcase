import { useEffect, useRef, useState } from 'react';
import { X } from 'lucide-react';
import type { Task, TaskPayload, TaskPriority, TaskStatus } from '../types/api';

interface Props {
  task: Task | null;
  onClose: () => void;
  onSubmit: (payload: TaskPayload) => void;
}

export function TaskModal({ task, onClose, onSubmit }: Props) {
  const [title, setTitle] = useState(task?.title ?? '');
  const [description, setDescription] = useState(task?.description ?? '');
  const [status, setStatus] = useState<TaskStatus>(task?.status ?? 'PENDING');
  const [priority, setPriority] = useState<TaskPriority>(task?.priority ?? 'MEDIUM');
  const [dueDate, setDueDate] = useState(task?.dueDate ?? '');
  const dialogRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [onClose]);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/70 p-4 backdrop-blur-sm"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="task-modal-title"
        className="w-full max-w-md rounded-lg border border-slate-700 bg-slate-900 p-5 shadow-xl"
      >
        <div className="mb-4 flex items-center justify-between">
          <h2 id="task-modal-title" className="text-sm font-semibold text-slate-100">
            {task ? 'Editar Tarea' : 'Nueva Tarea'}
          </h2>
          <button type="button" onClick={onClose} aria-label="Cerrar modal" className="rounded p-1 text-slate-400 hover:bg-slate-800">
            <X className="h-4 w-4" aria-hidden />
          </button>
        </div>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            const payload: TaskPayload = { title, description, status, priority };
            if (dueDate) payload.dueDate = dueDate;
            onSubmit(payload);
          }}
          className="flex flex-col gap-3"
        >
          <label className="flex flex-col gap-1 text-xs text-slate-400">
            Título *
            <input
              required
              minLength={3}
              maxLength={200}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              autoFocus
              className="rounded-md border border-slate-700 bg-slate-950 px-2.5 py-2 text-sm text-slate-100"
            />
          </label>
          <label className="flex flex-col gap-1 text-xs text-slate-400">
            Descripción
            <textarea
              maxLength={1000}
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="rounded-md border border-slate-700 bg-slate-950 px-2.5 py-2 text-sm text-slate-100"
            />
          </label>
          <div className="grid grid-cols-2 gap-3">
            <label className="flex flex-col gap-1 text-xs text-slate-400">
              Estado
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value as TaskStatus)}
                className="rounded-md border border-slate-700 bg-slate-950 px-2.5 py-2 text-sm text-slate-100"
              >
                {['PENDING', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED'].map((s) => (
                  <option key={s}>{s}</option>
                ))}
              </select>
            </label>
            <label className="flex flex-col gap-1 text-xs text-slate-400">
              Prioridad
              <select
                value={priority}
                onChange={(e) => setPriority(e.target.value as TaskPriority)}
                className="rounded-md border border-slate-700 bg-slate-950 px-2.5 py-2 text-sm text-slate-100"
              >
                {['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((p) => (
                  <option key={p}>{p}</option>
                ))}
              </select>
            </label>
          </div>
          <label className="flex flex-col gap-1 text-xs text-slate-400">
            Fecha de vencimiento
            <input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              className="rounded-md border border-slate-700 bg-slate-950 px-2.5 py-2 text-sm text-slate-100"
            />
          </label>
          <div className="mt-2 flex justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded-md border border-slate-700 px-3 py-2 text-sm text-slate-300 hover:bg-slate-800"
            >
              Cancelar
            </button>
            <button
              type="submit"
              className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-500"
            >
              {task ? 'Guardar cambios' : 'Crear tarea'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
