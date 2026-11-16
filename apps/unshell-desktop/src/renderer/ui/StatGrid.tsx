export interface Stat {
  value: string;
  label: string;
}

export function StatGrid({ stats }: { stats: Stat[] }) {
  return (
    <div className="u-stat-grid">
      {stats.map((stat) => (
        <div key={stat.label} className="u-stat">
          <span className="u-stat-value">{stat.value}</span>
          <span className="u-eyebrow">{stat.label}</span>
        </div>
      ))}
    </div>
  );
}
