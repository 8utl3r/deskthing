import React from 'react'
import { Box } from '@mantine/core'

interface GridProps {
  children: React.ReactNode
  /** Gap between tiles (default 12) */
  gap?: number
  /** 4x4 grid, each tile 2x2. For ControlTab. */
  variant?: 'default' | 'control'
  style?: React.CSSProperties
}

/**
 * Grid for tiles. Default: 12-column. Control variant: 4x4, each cell 2x2.
 */
export const Grid: React.FC<GridProps> = ({
  children,
  gap = 12,
  variant = 'default',
  style = {},
}) => {
  const isControl = variant === 'control'
  return (
    <Box
      style={{
        display: 'grid',
        gridTemplateColumns: isControl ? 'repeat(4, 1fr)' : 'repeat(12, 1fr)',
        gridTemplateRows: isControl ? 'repeat(4, 1fr)' : undefined,
        gap,
        ...style,
      }}
    >
      {children}
    </Box>
  )
}
