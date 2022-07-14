const BigNumber = require("bignumber.js").default;
const fetch = require("./service");

const fetchTicker = async () => {
  const res = await fetch({
    url: "https://ijib059e8792d5.jccdex.cn/info/alltickers",
    methods: "get",
  });
  const data = res.data["CCDAO-JUSDT"];
  const x = new BigNumber(data[6]);
  const y = new BigNumber(data[1]);
  if (x.isNaN() || y.isNaN()) {
    throw new Error("The ticker data is empty");
  }
  return {
    totalVolumeTraded: x.integerValue(1).toNumber(),
    fullyDilutedValuation: x.times(y).integerValue(1).toNumber(),
  };
};

module.exports = fetchTicker;
