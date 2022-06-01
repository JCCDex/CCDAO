<template>
  <div class="member-container" id="membership">
    <div class="member">
      <p class="membership">{{ $t("message.Membership") }}</p>
      <div class="memberbox">
        <div>
          <p class="mca">{{ $t("message.My_CCDAO_Amount") }}</p>
          <p class="mcanum">{{ ccdaoNum.toLocaleString() }}&nbsp;{{ $t("message.CCDAO") }}</p>
        </div>
        <div v-show="ccdaoNum >= 10000" style="display: flex; align-items: center; font-size: 14px">
          <span style="color: rgba(161, 166, 169, 1)">{{ $t("message.status") }}</span>
          <span style="color: rgba(51, 147, 230, 1); margin-right: 10px">{{ $t("message.YES") }}</span>
          <img src="../assets/member.svg" alt="" />
        </div>
        <div v-show="ccdaoNum < 10000" style="display: flex; align-items: center; font-size: 14px">
          <span style="color: rgba(161, 166, 169, 1)">{{ $t("message.status") }}</span>
          <span style="color: rgba(51, 147, 230, 1); margin-right: 10px">{{ $t("message.NO") }}</span>
          <img src="../assets/member1.svg" alt="" />
        </div>

        <div class="memberboxtext">
          <div style="display: flex; justify-content: space-between">
            <p style="margin: 0px; font-size: 20px">{{ $t("message.Membership_Requirements") }}</p>
            <img src="../assets/buyarrow.svg" class="memberarrow" />
          </div>
          <span class="needCcdao">
            {{ $t("message.$CCDAO_Member_need_to_hold_10000CCDAO_at_least") }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "Member",
  computed: {
    ccdaoNum() {
      return this.$store.getters.myCCDAONum;
    },
  },
};
</script>

<style lang="scss" scoped></style>
