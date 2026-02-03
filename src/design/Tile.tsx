import React from 'react'
import { Paper } from '@mantine/core'

const TILE_MIN_HEIGHT = 64
const TILE_PADDING = 16

interface TileProps {
  children: React.ReactNode
  /** Span full width in 2-col grid */
  fullWidth?: boolean
  /** Dashed border for placeholder state */
  placeholder?: boolean
  style?: React.CSSProperties
}

/** Touch-friendly tile for grid layouts. Min 64px height per Design Bible. */
export const Tile: React.FC<TileProps> = ({
  children,
  fullWidth = false,
  placeholder = false,
  style = {},
}) => (
  <Paper
    p="md"
    radius="md"
    withBorder
    style={{
      minHeight: TILE_MIN_HEIGHT,
      gridColumn: fullWidth ? '1 / -1' : undefined,
      borderStyle: placeholder ? 'dashed' : undefined,
      opacity: placeholder ? 0.7 : 1,
      ...style,
    }}
  >
    {children}
  </Paper>
)
