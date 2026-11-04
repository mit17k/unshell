export default function DesignSystem() {
  return (
    <section className="intro">
      <p className="eyebrow">Development only</p>
      <h1>Design language specimen</h1>
      <p className="lede">
        Editorial display. Operational metadata. Fine rules and compact
        controls.
      </p>
      <div className="connection">
        <div>
          <h2>Actions and status</h2>
          <button>Primary action</button>
          <button className="quiet">Secondary action</button>
        </div>
        <div>
          <span className="status success">Connected</span>
          <span className="status warning">Pending</span>
          <span className="status danger">Failed</span>
        </div>
      </div>
      <div className="swatches">
        {[
          "canvas",
          "surface",
          "surface-raised",
          "text",
          "text-muted",
          "border",
          "accent",
          "accent-text",
          "success",
          "warning",
          "danger",
        ].map((role) => (
          <div key={role}>
            <span style={{ background: `var(--${role})` }} />
            <code>{role}</code>
          </div>
        ))}
      </div>
    </section>
  );
}
