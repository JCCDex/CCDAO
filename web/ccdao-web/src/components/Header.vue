<template>
  <div class="box">
    <img class="boximg" src="../assets/CCDAO.svg" />
    <div style="position: relative">
      <div style="width: 490px; height: 36px; display: flex; justify-content: space-between">
        <div class="fbt" style="margin-left: 10px">
          <div class="fbt1">
            {{ $t("Comunity") }}
            <img src="../assets/downchart.svg" />
          </div>
          <div class="outbt" style="left: 0px">
            <a href="" class="outbts">{{ $t("Twitter") }}</a>
            <a href="" class="outbts">{{ $t("Discord") }}</a>
            <a href="" class="outbts">{{ $t("Telegram") }}</a>
          </div>
        </div>
        <div class="fbt" style="margin-left: 10px">
          <div class="fbt1">
            $CCDAO
            <img src="../assets/downchart.svg" />
          </div>
          <div class="outbt" style="left: 130px">
            <a href="#Holds" class="outbts">{{ $t("Holding") }}</a>
            <a href="#ToBuy" class="outbts">{{ $t("How to Buy") }}</a>
            <a href="#WebAdd" class="outbts">{{ $t("Contract Address") }}</a>
          </div>
        </div>
        <a href="#Member"
          ><div class="fbt2">{{ $t("Membership") }}</div></a
        >
        <a href="#Signers"
          ><div class="fbt2">{{ $t("Multi-Signers") }}</div></a
        >
      </div>
    </div>
    <div class="wallet"></div>
  </div>
</template>

<script>
export default {
  name: "Header",
};
</script>

<style>
a {
  text-decoration: none;
}
.box {
  width: 100%;
  height: 60px;
  background: rgba(246, 249, 253, 1);
  box-shadow: 0px 1px 5px rgba(201, 223, 240, 1);
  display: flex;
  align-items: center;
  justify-content: space-between;
  text-align: center;
  font-family: PingFangSC-Medium, sans-serif;
}
.boximg {
  width: 138.84px;
  height: 40px;
  margin-left: 50px;
}
.fbt1 {
  cursor: pointer;
  width: 80px;
  height: 36px;
  /* background: rgba(230, 236, 243, 1); */
  background: rgba(246, 249, 253, 1);
  border-radius: 3px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: rgba(12, 40, 69, 1);
  font-size: 14px;
  padding-left: 10px;
  padding-right: 10px;
}
.fbt2 {
  width: 100px;
  height: 36px;
  /* background: rgba(230, 236, 243, 1); */
  background: rgba(246, 249, 253, 1);
  border-radius: 3px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(12, 40, 69, 1);
  font-size: 14px;
}
.outbt {
  top: 45px;
  width: 120px;
  height: 140px;
  background: rgba(255, 255, 255, 1);
  background-blend-mode: normal;
  border: 1px solid rgba(251, 252, 254, 1);
  box-shadow: 0px 2px 4px rgba(228, 237, 246, 0.5);
  border-radius: 3px;
  z-index: 9999;
  position: absolute;
  display: none;
}
.fbt:hover .fbt1 {
  background: rgba(209, 230, 248, 1);
}
.fbt:hover .outbt {
  display: block;
}
.outbts {
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 1);
  /* color: rgba(12, 40, 69, 1); */
  width: 120px;
  height: 40px;
  background-blend-mode: normal;
  border-radius: 3px;
  mix-blend-mode: normal;
  color: rgba(108, 116, 124, 1);
  font-size: 14px;
}
.outbts:hover {
  background: rgba(244, 246, 248, 1);
}
.wallet {
  width: 180px;
  height: 36px;
  background: rgba(255, 255, 255, 1);
  box-shadow: 0px 0px 4px 2px rgba(237, 240, 242, 1);
  border-radius: 18px;
  margin-right: 50px;
}
</style>
