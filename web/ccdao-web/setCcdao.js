const axios = require("axios");
const { default: BigNumber } = require("bignumber.js");
const fs = require("fs");
const path = require("path");
const file = path.join(__dirname, "./public/config.json");
const CronJob = require("cron").CronJob;

const setCcdao = () => {
  axios
    .get("https://ijib059e8792d5.jccdex.cn/info/alltickers")
    .then((res) => {
      const ccdao = res.data.data["CCDAO-JUSDT"];
      const data = JSON.parse(fs.readFileSync(file, "utf8"));
      let x = new BigNumber(ccdao[6]);
      let y = new BigNumber(ccdao[1]);
      if (x.isNaN() || y.isNaN()) {
        return;
      }
      data.totalVolumeTraded = x.integerValue(1).toNumber();
      data.fullyDilutedValuation = x.times(y).integerValue(1).toNumber();
      fs.writeFileSync(file, JSON.stringify(data, null, 2), "utf8");
    })
    .catch(function (error) {
      console.log(error);
    });
};

var job = new CronJob(
  "1 */10 * * * *",
  function () {
    setCcdao();
  },
  null,
  true
);
job.start();
