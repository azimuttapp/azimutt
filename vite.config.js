import elmPlugin from 'vite-plugin-elm'
const { resolve } = require('path')

export default {
    plugins: [elmPlugin()],
    build: {
        rollupOptions: {
          input: {
            main: resolve(__dirname, 'index.html'),
            nested: resolve(__dirname, 'book.html')
          }
        }
      }
}
