<template>
  <div class="roll">
    <Netalter></Netalter>
    <component :is="is"></component>
  </div>
</template>

<script>
import en from "./en.vue";
import zh from "./zh.vue";
import Netalter from "../../components/Netalter";

export default {
  data() {
    return {
      is: "",
    };
  },
  beforeRouteEnter(to, from, next) {
    const { lang } = to.params;
    next((vm) => {
      if (lang) {
        vm.is = lang;
      } else {
        vm.is = vm.$i18n.locale;
      }
    });
  },
  components: {
    en,
    zh,
    Netalter,
  },
};
</script>
