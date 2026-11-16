import { useState } from "react";

interface AgentCardProps {
  name: string;
  status: "idle" | "running" | "failed";
  onRestart?: (name: string) => void;
}

export function AgentCard({ name, status, onRestart }: AgentCardProps) {
  const [expanded, setExpanded] = useState(false);
  const tone = status === "failed" ? "danger" : status === "running" ? "info" : "neutral";

  return (
    <article className={`agent-card agent-card--${tone}`}>
      <header onClick={() => setExpanded((open) => !open)}>
        <h3>{name}</h3>
        <span aria-label={`Agent is ${status}`}>{status}</span>
      </header>
      {expanded && (
        <button type="button" disabled={status === "running"} onClick={() => onRestart?.(name)}>
          Restart
        </button>
      )}
    </article>
  );
}
