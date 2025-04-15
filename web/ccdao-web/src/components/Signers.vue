<template>
  <div class="Signers" id="multi">
    <div class="signers">
      <span class="ms">{{ $t("message.Multi-Signers") }}</span>
      <!-- <span class="iiuc">{{ $t("message.It_is_under_construction") }}</span> -->
      <div class="addbox">
        <a href="https://multisign.ccda.ooo/" target="_blank">
          <span>{{ $t("message.toMultiUrl") }}</span>
          <img src="../assets/rightarrow.svg" class="right" />
        </a>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "Signers",
};
</script>

<style lang="scss" scoped></style>
