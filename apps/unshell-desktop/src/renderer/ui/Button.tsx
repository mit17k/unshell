import type { ButtonHTMLAttributes } from "react";
import { cx } from "./cx.js";

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "danger";
  size?: "sm" | "md" | "lg";
}

export function Button({
  variant = "secondary",
  size = "md",
  type = "button",
  className,
  ...rest
}: ButtonProps) {
  return (
    <button
      type={type}
      className={cx(
        "u-button",
        `u-button--${variant}`,
        `u-button--${size}`,
        className,
      )}
      {...rest}
    />
  );
}
