<template>
  <div class="contract" id="contract">
    <div class="webadd">
      <div class="webadds">
        <div class="webAddone">
          <p class="addtext">{{ $t("message.On-chain_contract_address") }}</p>
          <img src="../assets/addtext.svg" class="addtextimg" />
        </div>

        <div class="addbox" style="margin-top: 130px">
          <div class="addboxhead">
            <p class="addboxtext1" style="left: 40px; top: 1px">{{ $t("message.ETH") }}</p>
          </div>
          <a href="https://cn.etherscan.com/token/0x1487bd704fa05a222b0adb50dc420f001f003045" target="_blank">
            <span class="spantext">0x1487bd704fa05a222b0adb50dc420f001f003045</span>
            <img src="../assets/rightarrow.svg" class="right" />
          </a>
        </div>
        <div class="addbox" style="margin-top: 30px">
          <div class="addboxhead">
            <p class="addboxtext1" style="left: 30px; top: 1px">{{ $t("message.SWTC") }}</p>
          </div>
          <a
            href="https://swtcscan.jccdex.cn/#/tokendetail/?token=CCDAO_jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or"
            target="_blank"
          >
            <span class="spantext"
              >CCDAO&nbsp;&nbsp;<span style="font-size: 12px">{{ $t("message.issuer") }}</span></span
            >
            <img src="../assets/rightarrow.svg" class="right" />
          </a>
        </div>
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
