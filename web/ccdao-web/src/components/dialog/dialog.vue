<template>
  <el-dialog :visible.sync="visible" width="360px" :show-close="false" :center="true" :close-on-click-modal="false">
    <div slot="title">{{ $t("message.import_swt_wallet") }}</div>
    <!-- 切换按钮 -->
    <div class="dlbtcss">
      <button
        :class="btbool ? 'dlbt1' : 'dlbt'"
        @click="(btbool = true), clearData(), (btname = 'SecretKey')"
        style="border-top-left-radius: 25px; border-bottom-left-radius: 25px"
      >
        {{ $t("message.swt_wallet_secret") }}
      </button>
      <button
        :class="btbool ? 'dlbt' : 'dlbt1'"
        @click="(btbool = false), clearData(), (btname = 'ImportFile')"
        style="border-top-right-radius: 25px; border-bottom-right-radius: 25px"
      >
        {{ $t("message.swt_file") }}
      </button>
    </div>
    <component :is="btname"></component>

    <!-- 对话框底部按钮 -->
    <span slot="footer" class="dialog-footer" style="width: 320px; display: flex; justify-content: space-between">
      <el-button @click="(visible = false), clearData()">{{ $t("message.cancel") }}</el-button>
      <el-button type="primary" :disabled="!istextarea && file === undefined" @click="nextshow()">{{
        $t("message.confirm")
      }}</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { jtWallet } from "jcc_wallet";
import ImportDialogpass from "../dialogpass/index";
import SecretKey from "./SecretKey";
import ImportFile from "./ImportFile";
import { EventBus } from "../../Bus.js";

export default {
  name: "Dialog",
  components: {
    SecretKey,
    ImportFile,
  },
  data() {
    return {
      visible: false,
      btbool: true,
      btname: "",

      textarea: "",
      filename: "",
      file: undefined,
    };
  },
  computed: {
    istextarea() {
      return jtWallet.isValidSecret(this.textarea);
    },
  },
  mounted() {
    EventBus.$on("textarea", (text) => {
      this.textarea = text;
    });
    EventBus.$on("file", (f, fname) => {
      this.file = f;
      this.filename = fname;
    });
  },
  methods: {
    //控制对话框显示函数
    show() {
      this.visible = true;
      this.btname = "SecretKey";
      this.btbool = true;
    },
    //接受导入文件
    async importFile(e) {
      this.filename = e.target.files[0].name;
      this.file = e;
    },
    //清空导入文件
    clearFile() {
      // var obj = document.getElementById('fileupload') ;
      // obj.outerHTML=obj.outerHTML;

      // var obj = document.getElementById('fileupload') ;
      // obj.select();
      // document.selection.clear();
      this.filename = "";
      this.file = undefined;
    },
    // 清空数据
    clearData() {
      this.clearFile();
      this.textarea = "";
      this.btname = "";
    },
    //显示下一个对话框
    nextshow() {
      ImportDialogpass().show(this.textarea, this.file);
      this.visible = false;
      this.clearData();
    },
  },
};
</script>

<style>
button {
  border: none;
  cursor: pointer;
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
  border: 1px solid rgba(216, 230, 254, 1);
  background: rgba(242, 246, 253, 1);
  color: rgba(120, 127, 147, 1);
}
.dlbt1 {
  width: 160px;
  height: 40px;
  background-blend-mode: normal;
  mix-blend-mode: normal;
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
  padding-left: 25px;
  padding-right: 15px;
  width: 320px;
  height: 50px;
  background: rgba(209, 230, 248, 1);
  background-blend-mode: normal;
  border: 1px solid rgba(220, 230, 242, 1);
  border-radius: 25px;
  mix-blend-mode: normal;
  display: flex;
  justify-content: center;
}
.importbtcss p {
  margin: 0%;
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
