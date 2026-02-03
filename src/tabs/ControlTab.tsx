import React from 'react'
import { Box, Slider, Switch, Select, Text } from '@mantine/core'
import { Grid, Tile } from '@/design'
import { DeskThing } from '@deskthing/client'

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

  const handleMicToggle = (event: React.ChangeEvent<HTMLInputElement>) => {
    const checked = event.currentTarget.checked
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

  return (
    <Grid>
      <Tile span={6} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Text size="lg" fw={500}>Mic mute</Text>
        <Switch
          size="lg"
          checked={micMuted}
          onChange={handleMicToggle}
          color="red"
          styles={{
            track: { minWidth: 72, minHeight: 64 },
            thumb: { minWidth: 52, minHeight: 64 },
          }}
        />
      </Tile>

      <Tile span={6} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
        <Text size="lg" fw={500}>Volume</Text>
        <Box style={{ height: 160, width: 32, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          <Slider
            value={volume}
            onChange={handleVolumeChange}
            onChangeEnd={(val) => flushVolume(val)}
            min={0}
            max={100}
            orientation="vertical"
            size="lg"
            styles={{
              root: { height: 160 },
              track: { width: 24 },
              thumb: { width: 32, height: 32 },
            }}
          />
        </Box>
        <Text size="sm" c="dimmed">{volume}%</Text>
      </Tile>

      <Tile span={12}>
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

      <Tile span={12} placeholder>
        <Text size="lg" c="dimmed">miniDSP presets — coming soon</Text>
      </Tile>
    </Grid>
  )
}
