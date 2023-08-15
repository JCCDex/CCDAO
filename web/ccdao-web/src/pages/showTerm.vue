<template>
  <div class="roll">
    <Netalter></Netalter>
    <div class="term-background">
      <div class="term-content" v-if="data">
        <div class="title">{{ data.title }}</div>
        <div class="content">
          <div class="time">{{ data.time }}</div>
          <div style="margin-top: 20px" v-for="(item, index) in data.content" :key="index">
            <div
              :style="{ textIndent: v.indent ? '15px' : v.indent2 ? '30px' : v.indent3 ? '45px' : '0px' }"
              v-for="(v, i) in item"
              :key="i"
            >
              {{ v.value || v }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Netalter from "../components/Netalter";

export default {
  name: "TermOfService",
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      const { type } = to.params;
      if (type === "TermOfService") {
        vm.data = vm.$t("message.TermOfService");
      } else if (type === "PrivacyPolicy") {
        vm.data = vm.$t("message.PrivacyPolicy");
      }
    });
  },
  data() {
    return {
      data: null,
    };
  },
  components: {
    Netalter,
  },
};
</script>

<style></style>
