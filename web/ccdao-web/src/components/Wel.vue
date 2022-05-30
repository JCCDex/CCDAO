<template>
  <div class="community">
    <div class="content">
      <div class="wel">{{ $t("message.Welcome_to") }}</div>
      <div class="ccdao">{{ $t("message.CCDAO_Community") }}</div>
      <div class="vision">{{ $t("message.A_Community_to_improve_Cross_Chain_experience") }}</div>
      <div class="token">{{ $t("message.$CCDAO") }}</div>
      <div class="holder">{{ $t("message.Created_by_Community,for_the_Community") }}</div>
      <div class="amount">
        <div>
          <div>{{ $t("message.Total_Volume_Traded") }}</div>
          <!-- <div class="value">{{ totalVolumeTraded.toLocaleString() }}</div> -->
          <div class="value">{{ totalVolumeTraded }}</div>
        </div>
        <div>
          <div>{{ $t("message.Fully_Diluted_Valuation") }}</div>
          <div class="value">{{ fullyDilutedValuation }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "Wel",
  computed: {
    totalVolumeTraded() {
      return this.$store.state.totalVolumeTraded.toLocaleString();
    },
    fullyDilutedValuation() {
      return this.$store.state.fullyDilutedValuation.toLocaleString();
    },
  },
};
</script>
<style lang="scss" scoped></style>
