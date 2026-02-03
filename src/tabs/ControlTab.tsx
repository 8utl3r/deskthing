import React from 'react'
import { UnstyledButton, Select, Text } from '@mantine/core'
import { Grid, Tile } from '@/design'
import { VolumeTile } from '@/components/VolumeTile'
import { DeskThing } from '@deskthing/client'

const MIC_MUTED_COLOR = 'var(--mantine-color-red-6)'
const MIC_UNMUTED_COLOR = 'var(--mantine-color-green-6)'

const VOLUME_SEND_THROTTLE_MS = 50

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

  const handleMicToggle = () => {
    const next = !micMuted
    setMicMuted(next)
    DeskThing.send({
      type: 'control',
      payload: { action: 'mic-mute', value: next },
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

  const handleVolumeChange = (val: number) => {
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
    <Grid variant="control" style={{ minHeight: 240 }}>
      <VolumeTile
        value={volume}
        min={0}
        max={100}
        onChange={handleVolumeChange}
        onPointerUp={handleVolumePointerUp}
      />

      <UnstyledButton
        onClick={handleMicToggle}
        style={{
          gridColumn: '3 / 5',
          gridRow: '1 / 3',
          padding: 0,
          background: 'none',
          border: 'none',
        }}
      >
        <Tile
          span={2}
          backgroundColor={micMuted ? MIC_MUTED_COLOR : MIC_UNMUTED_COLOR}
          style={{
            width: '100%',
            height: '100%',
            minHeight: 64,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Text size="lg" fw={600} c="white">
            Mic {micMuted ? 'Muted' : 'On'}
          </Text>
        </Tile>
      </UnstyledButton>

      <Tile span={2} rowSpan={2} style={{ gridColumn: '1 / 3', gridRow: '3 / 5' }}>
        <Select
          label="Output device"
          placeholder="No devices"
          data={devices.map((d) => ({ value: d.id, label: d.name }))}
          value={selectedDeviceId}
          onChange={(id) => {
            if (id) {
              setSelectedDeviceId(id)
              DeskThing.send({
                type: 'control',
                payload: { action: 'output-device', value: id },
              })
            }
          }}
          disabled={devices.length === 0}
          size="lg"
          styles={{
            input: { minHeight: 64, fontSize: 20 },
          }}
        />
      </Tile>

      <Tile span={2} rowSpan={2} placeholder style={{ gridColumn: '3 / 5', gridRow: '3 / 5' }}>
        <Text size="lg" c="dimmed">miniDSP presets — coming soon</Text>
      </Tile>
    </Grid>
  )
}
