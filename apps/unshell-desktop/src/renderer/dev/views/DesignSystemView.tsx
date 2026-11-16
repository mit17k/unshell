const colors = [
  "canvas",
  "surface",
  "surface-raised",
  "border",
  "text",
  "text-muted",
  "accent",
  "success",
  "warning",
  "danger",
];
const spaces = ["1", "2", "3", "4", "6"];

export function DesignSystemView() {
  return (
    <div className="dev-stack">
      <h1>Design system</h1>

      <section>
        <h2>Colour</h2>
        <div className="dev-swatches">
          {colors.map((name) => (
            <figure key={name} className="dev-swatch">
              <div style={{ background: `var(--color-${name})` }} />
              <figcaption>--color-{name}</figcaption>
            </figure>
          ))}
        </div>
      </section>

      <section>
        <h2>Type</h2>
        <p style={{ fontFamily: "var(--font-ui)" }}>UI · The quick brown fox</p>
        <p style={{ fontFamily: "var(--font-mono)" }}>
          Mono · The quick brown fox
        </p>
      </section>

      <section>
        <h2>Spacing</h2>
        {spaces.map((step) => (
          <div key={step} className="dev-space">
            <code>--space-{step}</code>
            <span style={{ width: `var(--space-${step})` }} />
          </div>
        ))}
      </section>
    </div>
  );
}
