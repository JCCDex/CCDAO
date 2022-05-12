<template>
  <div class="foot">
    <p class="foottext">Copyright © 2022 by The CCDAO. All Rights Reserved.</p>

    <img src="../assets/foottag.svg" style="position: absolute; right: 50px; top: 20px" />
  </div>
</template>

<script>
export default {};
</script>

<style>
.foot {
  width: 100%;
  height: 60px;
  bottom: 0%;
  position: fixed;
  z-index: 1;
  background: rgba(246, 249, 253, 1);
  background-blend-mode: normal;
  mix-blend-mode: normal;
}
.foottext {
  left: 39%;
  top: 12px;
  width: 1440px;
  height: 60px;
  color: rgba(112, 112, 112, 1);
  font-size: 12px;
}
</style>
