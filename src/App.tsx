import React from 'react'
import { DeskThing } from '@deskthing/client'
import { TabBar, TabContent } from '@/design/components'
import { ControlTab } from './tabs/ControlTab'
import { MacrosTab } from './tabs/MacrosTab'
import { FeedTab } from './tabs/FeedTab'

const TABS = [
  { value: 'control', label: 'Audio' },
  { value: 'macros', label: 'Macros' },
  { value: 'feed', label: 'Feed' },
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

  return (
    <div className="min-h-screen bg-dt-base pl-dt-4 pr-dt-wheel pt-dt-4 pb-dt-4 overflow-auto text-dt-text-primary flex flex-col">
      <h1 className="text-xl font-bold mb-dt-4 shrink-0">Deskthing Dashboard</h1>
      <TabBar tabs={TABS} value={activeTab} onValueChange={setActiveTab}>
      <TabContent
        value="control"
        className="mt-dt-3 flex-1 min-h-0 data-[state=active]:flex data-[state=active]:flex-col"
      >
        <ControlTab />
      </TabContent>
      <TabContent
        value="macros"
        className="mt-dt-3 flex-1 min-h-0 data-[state=active]:flex data-[state=active]:flex-col"
      >
        <MacrosTab />
      </TabContent>
      <TabContent
        value="feed"
        className="mt-dt-3 flex-1 min-h-0 data-[state=active]:flex data-[state=active]:flex-col"
      >
        <FeedTab />
      </TabContent>
      </TabBar>
    </div>
  )
}

export default App
