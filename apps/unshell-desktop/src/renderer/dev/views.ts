import type { ComponentType } from "react";
import { CodeViewerView } from "./views/CodeViewerView.js";
import { DesignSystemView } from "./views/DesignSystemView.js";
import { TerminalView } from "./views/TerminalView.js";

export interface DevView {
  id: string;
  label: string;
  component: ComponentType;
}

// Register new dev views here. Order is the sidebar order.
export const devViews: DevView[] = [
  { id: "design-system", label: "Design system", component: DesignSystemView },
  { id: "code-viewer", label: "Code viewer", component: CodeViewerView },
  { id: "terminal", label: "Terminal", component: TerminalView },
];
