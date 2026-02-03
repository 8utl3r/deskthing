import React from 'react'

const THUMB_SIZE = 28
const TRACK_WIDTH = 48

interface VerticalSliderProps {
  value: number
  min?: number
  max?: number
  onChange: (value: number) => void
  onPointerUp?: () => void
  disabled?: boolean
  /** Fill container height; defaults to 160px if not in a flex context */
  style?: React.CSSProperties
}

export const VerticalSlider: React.FC<VerticalSliderProps> = ({
  value,
  min = 0,
  max = 100,
  onChange,
  onPointerUp,
  disabled = false,
  style = {},
}) => {
  const trackRef = React.useRef<HTMLDivElement>(null)
  const [isDragging, setIsDragging] = React.useState(false)

  const valueToPercent = (v: number) =>
    Math.max(0, Math.min(100, ((v - min) / (max - min)) * 100))

  const percentToValue = (p: number) =>
    min + (p / 100) * (max - min)

  const getValueFromY = React.useCallback((clientY: number): number => {
    const el = trackRef.current
    if (!el) return value
    const rect = el.getBoundingClientRect()
    const y = clientY - rect.top
    const percent = 100 - (y / rect.height) * 100
    return Math.round(percentToValue(Math.max(0, Math.min(100, percent))))
  }, [min, max])

  const handlePointerDown = (e: React.PointerEvent) => {
    if (disabled) return
    e.preventDefault()
    setIsDragging(true)
    onChange(getValueFromY(e.clientY))
    ;(e.target as HTMLElement).setPointerCapture?.(e.pointerId)
  }

  React.useEffect(() => {
    if (!isDragging) return
    const handleMove = (e: PointerEvent) => {
      onChange(getValueFromY(e.clientY))
    }
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
    <div
      ref={trackRef}
      role="slider"
      aria-valuemin={min}
      aria-valuemax={max}
      aria-valuenow={value}
      aria-disabled={disabled}
      tabIndex={disabled ? -1 : 0}
      onPointerDown={handlePointerDown}
      onKeyDown={(e) => {
        if (disabled) return
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
        width: TRACK_WIDTH,
        flex: 1,
        minHeight: 120,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        cursor: disabled ? 'not-allowed' : 'pointer',
        touchAction: 'none',
        ...style,
      }}
    >
      <div
        style={{
          width: TRACK_WIDTH,
          height: '100%',
          minHeight: 120,
          borderRadius: 4,
          background: 'var(--mantine-color-dark-4)',
          position: 'relative',
          flexShrink: 0,
        }}
      >
        <div
          style={{
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0,
            height: `${percent}%`,
            borderRadius: '0 0 4px 4px',
            background: 'var(--mantine-color-blue-5)',
          }}
        />
        <div
          style={{
            position: 'absolute',
            left: '50%',
            bottom: `calc(${percent}% - ${THUMB_SIZE / 2}px)`,
            transform: 'translateX(-50%)',
            width: THUMB_SIZE,
            height: THUMB_SIZE,
            borderRadius: 8,
            background: 'var(--mantine-color-blue-5)',
            boxShadow: '0 1px 3px rgba(0,0,0,0.3)',
            pointerEvents: 'none',
          }}
        />
      </div>
    </div>
  )
}
