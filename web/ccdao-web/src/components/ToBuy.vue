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
          <div>
            <div>
              <a href="https://letsdex.com" target="_blank">
                <div class="buyaddbox buylocation1">
                  <img src="../assets/buyaddtag1.svg" class="buytag" />
                  <p class="buyaddtext">{{ $t("message.LetsDEX") }}</p>
                </div>
              </a>
              <a href="https://app.uniswap.org/" target="_blank">
                <div class="buyaddbox buylocation2">
                  <img src="../assets/buyaddtag2.svg" class="buytag" />
                  <p class="buyaddtext">{{ $t("message.Uniswap") }}</p>
                </div>
              </a>
            </div>
            <div>
              <a
                href="https://pancakeswap.finance/swap?chain=bsc&outputCurrency=0x200F73AbA0D6F8919086F64035eF900669ea2De2"
                target="_blank"
              >
                <div class="buyaddbox buylocation3">
                  <img src="../assets/buyaddtag3.svg" class="buytag" />
                  <p class="buyaddtext">{{ $t("message.PancakeSwap") }}</p>
                </div>
              </a>
              <a
                href="https://quickswap.exchange/#/swap?swapIndex=1&currency0=ETH&currency1=0xee546f831533a913848b72f36a9D5E437F63dbB9"
                target="_blank"
              >
                <div class="buyaddbox buylocation4">
                  <img src="../assets/buyaddtag4.svg" class="buytag" />
                  <p class="buyaddtext">{{ $t("message.Quickswap") }}</p>
                </div>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {};
</script>

<style lang="scss" scoped></style>
