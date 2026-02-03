import React from 'react'
import { Paper, Text } from '@mantine/core'
import { usePalette } from '@/PaletteContext'

interface VolumeTileProps {
  value: number
  min?: number
  max?: number
  onChange: (value: number) => void
  onPointerUp?: () => void
}

/** Entire tile is the volume slider. 2x2 cell. */
export const VolumeTile: React.FC<VolumeTileProps> = ({
  value,
  min = 0,
  max = 100,
  onChange,
  onPointerUp,
}) => {
  const trackRef = React.useRef<HTMLDivElement>(null)
  const [isDragging, setIsDragging] = React.useState(false)
  const { palette } = usePalette()

  const percentToValue = (p: number) =>
    min + (p / 100) * (max - min)

  const valueToPercent = (v: number) =>
    Math.max(0, Math.min(100, ((v - min) / (max - min)) * 100))

  const getValueFromY = React.useCallback((clientY: number): number => {
    const el = trackRef.current
    if (!el) return value
    const rect = el.getBoundingClientRect()
    const y = clientY - rect.top
    const percent = 100 - (y / rect.height) * 100
    return Math.round(percentToValue(Math.max(0, Math.min(100, percent))))
  }, [min, max])

  const handlePointerDown = (e: React.PointerEvent) => {
    e.preventDefault()
    setIsDragging(true)
    onChange(getValueFromY(e.clientY))
    ;(e.target as HTMLElement).setPointerCapture?.(e.pointerId)
  }

  React.useEffect(() => {
    if (!isDragging) return
    const handleMove = (e: PointerEvent) => onChange(getValueFromY(e.clientY))
    const handleUp = () => {
      setIsDragging(false)
      onPointerUp?.()
    }
    window.addEventListener('pointermove', handleMove)
    window.addEventListener('pointerup', handleUp)
    window.addEventListener('pointercancel', handleUp)
    return () => {
      window.removeEventListener('pointermove', handleMove)
      window.removeEventListener('pointerup', handleUp)
      window.removeEventListener('pointercancel', handleUp)
    }
  }, [isDragging, onChange, onPointerUp, getValueFromY])

  const percent = valueToPercent(value)

  return (
    <Paper
      ref={trackRef}
      role="slider"
      aria-valuemin={min}
      aria-valuemax={max}
      aria-valuenow={value}
      tabIndex={0}
      p="md"
      radius="md"
      shadow="md"
      withBorder
      onPointerDown={handlePointerDown}
      onKeyDown={(e) => {
        const step = (max - min) / 20
        if (e.key === 'ArrowUp' || e.key === 'PageUp') {
          e.preventDefault()
          onChange(Math.min(max, value + (e.key === 'PageUp' ? step * 4 : step)))
        } else if (e.key === 'ArrowDown' || e.key === 'PageDown') {
          e.preventDefault()
          onChange(Math.max(min, value - (e.key === 'PageDown' ? step * 4 : step)))
        }
      }}
      style={{
        gridColumn: '1 / 3',
        gridRow: '1 / 3',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        backgroundColor: palette.tileBg,
        borderColor: palette.tileBorder,
        cursor: 'pointer',
        touchAction: 'none',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Volume fill from bottom */}
      <div
        style={{
          position: 'absolute',
          bottom: 0,
          left: 0,
          right: 0,
          height: `${percent}%`,
          background: 'var(--mantine-color-blue-5)',
          opacity: 0.4,
          pointerEvents: 'none',
        }}
      />
      <Text size="lg" fw={600} style={{ position: 'relative', zIndex: 1 }}>
        Volume
      </Text>
      <Text size="xl" fw={700} style={{ position: 'relative', zIndex: 1 }}>
        {value}%
      </Text>
    </Paper>
  )
}
