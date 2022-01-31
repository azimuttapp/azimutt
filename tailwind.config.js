const grayColors = ['slate', 'gray', 'zinc', 'neutral', 'stone'];
const realColors = ['red', 'orange', 'amber', 'yellow', 'lime', 'green', 'emerald', 'teal', 'cyan', 'sky', 'blue', 'indigo', 'violet', 'purple', 'fuchsia', 'pink', 'rose'];
const colors = grayColors.concat(realColors);

module.exports = {
    content: ["./src/Components/**/*.elm", "./src/PagesComponents/**/*.elm"],
    theme: {
        extend: {
            maxHeight: {'128': '32rem', '192': '48rem', '256': '64rem'},
            strokeWidth: {'3': '3'},
            zIndex: {'max': '10000'}
        },
    },
    plugins: [require('@tailwindcss/forms')],
    safelist: [
        ...colors.map(color => `bg-${color}-50`),
        ...colors.map(color => `bg-${color}-100`),
        ...colors.map(color => `bg-${color}-400`),
        ...colors.map(color => `bg-${color}-500`),
        ...colors.map(color => `bg-${color}-600`),
        ...colors.map(color => `border-${color}-300`),
        ...colors.map(color => `border-${color}-400`),
        ...colors.map(color => `border-${color}-500`),
        ...colors.map(color => `border-b-${color}-200`),
        ...colors.map(color => `placeholder-${color}-200`),
        ...colors.map(color => `placeholder-${color}-400`),
        ...colors.map(color => `ring-${color}-500`),
        ...colors.map(color => `ring-${color}-600`),
        ...colors.map(color => `ring-offset-${color}-600`),
        ...colors.map(color => `stroke-${color}-400`),
        ...colors.map(color => `stroke-${color}-500`),
        ...colors.map(color => `text-${color}-100`),
        ...colors.map(color => `text-${color}-200`),
        ...colors.map(color => `text-${color}-300`),
        ...colors.map(color => `text-${color}-400`),
        ...colors.map(color => `text-${color}-500`),
        ...colors.map(color => `text-${color}-600`),
        ...colors.map(color => `text-${color}-700`),
        ...colors.map(color => `text-${color}-800`),
        ...colors.map(color => `text-${color}-900`)
    ]
}
