<template>
  <div class="boxfive" id="Member">
    <div class="member">
      <p class="membership">{{ $t("message.Membership") }}</p>
      <div class="memberbox">
        <div>
          <p class="mca">{{ $t("message.My_CCDAO_Amount") }}</p>
          <p class="mcanum">{{ CCDAOnum }}&nbsp;{{ $t("message.CCDAO") }}</p>
        </div>
        <div v-show="CCDAOnum >= 10000" style="display: flex; align-items: center; font-size: 14px">
          <span style="color: rgba(161, 166, 169, 1)">{{ $t("message.status") }}</span>
          <span style="color: rgba(51, 147, 230, 1); margin-right: 10px">{{ $t("message.YES") }}</span>
          <img src="../assets/member.svg" alt="" />
        </div>
        <div v-show="CCDAOnum < 10000" style="display: flex; align-items: center; font-size: 14px">
          <span style="color: rgba(161, 166, 169, 1)">{{ $t("message.status") }}</span>
          <span style="color: rgba(51, 147, 230, 1); margin-right: 10px">{{ $t("message.NO") }}</span>
          <img src="../assets/member1.svg" alt="" />
        </div>

        <div class="memberboxtext">
          <div style="display: flex; justify-content: space-between">
            <p style="margin: 0px; font-size: 20px">{{ $t("message.Membership_Requirements") }}</p>
            <img src="../assets/buyarrow.svg" style="margin-left: 30px" />
          </div>
          <p style="position: absolute; margin: 0px; margin-top: 30px; font-size: 30px; width: 800px">
            {{ $t("message.$CCDAO_Member_need_to_hold_10000CCDAO_at_least") }}
          </p>
        </div>
      </div>
    </div>

    <img src="../assets/bgimg5.svg" style="width: 100%; position: relative; z-index: -1; display: flex" />
  </div>
</template>

<script>
import axios from "axios";
import { EventBus } from "../Bus.js";

export default {
  name: "Member",
  data() {
    return {
      CCDAOnum: 0,
      SWTCaddress: "",
    };
  },
  mounted() {
    EventBus.$on("aMsg", (SWTCaddress) => {
      const CCDAO = "CCDAO_jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or";
      this.SWTCaddress = SWTCaddress;
      axios
        .get("https://swtcscan.jccdex.cn/wallet/balance/" + this.SWTCaddress + "?w=" + this.SWTCaddress)
        .then((response) => {
          this.CCDAOnum = response.data.data.CCDAO_jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or.value;
        })
        .catch(function (error) {
          console.log(error);
        });
    });
  },
};
</script>

<style>
.boxfive {
  width: 100%;
  mix-blend-mode: normal;
  position: relative;
}
.member {
  width: 100%;
  position: absolute;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding-top: 100px;
}
.membership {
  margin: 0px;
  mix-blend-mode: normal;
  color: black;
  font-size: 40px;
  line-height: 46px;
}
.memberbox {
  margin-top: 150px;
  width: 600px;
  height: 120px;
  background: rgba(255, 255, 255, 1);
  background-blend-mode: normal;
  box-shadow: 0px 1px 5px rgba(201, 223, 240, 1);
  border-radius: 80px;
  mix-blend-mode: normal;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-left: 50px;
  position: relative;
}
.mca {
  margin: 0%;
  background-blend-mode: normal;
  mix-blend-mode: normal;
  color: rgba(161, 166, 169, 1);
  font-size: 16px;
  line-height: 40px;
}
.mcanum {
  margin: 0%;
  background-blend-mode: normal;
  mix-blend-mode: normal;
  color: rgba(73, 170, 239, 1);
  font-size: 30px;
  line-height: 30px;
}
.memberboxtext {
  position: absolute;
  top: 200px;
  left: 0px;
}
</style>
