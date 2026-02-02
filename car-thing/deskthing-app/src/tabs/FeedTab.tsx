import React from 'react'
import { DeskThing } from '@deskthing/client'
import { Card, EmptyState, SectionHeader } from '@/design/components'

const SCROLL_AMOUNT = 120

interface FeedItem {
  id: string
  title: string
  summary?: string
  url?: string
  source?: string
  timestamp?: string
}

/**
 * Feed: RSS and other sources aggregated by the Mac bridge.
 * Configure URLs in car-thing/config/feed.json (copy from feed.example.json).
 * Wheel scrolls when on this tab.
 */
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
    <div className="flex flex-col flex-1 min-h-0">
      <SectionHeader
        title="Feed"
        hint="RSS and other sources — configure URLs in feed.json on Mac."
      />
      {loading ? (
        <div className="py-dt-6 text-center text-dt-feed text-dt-text-muted">Loading…</div>
      ) : items.length === 0 ? (
        <EmptyState
          icon="📰"
          message="No feed items."
          hint="Copy feed.example.json to feed.json and add RSS URLs."
        />
      ) : (
        <div
          ref={scrollRef}
          className="flex flex-col gap-dt-3 flex-1 min-h-0 overflow-y-auto overflow-x-hidden mt-dt-2"
        >
          {items.map((item) => (
            <Card key={item.id}>
              <a
                href={item.url}
                target="_blank"
                rel="noopener noreferrer"
                className="block focus:outline-none focus-visible:ring-2 focus-visible:ring-dt-accent rounded-lg -m-dt-4 p-dt-4"
              >
                <p className="text-dt-feed font-medium text-dt-text-primary line-clamp-2">
                  {item.title}
                </p>
                {item.summary && (
                  <p className="text-dt-body text-dt-text-muted mt-dt-1 line-clamp-2">
                    {item.summary}
                  </p>
                )}
                {item.source && (
                  <p className="text-dt-touch text-dt-text-muted mt-dt-1">{item.source}</p>
                )}
              </a>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
