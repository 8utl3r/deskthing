import React from 'react'
import { Paper } from '@mantine/core'
import { usePalette } from '@/PaletteContext'

const TILE_MIN_HEIGHT = 64

interface TileProps {
  children: React.ReactNode
  /** Span 1–12 columns in the 12-col grid. 6 = half, 4 = third, 12 = full. */
  span?: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12
  /** Dashed border for placeholder state */
  placeholder?: boolean
  style?: React.CSSProperties
}

/** Floating tile for controls. Use inside Grid; span controls width (12-col grid). */
export const Tile: React.FC<TileProps> = ({
  children,
  span = 6,
  placeholder = false,
  style = {},
}) => {
  const { palette } = usePalette()
  return (
    <Paper
      p="md"
      radius="md"
      shadow="md"
      withBorder
      style={{
        minHeight: TILE_MIN_HEIGHT,
        gridColumn: `span ${span}`,
        backgroundColor: palette.tileBg,
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
