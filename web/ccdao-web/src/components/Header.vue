<template>
  <div class="box">
    <img class="boximg" src="../assets/CCDAO.svg" />
    <div style="position: relative">
      <div style="width: 490px; height: 36px; display: flex; justify-content: space-between">
        <div class="fbt" style="margin-left: 10px">
          <div class="fbt1">
            {{ $t("Community") }}
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
    <div class="wallet" style="position: relative">
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
  },
  components: {
    Dialogs,
  },
};
</script>

<style>
a {
  text-decoration: none;
}
.box {
  width: 100%;
  height: 60px;
  background: rgb(246, 249, 253, 1);
  box-shadow: 0px 1px 5px rgba(201, 223, 240, 1);
  display: flex;
  align-items: center;
  justify-content: space-between;
  /* position: fixed; */
  /* z-index: 1; */
}
.boximg {
  width: 138.84px;
  height: 40px;
  margin-left: 50px;
}
.fbt1 {
  cursor: pointer;
  width: 88px;
  height: 36px;
  /* background: rgba(230, 236, 243, 1); */
  background: rgba(230, 236, 243, 0.2);
  border-radius: 3px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: rgba(12, 40, 69, 1);
  font-size: 14px;
  padding-left: 6px;
  padding-right: 6px;
}
.fbt2 {
  width: 100px;
  height: 36px;
  /* background: rgba(230, 236, 243, 1); */
  background: rgba(230, 236, 243, 0.2);
  border-radius: 3px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(12, 40, 69, 1);
  font-size: 14px;
}
.fbt2:hover {
  background: rgb(230, 236, 243, 1);
}
.out {
  left: 0px;
  top: 36px;
  position: absolute;
  display: none;
  z-index: 9999;
}
.outbt {
  margin-top: 9px;
  width: 120px;
  height: 140px;
  background: rgb(255, 255, 255, 1);
  background-blend-mode: normal;
  box-shadow: 0px 2px 4px rgba(228, 237, 246, 0.5);
  border-radius: 3px;
}
.fbt:hover .fbt1 {
  background: rgb(209, 230, 248, 1);
}
.fbt:hover .out {
  display: block;
}
.outbts {
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgb(255, 255, 255, 1);
  /* color: rgba(12, 40, 69, 1); */
  width: 120px;
  height: 40px;
  background-blend-mode: normal;
  border-radius: 3px;
  mix-blend-mode: normal;
  color: rgba(108, 116, 124, 1);
  font-size: 14px;
}
.outbts:hover {
  background: rgb(244, 246, 248, 1);
  color: rgba(12, 40, 69, 1);
}
.wallet {
  width: 180px;
  height: 36px;
  background: rgba(255, 255, 255, 1);
  box-shadow: 0px 0px 4px 2px rgba(237, 240, 242, 1);
  border-radius: 18px;
  margin-right: 50px;
  font-size: 14px;
  border: 2px solid rgba(67, 162, 244, 0);
}
.walletbt {
  border: none;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-left: 25px;
  padding-right: 15px;
  width: 180px;
  height: 36px;
  background: rgba(255, 255, 255, 1);
  box-shadow: 0px 0px 4px 2px rgba(237, 240, 242, 1);
  border-radius: 18px;
  margin-right: 50px;
  font-size: 14px;
}
.walletdia {
  position: absolute;
  z-index: 9999;
  right: -50px;
  top: 36px;
  padding-top: 12px;
  display: none;
}
.wallet:hover {
  border: 2px solid #3394e6;
}
.wallet:hover .walletdia {
  display: block;
}
</style>
