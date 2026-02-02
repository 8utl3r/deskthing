import React from 'react'

interface DropdownOption {
  id: string
  label: string
}

interface DropdownProps {
  options: DropdownOption[]
  value: string | null
  onSelect: (id: string) => void
  placeholder?: string
  label?: string
  disabled?: boolean
}

/**
 * Touch-friendly dropdown: tap to expand, tap option to select.
 * Large touch targets for Car Thing.
 */
export const Dropdown: React.FC<DropdownProps> = ({
  options,
  value,
  onSelect,
  placeholder = 'Select…',
  label,
  disabled = false,
}) => {
  const [open, setOpen] = React.useState(false)
  const selected = options.find((o) => o.id === value)

  return (
    <div className="relative">
      {label && (
        <p className="text-dt-tab text-dt-text-muted mb-dt-2">{label}</p>
      )}
      <button
        type="button"
        disabled={disabled}
        onClick={() => setOpen(!open)}
        className="
          w-full min-h-touch-target px-dt-4 py-dt-3
          bg-dt-elevated rounded-lg
          text-dt-tab text-dt-text-primary text-left font-medium
          border border-dt-subtle
          hover:bg-dt-subtle focus:outline-none focus-visible:ring-2 focus-visible:ring-dt-accent
          flex items-center justify-between gap-dt-2
        "
      >
        <span className="truncate">{selected?.label ?? placeholder}</span>
        <span className="shrink-0 text-dt-text-muted">{open ? '▲' : '▼'}</span>
      </button>
      {open && (
        <>
          <div
            className="fixed inset-0 z-10"
            aria-hidden
            onClick={() => setOpen(false)}
          />
          <div
            className="
              absolute top-full left-0 right-0 mt-1 z-20
              max-h-60 overflow-auto
              bg-dt-elevated rounded-lg border border-dt-subtle
              shadow-lg
            "
          >
            {options.map((opt) => (
              <button
                key={opt.id}
                type="button"
                onClick={() => {
                  onSelect(opt.id)
                  setOpen(false)
                }}
                className={`
                  w-full min-h-touch-target px-dt-4 py-dt-3
                  text-dt-tab text-left
                  first:rounded-t-lg last:rounded-b-lg
                  transition-colors
                  ${value === opt.id
                    ? 'bg-dt-accent text-white'
                    : 'text-dt-text-primary hover:bg-dt-subtle'}
                `}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  )
}
