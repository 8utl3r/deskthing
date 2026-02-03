import React from 'react'
import { PALETTES, DEFAULT_PALETTE_ID, type Palette } from '@/palettes'

const STORAGE_KEY = 'deskthing-palette'

function loadPaletteId(): string {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored && PALETTES.some((p) => p.id === stored)) return stored
  } catch {
    /* ignore */
  }
  return DEFAULT_PALETTE_ID
}

const PaletteContext = React.createContext<{
  palette: Palette
  setPaletteId: (id: string) => void
} | null>(null)

export function PaletteProvider({ children }: { children: React.ReactNode }) {
  const [paletteId, setPaletteIdState] = React.useState(loadPaletteId)

  const setPaletteId = React.useCallback((id: string) => {
    if (PALETTES.some((p) => p.id === id)) {
      setPaletteIdState(id)
      try {
        localStorage.setItem(STORAGE_KEY, id)
      } catch {
        /* ignore */
      }
    }
  }, [])

  const palette = PALETTES.find((p) => p.id === paletteId) ?? PALETTES[0]!

  return (
    <PaletteContext.Provider value={{ palette, setPaletteId }}>
      {children}
    </PaletteContext.Provider>
  )
}

export function usePalette() {
  const ctx = React.useContext(PaletteContext)
  if (!ctx) throw new Error('usePalette must be used within PaletteProvider')
  return ctx
}
