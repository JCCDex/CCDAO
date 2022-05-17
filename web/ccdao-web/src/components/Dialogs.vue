<template>
  <div class="dialogbox">
    <div class="walletbox">
      <div v-show="MetaMask != ''">
        <div style="display: flex; margin-top: 20px; margin-left: 20px">
          <img src="../assets/MetaMaketag.svg" />
          <p style="margin: 0px; margin-left: 10px; color: rgba(146, 146, 146, 1)">{{ $t("ETH Wallet Address") }}</p>
        </div>
        <div style="width: 270px; margin-top: 10px; margin-left: 20px; height: 60px">
          <span style="word-wrap: break-word; font-size: 14px; line-height: 24px">{{ MetaMask }}</span>
          <button
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
          </button>
        </div>
      </div>
      <div v-show="WalletAddress != ''">
        <div style="display: flex; margin-top: 20px; margin-left: 20px">
          <img src="../assets/SWTCtag.svg" />
          <p style="margin: 0px; margin-left: 10px; color: rgba(146, 146, 146, 1)">{{ $t("SWTC Wallet Address") }}</p>
        </div>
        <div style="width: 270px; margin-top: 10px; margin-left: 20px; height: 60px">
          <span style="word-wrap: break-word; font-size: 14px; line-height: 24px">{{ WalletAddress }}</span>
          <button
            @click="showdialog()"
            style="
              background: none;
              float: right;
              margin-right: 17px;
              margin-top: 5px;
              font-size: 12px;
              color: rgba(71, 116, 175, 1);
            "
          >
            {{ $t("Switch SWTC Wallet") }}
          </button>
        </div>
      </div>
      <div
        v-show="MetaMask != '' || WalletAddress != ''"
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
        v-show="MetaMask == '' && WalletAddress == ''"
        style="text-align: center; margin-top: 30px; margin-bottom: 0px"
      >
        {{ $t("Connect Wallet") }}
      </p>
      <button v-show="MetaMask == ''" class="WB" style="margin-left: 20px; margin-top: 25px" @click="loginMetaMask()">
        {{ $t("Connect MetaMask") }}
      </button>
      <button v-show="WalletAddress == ''" class="WB" style="margin-left: 20px; margin-top: 25px" @click="showdialog()">
        {{ $t("Import SWTC Wallet") }}
      </button>
    </div>
  </div>
</template>

<script>
import ImportDialog from "./dialog/index";
import { JingchangWallet } from "jcc_wallet";
import { EventBus } from "../Bus.js";

export default {
  name: "Dialogs",
  data() {
    return {
      MetaMask: "",
      WalletAddress: "",
    };
  },
  computed: {},
  async created() {
    let value;
    let wallet;
    this.loginMetaMask();
    value = JingchangWallet.get();
    if (value != null) {
      wallet = new JingchangWallet(value);
      this.WalletAddress = await wallet.getAddress();
    }
    EventBus.$emit("ishave", "true");
    EventBus.$emit("SWTC", this.WalletAddress);
  },
  mounted() {
    EventBus.$on("aMsg", (SWTCaddress) => {
      this.WalletAddress = SWTCaddress;
      EventBus.$emit("ishave", "true");
      EventBus.$emit("SWTC", this.WalletAddress);
    });
  },
  methods: {
    //登录MetaMask
    async loginMetaMask() {
      if (typeof window.ethereum !== undefined) {
        let addr = await ethereum.request({ method: "eth_requestAccounts" });
        this.MetaMask = addr[0];
      } else {
        console.log("未安装插件");
      }
      EventBus.$emit("ishave", "true");
      EventBus.$emit("ETH", this.MetaMask);
    },
    //显示对话框
    showdialog() {
      ImportDialog().show();
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
  border: none;
  width: 260px;
  height: 40px;
  background: rgba(255, 255, 255, 1);
  background-blend-mode: normal;
  color: rgba(67, 162, 244, 1);
  border: 1px solid rgba(229, 232, 238, 1);
  border-radius: 18px;
  mix-blend-mode: normal;
}
.WB:hover {
  border: none;
  width: 260px;
  height: 40px;
  background: rgba(67, 162, 244, 1);
  background-blend-mode: normal;
  border-radius: 21.5px;
  mix-blend-mode: normal;
  color: rgba(255, 255, 255, 1);
}
</style>
