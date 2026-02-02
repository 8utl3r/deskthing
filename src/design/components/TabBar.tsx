import React from 'react'
import * as RadixTabs from '@radix-ui/react-tabs'

interface Tab {
  value: string
  label: string
}

interface TabBarProps {
  tabs: Tab[]
  value?: string
  onValueChange?: (value: string) => void
  defaultValue?: string
  children: React.ReactNode
}

export const TabBar: React.FC<TabBarProps> = ({
  tabs,
  value,
  onValueChange,
  defaultValue,
  children,
}) => (
  <RadixTabs.Root
    {...(value !== undefined
      ? { value, onValueChange }
      : { defaultValue: defaultValue ?? tabs[0]?.value })}
    className="flex flex-col flex-1"
  >
    <RadixTabs.List className="grid grid-cols-3 gap-dt-2 shrink-0">
      {tabs.map((tab) => (
        <RadixTabs.Trigger
          key={tab.value}
          value={tab.value}
          className="flex flex-col items-center justify-center min-h-touch py-dt-3 px-dt-2 text-dt-tab rounded-lg data-[state=active]:bg-dt-subtle text-dt-text-secondary data-[state=active]:text-dt-text-primary transition-colors font-semibold"
        >
          {tab.label}
        </RadixTabs.Trigger>
      ))}
    </RadixTabs.List>
    {children}
  </RadixTabs.Root>
)

/** Use with TabBar: <TabBar><TabContent value="x">...</TabContent></TabBar> */
export const TabContent = RadixTabs.Content
