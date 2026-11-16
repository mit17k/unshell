export function Switch({
  checked,
  onChange,
  label,
  disabled,
}: {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label: string;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      disabled={disabled}
      className="u-switch"
      onClick={() => onChange(!checked)}
    >
      <span className="u-switch-track" aria-hidden>
        <span className="u-switch-thumb" />
      </span>
      <span>{label}</span>
    </button>
  );
}
