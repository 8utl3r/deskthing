import React from 'react'
import { Paper } from '@mantine/core'
import { usePalette } from '@/PaletteContext'

const TILE_MIN_HEIGHT = 64

interface TileProps {
  children: React.ReactNode
  /** Span 1–12 columns in the 12-col grid. 6 = half, 4 = third, 12 = full. */
  span?: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12
  /** Row span in control grid (e.g. 5 for volume, 2 for mic) */
  rowSpan?: number
  /** Dashed border for placeholder state */
  placeholder?: boolean
  /** Override background (e.g. red/green for mic mute) */
  backgroundColor?: string
  style?: React.CSSProperties
}

/** Floating tile for controls. Use inside Grid; span controls width (12-col grid). */
export const Tile: React.FC<TileProps> = ({
  children,
  span = 6,
  rowSpan,
  placeholder = false,
  backgroundColor,
  style = {},
}) => {
  const { palette } = usePalette()
  const bg = backgroundColor ?? palette.tileBg
  return (
    <Paper
      p="md"
      radius="md"
      shadow="md"
      withBorder
      style={{
        minHeight: TILE_MIN_HEIGHT,
        gridColumn: `span ${span}`,
        gridRow: rowSpan ? `span ${rowSpan}` : undefined,
        backgroundColor: bg,
        borderColor: palette.tileBorder,
        borderStyle: placeholder ? 'dashed' : undefined,
        opacity: placeholder ? 0.7 : 1,
        ...style,
      }}
    >
      {children}
    </Paper>
  )
}
