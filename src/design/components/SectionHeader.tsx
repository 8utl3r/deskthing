import React from 'react'

interface SectionHeaderProps {
  title: string
  /** Optional hint below title */
  hint?: string
}

export const SectionHeader: React.FC<SectionHeaderProps> = ({ title, hint }) => (
  <div>
    <h2 className="text-sm font-semibold text-dt-text-secondary">{title}</h2>
    {hint && <p className="text-xs text-dt-text-muted mt-0.5">{hint}</p>}
  </div>
)
