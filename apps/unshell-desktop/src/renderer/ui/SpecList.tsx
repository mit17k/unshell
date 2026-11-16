import type { ReactNode } from "react";

export interface Spec {
  label: string;
  value: ReactNode;
  note?: ReactNode;
}

/** Label, dotted rule, value rows: the reference's spec sheet. */
export function SpecList({ items }: { items: Spec[] }) {
  return (
    <dl className="u-spec-list">
      {items.map((item) => (
        <div key={item.label} className="u-spec">
          <dt className="u-eyebrow">{item.label}</dt>
          <span className="u-rule" aria-hidden />
          <dd>
            <span className="u-spec-value">{item.value}</span>
            {item.note && <span className="u-spec-note">{item.note}</span>}
          </dd>
        </div>
      ))}
    </dl>
  );
}
