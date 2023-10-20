<template>
  <div class="dialogbox">
    <div class="walletbox">
      <div v-show="ethAddress != ''">
        <div style="display: flex; margin-top: 20px; margin-left: 20px; align-items: center">
          <img src="../assets/MetaMaketag.svg" />
          <p style="margin: 0px; margin-left: 10px; color: rgba(146, 146, 146, 1)">
            {{ $t("message.ETH_Wallet_Address") }}
          </p>
        </div>
        <div style="width: 270px; margin-top: 10px; margin-left: 20px; height: 60px">
          <span style="word-wrap: break-word; font-size: 14px; line-height: 24px">{{ ethAddress }}</span>
          <!-- <button
            @click="loginMetaMask()"
            style="
              background: none;
              float: right;
              margin-right: 17px;
              margin-top: 5px;
              font-size: 12px;
              color: rgba(71, 116, 175, 1);
            "
          >
            {{ $t("Switch ETH Wallet") }}
          </button> -->
        </div>
      </div>
      <div v-show="swtcAddress != ''">
        <div style="display: flex; margin-top: 20px; margin-left: 20px; align-items: center">
          <img src="../assets/SWTCtag.svg" />
          <p style="margin: 0px; margin-left: 10px; color: rgba(146, 146, 146, 1)">
            {{ $t("message.SWTC_Wallet_Address") }}
          </p>
        </div>
        <div style="width: 270px; margin-top: 10px; margin-left: 20px; height: 60px">
          <span style="word-wrap: break-word; font-size: 14px; line-height: 24px">{{ swtcAddress }}</span>
          <button
            @click="showdialog()"
            v-show="!haveCcdaoPlugin"
            style="
              background: none;
              float: right;
              margin-right: 17px;
              margin-top: 5px;
              font-size: 12px;
              color: rgba(71, 116, 175, 1);
            "
          >
            {{ $t("message.Switch_SWTC_Wallet") }}
          </button>
        </div>
      </div>
      <div
        v-show="ethAddress != '' || swtcAddress != ''"
        style="
          position: absolute;
          top: 115px;
          width: 260px;
          height: 1px;
          background: rgba(231, 231, 233, 1);
          margin-left: 20px;
        "
      ></div>

      <p
        v-show="ethAddress == '' && swtcAddress == ''"
        style="text-align: center; margin-top: 30px; margin-bottom: 0px"
      >
        {{ $t("message.Connect_Wallet") }}
      </p>
      <button v-show="ethAddress == ''" class="WB" style="margin-left: 20px; margin-top: 25px" @click="loginMetaMask()">
        {{ $t("message.Connect_MetaMask") }}
      </button>
      <button v-show="swtcAddress == ''" class="WB" style="margin-left: 20px; margin-top: 25px" @click="showdialog()">
        {{ $t("message.Import_SWTC_Wallet") }}
      </button>
    </div>
  </div>
</template>

<script>
import ImportDialog from "./dialog/index";
import { JingchangWallet } from "jcc_wallet";

export default {
  name: "Dialogs",
  data() {
    return {
      WalletAddress: "",
      haveCcdaoPlugin: window.ccdao ? true : false,
    };
  },
  computed: {
    ethAddress() {
      return this.$store.state.ethAddress;
    },
    swtcAddress() {
      return this.$store.state.swtcAddress;
    },
  },
  async created() {
    let value;
    let wallet;
    this.loginMetaMask();
    this.loginCCDAO();
    value = JingchangWallet.get();
    if (value != null) {
      wallet = new JingchangWallet(value);
      this.WalletAddress = await wallet.getAddress();
      this.$store.commit("setSwtcAddress", this.WalletAddress);
      this.$store.dispatch("setMySwtcNum");
    }
  },
  methods: {
    //登录MetaMask
    async loginMetaMask() {
      var tp = require("tp-js-sdk");
      if (tp.isConnected()) {
        tp.getWallet({ walletTypes: ["eth"], switch: false }).then((req) => {
          if (req.data.address !== undefined) this.$store.commit("setEthAddress", req.data.address);
        });
      } else if (window.ethereum) {
        let addr = await ethereum.request({ method: "eth_requestAccounts" });
        this.$store.commit("setEthAddress", addr[0]);
        this.$store.dispatch("setMyEthNum");
        let ethNetWork = ["1"];

        if (ethNetWork.indexOf(window.ethereum.networkVersion) < 0) {
          this.$store.commit("setIsNetWork", false);
        } else {
          this.$store.commit("setIsNetWork", true);
        }
      } else {
        console.log("未安装插件");
      }
    },
    //连接CCDAO插件
    async loginCCDAO() {
      if (window.ccdao) {
        let addr = await ethereum.request({ method: "swtc_requestAccounts" });
        this.$store.commit("setSwtcAddress", addr[0] === undefined ? "" : addr[0]);
      }
    },
    //显示对话框或移动端连接SWTC钱包
    async showdialog() {
      var tp = require("tp-js-sdk");
      if (tp.isConnected()) {
        tp.getWallet({ walletTypes: ["jingtum"], switch: false }).then((req) => {
          if (req.data.address !== undefined) {
            this.$store.commit("setSwtcAddress", req.data.address);
          }
        });
      } else if (window.ccdao) {
        let addr = await ethereum.request({ method: "swtc_requestAccounts" });
        this.$store.commit("setSwtcAddress", addr[0] === undefined ? "" : addr[0]);
      } else {
        ImportDialog().show();
        if (this.isMobile) {
          setTimeout(() => {
            this.$message.error(this.$t("message.no_ccdao_plugin"));
          }, 100);
        }
      }
    },
    isMobile() {
      let flag = navigator.userAgent.match(
        /(phone|pad|pod|iPhone|iPod|ios|iPad|Android|Mobile|BlackBerry|IEMobile|MQQBrowser|JUC|Fennec|wOSBrowser|BrowserNG|WebOS|Symbian|Windows Phone)/i
      );
      return flag;
    },
  },
};
</script>

<style>
button {
  border: none;
  cursor: pointer;
}
.dialogbox {
  width: 300px;
  height: 220px;
  background: rgba(255, 255, 255, 1);
  border: 1px solid rgba(216, 221, 230, 1);
  box-shadow: 2px 2px 6px rgba(225, 229, 234, 1);
  border-radius: 16px;
}

.walletbox {
  display: flex;
  flex-direction: column;
}
.WB {
  font-size: 14px;
  border: none;
  width: 260px;
  height: 40px;
  background: rgba(255, 255, 255, 1);
  background-blend-mode: normal;
  color: #3595e8;
  border: 1px solid rgba(229, 232, 238, 1);
  border-radius: 18px;
  mix-blend-mode: normal;
  border: 1px solid rgba(67, 162, 244, 1);
}
.WB:hover {
  border: none;
  width: 260px;
  height: 40px;
  background: #3595e8;
  background-blend-mode: normal;
  border-radius: 21.5px;
  mix-blend-mode: normal;
  color: rgba(255, 255, 255, 1);
}
</style>
