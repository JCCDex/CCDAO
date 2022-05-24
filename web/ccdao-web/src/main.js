import Vue from "vue";
import App from "./App.vue";

import ElementUI from "element-ui";
import "element-ui/lib/theme-chalk/index.css";
import "./css/dialog.scss";
// import i18n from './i18n'
Vue.config.productionTip = false;
Vue.use(ElementUI);

import VueI18n from "vue-i18n";
Vue.use(VueI18n);

import axios from "axios";
import store from "./store";
Vue.prototype.$axios = axios;

const messages = {
  en: {
    message: require("./locales/en"),
  },
};

const i18n = new VueI18n({
  locale: "en",
  messages,
});

// // 通过选项创建 VueI18n 实例
// const i18n = new VueI18n({
//   locale: 'en',    // 语言标识
//   messages: {
//     'en': require('./locales/en'),   // 英文语言包
//   }
// })

Vue.config.productionTip = false;

new Vue({
  i18n,
  store,
  render: (h) => h(App),
}).$mount("#app");
