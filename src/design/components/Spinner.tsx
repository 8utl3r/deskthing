import React from 'react'

interface SpinnerProps {
  size?: 'sm' | 'md'
  className?: string
}

export const Spinner: React.FC<SpinnerProps> = ({
  size = 'md',
  className = '',
}) => {
  const sizeClass = size === 'sm' ? 'w-4 h-4' : 'w-6 h-6'
  return (
    <div
      className={`animate-spin rounded-full border-2 border-dt-subtle border-t-dt-accent ${sizeClass} ${className}`}
      role="status"
      aria-label="Loading"
    />
  )
}
