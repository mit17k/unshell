import { lazy, Suspense } from "react";

// Dev tooling is only referenced when import.meta.env.DEV is true, so the
// production bundle drops the import (and the whole dev/ folder) entirely.
const DevTools = import.meta.env.DEV
  ? lazy(() => import("./dev/DevTools.js"))
  : null;

export function App() {
  return (
    <>
      {DevTools && (
        <Suspense fallback={null}>
          <DevTools />
        </Suspense>
      )}
    </>
  );
}
