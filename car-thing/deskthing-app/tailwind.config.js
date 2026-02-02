/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        'dt': {
          base: 'var(--color-bg-base)',
          elevated: 'var(--color-bg-elevated)',
          subtle: 'var(--color-bg-subtle)',
          'text-primary': 'var(--color-text-primary)',
          'text-secondary': 'var(--color-text-secondary)',
          'text-muted': 'var(--color-text-muted)',
          accent: 'var(--color-accent)',
          success: 'var(--color-success)',
          warning: 'var(--color-warning)',
          danger: 'var(--color-danger)',
          'muted-active': 'var(--color-muted-active)',
        },
      },
      spacing: {
        'dt-1': 'var(--space-1)',
        'dt-2': 'var(--space-2)',
        'dt-3': 'var(--space-3)',
        'dt-4': 'var(--space-4)',
        'dt-5': 'var(--space-5)',
        'dt-6': 'var(--space-6)',
        'dt-wheel': 'var(--space-wheel)',
      },
      minHeight: {
        touch: 'var(--touch-min)',
        'touch-target': 'var(--touch-target)',
      },
      width: {
        'slider-thumb': 'var(--slider-thumb-width)',
      },
      height: {
        'slider-thumb': 'var(--slider-thumb-width)',
        'slider-track': 'var(--slider-track-height)',
      },
      fontSize: {
        'dt-touch': 'var(--text-touch)',
        'dt-tab': 'var(--text-tab)',
        'dt-feed': 'var(--text-feed)',
        'dt-body': 'var(--text-body)',
      },
    },
  },
  plugins: [],
}

