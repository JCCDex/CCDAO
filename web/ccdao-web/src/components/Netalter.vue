<template>
  <div class="netalter" v-show="!isNetWork">
    <div class="alterbox">
      <p class="nettitle">{{ $t("message.Network_Error") }}</p>
      <p class="netcontent">{{ $t("message.Please_switch_to_the_Ethernet_Network") }}</p>
    </div>
  </div>
</template>

<script>
export default {
  name: "Netalter",
  computed: {
    isNetWork() {
      if (this.$store.state.isNetWork === false) {
        setTimeout(() => {
          this.$store.commit("setIsNetWork", true);
          return this.$store.state.isNetWork;
        }, 5000);
      } else return this.$store.state.isNetWork;
    },
  },
};
</script>

<style lang="scss" scoped>
.netalter {
  p {
    margin: 0px;
  }
  position: absolute;
  width: 100%;
  z-index: 1000;
  display: flex;
  justify-content: center;
  .alterbox {
    width: 340px;
    height: 100px;
    background: rgba(255, 255, 255, 1);
    border-radius: 16px;
    border: 1px solid rgba(216, 221, 230, 1);
    box-shadow: 2px 2px 6px rgba(225, 229, 234, 1);
    padding-left: 20px;
    padding-top: 20px;
    .nettitle {
      color: rgba(230, 53, 70, 1);
      letter-spacing: 0.2px;
      font-size: 18px;
      line-height: 20px;
    }
    .netcontent {
      margin-top: 20px;
      color: rgba(52, 63, 93, 1);
      letter-spacing: 0.2px;
      font-size: 16px;
      line-height: 20px;
    }
  }
}
</style>
