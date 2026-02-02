import React from 'react'

interface ControlRowProps {
  label: string
  children: React.ReactNode
  className?: string
}

/** Row with label left, control right. Min 44px height for touch. */
export const ControlRow: React.FC<ControlRowProps> = ({
  label,
  children,
  className = '',
}) => (
  <div
    className={`
      flex items-center justify-between min-h-touch p-dt-4
      bg-dt-elevated rounded-lg
      ${className}
    `.trim()}
  >
    <span className="text-dt-touch text-dt-text-primary">{label}</span>
    <div className="shrink-0">{children}</div>
  </div>
)
