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
        w-11 h-6 rounded-full relative
        bg-dt-subtle ${trackClass}
        data-[disabled]:opacity-50
        transition-colors
      `}
    >
      <RadixSwitch.Thumb
        className="
          block w-5 h-5 bg-white rounded-full
          transition-transform translate-x-0.5
          data-[state=checked]:translate-x-6
        "
      />
    </RadixSwitch.Root>
  )
}
