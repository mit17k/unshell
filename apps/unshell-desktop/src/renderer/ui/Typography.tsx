import type { ReactNode } from "react";
import { cx } from "./cx.js";

export function Display({
  size = "lg",
  as: Tag = "h1",
  children,
}: {
  size?: "xl" | "lg" | "md";
  as?: "h1" | "h2" | "h3";
  children: ReactNode;
}) {
  return (
    <Tag className={cx("u-display", `u-display--${size}`)}>{children}</Tag>
  );
}

/** Small uppercase mono label used for eyebrows, keys and metadata. */
export function Eyebrow({ children }: { children: ReactNode }) {
  return <span className="u-eyebrow">{children}</span>;
}

export function Kbd({ children }: { children: ReactNode }) {
  return <kbd className="u-kbd">{children}</kbd>;
}

export function TextLink({
  href,
  children,
}: {
  href: string;
  children: ReactNode;
}) {
  return (
    <a className="u-link" href={href}>
      {children}
    </a>
  );
}
