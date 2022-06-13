<template>
  <div class="sidebarbox" @click.stop="downSidebar()">
    <div @click.stop="" id="arr" class="sidebardiv" v-show="sidebarBool" :style="{ height: sidebarHeight + 'px' }">
      <div class="between">
        <span></span>
        <img class="fork" src="../assets/fork.svg" alt="" @click="downSidebar()" />
      </div>
      <div class="sidebarbt between" @click="isShowCommunity = !isShowCommunity">
        <span>{{ $t("message.Community") }}</span>
        <img v-show="!isShowCommunity" class="sidebarupimg" src="../assets/sidebardownimg.svg" alt="" />
        <img v-show="isShowCommunity" class="sidebarupimg" src="../assets/sidebarupimg.svg" alt="" />
      </div>
      <div v-show="isShowCommunity" class="sidebarselects">
        <a href="" target="_blank" class="sidebarselect" @click="downSidebar()">{{ $t("message.Twitter") }}</a>
        <a href="" target="_blank" class="sidebarselect" @click="downSidebar()">{{ $t("message.Discord") }}</a>
        <a href="" target="_blank" class="sidebarselect" @click="downSidebar()">{{ $t("message.Telegram") }}</a>
      </div>
      <div class="sidebarbt between" @click="isShowCcdao = !isShowCcdao">
        <span>{{ $t("message.$CCDAO") }}</span>
        <img v-show="!isShowCcdao" class="sidebarupimg" src="../assets/sidebardownimg.svg" alt="" />
        <img v-show="isShowCcdao" class="sidebarupimg" src="../assets/sidebarupimg.svg" alt="" />
      </div>
      <div v-show="isShowCcdao" class="sidebarselects">
        <a href="#holding" class="sidebarselect" @click="downSidebar()">{{ $t("message.Holding") }}</a>
        <a href="#trade" class="sidebarselect" @click="downSidebar()">{{ $t("message.How_to_Buy") }}</a>
        <a href="#contract" class="sidebarselect" @click="downSidebar()">{{ $t("message.Contract_Address") }}</a>
      </div>
      <a href="#membership">
        <div class="sidebarbt between" @click="downSidebar()">
          <span>{{ $t("message.Membership") }}</span>
          <span></span>
        </div>
      </a>
      <a href="#multi">
        <div class="sidebarbt between" @click="downSidebar()">
          <span>{{ $t("message.Multi-Signers") }}</span>
          <span></span>
        </div>
      </a>
    </div>
  </div>
</template>

<script>
export default {
  name: "Sidebar",
  data() {
    return {
      sidebarHeight: 0,
      isShowCommunity: false,
      isShowCcdao: false,
    };
  },
  computed: {
    sidebarBool() {
      return this.$store.state.sidebarBool;
    },
  },
  methods: {
    downSidebar() {
      this.$store.commit("downSidebar");
      this.isShowCommunity = false;
      this.isShowCcdao = false;
    },
  },
  mounted() {
    this.sidebarHeight = window.screen.height;
  },
};
</script>

<style lang="scss" scoped>
a {
  text-decoration: none;
}
.between {
  padding-top: 25px;
  padding-left: 20px;
  padding-right: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.sidebarbox {
  width: 100%;
  position: fixed;
  z-index: 10000;
  left: 0px;
}
.sidebardiv {
  // display: none;
  width: 81.25%;
  background: rgba(0, 21, 36, 0.8);
  left: 0px;
  color: white;
  .fork {
    width: 20px;
    height: 20px;
  }
  .sidebarbt {
    color: rgba(255, 255, 255, 1);
    font-size: 22px;
    .sidebarupimg {
      width: 25px;
      height: 25px;
    }
  }
  .sidebarselects {
    padding-left: 20px;
    .sidebarselect {
      margin-top: 20px;
      display: block;
      color: rgba(163, 180, 191, 1);
      font-size: 20px;
    }
    :hover {
      color: rgba(58, 158, 243, 1);
    }
  }
}
</style>
