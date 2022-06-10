<template>
  <div class="dlcss">
    <button class="importbtcss">
      <p style="margin-top: 12px" v-show="file === undefined">{{ $t("message.click_to_import_swt") }}</p>
      <div
        v-show="file !== undefined"
        style="display: flex; justify-content: space-between; width: 100%; height: 100%; align-items: center"
      >
        <p style="color: rgba(0, 0, 0, 1); margin-left: 0px; font-family: PingFangSC-Medium, sans-serif">
          {{ filename }}
        </p>
        <img src="../../assets/cleartag.svg" @click="clearFile()" />
      </div>
      <input id="fileupload" type="file" @change="importFile" v-show="file === undefined" />
    </button>
  </div>
</template>

<script>
import { EventBus } from "../../Bus.js";

export default {
  name: "ImportFile",
  data() {
    return {
      file: undefined,
      filename: "",
    };
  },
  methods: {
    async importFile(e) {
      this.filename = e.target.files[0].name;
      this.file = e;
    },
    clearFile() {
      this.filename = "";
      this.file = undefined;
    },
  },
  watch: {
    filename() {
      EventBus.$emit("file", this.file, this.filename);
    },
  },
};
</script>

<style></style>
