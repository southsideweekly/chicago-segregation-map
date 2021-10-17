import legacy from "@vitejs/plugin-legacy"

export default {
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          "mapbox-gl": ["mapbox-gl"],
        },
      },
    },
  },
  plugins: [
    legacy({
      targets: ["ie >= 11"],
      additionalLegacyPolyfills: ["regenerator-runtime/runtime"],
    }),
  ],
}
