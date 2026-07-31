/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // All values are CSS custom properties defined in src/styles/theme.css.
        // Swapping in MadNuur Capital's brand palette means editing that one file.
        border: 'rgb(var(--colour-border) / <alpha-value>)',
        input: 'rgb(var(--colour-input) / <alpha-value>)',
        ring: 'rgb(var(--colour-ring) / <alpha-value>)',
        background: 'rgb(var(--colour-background) / <alpha-value>)',
        surface: 'rgb(var(--colour-surface) / <alpha-value>)',
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
      },
    },
  },
  plugins: [],
};
