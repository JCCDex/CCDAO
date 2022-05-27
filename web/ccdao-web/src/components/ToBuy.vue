<template>
  <div class="buy-container" id="ToBuy">
    <div class="tobuy">
      <div class="tobuys">
        <div class="buyone">
          <p class="buytext">{{ $t("message.HOW_TO_BUY") }}</p>
          <img src="../assets/buytext.svg" class="buytextimg" />
        </div>

        <div class="buyadd">
          <span class="buy">{{ $t("message.You_can_buy_$CCDAO_in") }}</span>
          <img src="../assets/buyarrow.svg" class="buyimg" />
          <a href="https://letsdex.com" target="_blank">
            <div class="buyaddbox" style="top: 0px; right: 300px">
              <img src="../assets/buyaddtag1.svg" class="buytag" />
              <p class="buyaddtext">{{ $t("message.LetsDEX") }}</p>
            </div>
          </a>
          <a href="https://app.uniswap.org/" target="_blank">
            <div class="buyaddbox" style="top: 0px; right: 0px">
              <img src="../assets/buyaddtag2.svg" class="buytag" />
              <p class="buyaddtext">{{ $t("message.Uniswap") }}</p>
            </div>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {};
</script>

<style lang="scss" scoped>
@import "../css/background.scss";

.buy-container {
  width: 100%;
  position: relative;
  @include div-same-size-as-background-img("../assets/bgimg3.svg");

  .tobuy {
    width: 100%;
    display: flex;
    justify-content: center;
    position: absolute;
    left: 0;
    top: 0;
  }
  .tobuys {
    position: relative;
    padding-top: 150px;
  }
  .buyone {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 400px;
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
    margin-top: 200px;
    width: 919px;
    height: 60px;
    position: relative;
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
    margin-left: 50px;
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
}
</style>
