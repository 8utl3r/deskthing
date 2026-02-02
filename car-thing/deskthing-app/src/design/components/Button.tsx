import React from 'react'

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger'
type ButtonSize = 'md' | 'lg'

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
  size?: ButtonSize
  icon?: React.ReactNode
  children: React.ReactNode
}

const variantClasses: Record<ButtonVariant, string> = {
  primary: 'bg-dt-accent text-white hover:bg-blue-600 active:bg-blue-700',
  secondary: 'bg-dt-elevated border border-dt-subtle text-dt-text-primary hover:bg-dt-subtle active:bg-slate-600',
  ghost: 'bg-transparent text-dt-text-secondary hover:bg-dt-elevated active:bg-dt-subtle',
  danger: 'bg-dt-danger text-white hover:bg-red-600 active:bg-red-700',
}

const sizeClasses: Record<ButtonSize, string> = {
  md: 'min-h-touch px-dt-4 py-dt-3 text-dt-touch',
  lg: 'min-h-touch px-dt-5 py-dt-4 text-dt-touch',
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'secondary',
  size = 'md',
  icon,
  children,
  className = '',
  disabled,
  ...props
}) => (
  <button
    type="button"
    disabled={disabled}
    className={`
      inline-flex items-center justify-center gap-dt-2 rounded-lg font-medium
      transition-colors touch-manipulation
      disabled:opacity-50 disabled:cursor-not-allowed
      ${variantClasses[variant]} ${sizeClasses[size]}
      ${className}
    `.trim()}
    {...props}
  >
    {icon && <span className="shrink-0">{icon}</span>}
    {children}
  </button>
)
