import type { ReactNode } from "react";

/** Hairline box with corner brackets, for media, previews and callouts. */
export function Frame({
  caption,
  children,
}: {
  caption?: ReactNode;
  children: ReactNode;
}) {
  return (
    <figure className="u-frame">
      <span className="u-frame-corner u-frame-corner--tl" aria-hidden />
      <span className="u-frame-corner u-frame-corner--tr" aria-hidden />
      <span className="u-frame-corner u-frame-corner--bl" aria-hidden />
      <span className="u-frame-corner u-frame-corner--br" aria-hidden />
      {caption && <figcaption className="u-eyebrow">{caption}</figcaption>}
      {children}
    </figure>
  );
}
