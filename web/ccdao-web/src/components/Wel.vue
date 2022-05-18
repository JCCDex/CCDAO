<template>
  <div class="community">
    <div class="content">
      <div class="wel">{{ $t("message.Welcome_to") }}</div>
      <div class="ccdao">{{ $t("message.CCDAO_Community") }}</div>
      <div class="vision">{{ $t("message.A_Community_to_improve_Cross_Chain_experience") }}</div>
      <div class="token">{{ $t("message.$CCDAO") }}</div>
      <div class="holder">{{ $t("message.Created_by_Community,for_the_Community") }}</div>
      <div class="amount">
        <div>
          <div>{{ $t("message.Total_Volume_Traded") }}</div>
          <div class="value">{{ totalVolumeTraded.toLocaleString() }}</div>
        </div>
        <div>
          <div>{{ $t("message.Fully_Diluted_Valuation") }}</div>
          <div class="value">{{ fullyDilutedValuation.toLocaleString() }}</div>
        </div>
      </div>
    </div>
    <img src="../assets/bgimg1.svg" />
  </div>
</template>

<script>
import configdata from "../../public/config.json";

export default {
  name: "Wel",
  data() {
    return {
      totalVolumeTraded: configdata.totalVolumeTraded,
      fullyDilutedValuation: configdata.fullyDilutedValuation,
    };
  },
};
</script>
<style lang="scss" scoped>
.community {
  width: 100%;
  position: relative;

  img {
    display: flex;
    width: 100%;
  }
  .content {
    position: absolute;
    left: 0;
    top: 0;
    padding-left: 140px;
    padding-top: 74px;
    .wel {
      font-size: 40px;
      line-height: 30px;
      color: #444444;
    }

    .ccdao {
      font-size: 50px;
      line-height: 50px;
      color: #3393e6;
      margin-top: 12px;
    }

    .vision {
      font-size: 16px;
      color: #444;
      margin-top: 8px;
    }

    .token {
      font-size: 50px;
      color: #3393e6;
      margin-top: 40px;
    }

    .holder {
      font-size: 16px;
      color: #555656;
      margin-top: 6px;
    }

    .amount {
      display: flex;
      justify-content: space-between;
      padding: 14px 20px;
      margin-top: 45px;
      box-shadow: 0px 1px 5px rgba(201, 223, 240, 1);
      border-radius: 16px;
      background-color: #fff;
      color: #a1a6a9;
      font-size: 14px;
      .value {
        color: #3393e6;
        font-size: 20px;
        margin-top: 6px;
      }
    }
  }
}
</style>
