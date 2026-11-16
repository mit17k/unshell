import type { ReactNode } from "react";
import { cx } from "./cx.js";

export type Tone =
  | "neutral"
  | "accent"
  | "info"
  | "success"
  | "warning"
  | "danger";

export function Badge({
  tone = "neutral",
  dot = false,
  children,
}: {
  tone?: Tone;
  dot?: boolean;
  children: ReactNode;
}) {
  return (
    <span className={cx("u-badge", `u-tone--${tone}`)}>
      {dot && <span className="u-badge-dot" aria-hidden />}
      {children}
    </span>
  );
}
