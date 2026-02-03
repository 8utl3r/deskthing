import React from 'react'
import { Box } from '@mantine/core'

interface GridProps {
  children: React.ReactNode
  /** Gap between tiles (default 12) */
  gap?: number
  /** Use 2-col layout: 5fr + 2fr rows (volume, mic). For ControlTab. */
  variant?: 'default' | 'control'
  style?: React.CSSProperties
}

/**
 * Grid for tiles. Default: 12-column. Control variant: 2 cols, 5fr+2fr rows.
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
        gridTemplateColumns: isControl ? '1fr 1fr' : 'repeat(12, 1fr)',
        gridTemplateRows: isControl ? '5fr 2fr auto auto' : undefined,
        gap,
        ...style,
      }}
    >
      {children}
    </Box>
  )
}
