import { Minus, Plus } from "lucide-react";

import { useAppStore } from "@stores/app-store";

import { Button } from "@components/ui/button";

export function App() {
  const { count, title, increment, decrement } = useAppStore();

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-8 p-8">
      <h1 className="text-4xl font-bold">{title}</h1>
      <p className="text-muted-foreground">
        Welcome to your Electron + React + Zustand app
      </p>

      <div className="flex items-center gap-4">
        <Button variant="outline" size="icon" onClick={decrement}>
          <Minus className="h-4 w-4" />
        </Button>
        <span className="min-w-[3rem] text-center text-2xl font-semibold">
          {count}
        </span>
        <Button variant="outline" size="icon" onClick={increment}>
          <Plus className="h-4 w-4" />
        </Button>
      </div>

      <div className="flex gap-2">
        <Button variant="default">Primary</Button>
        <Button variant="secondary">Secondary</Button>
        <Button variant="outline">Outline</Button>
        <Button variant="ghost">Ghost</Button>
      </div>
    </div>
  );
}
