/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // All values are CSS custom properties defined in src/styles/theme.css.
        // Swapping in the firm's brand palette means editing that one file.
        border: 'rgb(var(--colour-border) / <alpha-value>)',
        input: 'rgb(var(--colour-input) / <alpha-value>)',
        ring: 'rgb(var(--colour-ring) / <alpha-value>)',
        background: {
          DEFAULT: 'rgb(var(--colour-background) / <alpha-value>)',
          far: 'rgb(var(--colour-background-far) / <alpha-value>)',
        },
        surface: 'rgb(var(--colour-surface) / <alpha-value>)',
        // The glass panel flattened against the canvas. Use this wherever a
        // solid equivalent is needed — nested wells, canvas elements, anything
        // that cannot itself be translucent.
        panel: 'rgb(var(--colour-panel-solid) / <alpha-value>)',
        foreground: 'rgb(var(--colour-foreground) / <alpha-value>)',
        muted: {
          DEFAULT: 'rgb(var(--colour-muted) / <alpha-value>)',
          foreground: 'rgb(var(--colour-muted-foreground) / <alpha-value>)',
        },
        primary: {
          DEFAULT: 'rgb(var(--colour-primary) / <alpha-value>)',
          foreground: 'rgb(var(--colour-primary-foreground) / <alpha-value>)',
        },
        accent: {
          DEFAULT: 'rgb(var(--colour-accent) / <alpha-value>)',
          foreground: 'rgb(var(--colour-accent-foreground) / <alpha-value>)',
        },
        // The logo's own colours. Used by the Brand component, not for UI.
        brand: {
          DEFAULT: 'rgb(var(--colour-brand) / <alpha-value>)',
          accent: 'rgb(var(--colour-brand-accent) / <alpha-value>)',
        },
        // The current-mission signal. Always accompanied by a word — see the
        // note in theme.css.
        highlight: {
          DEFAULT: 'rgb(var(--colour-highlight) / <alpha-value>)',
          foreground: 'rgb(var(--colour-highlight-foreground) / <alpha-value>)',
        },
        success: {
          DEFAULT: 'rgb(var(--colour-success) / <alpha-value>)',
          foreground: 'rgb(var(--colour-success-foreground) / <alpha-value>)',
        },
        warning: {
          DEFAULT: 'rgb(var(--colour-warning) / <alpha-value>)',
          foreground: 'rgb(var(--colour-warning-foreground) / <alpha-value>)',
        },
        danger: {
          DEFAULT: 'rgb(var(--colour-danger) / <alpha-value>)',
          foreground: 'rgb(var(--colour-danger-foreground) / <alpha-value>)',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'Segoe UI', 'sans-serif'],
        // Figures that must line up column to column — day counters, scores,
        // percentages. Tabular numerals stop a progress readout from jittering
        // as it counts.
        mono: ['ui-monospace', 'SFMono-Regular', 'Menlo', 'monospace'],
      },
      letterSpacing: {
        // For the small uppercase labels that give the console its voice.
        console: '0.14em',
      },
      keyframes: {
        'panel-in': {
          from: { opacity: '0', transform: 'translateY(6px)' },
          to: { opacity: '1', transform: 'none' },
        },
        sweep: {
          from: { transform: 'scaleX(0)' },
          to: { transform: 'scaleX(1)' },
        },
      },
      animation: {
        'panel-in': 'panel-in 320ms cubic-bezier(0.16, 1, 0.3, 1) both',
        sweep: 'sweep 600ms cubic-bezier(0.16, 1, 0.3, 1) both',
      },
      transitionTimingFunction: {
        // A single easing for the whole interface. Decelerating, never bouncy.
        console: 'cubic-bezier(0.16, 1, 0.3, 1)',
      },
    },
  },
  plugins: [],
};
