import { useCallback, useEffect, useState } from 'react';
import { api, onTrace, type Session } from './services/apiClient';
import type { ApiTraceLog, Task, TaskPayload, TaskPriority, TaskStatus } from './types/api';
import { TopNavbar } from './components/TopNavbar';
import { TaskBoard } from './components/TaskBoard';
import { TaskModal } from './components/TaskModal';
import { ApiInspector } from './components/ApiInspector';

const MAX_LOGS = 60;

export default function App() {
  const [session, setSession] = useState<Session | null>(null);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [logs, setLogs] = useState<ApiTraceLog[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [healthOk, setHealthOk] = useState<boolean | null>(null);
  const [simulate, setSimulate] = useState(false);
  const [busy, setBusy] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Task | null>(null);
  const [filters, setFilters] = useState<{ search: string; status: TaskStatus | 'ALL'; priority: TaskPriority | 'ALL' }>({
    search: '',
    status: 'ALL',
    priority: 'ALL',
  });

  useEffect(() => {
    const unsub = onTrace((log) => {
      setLogs((prev) => [log, ...prev].slice(0, MAX_LOGS));
      setSelectedId(log.id);
    });
    return unsub;
  }, []);

  const refreshTasks = useCallback(
    async (s: Session | null, f = filters) => {
      if (!s) return;
      const { data } = await api.listTasks(s, {
        status: f.status === 'ALL' ? undefined : f.status,
        priority: f.priority === 'ALL' ? undefined : f.priority,
        search: f.search || undefined,
      });
      if (data.success) setTasks(data.data);
    },
    [filters],
  );

  useEffect(() => {
    void refreshTasks(session);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [session]);

  const ping = useCallback(async () => {
    setBusy(true);
    try {
      const { status, data } = await api.health();
      setHealthOk(status === 200 && data.success);
    } finally {
      setBusy(false);
    }
  }, []);

  const login = useCallback(async () => {
    setBusy(true);
    try {
      const { data } = await api.login('demo_user', 'Password123!');
      if (data.success) {
        setSession({ token: data.data.accessToken, user: data.data.user });
      }
    } finally {
      setBusy(false);
    }
  }, []);

  const me = useCallback(async () => {
    if (!session) return;
    setBusy(true);
    try {
      await api.me(session);
    } finally {
      setBusy(false);
    }
  }, [session]);

  const submitTask = useCallback(
    async (payload: TaskPayload) => {
      if (!session) return;
      const { data, status } = editing
        ? await api.updateTask(session, editing.id, payload)
        : await api.createTask(session, payload);
      if (data.success || status === 422) {
        setModalOpen(false);
        setEditing(null);
        await refreshTasks(session);
      }
    },
    [session, editing, refreshTasks],
  );

  const force422 = useCallback(async () => {
    if (!session) return;
    await api.createTask(session, { title: 'A', priority: 'INVALID_ENUM' });
  }, [session]);

  return (
    <div className="flex h-screen flex-col">
      <TopNavbar
        session={session}
        healthOk={healthOk}
        simulate={simulate}
        busy={busy}
        onPing={ping}
        onLogin={login}
        onMe={me}
        onSimulateChange={setSimulate}
      />
      <div className="grid min-h-0 flex-1 grid-cols-1 lg:grid-cols-12">
        <main className="min-h-0 overflow-hidden lg:col-span-7">
          <TaskBoard
            tasks={tasks}
            authenticated={!!session}
            onSearch={(f) => {
              setFilters(f);
              void refreshTasks(session, f);
            }}
            onNewTask={() => {
              setEditing(null);
              setModalOpen(true);
            }}
            onEditTask={(t) => {
              setEditing(t);
              setModalOpen(true);
            }}
            onDeleteTask={async (t) => {
              if (!session) return;
              await api.deleteTask(session, t.id);
              await refreshTasks(session);
            }}
            onStatusChange={async (t, status) => {
              if (!session) return;
              await api.updateTask(session, t.id, { status });
              await refreshTasks(session);
            }}
            onForce422={force422}
          />
        </main>
        <div className="min-h-96 border-t border-slate-800 lg:col-span-5 lg:min-h-0 lg:border-t-0">
          <ApiInspector logs={logs} selectedId={selectedId} onSelect={setSelectedId} onClear={() => { setLogs([]); setSelectedId(null); }} />
        </div>
      </div>
      {modalOpen && (
        <TaskModal
          task={editing}
          onClose={() => {
            setModalOpen(false);
            setEditing(null);
          }}
          onSubmit={submitTask}
        />
      )}
    </div>
  );
}
