import React from 'react'
import * as RadixSwitch from '@radix-ui/react-switch'

interface SwitchProps {
  checked: boolean
  onCheckedChange: (checked: boolean) => void
  /** Use 'danger' for mute/stop; default is accent */
  variant?: 'accent' | 'danger'
  disabled?: boolean
}

export const Switch: React.FC<SwitchProps> = ({
  checked,
  onCheckedChange,
  variant = 'accent',
  disabled = false,
}) => {
  const trackClass =
    variant === 'danger'
      ? 'data-[state=checked]:bg-dt-danger'
      : 'data-[state=checked]:bg-dt-muted-active'
  return (
    <RadixSwitch.Root
      checked={checked}
      onCheckedChange={onCheckedChange}
      disabled={disabled}
      className={`
        min-w-[72px] min-h-touch rounded-full relative
        bg-dt-subtle ${trackClass}
        data-[disabled]:opacity-50
        transition-colors
      `}
    >
      <RadixSwitch.Thumb
        className="
          block min-w-[52px] min-h-touch bg-white rounded-full
          transition-transform translate-x-0.5
          data-[state=checked]:translate-x-5
        "
      />
    </RadixSwitch.Root>
  )
}
