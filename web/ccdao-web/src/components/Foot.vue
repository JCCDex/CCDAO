<template>
  <div class="foot">
    <p class="foottext">Copyright © 2022 by The CCDAO. All Rights Reserved.</p>
    <img src="../assets/foottag.svg" />
  </div>
</template>

<script>
export default {
  name: "Foot.vue",
};
</script>

<style>
.foot {
  width: 100%;
  height: 60px;
  background: rgba(246, 249, 253, 1);
  position: relative;
  text-align: center;
}
.foottext {
  margin-top: 25px;
  width: 100%;
  color: rgba(112, 112, 112, 1);
  font-size: 12px;
}
.foot img {
  position: absolute;
  width: 74px;
  height: 20.5px;
  right: 50px;
  top: 15px;
}
</style>
