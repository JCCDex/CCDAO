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
    ETHAddress: "",
    SWTCAddress: "",
    myCCDAONum: 0,
  },
  getters: {
    isHave(state) {
      return state.SWTCAddress === "" && state.ETHAddress === "";
    },
  },
  mutations: {
    setdata(state, res) {
      state.totalVolumeTraded = res.data.totalVolumeTraded;
      state.fullyDilutedValuation = res.data.fullyDilutedValuation;
      state.ETHCCDAO = res.data.ETH;
      state.SWTCCCDAO = res.data.SWTC;
    },
    setETHAddress(state, data) {
      state.ETHAddress = data;
    },
    setSWTCAddress(state, data) {
      state.SWTCAddress = data;
    },
    setMyCCDAONumdata(state, data) {
      state.myCCDAONum = data;
    },
  },
  actions: {
    setvalue(isstore, res) {
      isstore.commit("setdata", res);
    },
    setMyCCDAONum(isStore) {
      axios
        .get("https://swtcscan.jccdex.cn/wallet/balance/" + isStore.SWTCAddress + "?w=" + isStore.SWTCAddress)
        .then((response) => {
          // this.CCDAOnum = response.data.data.CCDAO_jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or.value;
          isStore.commit("setMyCCDAONumdata", response.data.data.CCDAO_jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or.value);
        })
        .catch(function (error) {
          console.log(error);
        });
    },
  },
  modules: {},
});
