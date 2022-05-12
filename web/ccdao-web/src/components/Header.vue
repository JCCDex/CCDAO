<template>
  <div class="box">
    <img class="boximg" src="../assets/CCDAO.svg" />
    <div class="downorder" style="margin-left: 17.5%; margin-top: 12px">
      <button class="ComunityCss">{{ $t("Comunity") }} &nbsp;<img src="../assets/downchart.svg" /></button>
      <div class="ordertext">
        <a href="">{{ $t("Twitter") }}</a>
        <a href="">{{ $t("Discord") }}</a>
        <a href="">{{ $t("Telegram") }}</a>
      </div>
    </div>
    <div class="downorder" style="margin-left: 30px; margin-top: 12px">
      <button class="ComunityCss">$CCDAO &nbsp;<img src="../assets/downchart.svg" /></button>
      <div class="ordertext">
        <a href="#Holds">{{ $t("Holding") }}</a>
        <a href="#ToBuy">{{ $t("How to Buy") }}</a>
        <a href="#WebAdd">{{ $t("Contract Address") }}</a>
      </div>
    </div>
    <a href="#Member" class="buttons" style="margin-left: 30px; margin-top: 12px">{{ $t("Membership") }}</a>
    <a href="#Signers" class="buttons" style="margin-left: 10px; margin-top: 12px">{{ $t("Multi-Signers") }}</a>
    <!-- <div class="downorder1" style="margin-left: 160px;margin-top: 12px;"> -->
    <div class="downorder1" style="margin-right: 2%; margin-top: 12px">
      <button class="wallet" style="margin-left: 100px; margin-top: 0px">
        <img src="../assets/connectwallet.svg" v-show="loginnum == 0" />
        <img src="../assets/mywallet.svg" v-show="loginnum != 0" />
      </button>
      <div class="walletbox">
        <div v-show="loginnum == 1 || loginnum == 3">
          <div style="display: flex; margin-top: 20px; margin-left: 20px">
            <img src="../assets/MetaMaketag.svg" />
            <p style="margin: 0px; color: rgba(146, 146, 146, 1)">ETH Wallet Address</p>
          </div>
          <div style="width: 270px; margin-top: 10px; margin-left: 20px; height: 60px">
            <span style="word-wrap: break-word; font-size: 14px; line-height: 24px">{{ MetaMaskaddr }}</span>
            <span
              style="float: right; margin-right: 17px; margin-top: 5px; font-size: 12px; color: rgba(71, 116, 175, 1)"
              >Switch ETH Wallet</span
            >
          </div>
        </div>
        <div v-show="loginnum == 2 || loginnum == 3">
          <div style="display: flex; margin-top: 20px; margin-left: 20px">
            <img src="../assets/SWTCtag.svg" />
            <p style="margin: 0px; color: rgba(146, 146, 146, 1)">SWTC Wallet Address</p>
          </div>
          <div style="width: 270px; margin-top: 10px; margin-left: 20px; height: 60px">
            <span style="word-wrap: break-word; font-size: 14px; line-height: 24px">{{ Walletaddr }}</span>
            <span
              style="float: right; margin-right: 17px; margin-top: 5px; font-size: 12px; color: rgba(71, 116, 175, 1)"
              >Switch ETH Wallet</span
            >
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

        <p v-show="loginnum == 0" style="margin-bottom: 0px">{{ $t("Connect Wallet") }}</p>
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
          @click="(dialogVisible1 = true), (n = 0), (dlinput = true), (dlimport = false)"
          class="WB"
          style="margin-left: 20px; margin-top: 25px"
        >
          {{ $t("Import SWTC Wallet") }}
        </button>
      </div>

      <el-dialog
        :visible.sync="dialogVisible1"
        width="360px"
        :show-close="false"
        :center="true"
        :modal-append-to-body="false"
      >
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
              <img src="../assets/cleartag.svg" @click="clearFile()" />
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
          <el-button
            type="primary"
            @click="(dialogVisible1 = false), (dialogVisible2 = true)"
            :disabled="isInputbool"
            >{{ $t("确 定") }}</el-button
          >
        </span>
        <!-- 导入SWTC钱包 -->
        <span
          v-show="dlimport"
          slot="footer"
          class="dialog-footer"
          style="width: 320px; display: flex; justify-content: space-between"
        >
          <el-button @click="dialogVisible1 = false">{{ $t("取 消") }}</el-button>
          <el-button
            type="primary"
            @click="(dialogVisible1 = false), (dialogVisible2 = true)"
            :disabled="isInputbool1"
            >{{ $t("确 定") }}</el-button
          >
        </span>
      </el-dialog>

      <el-dialog
        :title="$t('交易密码')"
        :visible.sync="dialogVisible2"
        width="360px"
        :show-close="false"
        :center="true"
        :modal-append-to-body="false"
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
  </div>
