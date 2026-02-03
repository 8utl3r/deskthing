import { createTheme, MantineColorsTuple } from '@mantine/core'

const slate: MantineColorsTuple = [
  '#f8fafc',
  '#f1f5f9',
  '#e2e8f0',
  '#cbd5e1',
  '#94a3b8',
  '#64748b',
  '#475569',
  '#334155',
  '#1e293b',
  '#0f172a',
]

export const theme = createTheme({
  primaryColor: 'blue',
  colors: {
    dark: slate,
  },
  defaultRadius: 'md',
  fontFamily: 'system-ui, sans-serif',
  headings: {
    fontFamily: 'system-ui, sans-serif',
  },
  fontSizes: {
    xs: '0.6875rem',
    sm: '0.875rem',
    md: '1rem',
    lg: '1.25rem',
    xl: '1.375rem',
  },
  other: {
    touchMin: 64,
    spaceWheel: 36,
    sliderThumbWidth: 120,
  },
})
