<template>
  <div class="hold-container" id="holding">
    <!-- <img src="../assets/bgimg2.svg" style="width: 100%;position: absolute; z-index: -1;"> -->
    <div class="boxtwotext">
      <div class="holdscss">
        <span class="p1 p11">{{ $t("message.$CCDAO") }}</span>
        <span class="p1 p12">{{ $t("message.HOLDING") }}</span>
        <div class="holdout">
          <div class="hold">
            <div class="holdbox">
              <img class="holdboximg" src="../assets/tag.svg" style="position: absolute" />
              <div class="boxText">
                <span class="text1">{{ $t("message.ETH_chain_Positions") }}</span>
                <span class="text2">{{ ethCcdao }}&nbsp;{{ $t("message.CCDAO") }}</span>
              </div>
            </div>
            <div class="holdbox holdboxplace">
              <img class="holdboximg" src="../assets/tag.svg" style="position: absolute" />
              <div class="boxText">
                <span class="text1">{{ $t("message.SWTC_chain_Positions") }}</span>
                <span class="text2">{{ swtcCcdao }}&nbsp;{{ $t("message.CCDAO") }}</span>
              </div>
            </div>
            <div class="holdbox holdboxplace">
              <img class="holdboximg" src="../assets/tag.svg" style="position: absolute" />
              <div class="boxText">
                <span class="text1">{{ $t("message.Polygon_chain_Positions") }}</span>
                <span class="text2">{{ polygonCcdao }}&nbsp;{{ $t("message.CCDAO") }}</span>
              </div>
            </div>
            <div class="holdbox holdboxplace">
              <img class="holdboximg" src="../assets/tag.svg" style="position: absolute" />
              <div class="boxText">
                <span class="text1">{{ $t("message.BSC_chain_Positions") }}</span>
                <span class="text2">{{ bscCcdao }}&nbsp;{{ $t("message.CCDAO") }}</span>
              </div>
            </div>
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
      return parseFloat(this.$store.state.ethCcdao).toLocaleString();
    },
    swtcCcdao() {
      return parseFloat(this.$store.state.swtcCcdao).toLocaleString();
    },
    polygonCcdao() {
      return parseFloat(this.$store.state.polygonCcdao).toLocaleString();
    },
    bscCcdao() {
      return parseFloat(this.$store.state.bscCcdao).toLocaleString();
    },
    hecoCcdao() {
      return parseFloat(this.$store.state.hecoCcdao).toLocaleString();
    },
  },
};
</script>

<style lang="scss" scoped>
.boxText {
  display: flex;
  flex-direction: column;
  height: calc(100% - 24px);
  justify-content: space-between;
  padding: 12px 0px;
}
</style>
