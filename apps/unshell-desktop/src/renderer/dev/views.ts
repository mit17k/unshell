import type { ComponentType } from "react";
import { DesignSystemView } from "./views/DesignSystemView.js";
import { ScreensView } from "./views/ScreensView.js";

export interface DevView {
  id: string;
  label: string;
  component: ComponentType;
}

// Register new dev views here. Order is the sidebar order.
export const devViews: DevView[] = [
  { id: "design-system", label: "Design system", component: DesignSystemView },
  { id: "screens", label: "Screens", component: ScreensView },
];
