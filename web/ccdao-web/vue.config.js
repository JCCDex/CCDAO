const { defineConfig } = require("@vue/cli-service");
const NodePolyfillPlugin = require("node-polyfill-webpack-plugin");
const assetFunctions = require("node-sass-asset-functions");

module.exports = defineConfig({
  transpileDependencies: true,
  lintOnSave: false,

  configureWebpack: {
    plugins: [new NodePolyfillPlugin()],
  },
  css: {
    loaderOptions: {
      scss: {
        sassOptions: {
          functions: assetFunctions(),
        },
      },
    },
  },

  pluginOptions: {
    i18n: {
      locale: "en",
      fallbackLocale: "en",
      localeDir: "locales",
      enableInSFC: true,
      includeLocales: false,
      enableBridge: true,
    },
  },
});
