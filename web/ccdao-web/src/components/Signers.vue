<template>
  <div class="Signers">
    <a name="Signers"></a>
    <div class="signers">
      <p>{{ $t("Multi-Signers") }}</p>
      <p>{{ $t("It is is under construction...") }}</p>
    </div>
    <img src="../assets/createimg.svg" style="width: 100%; position: absolute; bottom: 50px" />
    <img src="../assets/signers.svg" style="width: 100%; position: relative; z-index: -1; display: flex" />
  </div>
</template>

<script>
export default {
  name: "Signers",
};
</script>

<style>
.Signers {
  width: 100%;
  mix-blend-mode: normal;
  position: relative;
}
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
</style>
