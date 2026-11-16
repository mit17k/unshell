import { useState, type ReactNode } from "react";

export interface AccordionItem {
  id: string;
  title: string;
  content: ReactNode;
}

export function Accordion({
  items,
  defaultOpen,
}: {
  items: AccordionItem[];
  defaultOpen?: string;
}) {
  const [open, setOpen] = useState(defaultOpen ?? null);
  return (
    <div className="u-accordion">
      {items.map((item) => {
        const expanded = open === item.id;
        return (
          <section key={item.id} className="u-accordion-item">
            <h3>
              <button
                type="button"
                className="u-accordion-trigger"
                aria-expanded={expanded}
                aria-controls={`${item.id}-panel`}
                onClick={() => setOpen(expanded ? null : item.id)}
              >
                <span>{item.title}</span>
                <span aria-hidden>{expanded ? "−" : "+"}</span>
              </button>
            </h3>
            <div
              id={`${item.id}-panel`}
              className="u-accordion-panel"
              hidden={!expanded}
            >
              {item.content}
            </div>
          </section>
        );
      })}
    </div>
  );
}
