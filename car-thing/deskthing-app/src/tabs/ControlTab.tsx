import React from 'react'
import { DeskThing } from '@deskthing/client'
import { Card, ControlRow, SectionHeader, Switch } from '@/design/components'

const VOLUME_SEND_THROTTLE_MS = 50 // ~20 updates/sec during drag to avoid flooding the pipe

function sendVolume(value: number) {
  DeskThing.send({
    type: 'control',
    payload: { action: 'volume', value },
  })
}

/**
 * Computer control: mic mute, volume, audio source, miniDSP.
 * Sends commands to Mac bridge (Hammerspoon or HTTP server).
 */
export const ControlTab: React.FC = () => {
  const [micMuted, setMicMuted] = React.useState(false)
  const [volume, setVolume] = React.useState(50)

  const volumeLastSent = React.useRef<number>(50)
  const volumeThrottleTimer = React.useRef<ReturnType<typeof setTimeout> | null>(null)
  const volumePending = React.useRef<number | null>(null)

  React.useEffect(() => {
    const unsub = DeskThing.on('volume', (data: { payload?: unknown }) => {
      const v = data.payload
      if (typeof v === 'number' && v >= 0 && v <= 100) {
        setVolume(v)
        volumeLastSent.current = v
        volumePending.current = v
      }
    })
    return () => (typeof unsub === 'function' ? unsub() : undefined)
  }, [])

  React.useEffect(() => {
    DeskThing.send({ type: 'get-volume' })
  }, [])

  const handleMicToggle = (checked: boolean) => {
    setMicMuted(checked)
    DeskThing.send({
      type: 'control',
      payload: { action: 'mic-mute', value: checked },
    })
  }

  const flushVolume = React.useCallback((val: number) => {
    if (volumeThrottleTimer.current) {
      clearTimeout(volumeThrottleTimer.current)
      volumeThrottleTimer.current = null
    }
    volumePending.current = null
    if (volumeLastSent.current !== val) {
      volumeLastSent.current = val
      sendVolume(val)
    }
  }, [])

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = parseInt(e.target.value, 10)
    setVolume(val)
    volumePending.current = val

    if (volumeLastSent.current === val) return

    if (volumeThrottleTimer.current === null) {
      sendVolume(val)
      volumeLastSent.current = val
      volumeThrottleTimer.current = setTimeout(() => {
        volumeThrottleTimer.current = null
        const pending = volumePending.current
        if (pending !== null && pending !== volumeLastSent.current) {
          volumeLastSent.current = pending
          sendVolume(pending)
        }
      }, VOLUME_SEND_THROTTLE_MS)
    }
  }

  const handleVolumePointerUp = () => {
    flushVolume(volumePending.current ?? volume)
  }

  return (
    <div className="space-y-dt-4">
      <SectionHeader title="Audio" />
      <ControlRow label="Mic mute">
        <Switch
          checked={micMuted}
          onCheckedChange={handleMicToggle}
          variant="danger"
        />
      </ControlRow>
      <div className="flex items-center justify-between min-h-touch p-dt-3 bg-dt-elevated rounded-lg gap-dt-4">
        <span className="text-sm text-dt-text-primary shrink-0">Volume</span>
        <input
          type="range"
          min={0}
          max={100}
          value={volume}
          onChange={handleVolumeChange}
          onPointerUp={handleVolumePointerUp}
          onPointerCancel={handleVolumePointerUp}
          className="flex-1 h-2 bg-dt-subtle rounded-full appearance-none cursor-pointer accent-dt-accent [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-5 [&::-webkit-slider-thumb]:h-5 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-dt-accent [&::-webkit-slider-thumb]:cursor-pointer"
        />
        <span className="text-sm text-dt-text-muted w-8 shrink-0">{volume}%</span>
      </div>
      <Card placeholder>
        <p className="text-xs text-dt-text-muted">Audio source — coming soon</p>
      </Card>
      <Card placeholder>
        <p className="text-xs text-dt-text-muted">miniDSP presets — coming soon</p>
      </Card>
    </div>
  )
}
