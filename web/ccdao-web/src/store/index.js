import Vue from "vue";
import Vuex from "vuex";
import axios from "axios";

import { Token, SwapContract, SwapMulticall, SwapBalance } from "@jccdex/ethereum-contract";
import { Web3Provider } from "@ethersproject/providers";
import { normalizeAccount } from "@jccdex/ethereum-contract/lib/utils/normalizers";
import BigNumber from "bignumber.js";

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    totalVolumeTraded: "",
    fullyDilutedValuation: "",
    ethCcdao: "",
    swtcCcdao: "",
    polygonCcdao: "",
    bscCcdao: "",
    hecoCcdao: "",
    ethAddress: "",
    swtcAddress: "",
    isNetWork: true,
    myEthNum: 0,
    mySwtcNum: 0,
    sidebarBool: false,
    isTp: false,
  },
  getters: {
    isHave(state) {
      return state.swtcAddress !== "" || state.ethAddress !== "";
    },
    myCCDAONum(state) {
      return new BigNumber(state.mySwtcNum).plus(state.myEthNum).toNumber();
    },
  },
  mutations: {
    setData(state, res) {
      state.totalVolumeTraded = res.totalVolumeTraded;
      state.fullyDilutedValuation = res.fullyDilutedValuation;
      state.ethCcdao = res.ETH;
      state.swtcCcdao = res.SWT;
      state.polygonCcdao = res.POLYGON;
      state.bscCcdao = res.BSC;
      state.hecoCcdao = res.HECO;
    },
    setEthAddress(state, data) {
      state.ethAddress = data;
    },
    setSwtcAddress(state, data) {
      state.swtcAddress = data;
    },
    setMyEthNumData(state, data) {
      state.myEthNum = data;
    },
    setMySwtcNumData(state, data) {
      state.mySwtcNum = data;
    },
    setIsNetWork(state, data) {
      state.isNetWork = data;
    },
    showSidebar(state) {
      state.sidebarBool = true;
    },
    downSidebar(state) {
      state.sidebarBool = false;
    },
    setIsTp(state, data) {
      state.isTp = data;
    },
  },
  actions: {
    setValue(isstore, res) {
      isstore.commit("setData", res);
    },
    async setMySwtcNum(isStore) {
      try {
        const res = await axios.get(
          "https://swtcscan.jccdex.cn/wallet/balance/" + isStore.state.swtcAddress + "?w=" + isStore.state.swtcAddress
        );
        const value = res.data.data.CCDAO_jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or.value;
        isStore.commit("setMySwtcNumData", value);
      } catch (error) {
        isStore.commit("setMySwtcNumData", 0);
      }
    },
    async setMyEthNum(isStore) {
      if (isStore.state.ethAddress === "") {
        isStore.commit("setMyEthNumData", 0);
        return;
      }

      try {
        let chainId = 1;
        let web3 = window.web3;
        let multicallAddress = "0xeefba1e63905ef1d7acba5a8513c70307c1ce441";
        let account = normalizeAccount(isStore.state.ethAddress);
        const currentProvider = web3.currentProvider;
        const web3Provider = new Web3Provider(currentProvider, chainId);
        let swapContract = new SwapContract(account, multicallAddress, web3Provider);
        let swapMulticall = new SwapMulticall(chainId, web3, swapContract);
        let swapBalance = new SwapBalance(swapMulticall);
        const token = new Token(chainId, "0x1487Bd704Fa05A222B0aDB50dc420f001f003045", 18);
        const amount = await swapBalance.useTokenBalance(account, token);
        isStore.commit("setMyEthNumData", amount.toSignificant(10));
      } catch (error) {
        isStore.commit("setMyEthNumData", 0);
      }
    },
  },
  modules: {},
});
