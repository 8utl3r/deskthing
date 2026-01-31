import React from 'react'

interface CardProps {
  children: React.ReactNode
  className?: string
  /** Dashed border for placeholder/coming-soon state */
  placeholder?: boolean
}

export const Card: React.FC<CardProps> = ({
  children,
  className = '',
  placeholder = false,
}) => (
  <div
    className={`
      p-dt-4 rounded-lg
      ${placeholder
        ? 'bg-dt-elevated/50 border border-dashed border-dt-subtle'
        : 'bg-dt-elevated'}
      ${className}
    `.trim()}
  >
    {children}
  </div>
)
