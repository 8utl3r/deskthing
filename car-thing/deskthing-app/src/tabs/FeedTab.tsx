import React from 'react'
import { Box, Card, ScrollArea, Stack, Text } from '@mantine/core'
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

  return (
    <Box style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0 }}>
      <Text size="xl" fw={600} c="dimmed">Feed</Text>
      <Text size="md" c="dimmed" mt={4}>
        RSS and other sources — configure URLs in feed.json on Mac.
      </Text>
      {loading ? (
        <Text py="xl" ta="center" c="dimmed" size="lg">Loading…</Text>
      ) : items.length === 0 ? (
        <Card p="xl" radius="md" withBorder style={{ borderStyle: 'dashed', marginTop: 8 }}>
          <Stack align="center" gap="md">
            <Text size="2rem" aria-hidden>📰</Text>
            <Text size="xl" c="dimmed" ta="center">No feed items.</Text>
            <Text size="md" c="dimmed" ta="center">
              Copy feed.example.json to feed.json and add RSS URLs.
            </Text>
          </Stack>
        </Card>
      ) : (
        <ScrollArea
          viewportRef={scrollRef}
          style={{ flex: 1, minHeight: 0, marginTop: 8 }}
          scrollbarSize="md"
        >
          <Stack gap="md">
            {items.map((item) => (
              <Card key={item.id} p="md" radius="md" withBorder>
                <a
                  href={item.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{
                    display: 'block',
                    textDecoration: 'none',
                    color: 'inherit',
                    outline: 'none',
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
              </Card>
            ))}
          </Stack>
        </ScrollArea>
      )}
    </Box>
  )
}
