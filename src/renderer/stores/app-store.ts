import { create } from "zustand";

interface AppState {
  count: number;
  title: string;
  increment: () => void;
  decrement: () => void;
  setTitle: (title: string) => void;
}

export const useAppStore = create<AppState>((set) => ({
  count: 0,
  title: "Unshell",
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  setTitle: (title) => set({ title }),
}));
