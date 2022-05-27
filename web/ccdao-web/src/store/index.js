import Vue from "vue";
import Vuex from "vuex";
import axios from "axios";

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    totalVolumeTraded: "",
    fullyDilutedValuation: "",
    ethCcdao: "",
    swtcCcdao: "",
    ethAddress: "",
    swtcAddress: "",
    myCCDAONum: 0,
  },
  getters: {
    isHave(state) {
      return state.swtcAddress !== "" || state.ethAddress !== "";
    },
  },
  mutations: {
    setData(state, res) {
      state.totalVolumeTraded = res.data.totalVolumeTraded;
      state.fullyDilutedValuation = res.data.fullyDilutedValuation;
      state.ethCcdao = res.data.ETH;
      state.swtcCcdao = res.data.SWTC;
    },
    setEthAddress(state, data) {
      state.ethAddress = data;
    },
    setSwtcAddress(state, data) {
      state.swtcAddress = data;
    },
    setMyCCDAONumdata(state, data) {
      state.myCCDAONum = data;
    },
  },
  actions: {
    setValue(isstore, res) {
      isstore.commit("setData", res);
    },
    setMyCCDAONum(isStore) {
      axios
        .get(
          "https://swtcscan.jccdex.cn/wallet/balance/" + isStore.state.swtcAddress + "?w=" + isStore.state.swtcAddress
        )
        .then((response) => {
          isStore.commit("setMyCCDAONumdata", response.data.data.CCDAO_jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or.value);
        })
        .catch(function (error) {
          console.log(error);
        });
    },
  },
  modules: {},
});
