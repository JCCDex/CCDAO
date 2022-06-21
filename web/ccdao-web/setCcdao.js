var axios = require("axios");
const { default: BigNumber } = require("bignumber.js");
var fs = require("fs");
var ccdao = {};
axios
  .get("https://ijib059e8792d5.jccdex.cn/info/alltickers")
  .then((res) => {
    ccdao = res.data.data["JJCC-JUSDT"];
    const data = JSON.parse(fs.readFileSync("./public/config.json", "utf8"));
    let x = new BigNumber(ccdao[6]);
    let y = new BigNumber(ccdao[1]);
    data.totalVolumeTraded = x.integerValue(1).toNumber();
    data.fullyDilutedValuation = x.times(y).integerValue(1).toNumber();
    fs.writeFileSync("./public/config.json", JSON.stringify(data), "utf8");
    console.log("success");
  })
  .catch(function (error) {
    console.log(error);
  });
