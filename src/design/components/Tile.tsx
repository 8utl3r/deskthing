import React from 'react'

interface TileProps {
  children: React.ReactNode
  /** Span full width (2 cols in 2-col grid) */
  fullWidth?: boolean
  className?: string
}

/** Touch-friendly tile for grid layouts. Min touch height. */
export const Tile: React.FC<TileProps> = ({
  children,
  fullWidth = false,
  className = '',
}) => (
  <div
    className={`
      min-h-touch p-dt-4 bg-dt-elevated rounded-lg
      flex flex-col justify-center
      ${fullWidth ? 'col-span-2' : ''}
      ${className}
    `.trim()}
  >
    {children}
  </div>
)
