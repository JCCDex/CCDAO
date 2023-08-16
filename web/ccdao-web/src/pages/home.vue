<template>
  <div class="roll">
    <Netalter></Netalter>
    <Wel></Wel>
    <Holds></Holds>
    <ToBuy></ToBuy>
    <WebAdd></WebAdd>
    <Member></Member>
    <Signers></Signers>
    <Connector></Connector>
  </div>
</template>

<script>
import Netalter from "../components/Netalter";
import Wel from "../components/Wel";
import Holds from "../components/Holds";
import ToBuy from "../components/ToBuy";
import WebAdd from "../components/WebAdd";
import Member from "../components/Member";
import Signers from "../components/Signers";
import Connector from "../components/Connector";

export default {
  name: "home",
  data() {
    return {
      anchor: "",
    };
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      if (to.hash) {
        vm.anchor = to.hash.replace("#", "");
      }
    });
  },
  watch: {
    anchor(newValue, oleValue) {
      setTimeout(() => {
        const targetElement = document.getElementById(newValue);
        if (targetElement) {
          targetElement.scrollIntoView({
            behavior: "smooth", // 平滑滚动
            block: "start", // 滚动到目标元素的顶部
          });
        }
      }, 100);
    },
  },
  components: {
    Netalter,
    Wel,
    Holds,
    ToBuy,
    WebAdd,
    Member,
    Signers,
    Connector,
  },
};
</script>

<style></style>
