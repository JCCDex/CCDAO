<template>
  <div class="Signers" id="Signers">
    <div class="signers">
      <p>{{ $t("message.Multi-Signers") }}</p>
      <p>{{ $t("message.It_is_under_construction") }}</p>
    </div>
  </div>
</template>

<script>
export default {
  name: "Signers",
};
</script>

<style lang="scss" scoped>
@import "../css/background.scss";

.Signers {
  position: relative;
  @include div-same-size-as-background-img("../assets/signers.svg");

  .signers {
    top: 100px;
    width: 100%;
    position: absolute;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    color: rgba(255, 255, 255, 1);
    font-size: 50px;
  }
}
</style>
