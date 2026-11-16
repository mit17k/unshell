import { useState } from "react";
import { DevArea } from "./DevArea.js";
import "./dev.css";

export default function DevTools() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button
        type="button"
        className="dev-toggle"
        aria-pressed={open}
        onClick={() => setOpen((value) => !value)}
      >
        Dev
      </button>
      {open && <DevArea onClose={() => setOpen(false)} />}
    </>
  );
}
