import { createRequire } from 'node:module'
import { DeskThing } from '@deskthing/server'
import { DESKTHING_EVENTS } from '@deskthing/types'

// Read version from manifest.json (in packaged app zip); package.json is not in the zip.
const require = createRequire(import.meta.url)
let appVersion = '0.4.6'
let appVersionCode = 7
try {
  const manifest = require('../manifest.json') as { version?: string; version_code?: number }
  if (manifest.version) appVersion = manifest.version
  if (typeof manifest.version_code === 'number') appVersionCode = manifest.version_code
} catch {
  // Fallback so server never crashes when manifest is missing
}
const BRIDGE_URL = process.env.CAR_THING_BRIDGE_URL || 'http://127.0.0.1:8765'

const VOLUME_WHEEL_STEP = 5

/** Action IDs we register; user maps these to hardware in DeskThing Desktop. */
const ACTIONS = {
  VOLUME_UP: 'carthing-volume-up',
  VOLUME_DOWN: 'carthing-volume-down',
  TAB_AUDIO: 'carthing-tab-audio',
  TAB_MACROS: 'carthing-tab-macros',
  TAB_FEED: 'carthing-tab-feed',
  BUTTON_4: 'carthing-button-4',
} as const

async function getBridge(path: string): Promise<Record<string, unknown> | null> {
  try {
    const res = await fetch(`${BRIDGE_URL}${path}`)
    const text = await res.text()
    if (!res.ok) return null
    return (JSON.parse(text || '{}') as Record<string, unknown>) || null
  } catch {
    return null
  }
}

async function callBridge(path: string, body: object): Promise<void> {
  const url = `${BRIDGE_URL}${path}`
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
    const text = await res.text()
    if (!res.ok) {
      console.error(`[Car Thing] Bridge ${path} failed: ${res.status} ${res.statusText} body=${text}`)
      return
    }
    if (text && !text.includes('"ok"')) {
      console.error(`[Car Thing] Bridge ${path} unexpected body: ${text}`)
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    console.error(`[Car Thing] Bridge ${path} error: ${msg} (is bridge running at ${BRIDGE_URL}?)`)
  }
}

async function sendVolumeToClient(vol: number): Promise<void> {
  DeskThing.send({ type: 'volume', payload: vol })
}

const start = async () => {
  console.log('Started the server')

  // Register actions so they appear in DeskThing Desktop → Button/Key mapping. User maps hardware to these IDs.
  // Include source, version_code, tag so the mapping UI has full action shape (may prevent "unknown error").
  const APP_ID = 'deskthing-dashboard'
  const actionList = [
    { id: ACTIONS.VOLUME_UP, name: 'Volume up (wheel)', version: appVersion, version_code: appVersionCode, enabled: true, source: APP_ID, tag: 'media' as const },
    { id: ACTIONS.VOLUME_DOWN, name: 'Volume down (wheel)', version: appVersion, version_code: appVersionCode, enabled: true, source: APP_ID, tag: 'media' as const },
    { id: ACTIONS.TAB_AUDIO, name: 'Tab: Audio', version: appVersion, version_code: appVersionCode, enabled: true, source: APP_ID, tag: 'nav' as const },
    { id: ACTIONS.TAB_MACROS, name: 'Tab: Macros', version: appVersion, version_code: appVersionCode, enabled: true, source: APP_ID, tag: 'nav' as const },
    { id: ACTIONS.TAB_FEED, name: 'Tab: Feed', version: appVersion, version_code: appVersionCode, enabled: true, source: APP_ID, tag: 'nav' as const },
    { id: ACTIONS.BUTTON_4, name: 'Button 4', version: appVersion, version_code: appVersionCode, enabled: true, source: APP_ID, tag: 'basic' as const },
  ]
  actionList.forEach((a) => {
    try {
      DeskThing.registerAction(a)
    } catch (e) {
      console.error('[Car Thing] registerAction failed:', a.id, e)
    }
  })

  // Two-way: on start, send current volume to client so slider is in sync
  getBridge('/audio/volume').then((json) => {
    const v = json && typeof json.volume === 'number' ? json.volume : null
    if (v !== null) sendVolumeToClient(v)
  })

  DeskThing.on('control', (data: { payload?: { action: string; value?: unknown } }) => {
    const { action, value } = data.payload || {}
    console.log('[control]', action, value)
    callBridge('/control', { action, value })
    if (action === 'volume' && typeof value === 'number') sendVolumeToClient(value)
  })

  DeskThing.on('macro', (data: { payload?: { id: string } }) => {
    const id = data.payload?.id
    console.log('[macro]', id)
    callBridge('/macro', { id })
  })

  DeskThing.on('get-volume', () => {
    getBridge('/audio/volume').then((json) => {
      const v = json && typeof json.volume === 'number' ? json.volume : null
      if (v !== null) sendVolumeToClient(v)
    })
  })

  DeskThing.on('get-audio-devices', () => {
    getBridge('/audio/devices').then((json) => {
      const devices = json && Array.isArray(json.devices) ? json.devices : []
      const defaultId = json && typeof json.defaultId === 'string' ? json.defaultId : null
      DeskThing.send({ type: 'audio-devices', payload: { devices, defaultId } })
    })
  })

  DeskThing.on('get-mic-muted', () => {
    getBridge('/audio/mic-muted').then((json) => {
      const muted = json && typeof json.muted === 'boolean' ? json.muted : false
      DeskThing.send({ type: 'mic-muted', payload: muted })
    })
  })

  DeskThing.on('get-feed', () => {
    getBridge('/feed').then((json) => {
      const items = json && Array.isArray(json.items) ? json.items : []
      DeskThing.send({ type: 'feed', payload: items })
    })
  })

  DeskThing.on('action', (data: { payload?: Record<string, unknown> }) => {
    const id = data.payload?.id as string | undefined
    console.log('[action]', id, JSON.stringify(data.payload || {}))

    if (id === ACTIONS.TAB_AUDIO) {
      DeskThing.send({ type: 'tab', payload: 'control' })
      return
    }
    if (id === ACTIONS.TAB_MACROS) {
      DeskThing.send({ type: 'tab', payload: 'macros' })
      return
    }
    if (id === ACTIONS.TAB_FEED) {
      DeskThing.send({ type: 'tab', payload: 'feed' })
      return
    }
    if (id === ACTIONS.BUTTON_4) {
      DeskThing.send({ type: 'tab', payload: 'feed' })
      return
    }

    if (id === ACTIONS.VOLUME_UP || id === ACTIONS.VOLUME_DOWN) {
      const step = id === ACTIONS.VOLUME_UP ? VOLUME_WHEEL_STEP : -VOLUME_WHEEL_STEP
      getBridge('/audio/volume')
        .then((json) => {
          const current = (json && typeof json.volume === 'number' ? json.volume : 50) as number
          const next = Math.max(0, Math.min(100, current + step))
          callBridge('/control', { action: 'volume', value: next }).then(() => sendVolumeToClient(next))
        })
        .catch(() => {})
    }
  })

  DeskThing.on('input', (data: { payload?: Record<string, unknown> }) => {
    const id = data.payload?.id as string | undefined
    if (id) console.log('[input]', id, JSON.stringify(data.payload || {}))
  })
}

const stop = async () => {
  console.log('Stopped the server')
}

DeskThing.on(DESKTHING_EVENTS.START, start)
DeskThing.on(DESKTHING_EVENTS.STOP, stop)
