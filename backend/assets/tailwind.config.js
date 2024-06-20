// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

let plugin = require('tailwindcss/plugin')
const colors = require("tailwindcss/colors");

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex',
    '../lib/*_web/**/*.*exs'

  ],
  safelist: [
    'w-1/4',
    'w-1/5',
    'grid-cols-4',
    'grid-cols-5',
    {
      pattern: /(bg|text|border|from|via|to)-(red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-.*/,
    },
  ],
  theme: {
    extend: {
      colors: {
        default: {
          DEFAULT: colors.gray[600],
        },
        "default-txt": {
          DEFAULT: colors.gray[600],
          secondary: colors.gray[500],
          informative: colors.gray[400],
          hover: colors.indigo[600],
        },
        "default-border": {
          DEFAULT: colors.gray[200],
        },
        "default-bg": {
          DEFAULT: colors.gray[50],
          disabled: colors.gray[100],
          hover: colors.gray[100],
        },
        "default-btn": {
          DEFAULT: colors.gray[200],
          hover: colors.gray[50],
          focus: colors.gray[400],
          disabled: colors.gray[100],
        },
        primary: {
          DEFAULT: colors.indigo[600],
        },
        "primary-txt": {
          DEFAULT: colors.indigo[600],
          secondary: colors.indigo[600],
        },
        "primary-bg": {
          DEFAULT: colors.indigo[50],
          hover: colors.indigo[100],
        },
        "primary-btn": {
          DEFAULT: colors.indigo[200],
          hover: colors.indigo[50],
          focus: colors.indigo[400],
          disabled: colors.indigo[100],
        },
        success: {
          DEFAULT: colors.emerald[500],
        },
        "success-txt": {
          DEFAULT: colors.emerald[500],
          secondary: colors.emerald[400],
        },
        "success-bg": {
          DEFAULT: colors.emerald[50],
          hover: colors.emerald[100],
        },
        "success-btn": {
          DEFAULT: colors.emerald[500],
          hover: colors.emerald[600],
          focus: colors.emerald[500],
          disabled: colors.emerald[300],
        },
        info: {
          DEFAULT: colors.blue[500],
        },
        "info-txt": {
          DEFAULT: colors.blue[500],
          secondary: colors.blue[400],
        },
        "info-bg": {
          DEFAULT: colors.blue[50],
          hover: colors.blue[100],
        },
        "info-btn": {
          DEFAULT: colors.blue[500],
          hover: colors.blue[600],
          focus: colors.blue[500],
          disabled: colors.blue[300],
        },
        warning: {
          DEFAULT: colors.amber[500],
        },
        "warning-txt": {
          DEFAULT: colors.amber[600],
          secondary: colors.amber[500],
        },
        "warning-bg": {
          DEFAULT: colors.amber[50],
          hover: colors.amber[100],
        },
        "warning-btn": {
          DEFAULT: colors.amber[500],
          hover: colors.amber[600],
          focus: colors.amber[500],
          disabled: colors.amber[300],
        },
        danger: {
          DEFAULT: colors.red[500],
        },
        "danger-txt": {
          DEFAULT: colors.red[500],
          secondary: colors.red[300],
        },
        "danger-border": {
          DEFAULT: colors.red[400],
        },
        "danger-bg": {
          DEFAULT: colors.red[50],
          hover: colors.red[100],
        },
        "danger-btn": {
          DEFAULT: colors.red[500],
          hover: colors.red[600],
          focus: colors.red[500],
          disabled: colors.red[300],
        },
        'scheme-red': '#EF476F',
        'scheme-yellow': '#FFD166',
        'scheme-green': '#06D6A0',
        'scheme-blue': '#118AB2',
        'scheme-darkblue': '#118AB2',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    plugin(({addVariant}) => addVariant('phx-no-feedback', ['&.phx-no-feedback', '.phx-no-feedback &'])),
    plugin(({addVariant}) => addVariant('phx-click-loading', ['&.phx-click-loading', '.phx-click-loading &'])),
    plugin(({addVariant}) => addVariant('phx-submit-loading', ['&.phx-submit-loading', '.phx-submit-loading &'])),
    plugin(({addVariant}) => addVariant('phx-change-loading', ['&.phx-change-loading', '.phx-change-loading &']))
  ]
}
