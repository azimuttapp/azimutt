/// <reference types="vitest" />

import { defineConfig } from "vite"
import react from "@vitejs/plugin-react-swc"
import { viteSingleFile } from "vite-plugin-singlefile"
import path from "path"

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), viteSingleFile()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    outDir: "../resources",
    emptyOutDir: false,
    rollupOptions: {
      input: "report.html",
    },
  },
  server: {
    open: "report.html",
  },
  test: {
    globals: true,
    setupFiles: ["./setup-vitest.ts"],
    environment: "jsdom",
  },
})
