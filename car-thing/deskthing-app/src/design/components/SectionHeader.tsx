import React from 'react'

interface SectionHeaderProps {
  title: string
  /** Optional hint below title */
  hint?: string
}

export const SectionHeader: React.FC<SectionHeaderProps> = ({ title, hint }) => (
  <div>
    <h2 className="text-dt-tab font-semibold text-dt-text-secondary">{title}</h2>
    {hint && <p className="text-dt-body text-dt-text-muted mt-dt-1">{hint}</p>}
  </div>
)
