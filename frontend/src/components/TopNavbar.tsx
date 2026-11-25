import { Activity, FlaskConical, KeyRound, Radio, User as UserIcon } from 'lucide-react';
import type { Session } from '../services/apiClient';
import { setSimulateMode } from '../services/apiClient';

interface Props {
  session: Session | null;
  healthOk: boolean | null;
  simulate: boolean;
  onLogin: () => void;
  onMe: () => void;
  onPing: () => void;
  onSimulateChange: (v: boolean) => void;
  busy: boolean;
}

export function TopNavbar({ session, healthOk, simulate, onLogin, onMe, onPing, onSimulateChange, busy }: Props) {
  return (
    <nav className="flex flex-wrap items-center gap-3 border-b border-slate-800 bg-slate-900/80 px-4 py-3 backdrop-blur">
      <div className="flex items-center gap-2 font-semibold text-slate-100">
        <Activity className="h-5 w-5 text-indigo-400" aria-hidden />
        TaskMaster <span className="text-slate-500">/</span> DevTools Inspector
      </div>

      <div className="flex items-center gap-2" role="status" aria-label="Backend health">
        <span
          className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${
            healthOk === null
              ? 'bg-slate-800 text-slate-400'
              : healthOk
                ? 'bg-emerald-500/15 text-emerald-400'
                : 'bg-rose-500/15 text-rose-400'
          }`}
        >
          <Radio className="h-3 w-3" aria-hidden />
          {healthOk === null ? 'Sin ping' : healthOk ? 'API Saludable' : 'API Caída'}
        </span>
      </div>

      <button
        type="button"
        onClick={() => {
          const next = !simulate;
          setSimulateMode(next);
          onSimulateChange(next);
        }}
        aria-pressed={simulate}
        className={`inline-flex items-center gap-1.5 rounded-md border px-2.5 py-1 text-xs transition ${
          simulate
            ? 'border-amber-500/40 bg-amber-500/10 text-amber-300'
            : 'border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700'
        }`}
      >
        <FlaskConical className="h-3.5 w-3.5" aria-hidden />
        {simulate ? 'Modo Simulado' : 'Modo Live'}
      </button>

      <div className="ms-auto flex flex-wrap items-center gap-2">
        {session ? (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-indigo-500/15 px-2.5 py-0.5 text-xs text-indigo-300">
            <UserIcon className="h-3 w-3" aria-hidden />
            {session.user.username}
          </span>
        ) : (
          <span className="text-xs text-slate-500">No autenticado</span>
        )}
        <button
          type="button"
          onClick={onPing}
          disabled={busy}
          className="rounded-md border border-slate-700 bg-slate-800 px-2.5 py-1 text-xs text-slate-200 hover:bg-slate-700 disabled:opacity-50"
        >
          Ping /health
        </button>
        <button
          type="button"
          onClick={onMe}
          disabled={busy || !session}
          className="rounded-md border border-slate-700 bg-slate-800 px-2.5 py-1 text-xs text-slate-200 hover:bg-slate-700 disabled:opacity-50"
        >
          Probar /auth/me
        </button>
        <button
          type="button"
          onClick={onLogin}
          disabled={busy}
          className="inline-flex items-center gap-1.5 rounded-md bg-indigo-600 px-3 py-1 text-xs font-medium text-white hover:bg-indigo-500 disabled:opacity-50"
        >
          <KeyRound className="h-3.5 w-3.5" aria-hidden />
          Autenticar como demo_user
        </button>
      </div>
    </nav>
  );
}
