import React from 'react'
import { Button } from './Button'

interface MacroButtonProps {
  id: string
  label: string
  icon?: string
  onClick: () => void
  disabled?: boolean
}

/** Grid-friendly macro launcher button. */
export const MacroButton: React.FC<MacroButtonProps> = ({
  label,
  icon,
  onClick,
  disabled = false,
}) => (
  <Button
    variant="secondary"
    size="md"
    icon={icon ? <span>{icon}</span> : undefined}
    onClick={onClick}
    disabled={disabled}
    className="h-auto min-h-touch py-dt-4 text-left justify-start"
  >
    {label}
  </Button>
)
