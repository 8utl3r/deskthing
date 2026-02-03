import React from 'react'
import { Text, UnstyledButton } from '@mantine/core'
import { Grid, Tile } from '@/design'
import { DeskThing } from '@deskthing/client'

const MACROS = [
  { id: 'test', label: 'Test', icon: '✓' },
  { id: 'mute-teams', label: 'Mute Teams', icon: '🎤' },
  { id: 'focus-mode', label: 'Focus mode', icon: '🎯' },
  { id: 'add-inbox', label: 'Add to inbox', icon: '📥' },
]

export const MacrosTab: React.FC = () => {
  const runMacro = (id: string) => {
    DeskThing.send({ type: 'macro', payload: { id } })
  }

  return (
    <Grid>
      {MACROS.map((m) => (
        <Tile key={m.id} span={6}>
          <UnstyledButton
            style={{
              width: '100%',
              minHeight: 48,
              display: 'flex',
              alignItems: 'center',
              gap: 12,
              justifyContent: 'flex-start',
            }}
            onClick={() => runMacro(m.id)}
          >
            <Text size="xl" aria-hidden>{m.icon}</Text>
            <Text size="lg" fw={500}>{m.label}</Text>
          </UnstyledButton>
        </Tile>
      ))}
    </Grid>
  )
}
