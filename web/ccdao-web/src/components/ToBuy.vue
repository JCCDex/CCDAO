<template>
  <div class="boxthree">
    <a name="ToBuy"></a>
    <div class="buyone">
      <p class="buytext">{{ $t("HOW TO BUY") }}</p>
      <img src="../assets/buytext.svg" class="buytextimg" />
    </div>
    <div class="buyadd">
      <p class="buy">{{ $t("You can buy $CCDAO in") }}</p>
      <img src="../assets/buyarrow.svg" class="buyimg" />
      <a href="">
        <div href="" class="buyaddbox" style="top: 25px; right: 300px">
          <img src="../assets/buyaddtag1.svg" class="buytag" />
          <p class="buyaddtext">{{ $t("Let' sDEX") }}</p>
        </div>
      </a>
      <a href="">
        <div href="" class="buyaddbox" style="top: 25px; right: 0px">
          <img src="../assets/buyaddtag2.svg" class="buytag" />
          <p class="buyaddtext">{{ $t("Uniswap") }}</p>
        </div>
      </a>
    </div>
    <img src="../assets/bgimg3.svg" style="width: 100%; position: relative; z-index: -1; display: flex" />
  </div>
</template>

<script>
export default {};
</script>

<style>
.boxthree {
  width: 100%;
  position: relative;
}
.buyone {
  position: absolute;
  display: flex;
  justify-content: space-between;
  align-items: center;
  left: 280px;
  top: 170px;
}
.buytext {
  margin: 0px;
  width: 350px;
  height: 50px;
  mix-blend-mode: normal;
  color: rgba(61, 61, 59, 1);
  font-size: 46px;
  line-height: 50px;
}
.buytextimg {
  width: 36px;
  height: 36px;
}
.buyadd {
  left: 272px;
  top: 403px;
  width: 919px;
  height: 60px;
  position: absolute;
}
.buy {
  width: 240px;
  height: 30px;
  mix-blend-mode: normal;
  color: rgba(61, 61, 59, 1);
  font-size: 20px;
  line-height: 30px;
}
.buyimg {
  left: 262px;
  position: absolute;
  top: 28px;
  width: 16.01px;
  height: 14.09px;
  background-blend-mode: normal;
  mix-blend-mode: normal;
}
.buyaddbox {
  position: absolute;
  width: 260px;
  height: 60px;
  background: rgba(255, 255, 255, 1);
  background-blend-mode: normal;
  box-shadow: 0px 1px 5px rgba(201, 223, 240, 1);
  border-radius: 16px;
  mix-blend-mode: normal;
  display: flex;
  align-items: center;
}
.buytag {
  margin-left: 15px;
  width: 30px;
  height: 30px;
  mix-blend-mode: normal;
}
.buyaddtext {
  margin-left: 15px;
  width: 77px;
  height: 24px;
  mix-blend-mode: normal;
  color: rgba(23, 25, 29, 1);
  font-size: 16px;
}
</style>
