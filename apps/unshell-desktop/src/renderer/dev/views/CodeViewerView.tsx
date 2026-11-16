import { useEffect, useState } from "react";
import { CodeViewer, languages } from "../../code/index.js";
import { samples } from "../samples.js";

const screens = languages.filter((language) => samples[language.id]);

export function CodeViewerView() {
  const [activeId, setActiveId] = useState(screens[0]?.id ?? "");
  const [code, setCode] = useState<string | null>(null);
  const sample = samples[activeId];

  useEffect(() => {
    let active = true;
    setCode(null);
    void sample?.load().then((module) => {
      if (active) setCode(module.default);
    });
    return () => {
      active = false;
    };
  }, [sample]);

  return (
    <div className="cv-screen">
      <nav className="cv-languages" aria-label="Languages">
        <p className="u-eyebrow">{screens.length} languages</p>
        {screens.map((language) => (
          <button
            key={language.id}
            type="button"
            className="dev-nav-item"
            aria-current={language.id === activeId ? "page" : undefined}
            onClick={() => setActiveId(language.id)}
          >
            {language.label}
          </button>
        ))}
      </nav>
      {sample && code !== null ? (
        <CodeViewer code={code} lang={activeId} filename={sample.filename} />
      ) : (
        <div className="code-viewer" />
      )}
    </div>
  );
}
