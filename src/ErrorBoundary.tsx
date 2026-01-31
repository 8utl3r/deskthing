import React from 'react'

interface State {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  State
> {
  state: State = { hasError: false, error: null }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  render() {
    if (this.state.hasError && this.state.error) {
      return (
        <div
          className="min-h-screen bg-dt-base p-dt-4 text-dt-text-primary flex flex-col gap-4"
          style={{ background: '#0f172a', color: '#f8fafc', padding: 16 }}
        >
          <h1 className="text-xl font-bold">Something went wrong</h1>
          <pre className="text-sm overflow-auto break-all">
            {this.state.error.message}
          </pre>
        </div>
      )
    }
    return this.props.children
  }
}
