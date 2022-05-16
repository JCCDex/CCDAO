<template>
  <div class="dialogbox">
    <div class="walletbox">
      <div v-show="loginnum == 1 || loginnum == 3">
        <div style="display: flex; margin-top: 20px; margin-left: 20px">
          <img src="../assets/MetaMaketag.svg" />
          <p style="margin: 0px; margin-left: 10px; color: rgba(146, 146, 146, 1)">{{ $t("ETH Wallet Address") }}</p>
        </div>
        <div style="width: 270px; margin-top: 10px; margin-left: 20px; height: 60px">
          <span style="word-wrap: break-word; font-size: 14px; line-height: 24px">{{ MetaMaskaddr }}</span>
          <button
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
      <div v-show="loginnum == 2 || loginnum == 3">
        <div style="display: flex; margin-top: 20px; margin-left: 20px">
          <img src="../assets/SWTCtag.svg" />
          <p style="margin: 0px; margin-left: 10px; color: rgba(146, 146, 146, 1)">{{ $t("SWTC Wallet Address") }}</p>
        </div>
        <div style="width: 270px; margin-top: 10px; margin-left: 20px; height: 60px">
          <span style="word-wrap: break-word; font-size: 14px; line-height: 24px">{{ Walletaddr }}</span>
          <button
            @click="showImportDialog"
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
        v-show="loginnum != 0"
        style="
          position: absolute;
          top: 115px;
          width: 260px;
          height: 1px;
          background: rgba(231, 231, 233, 1);
          margin-left: 20px;
        "
      ></div>

      <p v-show="loginnum == 0" style="text-align: center; margin-top: 30px; margin-bottom: 0px">
        {{ $t("Connect Wallet") }}
      </p>
      <button
        v-show="loginnum == 2 || loginnum == 0"
        class="WB"
        style="margin-left: 20px; margin-top: 25px"
        @click="loginMetaMask()"
      >
        {{ $t("Connect MetaMask") }}
      </button>
      <button
        v-show="loginnum == 1 || loginnum == 0"
        @click="showImportDialog"
        class="WB"
        style="margin-left: 20px; margin-top: 25px"
      >
        {{ $t("Import SWTC Wallet") }}
      </button>
    </div>
    <el-dialog
      :title="$t('交易密码')"
      :visible.sync="dialogVisible2"
      width="360px"
      :show-close="false"
      :center="true"
      :modal-append-to-body="true"
      :close-on-click-modal="false"
    >
      <div style="width: 360px; padding-top: 80px; padding-left: 20px; padding-right: 20px">
        <el-input :placeholder="$t('请输入交易密码')" v-model="password" show-password clearable></el-input>
      </div>

      <span
        slot="footer"
        class="dialog-footer"
        style="width: 320px; display: flex; justify-content: space-between; padding-top: 15px"
      >
        <el-button @click="dialogVisible2 = false">{{ $t("取 消") }}</el-button>
        <!-- <el-button type="primary" @click="dialogVisible2 = false">确 定</el-button> -->
        <el-button type="primary" @click="createWallet(), (dialogVisible2 = false)" :disabled="isPassbool">{{
          $t("确 定")
        }}</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { jtWallet } from "jcc_wallet";
import { importFile } from "jcc_file";
import { JingchangWallet } from "jcc_wallet";
import ImportDialog from "./import-dialog/index";
export default {
  name: "Dialogs",
  async created() {
    let value;
    let wallet;
    this.loginMetaMask();
    value = JingchangWallet.get();
    if (value != null) {
      wallet = new JingchangWallet(JSON.parse(value));
      this.Walletaddr = await wallet.getAddress();
      this.loginnum += 2;
    }
    this.$emit("getlogin", this.loginnum);
  },
  data() {
    return {
      textarea: "",
      n: 0,
      dlinput: false,
      dlimport: false,

      dialogVisible2: false,
      password: "",

      filename: "",
      file: undefined,

      Walletaddr: "",
      MetaMaskaddr: "",

      loginnum: 0,
    };
  },
  computed: {
    dlbts1() {
      return this.n == 0 ? "dlbt1" : "dlbt";
    },
    dlbts2() {
      return this.n == 1 ? "dlbt1" : "dlbt";
    },
    isInputbool() {
      return jtWallet.isValidSecret(this.textarea) ? false : true;
    },
    isInputbool1() {
      return this.filename == "" ? true && this.dlimport : false && this.dlimport;
    },
    isPassbool() {
      return this.password == "" ? true : false;
    },
    filebool() {
      return this.filename == "" ? true && this.dlimport : false && this.dlimport;
    },
  },
  methods: {
    async loginMetaMask() {
      if (typeof window.ethereum !== undefined) {
        let addr = await ethereum.request({ method: "eth_requestAccounts" });
        this.MetaMaskaddr = addr[0];
        this.loginnum += 1;
      } else {
        console.log("未安装插件");
      }
      this.$emit("getlogin", this.loginnum);
    },
    async importFile(e) {
      this.filename = e.target.files[0].name;
      this.file = e;
    },
    showImportDialog() {
      console.log("aaaa");
      ImportDialog().show();
    },
    async createWallet() {
      let value;
      let wallet;
      if (this.dlinput) {
        value = await JingchangWallet.generate(this.password, this.textarea);
        this.password = "";
        wallet = new JingchangWallet(value);
      } else {
        value = await importFile(this.file);
        wallet = new JingchangWallet(JSON.parse(value));
        try {
          await wallet.getSecretWithType(this.password);
        } catch (error) {
          console.log("错误！");
          return;
        }
        this.password = "";
      }
      if (this.loginnum >= 2) {
        this.loginnum -= 2;
      }
      JingchangWallet.save(value);
      this.loginnum += 2;
      this.Walletaddr = await wallet.getAddress();
      this.$emit("getlogin", this.loginnum);
    },
    clearFile() {
      this.filename = "";
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
  font-family: PingFangSC-Medium, sans-serif;
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
  font-family: PingFangSC-Medium, sans-serif;
}
.dlbtcss {
  margin-top: 20px;
  bottom: 30px;
  display: flex;
  justify-content: center;
  height: 40px;
}
.dlbt {
  width: 160px;
  height: 40px;
  background-blend-mode: normal;
  mix-blend-mode: normal;
  font-family: PingFangSC-Medium, sans-serif;
  border: 1px solid rgba(216, 230, 254, 1);
  background: rgba(242, 246, 253, 1);
  color: rgba(120, 127, 147, 1);
}
.dlbt1 {
  width: 160px;
  height: 40px;
  background-blend-mode: normal;
  mix-blend-mode: normal;
  font-family: PingFangSC-Medium, sans-serif;
  border: 1px solid rgba(216, 230, 254, 1);
  background: rgba(74.35800000000002, 147.0636, 206.55, 1);
  color: rgba(255, 255, 255, 1);
}
.dlcss {
  margin-top: 30px;
  display: flex;
  justify-content: center;
}
.importbtcss {
  position: relative;
  margin-top: 20px;
  width: 320px;
  height: 50px;
  background: rgba(209, 230, 248, 1);
  background-blend-mode: normal;
  border: 1px solid rgba(220, 230, 242, 1);
  border-radius: 25px;
  mix-blend-mode: normal;
}
.importbtcss p {
  margin-top: 12px;
  width: 155px;
  height: 21px;
  mix-blend-mode: normal;
  color: rgba(43, 53, 81, 1);
  font-size: 14px;
}
.importbtcss input {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 50px;
  cursor: pointer;
  opacity: 0;
}
</style>
