import React from 'react'

interface EmptyStateProps {
  icon?: string
  message: string
  hint?: string
  className?: string
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  icon = '📭',
  message,
  hint,
  className = '',
}) => (
  <div
    className={`
      flex flex-col items-center justify-center p-dt-6
      bg-dt-elevated rounded-lg border border-dashed border-dt-subtle
      text-center
      ${className}
    `.trim()}
  >
    <span className="text-2xl mb-dt-2" aria-hidden>
      {icon}
    </span>
    <p className="text-sm text-dt-text-secondary">{message}</p>
    {hint && <p className="text-xs text-dt-text-muted mt-dt-2">{hint}</p>}
  </div>
)
