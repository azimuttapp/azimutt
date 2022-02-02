const colors = require('tailwindcss/colors')

module.exports = {
    content: {
        files: ["./src/Components/**/*.elm", "./src/PagesComponents/**/*.elm"],
        transform: {
            // https://tailwindcss.com/docs/content-configuration#transforming-source-files
            elm: (content) => {
                // transform elm sources to create full tailwind classes from helpers functions (cf src/Libs/Tailwind.elm)
                const mappings = {xxl: '2xl', focusWithin: 'focus-within'}
                return content.replaceAll(/(\[ |, )(?:Tw\.)?(sm|md|lg|xl|xxl|hover|focus|active|disabled|focusWithin) "([^"]+)"/g, (match, start, state, classes) => {
                    const twState = mappings[state] ||  state
                    return `${start}"${classes.split(' ').map(c => c.trim()).filter(c => c !== '').map(c => twState + ':' + c).join(' ')}"`
                })
            }
        }
    },
    theme: {
        extend: {
            maxHeight: {'128': '32rem', '192': '48rem', '256': '64rem'},
            strokeWidth: {'3': '3'},
            zIndex: {'max': '10000'}
        },
        colors: {
            // https://tailwindcss.com/docs/customizing-colors#aliasing-color-names
            transparent: 'transparent',
            current: 'currentColor',
            black: colors.black,
            white: colors.white,
            gray: colors.gray,
            primary: colors.indigo,
            default: colors.slate,
            slate: colors.slate,
            red: colors.red,
            orange: colors.orange,
            amber: colors.amber,
            yellow: colors.yellow,
            lime: colors.lime,
            green: colors.green,
            emerald: colors.emerald,
            teal: colors.teal,
            cyan: colors.cyan,
            sky: colors.sky,
            blue: colors.blue,
            indigo: colors.indigo,
            violet: colors.violet,
            purple: colors.purple,
            fuchsia: colors.fuchsia,
            pink: colors.pink,
            rose: colors.rose,
        }
    },
    plugins: [
        require('@tailwindcss/forms'),
        require('@tailwindcss/typography')
    ],
    safelist: [
        // https://tailwindcss.com/docs/content-configuration#using-regular-expressions
        {pattern: /bg-(slate|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(50|100|200|300|400|500|600|700)/, variants: ['hover', 'disabled']},
        {pattern: /border-(slate|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(300|400|500|700)/},
        {pattern: /border-b-(slate|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(200)/},
        {pattern: /placeholder-(slate|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(200|400)/, variants: ['focus']},
        {pattern: /ring-(slate|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(500|600)/, variants: ['focus', 'focus-within']},
        {pattern: /ring-offset-(slate|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(500|600)/, variants: ['focus', 'focus-within']},
        {pattern: /stroke-(slate|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(400|500)/},
        {pattern: /text-(slate|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(100|200|300|400|500|600|700|800|900)/, variants: ['focus', 'disabled']}
    ]
}
