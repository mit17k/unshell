import { useId, type InputHTMLAttributes } from "react";
import { cx } from "./cx.js";

export interface FieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  hint?: string;
  error?: string;
}

export function Field({ label, hint, error, className, ...rest }: FieldProps) {
  const id = useId();
  const describedBy = error || hint ? `${id}-desc` : undefined;
  return (
    <div className={cx("u-field", error && "u-field--error", className)}>
      <label className="u-eyebrow" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        className="u-input"
        aria-invalid={error ? true : undefined}
        aria-describedby={describedBy}
        {...rest}
      />
      {(error || hint) && (
        <span id={describedBy} className="u-field-desc">
          {error ?? hint}
        </span>
      )}
    </div>
  );
}
