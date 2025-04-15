<template>
  <div class="connector" id="connector">
    <div class="connector-div">
      <div class="content">
        <div class="title">
          {{ $t("message.Connector") }}
          <img src="../assets/buytext.svg" />
        </div>
        <div class="explain">
          <div>
            <img src="../assets/unlimitAccounts.svg" alt="" />
          </div>
          <div style="margin-left: 100px">
            <div class="connector_explain" style="margin-top: 33px">{{ $t("message.connector_explain") }}</div>
            <div class="just_one_plugin" style="margin-top: 38px">{{ $t("message.just_one_plugin") }}</div>
            <div id="connectorBt" style="padding-top: 40px">
              <el-button @click="toUrl('chrome')">{{ $t("message.chrome_download") }}</el-button>
              <el-button @click="toUrl('firefox')">{{ $t("message.firefox_download") }}</el-button>
            </div>
            <img style="padding-top: 80px; padding-left: 50px" src="../assets/mnemonic.svg" alt="" />
          </div>
          <div>
            <img style="padding-top: 110px" src="../assets/multiNetwork.svg" alt="" />
          </div>
        </div>
      </div>
      <div class="phoneContent">
        <div class="title">
          {{ $t("message.Connector") }}
          <img src="../assets/buytext.svg" />
        </div>
        <div class="connector_explain">{{ $t("message.connector_explain") }}</div>
        <div class="just_one_plugin">{{ $t("message.just_one_plugin") }}</div>
        <div class="showImg">
          <img class="unlimitAccounts" src="../assets/unlimitAccounts.svg" alt="" />
          <div class="right">
            <img class="multiNetwork" src="../assets/multiNetwork.svg" alt="" />
            <img class="mnemonic" src="../assets/mnemonic.svg" alt="" />
          </div>
        </div>
        <div class="phone-connector-button">
          <div>
            <span class="left" @click="() => this.$router.push('/connector/TermOfService')">{{
              $t("message.terms_of_service")
            }}</span>
            |
            <span class="right" @click="() => this.$router.push('/connector/PrivacyPolicy')">{{
              $t("message.privacy_policy")
            }}</span>
          </div>
        </div>
      </div>
    </div>
    <div class="connector-button">
      <div>
        <span class="left" @click="() => this.$router.push('/connector/TermOfService')">{{
          $t("message.terms_of_service")
        }}</span>
        |
        <span class="right" @click="() => this.$router.push('/connector/PrivacyPolicy')">{{
          $t("message.privacy_policy")
        }}</span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "Connector",
  methods: {
    toUrl(str) {
      switch (str) {
        case "chrome":
          window.open(
            "https://chrome.google.com/webstore/detail/ccdao-connector/fpondiojcgaollhcmjgpjmldjjkealjb?hl=zh-CN",
            "_blank"
          );
          break;
        case "firefox":
          window.open("https://addons.mozilla.org/zh-CN/firefox/addon/ccdao-connector/", "_blank");
          break;
      }
    },
  },
};
</script>

<style lang="scss" scoped></style>
