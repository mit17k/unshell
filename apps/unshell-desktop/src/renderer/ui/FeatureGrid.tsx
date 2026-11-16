import type { ReactNode } from "react";

export interface Feature {
  glyph: ReactNode;
  title: string;
  body: ReactNode;
}

export function FeatureGrid({ items }: { items: Feature[] }) {
  return (
    <div className="u-feature-grid">
      {items.map((item) => (
        <article key={item.title} className="u-feature">
          <span className="u-feature-glyph">{item.glyph}</span>
          <h3>{item.title}</h3>
          <p>{item.body}</p>
        </article>
      ))}
    </div>
  );
}
