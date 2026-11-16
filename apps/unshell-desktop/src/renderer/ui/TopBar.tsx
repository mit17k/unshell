import type { ReactNode } from "react";
import { cx } from "./cx.js";

export interface NavItem {
  id: string;
  label: string;
}

export function TopBar({
  brand,
  nav,
  active,
  onNavigate,
  actions,
}: {
  brand: ReactNode;
  nav: NavItem[];
  active?: string;
  onNavigate?: (id: string) => void;
  actions?: ReactNode;
}) {
  return (
    <header className="u-topbar">
      <div className="u-topbar-brand">{brand}</div>
      <nav className="u-topbar-nav">
        {nav.map((item) => (
          <button
            key={item.id}
            type="button"
            className={cx("u-nav-link", item.id === active && "is-active")}
            aria-current={item.id === active ? "page" : undefined}
            onClick={() => onNavigate?.(item.id)}
          >
            {item.label}
          </button>
        ))}
      </nav>
      <div className="u-topbar-actions">{actions}</div>
    </header>
  );
}
