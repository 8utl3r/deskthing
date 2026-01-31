/**
 * Polyfill for globalThis (ES2020) so the app runs in older runtimes (e.g. Car Thing WebView).
 * Must be imported first in main.tsx so it runs before any code that uses globalThis.
 */
try {
  if (typeof globalThis === 'undefined') {
    const g: unknown =
      typeof self !== 'undefined'
        ? self
        : typeof window !== 'undefined'
          ? window
          : typeof global !== 'undefined'
            ? global
            : undefined
    if (g && typeof g === 'object') {
      ;(g as Record<string, unknown>).globalThis = g
    }
  }
} catch {
  const g: unknown =
    typeof self !== 'undefined'
      ? self
      : typeof window !== 'undefined'
        ? window
        : typeof global !== 'undefined'
          ? global
          : undefined
  if (g && typeof g === 'object') {
    ;(g as Record<string, unknown>).globalThis = g
  }
}
