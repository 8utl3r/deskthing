import React from 'react'
import { Box, Tabs } from '@mantine/core'
import { DeskThing } from '@deskthing/client'
import { PaletteProvider } from './PaletteContext'
import { ControlTab } from './tabs/ControlTab'
import { MacrosTab } from './tabs/MacrosTab'
import { FeedTab } from './tabs/FeedTab'
import { SettingsTab } from './tabs/SettingsTab'

const TABS = [
  { value: 'control', label: 'Audio' },
  { value: 'macros', label: 'Macros' },
  { value: 'feed', label: 'Feed' },
  { value: 'settings', label: 'Settings' },
]

const App: React.FC = () => {
  const [activeTab, setActiveTab] = React.useState('control')

  React.useEffect(() => {
    const unsub = DeskThing.on('tab', (data: { payload?: string }) => {
      const tab = data.payload
      if (tab && TABS.some((t) => t.value === tab)) setActiveTab(tab)
    })
    return () => (typeof unsub === 'function' ? unsub() : undefined)
  }, [])

  const handleTabChange = (value: string | null) => {
    if (value) {
      setActiveTab(value)
      DeskThing.send({ type: 'tab-changed', payload: value })
    }
  }

  return (
    <PaletteProvider>
    <Box
      style={{
        minHeight: '100vh',
        padding: '16px 36px 16px 16px',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'auto',
      }}
    >
      <Tabs
        value={activeTab}
        onChange={handleTabChange}
        variant="pills"
        style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}
      >
        <Tabs.List grow style={{ marginBottom: 12, flexShrink: 0, gap: 8 }}>
          {TABS.map((tab) => (
            <Tabs.Tab
              key={tab.value}
              value={tab.value}
              style={{
                fontSize: 22,
                fontWeight: 600,
                minHeight: 64,
                borderRadius: 8,
                border: '1px solid var(--mantine-color-dark-4)',
              }}
            >
              {tab.label}
            </Tabs.Tab>
          ))}
        </Tabs.List>

        <Tabs.Panel value="control" style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
          <ControlTab />
        </Tabs.Panel>
        <Tabs.Panel value="macros" style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
          <MacrosTab />
        </Tabs.Panel>
        <Tabs.Panel value="feed" style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
          <FeedTab />
        </Tabs.Panel>
        <Tabs.Panel value="settings" style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
          <SettingsTab />
        </Tabs.Panel>
      </Tabs>
    </Box>
    </PaletteProvider>
  )
}

export default App
