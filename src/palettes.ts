/**
 * Professional color palettes for tile backgrounds.
 * Sources: IBM Carbon, Material Design 3, Primer, PatternFly.
 */

export interface Palette {
  id: string
  name: string
  /** Tile/surface background (elevated) */
  tileBg: string
  /** Optional tile border */
  tileBorder?: string
  source?: string
}

export const PALETTES: Palette[] = [
  {
    id: 'carbon-gray80',
    name: 'Carbon Gray 80',
    tileBg: '#393939',
    tileBorder: '#525252',
    source: 'IBM Carbon Design System',
  },
  {
    id: 'carbon-gray90',
    name: 'Carbon Gray 90',
    tileBg: '#262626',
    tileBorder: '#393939',
    source: 'IBM Carbon Design System',
  },
  {
    id: 'material-surface',
    name: 'Material Surface',
    tileBg: '#2c2c2e',
    tileBorder: '#3a3a3c',
    source: 'Material Design 3',
  },
  {
    id: 'material-surface-dim',
    name: 'Material Dim',
    tileBg: '#1c1c1e',
    tileBorder: '#2c2c2e',
    source: 'Material Design 3',
  },
  {
    id: 'primer-canvas',
    name: 'Primer Canvas',
    tileBg: '#21262d',
    tileBorder: '#30363d',
    source: 'GitHub Primer',
  },
  {
    id: 'slate',
    name: 'Slate',
    tileBg: '#334155',
    tileBorder: '#475569',
    source: 'Tailwind Slate',
  },
  {
    id: 'zinc',
    name: 'Zinc',
    tileBg: '#27272a',
    tileBorder: '#3f3f46',
    source: 'Tailwind Zinc',
  },
  {
    id: 'blue-gray',
    name: 'Blue Gray',
    tileBg: '#1e293b',
    tileBorder: '#334155',
    source: 'Tailwind Slate-800',
  },
]

export const DEFAULT_PALETTE_ID = 'carbon-gray80'
