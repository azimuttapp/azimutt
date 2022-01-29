const grayColors = ['slate', 'gray', 'zinc', 'neutral', 'stone'];
const realColors = ['red', 'orange', 'amber', 'yellow', 'lime', 'green', 'emerald', 'teal', 'cyan', 'sky', 'blue', 'indigo', 'violet', 'purple', 'fuchsia', 'pink', 'rose'];
const colors = grayColors.concat(realColors);

module.exports = {
    content: ["./src/Components/**/*.elm", "./src/PagesComponents/**/*.elm"],
    theme: {
        extend: {
            strokeWidth: {'3': '3'}
        },
    },
    plugins: [],
    safelist: [
        ...colors.map(color => `stroke-${color}-500`),
        'stroke-slate-400'
    ]
}
