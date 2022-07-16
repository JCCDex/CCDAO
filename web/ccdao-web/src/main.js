import Vue from "vue";
import App from "./App.vue";
import ElementUI from "element-ui";
import "element-ui/lib/theme-chalk/index.css";
import "./css/dialog.scss";
import "./css/wel.scss";
import "./css/webadd.scss";
import "./css/tobuy.scss";
import "./css/signers.scss";
import "./css/member.scss";
import "./css/holds.scss";
import "./css/header.scss";
import "./css/foot.scss";

Vue.config.productionTip = false;
Vue.use(ElementUI);

import VueI18n from "vue-i18n";
Vue.use(VueI18n);

import axios from "axios";
import store from "./store";
import BigNumber from "bignumber.js";
Vue.prototype.$axios = axios;

const { fetchPrice, fetchVolume } = require("../scripts/fetch-ticker");
const fetchEthereumPosition = require("../scripts/fetch-ethereum-position");
const fetchSwtPosition = require("../scripts/fetch-swt-position");
const fetchPolygonPosition = require("../scripts/fetch-polygon-position");
const fetchBscPosition = require("../scripts/fetch-bsc-position");
const fetchHecoPosition = require("../scripts/fetch-heco-position");

const messages = {
  en: {
    message: require("./locales/en"),
  },
};

const i18n = new VueI18n({
  locale: "en",
  messages,
});

Vue.config.productionTip = false;

const { SubscribeFactory } = require("jcc_rpc");

const subscribeInst = SubscribeFactory.init();

// task name
const TASK_NAME = "pollingConfig";
// task function
const task = async () => {
  const price = await fetchPrice();
  const volume = await fetchVolume();
  const ethereumPosition = await fetchEthereumPosition();
  const swtPosition = await fetchSwtPosition();
  const polygonPosition = await fetchPolygonPosition();
  const bscPosition = await fetchBscPosition();
  const hecoPosition = await fetchHecoPosition();
  return {
    totalVolumeTraded: new BigNumber(volume).toFixed(0),
    fullyDilutedValuation: new BigNumber(2e9).times(price).toFixed(0),
    ETH: ethereumPosition,
    SWT: swtPosition,
    POLYGON: polygonPosition,
    BSC: bscPosition,
    HECO: hecoPosition,
  };
};
// whether polling, default true
const polling = true;
// polling interval, default 5000(ms)
const timer = 5 * 60 * 1000;

const callback = (err, res) => {
  if (err == null) {
    store.dispatch("setValue", res);
  }
};

subscribeInst
  // register task
  .register(TASK_NAME, task, polling, timer)
  // watch task
  .on(TASK_NAME, callback)
  // start task
  .start(TASK_NAME);

const tp = require("tp-js-sdk");

if (tp.isConnected()) {
  store.commit("setIsTp", true);
  tp.getWallet({ walletTypes: ["jingtum"], switch: false }).then((req) => {
    if (req.data.address !== undefined) store.commit("setSwtcAddress", req.data.address);
  });
}
if (window.ethereum) {
  const ethereum = window.ethereum;

  ethereum.on("chainChanged", (_chainId) => {
    let ethNetWork = ["0x1"];
    if (ethNetWork.indexOf(_chainId) < 0) {
      store.commit("setIsNetWork", false);
    } else {
      store.commit("setIsNetWork", true);
    }
  });
  ethereum.on("accountsChanged", (acc) => {
    store.commit("setEthAddress", acc[0] === undefined ? "" : acc[0]);
    store.dispatch("setMyEthNum");
  });
}

new Vue({
  i18n,
  store,
  render: (h) => h(App),
}).$mount("#app");
