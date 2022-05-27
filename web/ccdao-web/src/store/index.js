import Vue from "vue";
import Vuex from "vuex";
import axios from "axios";

import { Token, SwapContract, SwapMulticall, SwapBalance } from "@jccdex/ethereum-contract";
import { Web3Provider } from "@ethersproject/providers";
import { normalizeAccount } from "@jccdex/ethereum-contract/lib/utils/normalizers";

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    totalVolumeTraded: "",
    fullyDilutedValuation: "",
    ethCcdao: "",
    swtcCcdao: "",
    ethAddress: "",
    swtcAddress: "",
    myEthNum: 0,
    mySwtcNum: 0,
  },
  getters: {
    isHave(state) {
      return state.swtcAddress !== "" || state.ethAddress !== "";
    },
    myCCDAONum(state) {
      return state.mySwtcNum + state.myEthNum;
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
    setMyEthNumData(state, data) {
      state.myEthNum = Number(data);
    },
    setMySwtcNumData(state, data) {
      state.mySwtcNum = Number(data);
    },
  },
  actions: {
    setValue(isstore, res) {
      isstore.commit("setData", res);
    },
    setMySwtcNum(isStore) {
      axios
        .get(
          "https://swtcscan.jccdex.cn/wallet/balance/" + isStore.state.swtcAddress + "?w=" + isStore.state.swtcAddress
          // "https://swtcscan.jccdex.cn/wallet/balance/" + "jsk45ksJZUB7durZrLt5e86Eu2gtiXNRN4" + "?w=" + "jsk45ksJZUB7durZrLt5e86Eu2gtiXNRN4"
        )
        .then((response) => {
          console.log(1);
          isStore.commit("setMySwtcNumData", response.data.data.CCDAO_jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or.value);
        })
        .catch(function (error) {
          console.log(error);
        });
    },
    async setMyEthNum(isStore) {
      if (isStore.state.ethAddress === "") {
        isStore.commit("setMyEthNumData", 0);
        return;
      }

      let chainId = 1;
      let web3 = window.web3;
      let multicallAddress = "0xeefba1e63905ef1d7acba5a8513c70307c1ce441";

      // let account = normalizeAccount("0x3907acb4c1818adf72d965c08e0a79af16e7ffb8");
      let account = normalizeAccount(isStore.state.ethAddress);
      const currentProvider = web3.currentProvider;
      const web3Provider = new Web3Provider(currentProvider, chainId);
      let swapContract = new SwapContract(account, multicallAddress, web3Provider);
      let swapMulticall = new SwapMulticall(chainId, web3, swapContract);
      let swapBalance = new SwapBalance(swapMulticall);
      const token = new Token(chainId, "0x1487Bd704Fa05A222B0aDB50dc420f001f003045", 18);
      let num = await (await swapBalance.useTokenBalance(account, token)).toSignificant(10);
      isStore.commit("setMyEthNumData", num);
    },
  },
  modules: {},
});
