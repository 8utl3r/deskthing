import React from 'react'
import { Box, ScrollArea, Stack, Text } from '@mantine/core'
import { Grid, Tile } from '@/design'
import { DeskThing } from '@deskthing/client'

const SCROLL_AMOUNT = 120

interface FeedItem {
  id: string
  title: string
  summary?: string
  url?: string
  source?: string
  timestamp?: string
}

export const FeedTab: React.FC = () => {
  const [items, setItems] = React.useState<FeedItem[]>([])
  const [loading, setLoading] = React.useState(true)
  const scrollRef = React.useRef<HTMLDivElement>(null)

  React.useEffect(() => {
    const unsub = DeskThing.on('feed', (data: { payload?: unknown }) => {
      const list = data.payload
      if (Array.isArray(list)) setItems(list as FeedItem[])
      setLoading(false)
    })
    return () => (typeof unsub === 'function' ? unsub() : undefined)
  }, [])

  React.useEffect(() => {
    const unsub = DeskThing.on('scroll', (data: { payload?: string }) => {
      const dir = data.payload
      const el = scrollRef.current
      if (!el || (dir !== 'up' && dir !== 'down')) return
      const delta = dir === 'up' ? -SCROLL_AMOUNT : SCROLL_AMOUNT
      el.scrollBy({ top: delta, behavior: 'smooth' })
    })
    return () => (typeof unsub === 'function' ? unsub() : undefined)
  }, [])

  React.useEffect(() => {
    setLoading(true)
    DeskThing.send({ type: 'get-feed' })
  }, [])

  if (loading) {
    return (
      <Box style={{ flex: 1, minHeight: 0 }}>
      <Grid>
        <Tile span={12}>
          <Text size="lg" c="dimmed" ta="center">Loading…</Text>
        </Tile>
      </Grid>
      </Box>
    )
  }

  if (items.length === 0) {
    return (
      <Box style={{ flex: 1, minHeight: 0 }}>
      <Grid>
        <Tile span={12} placeholder>
          <Stack align="center" gap="md">
            <Text size="2rem" aria-hidden>📰</Text>
            <Text size="xl" c="dimmed" ta="center">No feed items.</Text>
            <Text size="md" c="dimmed" ta="center">
              Copy feed.example.json to feed.json and add RSS URLs.
            </Text>
          </Stack>
        </Tile>
      </Grid>
      </Box>
    )
  }

  return (
    <Box style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
    <ScrollArea
      viewportRef={scrollRef}
      style={{ flex: 1, minHeight: 0 }}
      scrollbarSize="md"
    >
      <Grid style={{ marginTop: 12 }}>
        {items.map((item) => (
          <Tile key={item.id} span={12}>
            <a
              href={item.url}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: 'block',
                textDecoration: 'none',
                color: 'inherit',
                outline: 'none',
                margin: -16,
                padding: 16,
              }}
            >
              <Text size="xl" fw={500} lineClamp={2}>
                {item.title}
              </Text>
              {item.summary && (
                <Text size="md" c="dimmed" mt={4} lineClamp={2}>
                  {item.summary}
                </Text>
              )}
              {item.source && (
                <Text size="md" c="dimmed" mt={4}>
                  {item.source}
                </Text>
              )}
            </a>
          </Tile>
        ))}
      </Grid>
    </ScrollArea>
    </Box>
  )
}
