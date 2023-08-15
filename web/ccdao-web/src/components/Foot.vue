<template>
  <div class="foot">
    <p class="foottext">Copyright © {{ year }} by The CCDAO. All Rights Reserved.</p>
    <img src="../assets/foottag.svg" />
  </div>
</template>

<script>
export default {
  name: "Foot.vue",
  data() {
    return {
      year: new Date().getFullYear(),
    };
  },
};
</script>

<style></style>
