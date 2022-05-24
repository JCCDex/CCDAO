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
    setvalue(isstore, res) {
      isstore.commit("setdata", res);
    },
  },
  modules: {},
});
