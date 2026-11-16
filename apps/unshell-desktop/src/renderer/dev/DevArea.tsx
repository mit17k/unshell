import { useEffect, useState } from "react";
import { devViews } from "./views.js";

export function DevArea({ onClose }: { onClose: () => void }) {
  const [activeId, setActiveId] = useState(devViews[0]?.id);
  const active = devViews.find((view) => view.id === activeId) ?? devViews[0];

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div className="dev-area" role="dialog" aria-label="Development only">
      <nav className="dev-nav">
        <p className="dev-nav-title">Development only</p>
        {devViews.map((view) => (
          <button
            key={view.id}
            type="button"
            className="dev-nav-item"
            aria-current={view.id === active?.id ? "page" : undefined}
            onClick={() => setActiveId(view.id)}
          >
            {view.label}
          </button>
        ))}
      </nav>
      <main className="dev-content">
        {active ? <active.component /> : <p>No dev views registered.</p>}
      </main>
    </div>
  );
}
