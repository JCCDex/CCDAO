import Vue from "vue";
import App from "./App.vue";
import ElementUI from "element-ui";
import "element-ui/lib/theme-chalk/index.css";
import "./css/dialog.scss";
import { EventBus } from "./Bus.js";
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

const { SubscribeFactory } = require("jcc_rpc");

const subscribeInst = SubscribeFactory.init();

// task name
const TASK_NAME = "pollingConfig";
// task function
const task = function () {
  const promisedata = axios.get("./config.json").catch(function (error) {
    console.log(error);
  });
  return promisedata;
};
// whether polling, default true
const polling = true;
// polling interval, default 5000(ms)
const timer = 1000 * 60 * 10;

const callback = (err, res) => {
  if (err == null) store.dispatch("setValue", res);
  else console.log(err);
};

subscribeInst
  // register task
  .register(TASK_NAME, task, polling, timer)
  // watch task
  .on(TASK_NAME, callback)
  // start task
  .start(TASK_NAME);

if (typeof window.ethereum !== undefined) {
  ethereum.on("chainChanged", (_chainId) => window.location.reload());
  ethereum.on("accountsChanged", (acc) => {
    // store.state.ETHaddress=acc[0];
    store.commit("setEthAddress", acc[0] === undefined ? "" : acc[0]);
  });
}

new Vue({
  i18n,
  store,
  render: (h) => h(App),
}).$mount("#app");
