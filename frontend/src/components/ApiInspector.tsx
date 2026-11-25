import { useState } from 'react';
import { Check, Copy, Eraser, ShieldCheck } from 'lucide-react';
import type { ApiTraceLog, HttpMethod } from '../types/api';

const methodBadge: Record<HttpMethod, string> = {
  GET: 'bg-blue-500/15 text-blue-400',
  POST: 'bg-emerald-500/15 text-emerald-400',
  PUT: 'bg-amber-500/15 text-amber-400',
  DELETE: 'bg-rose-500/15 text-rose-400',
};

function statusBadge(code: number): string {
  if (code < 300) return 'bg-emerald-500/15 text-emerald-400';
  if (code < 500) return 'bg-amber-500/15 text-amber-400';
  return 'bg-rose-500/15 text-rose-400';
}

const OWASP_KEYS = new Set(['x-content-type-options', 'x-frame-options', 'content-security-policy', 'referrer-policy', 'strict-transport-security']);
const TABS = ['Response JSON', 'Request & Headers', 'CFML Security & SQL', 'cURL'] as const;
type Tab = (typeof TABS)[number];

interface Props {
  logs: ApiTraceLog[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onClear: () => void;
}

export function ApiInspector({ logs, selectedId, onSelect, onClear }: Props) {
  const [tab, setTab] = useState<Tab>('Response JSON');
  const [copied, setCopied] = useState(false);
  const selected = logs.find((l) => l.id === selectedId) ?? logs[0] ?? null;

  const copyCurl = async () => {
    if (!selected) return;
    await navigator.clipboard.writeText(selected.curlCommand);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <aside aria-label="API live inspector" className="flex h-full flex-col border-l border-slate-800 bg-slate-900/40">
      {/* Request stream */}
      <div className="flex h-1/2 min-h-48 flex-col border-b border-slate-800">
        <div className="flex items-center justify-between border-b border-slate-800 px-3 py-2">
          <h2 className="text-xs font-semibold tracking-wider text-slate-300">REQUEST STREAM</h2>
          <button
            type="button"
            onClick={onClear}
            className="inline-flex items-center gap-1 rounded border border-slate-700 px-2 py-0.5 text-[11px] text-slate-400 hover:bg-slate-800"
          >
            <Eraser className="h-3 w-3" aria-hidden /> Clear logs
          </button>
        </div>
        <ul className="flex-1 overflow-auto scrollbar-thin">
          {logs.length === 0 && (
            <li className="p-4 text-xs text-slate-600">Sin peticiones aún. Interactúa con el panel izquierdo.</li>
          )}
          {logs.map((log) => (
            <li key={log.id}>
              <button
                type="button"
                onClick={() => onSelect(log.id)}
                aria-current={selected?.id === log.id}
                className={`flex w-full items-center gap-2 border-b border-slate-800/60 px-3 py-2 text-left text-xs transition hover:bg-slate-800/60 ${
                  selected?.id === log.id ? 'bg-slate-800/80' : ''
                }`}
              >
                <span className={`w-12 shrink-0 rounded px-1.5 py-0.5 text-center text-[10px] font-bold ${methodBadge[log.method]}`}>
                  {log.method}
                </span>
                <span className="min-w-0 flex-1 truncate text-slate-300">{log.endpoint}</span>
                <span className={`rounded px-1.5 py-0.5 text-[10px] font-semibold ${statusBadge(log.statusCode)}`}>
                  {log.statusCode}
                </span>
                <span className="w-12 text-right text-[10px] text-slate-500">{log.durationMs}ms</span>
                <span
                  className={`rounded px-1.5 py-0.5 text-[9px] font-semibold ${
                    log.source === 'LIVE' ? 'bg-indigo-500/15 text-indigo-300' : 'bg-amber-500/15 text-amber-300'
                  }`}
                >
                  {log.source === 'LIVE' ? 'LIVE' : 'SIMULATED'}
                </span>
              </button>
            </li>
          ))}
        </ul>
      </div>

      {/* Detail tabs */}
      <div className="flex h-1/2 min-h-0 flex-col">
        <div className="flex border-b border-slate-800" role="tablist" aria-label="Detalle de petición">
          {TABS.map((t) => (
            <button
              key={t}
              type="button"
              role="tab"
              aria-selected={tab === t}
              onClick={() => setTab(t)}
              className={`px-3 py-2 text-[11px] transition ${
                tab === t ? 'border-b-2 border-indigo-500 text-slate-100' : 'text-slate-500 hover:text-slate-300'
              }`}
            >
              {t}
            </button>
          ))}
        </div>
        <div className="flex-1 overflow-auto scrollbar-thin p-3" role="tabpanel">
          {!selected && <p className="text-xs text-slate-600">Selecciona una petición del stream.</p>}
          {selected && tab === 'Response JSON' && (
            <pre className="text-[11px] leading-relaxed text-slate-300"><code>{selected.responseBody}</code></pre>
          )}
          {selected && tab === 'Request & Headers' && (
            <div className="flex flex-col gap-4 text-[11px]">
              {selected.requestBody && (
                <section>
                  <h3 className="mb-1 font-semibold text-slate-300">Request Body</h3>
                  <pre className="rounded border border-slate-800 bg-slate-950 p-2 text-slate-300"><code>{selected.requestBody}</code></pre>
                </section>
              )}
              <section>
                <h3 className="mb-1 font-semibold text-slate-300">Request Headers</h3>
                <HeaderTable headers={selected.requestHeaders} />
              </section>
              <section>
                <h3 className="mb-1 flex items-center gap-1.5 font-semibold text-slate-300">
                  Response Headers <ShieldCheck className="h-3.5 w-3.5 text-emerald-400" aria-hidden />
                </h3>
                <HeaderTable headers={selected.responseHeaders} highlightOwasp />
              </section>
            </div>
          )}
          {selected && tab === 'CFML Security & SQL' && (
            <div className="flex flex-col gap-3 text-[11px]">
              <p className="rounded border border-emerald-500/30 bg-emerald-500/5 p-2 text-emerald-300/90">
                Todas las consultas usan <code>queryExecute()</code> con parámetros <code>cfsqltype</code> tipados
                (anti-SQLi). El filtro <code>user_id = token.sub</code> garantiza aislamiento por tenant y previene
                BOLA/IDOR: un usuario nunca puede leer o mutar tareas de otro.
              </p>
              <pre className="rounded border border-slate-800 bg-slate-950 p-3 leading-relaxed text-slate-300">
                <code>{selected.sqlPreview}</code>
              </pre>
            </div>
          )}
          {selected && tab === 'cURL' && (
            <div className="flex flex-col gap-2">
              <button
                type="button"
                onClick={copyCurl}
                className="inline-flex w-fit items-center gap-1.5 rounded border border-slate-700 px-2.5 py-1 text-[11px] text-slate-300 hover:bg-slate-800"
              >
                {copied ? <Check className="h-3.5 w-3.5 text-emerald-400" aria-hidden /> : <Copy className="h-3.5 w-3.5" aria-hidden />}
                {copied ? 'Copiado' : 'Copy to clipboard'}
              </button>
              <pre className="whitespace-pre-wrap break-all rounded border border-slate-800 bg-slate-950 p-3 text-[11px] leading-relaxed text-slate-300">
                <code>{selected.curlCommand}</code>
              </pre>
            </div>
          )}
        </div>
      </div>
    </aside>
  );
}

function HeaderTable({ headers, highlightOwasp = false }: { headers: Record<string, string>; highlightOwasp?: boolean }) {
  const entries = Object.entries(headers);
  if (entries.length === 0) return <p className="text-slate-600">Sin headers.</p>;
  return (
    <table className="w-full border-collapse">
      <tbody>
        {entries.map(([k, v]) => {
          const isOwasp = highlightOwasp && OWASP_KEYS.has(k.toLowerCase());
          return (
            <tr key={k} className={isOwasp ? 'bg-emerald-500/5' : ''}>
              <td className={`border-b border-slate-800/60 py-1 pr-2 align-top font-medium ${isOwasp ? 'text-emerald-400' : 'text-slate-400'}`}>
                {k}
              </td>
              <td className="border-b border-slate-800/60 py-1 text-slate-300 break-all">{v}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
