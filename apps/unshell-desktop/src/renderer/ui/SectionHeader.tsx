import type { ReactNode } from "react";

/** "01  SEE IT RUNNING ───────── 見" */
export function SectionHeader({
  index,
  title,
  glyph,
}: {
  index?: string;
  title: string;
  glyph?: ReactNode;
}) {
  return (
    <div className="u-section-header">
      {index && <span className="u-section-index">{index}</span>}
      <span className="u-eyebrow">{title}</span>
      <span className="u-rule" aria-hidden />
      {glyph && <span className="u-section-glyph">{glyph}</span>}
    </div>
  );
}
