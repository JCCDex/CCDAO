<template>
  <div class="box">
    <img class="sanhen" style="margin-left: 10px" src="../assets/sanhen.svg" @click="showSidebar()" />
    <img v-if="!isTp" class="boximg" src="../assets/CCDAO.svg" />
    <span class="sanhen" style="margin-right: 10px"></span>
    <div class="headbt1" style="position: relative">
      <div style="width: 490px; height: 36px; display: flex; justify-content: space-between">
        <div class="fbt" style="margin-left: 10px">
          <div class="fbt1">
            {{ $t("message.Community") }}
            <img src="../assets/downchart.svg" />
          </div>
          <div class="out" style="left: 0px">
            <div class="outbt">
              <a href="" target="_blank" class="outbts">{{ $t("message.Twitter") }}</a>
              <a href="" target="_blank" class="outbts">{{ $t("message.Discord") }}</a>
              <a href="" target="_blank" class="outbts">{{ $t("message.Telegram") }}</a>
            </div>
          </div>
        </div>
        <div class="fbt" style="margin-left: 10px">
          <div class="fbt1">
            {{ $t("message.$CCDAO") }}
            <img src="../assets/downchart.svg" />
          </div>
          <div class="out" style="left: 130px">
            <div class="outbt" style="left: 130px">
              <a href="#holding" class="outbts">{{ $t("message.Holding") }}</a>
              <a href="#trade" class="outbts">{{ $t("message.How_to_Buy") }}</a>
              <a href="#contract" class="outbts">{{ $t("message.Contract_Address") }}</a>
            </div>
          </div>
        </div>
        <a href="#membership"
          ><div class="fbt2">{{ $t("message.Membership") }}</div></a
        >
        <a href="#multi"
          ><div class="fbt2">{{ $t("message.Multi-Signers") }}</div></a
        >
      </div>
    </div>
    <div class="wallet" v-if="isTpWallet" style="position: relative">
      <button class="walletbt">
        <div v-show="!isHave" style="display: flex; align-items: center; justify-content: space-between">
          <img src="../assets/Shape.svg" style="width: 20px; height: 20px" />
          <p style="margin: 0px; margin-left: 10px">{{ $t("message.Connect_Wallet") }}</p>
        </div>

        <div
          v-show="isHave"
          style="color: rgba(58, 155, 232, 1); display: flex; align-items: center; justify-content: space-between"
        >
          <img src="../assets/shaceblue.svg" style="width: 20px; height: 20px" />
          <p class="bttext" style="margin: 0px; margin-left: 5px">{{ $t("message.My_Wallet") }}</p>
        </div>

        <img src="../assets/triangular.svg" style="width: 11px; height: 5.13px" />
      </button>

      <div class="walletdia">
        <Dialogs></Dialogs>
      </div>
    </div>
  </div>
</template>

<script>
import Dialogs from "./Dialogs";

export default {
  name: "Header",
  computed: {
    isHave() {
      return this.$store.getters.isHave;
    },
    isTp() {
      return this.$store.state.isTp;
    },
    isTpWallet() {
      return this.$store.state.isTp || window.screen.width >= 1079;
    },
  },
  components: {
    Dialogs,
  },
  methods: {
    showSidebar() {
      this.$store.commit("showSidebar");
    },
  },
};
</script>

<style></style>
