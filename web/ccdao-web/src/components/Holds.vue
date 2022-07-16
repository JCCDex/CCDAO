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
            <div class="holdbox holdboxplace">
              <img class="holdboximg" src="../assets/tag.svg" style="position: absolute" />
              <p class="p2 p21">
                {{ $t("message.Polygon_chain_Positions") }}
              </p>
              <p class="p2 p22">{{ polygonCcdao }}&nbsp;{{ $t("message.CCDAO") }}</p>
            </div>
            <div class="holdbox holdboxplace">
              <img class="holdboximg" src="../assets/tag.svg" style="position: absolute" />
              <p class="p2 p21">
                {{ $t("message.BSC_chain_Positions") }}
              </p>
              <p class="p2 p22">{{ bscCcdao }}&nbsp;{{ $t("message.CCDAO") }}</p>
            </div>
            <div class="holdbox holdboxplace">
              <img class="holdboximg" src="../assets/tag.svg" style="position: absolute" />
              <p class="p2 p21">
                {{ $t("message.HECO_chain_Positions") }}
              </p>
              <p class="p2 p22">{{ hecoCcdao }}&nbsp;{{ $t("message.CCDAO") }}</p>
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

<style lang="scss" scoped></style>
