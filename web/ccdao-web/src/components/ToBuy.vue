<template>
  <div class="buy-container" id="trade">
    <div class="tobuy">
      <div class="tobuys">
        <div class="buyone">
          <p class="buytext">{{ $t("message.HOW_TO_BUY") }}</p>
          <img src="../assets/buytext.svg" class="buytextimg" />
        </div>

        <div class="buyadd">
          <span class="buy">{{ $t("message.You_can_buy_$CCDAO_in") }}</span>
          <img src="../assets/buyarrow.svg" class="buyimg" />
          <a class="buyaddimport" href="https://letsdex.com" target="_blank">
            <div class="buyaddbox buylocation1">
              <img src="../assets/buyaddtag1.svg" class="buytag" />
              <p class="buyaddtext">{{ $t("message.LetsDEX") }}</p>
            </div>
          </a>
          <a class="buyaddimport" href="https://app.uniswap.org/" target="_blank">
            <div class="buyaddbox buylocation2">
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

<style lang="scss" scoped></style>
