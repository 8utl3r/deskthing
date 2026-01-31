import React from 'react'
import { DeskThing } from '@deskthing/client'
import { MacroButton, SectionHeader } from '@/design/components'

const MACROS = [
  { id: 'mute-teams', label: 'Mute Teams', icon: '🎤' },
  { id: 'focus-mode', label: 'Focus mode', icon: '🎯' },
  { id: 'add-inbox', label: 'Add to inbox', icon: '📥' },
]

export const MacrosTab: React.FC = () => {
  const runMacro = (id: string) => {
    DeskThing.send({ type: 'macro', payload: { id } })
  }

  return (
    <div className="space-y-dt-4">
      <SectionHeader
        title="Macros"
        hint="Run AppleScript or Shortcuts. Edit config to add more."
      />
      <div className="grid grid-cols-2 gap-dt-2">
        {MACROS.map((m) => (
          <MacroButton
            key={m.id}
            id={m.id}
            label={m.label}
            icon={m.icon}
            onClick={() => runMacro(m.id)}
          />
        ))}
      </div>
    </div>
  )
}
