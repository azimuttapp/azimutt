const colors = require('tailwindcss/colors')

const usedColors = ['primary', 'default', 'slate', 'gray', 'red', 'orange', 'amber', 'yellow', 'lime', 'green', 'emerald', 'teal', 'cyan', 'sky', 'blue', 'indigo', 'violet', 'purple', 'fuchsia', 'pink', 'rose']
function expandDynamicColors(fileContent) {
    // see "DYNAMIC COLOR CLASSES" in src/Libs/Tailwind.elm
    return fileContent.replace(/([^_\n])(bg|border|fill|placeholder|ring|ring_offset|stroke|text)_([0-9]{1,2}0) [^ ,):\n]+/g, (match, start, attr, level) => {
        return `${start}"${usedColors.map(clazz => `${attr.replaceAll('_', '-')}-${clazz}-${level}`).join(' ')}"`
    })
}

const stateMappings = {xxl: '2xl', focusWithin: 'focus-within'}
function expandDynamicStates(fileContent) {
    // see "DYNAMIC STATE CLASSES" in src/Libs/Tailwind.elm
    return fileContent.replace(/(?:Tw\.)?(sm|md|lg|xl|xxl|hover|focus|active|disabled|focusWithin) \[ ([^\]]+) ]/g, (match, state, content) => {
        const stateClass = stateMappings[state] || state
        const classes = [...content.matchAll(/"([^"]+)"/g)].map(match => match[1]) // collect string and concat them
        return `"${classes.join(' ').split(' ').map(c => c.trim()).filter(c => c !== '').map(clazz => stateClass + ':' + clazz).join(' ')}"`
    })
}

module.exports = {
    content: {
        files: ["src/Libs/Tailwind.elm", "./src/Components/**/*.elm", "./src/PagesComponents/**/*.elm"],
        transform: {
            // https://tailwindcss.com/docs/content-configuration#transforming-source-files
            // transform elm sources to expand helpers to full tailwind classes (cf src/Libs/Tailwind.elm)
            elm: content => expandDynamicStates(expandDynamicColors(content))
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
    ]
}
