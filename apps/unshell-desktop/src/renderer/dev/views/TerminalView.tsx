import { useCallback, useState } from "react";
import { TerminalPane, type TerminalStatus } from "../../terminal/index.js";
import { Badge, Button } from "../../ui/index.js";

interface Tab {
  key: number;
  status?: TerminalStatus;
}

let nextKey = 1;

export function TerminalView() {
  const [tabs, setTabs] = useState<Tab[]>(() => [{ key: nextKey++ }]);
  const [activeKey, setActiveKey] = useState(tabs[0]?.key ?? 0);
  const active = tabs.find((tab) => tab.key === activeKey);

  const addTab = () => {
    const key = nextKey++;
    setTabs((list) => [...list, { key }]);
    setActiveKey(key);
  };

  const closeTab = (key: number) => {
    const next = tabs.filter((tab) => tab.key !== key);
    setTabs(next);
    if (key === activeKey && next.length)
      setActiveKey(next[next.length - 1]!.key);
  };

  const setStatus = useCallback((key: number, status: TerminalStatus) => {
    setTabs((list) =>
      list.map((tab) => (tab.key === key ? { ...tab, status } : tab)),
    );
  }, []);

  const status = active?.status;
  const shellName = (tab: Tab) =>
    tab.status?.shell?.split("/").pop() ?? "shell";

  return (
    <div className="term-screen">
      <div className="term-toolbar">
        <div className="term-tabs" role="tablist">
          {tabs.map((tab) => (
            <div
              key={tab.key}
              className="term-tab"
              role="tab"
              aria-selected={tab.key === activeKey}
              tabIndex={0}
              onClick={() => setActiveKey(tab.key)}
              onKeyDown={(event) =>
                event.key === "Enter" && setActiveKey(tab.key)
              }
            >
              <span>{shellName(tab)}</span>
              {tab.status?.exitCode !== undefined && (
                <span className="term-exited">exited</span>
              )}
              <button
                type="button"
                className="term-tab-close"
                aria-label="Close terminal"
                onClick={(event) => {
                  event.stopPropagation();
                  closeTab(tab.key);
                }}
              >
                ×
              </button>
            </div>
          ))}
          <Button size="sm" variant="ghost" onClick={addTab}>
            + New
          </Button>
        </div>
        {status && (
          <div className="term-meta">
            <Badge
              dot
              tone={status.renderer === "webgl" ? "success" : "warning"}
            >
              {status.renderer}
            </Badge>
            <Badge>
              {status.cols}×{status.rows}
            </Badge>
          </div>
        )}
      </div>
      <div className="term-body">
        {tabs.map((tab) => (
          <TerminalPane
            key={tab.key}
            active={tab.key === activeKey}
            onStatus={(next) => setStatus(tab.key, next)}
          />
        ))}
        {tabs.length === 0 && (
          <div className="term-empty">
            <Button variant="primary" onClick={addTab}>
              Open a terminal
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
