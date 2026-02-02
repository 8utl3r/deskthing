import React from 'react'
import { DeskThing } from '@deskthing/client'
import { Dropdown, SectionHeader, Switch, Tile } from '@/design/components'

const VOLUME_SEND_THROTTLE_MS = 50 // ~20 updates/sec during drag to avoid flooding the pipe

function sendVolume(value: number) {
  DeskThing.send({
    type: 'control',
    payload: { action: 'volume', value },
  })
}

interface AudioDevice {
  id: string
  name: string
}

/**
 * Computer control: mic mute, volume, audio source, miniDSP.
 * Sends commands to Mac bridge (Hammerspoon or HTTP server).
 */
export const ControlTab: React.FC = () => {
  const [micMuted, setMicMuted] = React.useState(false)
  const [volume, setVolume] = React.useState(50)
  const [devices, setDevices] = React.useState<AudioDevice[]>([])
  const [selectedDeviceId, setSelectedDeviceId] = React.useState<string | null>(null)

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
    const unsub = DeskThing.on('audio-devices', (data: { payload?: { devices?: unknown; defaultId?: string | null } }) => {
      const p = data.payload
      if (p && Array.isArray(p.devices)) {
        setDevices(p.devices as AudioDevice[])
        if (typeof p.defaultId === 'string') setSelectedDeviceId(p.defaultId)
      }
    })
    return () => (typeof unsub === 'function' ? unsub() : undefined)
  }, [])

  React.useEffect(() => {
    const unsub = DeskThing.on('mic-muted', (data: { payload?: unknown }) => {
      const m = data.payload
      if (typeof m === 'boolean') setMicMuted(m)
    })
    return () => (typeof unsub === 'function' ? unsub() : undefined)
  }, [])

  React.useEffect(() => {
    DeskThing.send({ type: 'get-volume' })
    DeskThing.send({ type: 'get-audio-devices' })
    DeskThing.send({ type: 'get-mic-muted' })
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
      <div className="grid grid-cols-2 gap-dt-3">
        <Tile className="flex-row justify-between items-center">
          <span className="text-dt-touch text-dt-text-primary">Mic mute</span>
          <Switch
            checked={micMuted}
            onCheckedChange={handleMicToggle}
            variant="danger"
          />
        </Tile>
        <Tile className="items-center">
          <div className="flex flex-col items-center gap-dt-2 w-full">
            <span className="text-dt-touch text-dt-text-primary font-medium">Volume</span>
            <div
              className="flex justify-center items-center min-h-[160px] shrink-0"
              style={{ width: 'var(--slider-thumb-width)' }}
            >
              <input
                type="range"
                min={0}
                max={100}
                value={volume}
                onChange={handleVolumeChange}
                onPointerUp={handleVolumePointerUp}
                onPointerCancel={handleVolumePointerUp}
                className="
                  bg-dt-subtle rounded-full
                  appearance-none cursor-pointer accent-dt-accent
                  [&::-webkit-slider-thumb]:appearance-none
                  [&::-webkit-slider-thumb]:w-6
                  [&::-webkit-slider-thumb]:h-slider-thumb
                  [&::-webkit-slider-thumb]:rounded-lg
                  [&::-webkit-slider-thumb]:bg-dt-accent
                  [&::-webkit-slider-thumb]:cursor-pointer
                  [&::-webkit-slider-thumb]:shadow-md
                  [&::-moz-range-thumb]:w-6
                  [&::-moz-range-thumb]:h-slider-thumb
                  [&::-moz-range-thumb]:rounded-lg
                  [&::-moz-range-thumb]:bg-dt-accent
                  [&::-moz-range-thumb]:cursor-pointer
                  [&::-moz-range-thumb]:border-0
                "
                style={{
                  transform: 'rotate(90deg)',
                  width: 160,
                  height: 'var(--slider-thumb-width)',
                  minWidth: 160,
                  minHeight: 'var(--slider-thumb-width)',
                } as React.CSSProperties}
              />
            </div>
            <span className="text-dt-touch text-dt-text-muted">{volume}%</span>
          </div>
        </Tile>
        <Tile fullWidth>
          <Dropdown
            label="Output device"
            options={devices.map((d) => ({ id: d.id, label: d.name }))}
            value={selectedDeviceId}
            onSelect={(id) => {
              setSelectedDeviceId(id)
              DeskThing.send({
                type: 'control',
                payload: { action: 'output-device', value: id },
              })
            }}
            placeholder="No devices"
            disabled={devices.length === 0}
          />
        </Tile>
        <Tile fullWidth className="border border-dashed border-dt-subtle bg-dt-elevated/50">
          <p className="text-dt-touch text-dt-text-muted">miniDSP presets — coming soon</p>
        </Tile>
      </div>
    </div>
  )
}
