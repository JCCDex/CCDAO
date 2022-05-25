<template>
  <div class="Signers" id="Signers">
    <div class="signers">
      <p>{{ $t("message.Multi-Signers") }}</p>
      <p>{{ $t("message.It_is_under_construction") }}</p>
    </div>
    <img src="../assets/signers.svg" class="img2" />
  </div>
</template>

<script>
export default {
  name: "Signers",
};
</script>

<style lang="scss" scoped>
.Signers {
  width: 100%;
  mix-blend-mode: normal;
  position: relative;

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

  .img1 {
    left: 0;
    width: 100%;
    position: absolute;
    bottom: -16px;
  }

  .img2 {
    width: 100%;
    z-index: -1;
  }
}
</style>
