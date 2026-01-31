import './globalThis'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'

function showLoadError(message: string) {
  const root = document.getElementById('root')
  if (root) {
    root.innerHTML = `<div style="padding:1rem;background:#0f172a;color:#f8fafc;min-height:100vh"><h1 style="font-size:1.25rem">Load error</h1><pre style="font-size:0.875rem;overflow:auto;white-space:pre-wrap">${message.replace(/</g, '&lt;')}</pre></div>`
  }
}

function LoadingScreen() {
  return (
    <div
      style={{
        padding: '1rem',
        background: '#0f172a',
        color: '#f8fafc',
        minHeight: '100vh',
        fontSize: '1rem',
      }}
    >
      Starting…
    </div>
  )
}

const rootEl = document.getElementById('root')
if (!rootEl) {
  document.body.innerHTML =
    '<div style="padding:1rem;color:#f8fafc;background:#0f172a">No #root element</div>'
} else {
  const root = createRoot(rootEl)
  root.render(
    <StrictMode>
      <LoadingScreen />
    </StrictMode>,
  )

  // Load app (and @deskthing/client) in a separate chunk so load errors are caught
  const loadTimeout = setTimeout(() => {
    showLoadError(
      'Load timed out. The app chunk may have failed to load or execute on this device. Try Wi‑Fi and re-upload, or check DeskThing Discord.',
    )
  }, 15000)

  Promise.all([import('./App'), import('./ErrorBoundary')])
    .then(([{ default: App }, { ErrorBoundary }]) => {
      clearTimeout(loadTimeout)
      root.render(
        <StrictMode>
          <ErrorBoundary>
            <App />
          </ErrorBoundary>
        </StrictMode>,
      )
    })
    .catch((e) => {
      clearTimeout(loadTimeout)
      const msg = e instanceof Error ? e.message : String(e)
      const stack = e instanceof Error ? e.stack : ''
      showLoadError(stack ? `${msg}\n\n${stack}` : msg)
    })
}
