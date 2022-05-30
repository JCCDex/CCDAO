<template>
  <div class="hold-container" id="holding">
    <!-- <img src="../assets/bgimg2.svg" style="width: 100%;position: absolute; z-index: -1;"> -->
    <div class="boxtwotext">
      <span class="p1" style="font-size: 50px; line-height: 50px">{{ $t("message.$CCDAO") }}</span>
      <span class="p1" style="font-size: 40px; line-height: 50px">{{ $t("message.HOLDING") }}</span>
      <div class="holdout">
        <div class="hold">
          <div class="holdbox">
            <img src="../assets/tag.svg" style="position: absolute" />
            <p class="p2" style="margin-left: 160px; margin-top: 20px; font-size: 14px; line-height: 40px">
              {{ $t("message.ETH_chain_Positions") }}
            </p>
            <p class="p2" style="margin-left: 160px; margin-top: 60px; font-size: 30px">
              {{ ethCcdao }}&nbsp;{{ $t("message.CCDAO") }}
            </p>
          </div>
          <div class="holdbox" style="margin-top: 50px">
            <img src="../assets/tag.svg" style="position: absolute" />
            <p class="p2" style="margin-left: 160px; margin-top: 20px; font-size: 14px; line-height: 40px">
              {{ $t("message.SWTC_chain_Positions") }}
            </p>
            <p class="p2" style="margin-left: 160px; margin-top: 60px; font-size: 30px">
              {{ swtcCcdao }}&nbsp;{{ $t("message.CCDAO") }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "Holds",
  computed: {
    ethCcdao() {
      return this.$store.state.ethCcdao.toLocaleString();
    },
    swtcCcdao() {
      return this.$store.state.swtcCcdao.toLocaleString();
    },
  },
};
</script>

<style lang="scss" scoped></style>
