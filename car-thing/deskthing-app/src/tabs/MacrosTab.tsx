import React from 'react'
import { Box, Button, SimpleGrid, Text } from '@mantine/core'
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
    <Box style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <Text size="xl" fw={600} c="dimmed">Macros</Text>
      <Text size="md" c="dimmed" mt={4}>
        Run AppleScript or Shortcuts. Edit config to add more.
      </Text>
      <SimpleGrid cols={2} spacing="md">
        {MACROS.map((m) => (
          <Button
            key={m.id}
            variant="light"
            size="xl"
            onClick={() => runMacro(m.id)}
            style={{
              minHeight: 64,
              justifyContent: 'flex-start',
              fontSize: 20,
            }}
            leftSection={<span>{m.icon}</span>}
          >
            {m.label}
          </Button>
        ))}
      </SimpleGrid>
    </Box>
  )
}