</template>

<script>
import { jtWallet } from "jcc_wallet";
import { importFile } from "jcc_file";
import { JingchangWallet } from "jcc_wallet";

export default {
  name: "Header",
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
  },
  data() {
    return {
      dialogVisible1: false,
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
    },
    clearFile() {
      this.filename = "";
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
        JingchangWallet.save(value);
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
        JingchangWallet.save(value);
        this.password = "";
      }
      this.loginnum += 2;
      this.Walletaddr = await wallet.getAddress();
    },
  },
};
</script>

<style>
.box {
  width: 100%;
  height: 60px;
  background: rgba(246, 249, 253, 1);
  background-blend-mode: normal;
  box-shadow: 0px 1px 5px rgba(201, 223, 240, 1);
  mix-blend-mode: normal;
}
.boximg {
  margin-left: 47px;
  margin-top: 10px;
  width: 139px;
  height: 40px;
  float: left;
}
.downorder {
  width: 100px;
  height: auto;
  position: relative;
  float: left;
}
.downorder:hover .ComunityCss {
  background-color: rgba(230, 236, 243, 1);
}
.downorder:hover .ordertext {
  display: block;
}
.downorder:hover a {
  display: block;
}
.ComunityCss {
  width: 120px;
  height: 36px;
  background-color: rgba(246, 249, 253, 1);
  background-blend-mode: normal;
  border-radius: 3px;
  mix-blend-mode: normal;
  text-align: center;
  border: none;
  float: left;
  font-family: PingFangSC-Medium, sans-serif;
}
.ordertext {
  width: 120px;
  height: 140px;
  margin-top: 12px;
  background: rgba(255, 255, 255, 1);
  background-blend-mode: normal;
  border: 1px solid rgba(251, 252, 254, 1);
  box-shadow: 0px 2px 4px rgba(228, 237, 246, 0.5);
  border-radius: 3px;
  float: left;
  text-align: center;
  font-size: 14px;
  font-family: PingFangSC-Medium, sans-serif;
  display: none;
}
.ordertext a {
  width: 120px;
  height: 40px;
  vertical-align: middle;
  line-height: 40px;
  border-radius: 3px;
  mix-blend-mode: normal;
  text-decoration: none;
  color: rgba(108, 116, 124, 1);
  display: none;
}
.ordertext a:hover {
  background: rgba(244, 246, 248, 1);
  background-blend-mode: normal;
  color: rgba(12, 40, 69, 1);
}
.buttons {
  width: 120px;
  height: 36px;
  color: rgba(12, 40, 69, 1);
  background-blend-mode: normal;
  border-radius: 3px;
  mix-blend-mode: normal;
  text-align: center;
  text-decoration: none;
  float: left;
  /* 文字上下居中 */
  vertical-align: middle;
  line-height: 36px;
  font-family: PingFangSC-Medium, sans-serif;
}
.buttons:hover {
  background-color: rgba(230, 236, 243, 1);
}

.downorder1 {
  width: 300px;
  height: auto;
  position: relative;
  float: right;
  font-family: PingFangSC-Medium, sans-serif;
}
.downorder1:hover .walletbox {
  display: block;
}
.wallet {
  border: none;
  width: 180px;
  height: 36px;
  background: rgba(255, 255, 255, 1);
  background-blend-mode: normal;
  box-shadow: 0px 0px 4px 2px rgba(237, 240, 242, 1);
  border-radius: 18px;
  mix-blend-mode: normal;
  font-family: PingFangSC-Medium, sans-serif;
}
.walletbox {
  position: relative;
  margin-top: 12px;
  width: 300px;
  height: 220px;
  background: rgba(255, 255, 255, 1);
  background-blend-mode: normal;
  border: 1px solid rgba(216, 221, 230, 1);
  box-shadow: 2px 2px 6px rgba(225, 229, 234, 1);
  border-radius: 16px;
  mix-blend-mode: normal;
  display: none;
  font-family: PingFangSC-Medium, sans-serif;
}
.downorder1 p {
  position: relative;
  margin-left: auto;
  margin-right: auto;
  margin-top: 24px;
  text-align: center;
  width: 172px;
  height: 20px;
  mix-blend-mode: normal;
  color: rgba(12, 40, 69, 1);
  font-size: 16px;
  font-family: PingFangSC-Medium, sans-serif;
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
