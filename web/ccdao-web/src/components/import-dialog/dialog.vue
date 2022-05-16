<template>
  <el-dialog :visible.sync="visible" width="360px" :show-close="false" :center="true" :close-on-click-modal="false">
    <div slot="title">{{ $t("message.导入SWTC钱包") }}</div>
    <div class="dlbtcss">
      <button
        :class="dlbts1"
        @click="(n = 0), (dlinput = true), (dlimport = false)"
        style="border-top-left-radius: 25px; border-bottom-left-radius: 25px"
      >
        {{ $t("SWTC钱包密钥") }}
      </button>
      <button
        :class="dlbts2"
        @click="(n = 1), (dlinput = false), (dlimport = true)"
        style="border-top-right-radius: 25px; border-bottom-right-radius: 25px"
      >
        {{ $t("SWTC文件") }}
      </button>
    </div>
    <div class="dlcss" v-show="dlinput">
      <div style="width: 320px">
        <el-input
          class="dltext"
          type="textarea"
          :rows="2"
          :placeholder="$t('message.请输入SWTC钱包密钥')"
          v-model="textarea"
        >
        </el-input>
      </div>
    </div>
    <div class="dlcss" v-show="dlimport">
      <button class="importbtcss">
        <p v-show="filebool">{{ $t("点击导入SWTC文件") }}</p>
        <div v-show="!filebool" style="display: flex; justify-content: center">
          <p style="color: rgba(0, 0, 0, 1); margin-left: 0px">{{ filename }}</p>
          <img src="../../assets/cleartag.svg" @click="clearFile()" />
        </div>
        <input type="file" @change="importFile" v-show="filebool" />
      </button>
    </div>
    <!-- 输入钱包密钥 -->
    <span
      v-show="dlinput"
      slot="footer"
      class="dialog-footer"
      style="width: 320px; display: flex; justify-content: space-between"
    >
      <el-button @click="dialogVisible1 = false">{{ $t("取 消") }}</el-button>
      <el-button type="primary" @click="(dialogVisible1 = false), (dialogVisible2 = true)" :disabled="isInputbool">{{
        $t("确 定")
      }}</el-button>
    </span>
    <!-- 导入SWTC钱包 -->
    <span
      v-show="dlimport"
      slot="footer"
      class="dialog-footer"
      style="width: 320px; display: flex; justify-content: space-between"
    >
      <el-button @click="dialogVisible1 = false">{{ $t("取 消") }}</el-button>
      <el-button type="primary" @click="(dialogVisible1 = false), (dialogVisible2 = true)" :disabled="isInputbool1">{{
        $t("确 定")
      }}</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { jtWallet } from "jcc_wallet";
import { importFile } from "jcc_file";
import { JingchangWallet } from "jcc_wallet";

export default {
  name: "Dialogs",
  data() {
    return {
      visible: false,
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
    show() {
      this.visible = true;
    },
    async importFile(e) {
      this.filename = e.target.files[0].name;
      this.file = e;
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
      JingchangWallet.save(value);
      this.Walletaddr = await wallet.getAddress();
      this.$emit("getlogin", this.loginnum);
    },
    clearFile() {
      this.filename = "";
    },
  },
};
</script>

<style scoped>
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
