import { lazy, Suspense, useEffect, useState } from "react";
import type { Overview } from "../bridge.js";

const DesignSystem = import.meta.env.DEV
  ? lazy(() => import("./DesignSystem.js"))
  : null;

export function App() {
  const [overview, setOverview] = useState<Overview | null>(null);
  const [bridgeError, setBridgeError] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);
  const [showDesign, setShowDesign] = useState(false);

  useEffect(() => {
    let active = true;
    async function refresh() {
      try {
        const next = await window.unshell.overview();
        if (active) {
          setOverview(next);
          setBridgeError(null);
        }
      } catch {
        if (active)
          setBridgeError(
            "Unable to communicate with the desktop process. Restart Unshell to reconnect.",
          );
      }
    }
    void refresh();
    const timer = setInterval(() => {
      void refresh();
    }, 10000);
    return () => {
      active = false;
      clearInterval(timer);
    };
  }, [attempt]);

  const connected = overview?.connected && !bridgeError;
  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="wordmark">
          unshell<span> / </span>
        </div>
        <p className="eyebrow">Development environment</p>
        <nav aria-label="Primary navigation">
          <button
            className="nav-item active"
            onClick={() => setShowDesign(false)}
          >
            Control center <span>01</span>
          </button>
        </nav>
        <div className="sidebar-note">
          <span className="eyebrow">Foundation / 0.1</span>
          <p>
            One environment.
            <br />
            People and agents.
          </p>
          {import.meta.env.DEV && (
            <button className="quiet" onClick={() => setShowDesign(true)}>
              Design language
            </button>
          )}
        </div>
      </aside>
      <main>
        {import.meta.env.DEV && showDesign && DesignSystem ? (
          <Suspense fallback={<p>Loading specimen…</p>}>
            <DesignSystem />
          </Suspense>
        ) : (
          <>
            <header className="page-header">
              <span className="eyebrow">Unshell / Control center</span>
              <span className="eyebrow">Local coordination</span>
            </header>
            <section className="intro">
              <p className="eyebrow">Your development environment</p>
              <h1>
                A place to
                <br />
                <em>bring work together.</em>
              </h1>
              <p className="lede">
                Workspaces, version control, projects, agents, and automation. A
                shared foundation for everything you build.
              </p>
            </section>
            <section
              className="connection"
              aria-label="API connection"
              aria-live="polite"
            >
              <div>
                <span className={`status ${connected ? "success" : "warning"}`}>
                  {connected
                    ? "Connected"
                    : overview || bridgeError
                      ? "Disconnected"
                      : "Connecting"}
                </span>
                <h2>Coordination API</h2>
                <code>{overview?.endpoint ?? "Checking local service…"}</code>
              </div>
              <div className="connection-detail">
                {connected && overview?.connected ? (
                  <>
                    <span className="eyebrow">
                      API v{overview.health.apiVersion}
                    </span>
                    <p>Uptime {overview.health.uptimeSeconds}s</p>
                  </>
                ) : (
                  <p>
                    {bridgeError ??
                      (overview && !overview.connected
                        ? overview.error
                        : "Establishing a connection to the local API.")}
                  </p>
                )}
                <button onClick={() => setAttempt((value) => value + 1)}>
                  Refresh connection
                </button>
              </div>
            </section>
            <section
              className="capabilities"
              aria-labelledby="capabilities-heading"
            >
              <div className="section-heading">
                <h2 id="capabilities-heading">Environment capabilities</h2>
                <span className="eyebrow">Migration in progress</span>
              </div>
              {connected && overview?.connected ? (
                <div className="capability-list">
                  {overview.capabilities.capabilities.map(
                    (capability, index) => (
                      <article className="capability" key={capability.id}>
                        <span className="index">0{index + 1}</span>
                        <div>
                          <h3>{capability.name}</h3>
                          <p>{capability.description}</p>
                        </div>
                        <span className="status">{capability.state}</span>
                      </article>
                    ),
                  )}
                </div>
              ) : (
                <p className="empty-state">
                  Capabilities will appear when the coordination API is
                  connected.
                </p>
              )}
            </section>
            <footer>
              The Electron foundation is live. Workspace creation and existing
              local data support will return as the Rust features are ported.
            </footer>
          </>
        )}
      </main>
    </div>
  );
}
