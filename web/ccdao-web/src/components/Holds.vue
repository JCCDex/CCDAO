<template>
  <div class="boxtwo">
    <a name="Holds"></a>
    <!-- <img src="../assets/bgimg2.svg" style="width: 100%;position: absolute; z-index: -1;"> -->
    <div class="boxtwotext">
      <span class="p1" style="font-size: 50px; line-height: 50px">{{ $t("message.$CCDAO") }}</span>
      <span class="p1" style="font-size: 40px; line-height: 50px">{{ $t("message.HOLDING") }}</span>
      <div class="holdout">
        <div class="hold">
          <div class="holdbox">
            <img src="../assets/tag.svg" style="position: absolute" />
            <p class="p2" style="margin-left: 160px; margin-top: 20px; font-size: 14px; line-height: 40px">
              {{ $t("message.ETH_chain_Positions") }}
            </p>
            <p class="p2" style="margin-left: 160px; margin-top: 60px; font-size: 30px">{{ ETHCCDAO }}CCDAO</p>
          </div>
          <div class="holdbox" style="margin-top: 50px">
            <img src="../assets/tag.svg" style="position: absolute" />
            <p class="p2" style="margin-left: 160px; margin-top: 20px; font-size: 14px; line-height: 40px">
              {{ $t("message.SWTC_chain_Positions") }}
            </p>
            <p class="p2" style="margin-left: 160px; margin-top: 60px; font-size: 30px">{{ SWTCCCDAO }}CCDAO</p>
          </div>
        </div>
      </div>
    </div>
    <img src="../assets/bgimg2.svg" style="width: 100%; position: relative; z-index: -1; display: flex" />
  </div>
</template>

<script>
import axios from "axios";

export default {
  name: "Holds",
  data() {
    return {
      ETHCCDAO: "",
      SWTCCCDAO: "",
    };
  },
  mounted() {
    setTimeout(() => {
      this.setdatatime();
    }, 0);
  },
  methods: {
    setdatatime() {
      axios
        .get("./config.json")
        .then((response) => {
          this.ETHCCDAO = response.data.ETH;
          this.SWTCCCDAO = response.data.SWTC;
        })
        .catch(function (error) {
          console.log(error);
        });
      setTimeout(() => {
        this.setdatatime();
      }, 1000 * 60 * 10);
    },
  },
};
</script>

<style>
.boxtwo {
  width: 100%;
  position: relative;
  /* background-image: url("../assets/bgimg2.svg"); */
}
.boxtwotext {
  padding-top: 80px;
  position: absolute;
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.p1 {
  margin-bottom: 35px;
  mix-blend-mode: normal;
  color: rgba(255, 255, 255, 1);
}
.p2 {
  width: 183px;
  height: 50px;
  mix-blend-mode: normal;
  color: rgba(255, 255, 255, 1);
  position: absolute;
}
.holdout {
  display: flex;
  justify-content: center;
}
.hold {
  /* margin-left: 29.1%; */
  width: 600px;
  height: 290px;
}
.holdbox {
  width: 600px;
  height: 120px;
  background: rgba(96.00000000000001, 194.00000000000006, 248, 1);
  background-blend-mode: normal;
  border-radius: 110px;
  mix-blend-mode: normal;
}
</style>
