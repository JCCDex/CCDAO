import Vue from "vue";
import Vuex from "vuex";
import axios from "axios";

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    totalVolumeTraded: "",
    fullyDilutedValuation: "",
    ETHCCDAO: "",
    SWTCCCDAO: "",
  },
  getters: {},
  mutations: {
    setdata(state, res) {
      state.totalVolumeTraded = res.data.totalVolumeTraded;
      state.fullyDilutedValuation = res.data.fullyDilutedValuation;
      state.ETHCCDAO = res.data.ETH;
      state.SWTCCCDAO = res.data.SWTC;
    },
  },
  actions: {
    setvalue(isstore) {
      const { SubscribeFactory } = require("jcc_rpc");

      const subscribeInst = SubscribeFactory.init();

      // task name
      const TASK_NAME = "pollingConfig";
      // task function
      const task = function () {
        const data = axios.get("./config.json");
        // .then((response) => {
        //   console.log(response);
        //   return response;
        // })
        // .catch(function (error) {
        //   console.log(error);
        // });
        return data;
      };
      // whether polling, default true
      const polling = true;
      // polling interval, default 5000(ms)
      const timer = 1000 * 60 * 10;

      const callback = (err, res) => {
        // console.log(err);
        // console.log(res);
        isstore.commit("setdata", res);
      };

      subscribeInst
        // register task
        .register(TASK_NAME, task, polling, timer)
        // watch task
        .on(TASK_NAME, callback)
        // start task
        .start(TASK_NAME);
    },
  },
  modules: {},
});
