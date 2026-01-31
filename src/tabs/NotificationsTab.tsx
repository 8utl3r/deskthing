import React from 'react'
import { EmptyState, SectionHeader } from '@/design/components'

/**
 * Dynamic notifications: YouTube, GitHub, calendar, RSS, etc.
 * Fetched by Mac service; displayed here.
 */
export const NotificationsTab: React.FC = () => (
  <div className="space-y-dt-4">
    <SectionHeader
      title="Notifications"
      hint="YouTube uploads, GitHub, calendar — configure sources on Mac."
    />
    <EmptyState
      icon="📭"
      message="No notifications configured yet."
      hint="Add a fetcher service + config to enable."
    />
  </div>
)
