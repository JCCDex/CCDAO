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
              <p class="p2 p21">
                {{ $t("message.ETH_chain_Positions") }}
              </p>
              <p class="p2 p22">{{ ethCcdao }}&nbsp;{{ $t("message.CCDAO") }}</p>
            </div>
            <div class="holdbox holdboxplace">
              <img class="holdboximg" src="../assets/tag.svg" style="position: absolute" />
              <p class="p2 p21">
                {{ $t("message.SWTC_chain_Positions") }}
              </p>
              <p class="p2 p22">{{ swtcCcdao }}&nbsp;{{ $t("message.CCDAO") }}</p>
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
      return this.$store.state.ethCcdao.toLocaleString();
    },
    swtcCcdao() {
      return this.$store.state.swtcCcdao.toLocaleString();
    },
  },
};
</script>

<style lang="scss" scoped></style>
