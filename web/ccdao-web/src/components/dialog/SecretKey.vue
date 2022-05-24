<template>
  <div>
    <div class="dlcss">
      <div style="width: 320px">
        <el-input
          class="dltext"
          type="textarea"
          :rows="2"
          :placeholder="$t('message.pls_enter_swt_secret')"
          v-model="textarea"
        >
        </el-input>
      </div>
    </div>
  </div>
</template>

<script>
import { EventBus } from "../../Bus.js";

export default {
  name: "SecretKey",
  data() {
    return {
      textarea: "",
    };
  },
  watch: {
    textarea() {
      EventBus.$emit("textarea", this.textarea);
    },
  },
};
</script>

<style></style>
