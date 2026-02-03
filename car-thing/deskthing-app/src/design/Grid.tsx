import React from 'react'
import { Box } from '@mantine/core'

interface GridProps {
  children: React.ReactNode
  /** Gap between tiles (default 12) */
  gap?: number
  style?: React.CSSProperties
}

/**
 * 12-column invisible grid. Tiles use span (1–12) to occupy columns.
 * Add rows as needed; grid flows automatically.
 */
export const Grid: React.FC<GridProps> = ({
  children,
  gap = 12,
  style = {},
}) => (
  <Box
    style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(12, 1fr)',
      gap,
      ...style,
    }}
  >
    {children}
  </Box>
)
