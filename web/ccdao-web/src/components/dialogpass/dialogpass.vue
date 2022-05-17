<template>
  <el-dialog
    :title="$t('交易密码')"
    :visible.sync="visiblepass"
    width="360px"
    :show-close="false"
    :center="true"
    :modal-append-to-body="false"
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
      <el-button @click="(visiblepass = false), (password = '')">{{ $t("取 消") }}</el-button>
      <!-- <el-button type="primary" @click="dialogVisible2 = false">确 定</el-button> -->
      <el-button type="primary" :disabled="password == ''" @click="finishwallet()">{{ $t("确 定") }}</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { JingchangWallet } from "jcc_wallet";
import { importFile } from "jcc_file";
import { EventBus } from "../../Bus.js";

export default {
  name: "dialogpass",
  data() {
    return {
      visiblepass: false,
      password: "",
      value: undefined,
      textarea: "",
    };
  },
  methods: {
    //控制对话框显示函数
    show(text, file) {
      this.textarea = text;
      this.value = file;
      this.visiblepass = true;
    },
    //完成钱包登录
    async finishwallet() {
      let wallet;
      if (this.textarea != "") {
        this.value = await JingchangWallet.generate(this.password, this.textarea);
        this.password = "";
        wallet = new JingchangWallet(this.value);
      } else {
        let walletvalue = await importFile(this.value);
        wallet = new JingchangWallet(JSON.parse(walletvalue));
        try {
          await wallet.getSecretWithType(this.password);
        } catch (error) {
          console.log("错误！");
          return;
        }
        this.password = "";
      }
      JingchangWallet.save(this.value);
      let SWTCaddress = await wallet.getAddress();
      this.visiblepass = false;
      EventBus.$emit("aMsg", SWTCaddress);
    },
  },
};
</script>

<style></style>
