import React from 'react'
import { Text, UnstyledButton, Box } from '@mantine/core'
import { Grid, Tile } from '@/design'
import { usePalette } from '@/PaletteContext'
import { PALETTES } from '@/palettes'

export const SettingsTab: React.FC = () => {
  const { palette, setPaletteId } = usePalette()

  return (
    <Grid>
      <Tile span={12}>
        <Text size="lg" fw={500} mb="md">Color palette</Text>
        <Text size="sm" c="dimmed" mb="md">
          Choose a tile color from professional design systems.
        </Text>
        <Box style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
          {PALETTES.map((p) => (
            <UnstyledButton
              key={p.id}
              onClick={() => setPaletteId(p.id)}
              style={{
                padding: 12,
                borderRadius: 8,
                backgroundColor: p.tileBg,
                border: '2px solid',
                borderColor: palette.id === p.id ? 'var(--mantine-color-blue-5)' : p.tileBorder ?? 'transparent',
                minWidth: 80,
                textAlign: 'center',
              }}
            >
              <Text size="sm" fw={500} c={palette.id === p.id ? 'blue.3' : 'white'}>
                {p.name}
              </Text>
              {p.source && (
                <Text size="xs" c="dimmed" mt={4}>
                  {p.source}
                </Text>
              )}
            </UnstyledButton>
          ))}
        </Box>
      </Tile>
    </Grid>
  )
}
