<template>
  <el-dialog :visible.sync="visible" width="360px" :show-close="false" :center="true" :close-on-click-modal="true">
    <div slot="title">{{ $t("message.download_ccdao") }}</div>
    <div style="padding: 25px 30px 25px">
      <div style="display: flex; align-items: center">
        <img style="width: 24px" src="@/assets/CCDAODownload.svg" alt="" />
        <span style="margin-left: 10px">{{ $t("message.Version") }}: {{ info && info.version }}</span>
      </div>
      <div style="display: flex; flex-direction: column; margin-top: 25px">
        <span style="color: #787f93">{{ $t("message.apk_sha256") }}</span>
        <span style="color: #000000; margin-top: 8px">{{ info && info.checksums.apkSha256 }}</span>
      </div>
      <div style="display: flex; flex-direction: column; margin-top: 25px">
        <span style="color: #787f93">{{ $t("message.certificate_sha256") }}</span>
        <span style="color: #000000; margin-top: 8px">{{ info && info.checksums.signingCertSha256 }}</span>
      </div>
      <div class="apkDownload" style="margin-top: 40px" @click="download(info.files[0].name)">
        {{ info && info.files[0].name }}
        <img style="width: 20px; margin-left: 14px" src="@/assets/fileDownload.svg" alt="" />
      </div>
      <div class="certificateDownload" style="margin-top: 20px" @click="download(info.files[1].name)">
        {{ info && info.files[1].name }}
        <img style="width: 20px; margin-left: 14px" src="@/assets/fileDownload.svg" alt="" />
      </div>
    </div>
  </el-dialog>
</template>

<script>
export default {
  name: "Dialog",
  data() {
    return {
      visible: false,
      loading: false,
      error: null,
      info: null,
    };
  },
  methods: {
    show() {
      this.visible = true;
      this.fetchVersion();
    },

    async fetchVersion() {
      this.loading = true;
      this.error = null;
      try {
        const timestamp = new Date().getTime();
        const res = await fetch(`/version.json?t=${timestamp}`);
        if (!res.ok) throw new Error(this.$t("message.fetch_version_error"));
        this.info = await res.json();
      } catch (e) {
        this.$message.error(e.message);
      } finally {
        this.loading = false;
      }
    },

    download(filename) {
      const a = document.createElement("a");
      a.href = `/${filename}`;
      a.download = filename;
      a.click();
    },
  },
};
</script>

<style lang="scss" scoped>
.apkDownload {
  cursor: pointer;
  width: 100%;
  height: 40px;
  opacity: 1;
  border-radius: 30px;
  background: #3e9df3;
  display: flex;
  justify-content: center;
  align-items: center;
  color: #ffffff;
  &:hover {
    background: #3393e6;
  }
}
.certificateDownload {
  cursor: pointer;
  width: 100%;
  height: 40px;
  opacity: 1;
  border-radius: 30px;
  background: #4a93cf;
  display: flex;
  justify-content: center;
  align-items: center;
  color: #ffffff;
  &:hover {
    background: #3683c2;
  }
}
</style>
