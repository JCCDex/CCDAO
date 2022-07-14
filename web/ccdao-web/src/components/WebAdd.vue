<template>
  <div class="contract" id="contract">
    <div class="webadd">
      <div class="webadds">
        <div class="webAddone">
          <p class="addtext">{{ $t("message.On-chain_contract_address") }}</p>
          <img src="../assets/addtext.svg" class="addtextimg" />
        </div>

        <div class="addbox addboxlocation1">
          <div class="addboxhead">
            <p style="left: 40px; top: 1px">{{ $t("message.ETH") }}</p>
          </div>
          <a href="https://cn.etherscan.com/token/0x1487bd704fa05a222b0adb50dc420f001f003045" target="_blank">
            <span class="spantext">0x1487bd704fa05a222b0adb50dc420f001f003045</span>
            <img src="../assets/rightarrow.svg" class="right" />
          </a>
        </div>
        <div class="addbox addboxlocation2">
          <div class="addboxhead">
            <p style="left: 30px; top: 1px">{{ $t("message.SWTC") }}</p>
          </div>
          <a
            href="https://swtcscan.jccdex.cn/#/tokendetail/?token=CCDAO_jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or"
            target="_blank"
          >
            <span class="spantext"
              >CCDAO&nbsp;&nbsp;<span class="spantext1">{{ $t("message.issuer") }}</span></span
            >
            <img src="../assets/rightarrow.svg" class="right" />
          </a>
        </div>
        <div class="addbox addboxlocation2">
          <div class="addboxhead">
            <p style="left: 30px; top: 1px">{{ $t("message.BSC") }}</p>
          </div>
          <a href="https://www.bscscan.com/token/0x200f73aba0d6f8919086f64035ef900669ea2de2" target="_blank">
            <span class="spantext">0x200f73aba0d6f8919086f64035ef900669ea2de2</span>
            <img src="../assets/rightarrow.svg" class="right" />
          </a>
        </div>
        <div class="addbox addboxlocation2">
          <div class="addboxhead">
            <p style="left: 30px; top: 1px">{{ $t("message.HECO") }}</p>
          </div>
          <a href="https://hecoinfo.com/token/0xd4d0e5651debcab0d7abfd549bbf2c4154a3442c" target="_blank">
            <span class="spantext">0xd4d0e5651debcab0d7abfd549bbf2c4154a3442c</span>
            <img src="../assets/rightarrow.svg" class="right" />
          </a>
        </div>
        <div class="addbox addboxlocation2">
          <div class="addboxhead">
            <p style="left: 30px; top: 1px">{{ $t("message.Polygon") }}</p>
          </div>
          <a href="https://polygonscan.com/token/0xee546f831533a913848b72f36a9d5e437f63dbb9" target="_blank">
            <span class="spantext">0xee546f831533a913848b72f36a9d5e437f63dbb9</span>
            <img src="../assets/rightarrow.svg" class="right" />
          </a>
        </div>
        -->
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "WebAdd",
};
</script>

<style lang="scss" scoped></style>
