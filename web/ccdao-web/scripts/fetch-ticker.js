const BigNumber = require("bignumber.js").default;
const fetch = require("./service");
const fetchBalance = require("./fetch-balance");
const { isCCDAO } = require("./utils");
const accounts = [
  "jaD7WM3G38RUBA12jtgXLGFXqgVZvCCq12",
  "jEZHFAYMZMrYVrqetoK9b8HBv2NE1YjaZN",
  "jP4nwWb6Zrk748LBUXew5Ys7RWvGCncCd1",
];

const fetchPrice = async () => {
  const res = await fetch({
    url: "https://ijib059e8792d5.jccdex.cn/info/alltickers",
    methods: "get",
  });
  const data = res.data["CCDAO-JUSDT"];
  const price = new BigNumber(data[1]);
  if (price.isNaN()) {
    throw new Error("The price is empty");
  }
  return price.toString(10);
};

const fetchVolume = async () => {
  const promises = [];

  for (const a of accounts) {
    promises.push(fetchBalance(a));
  }

  const balances = await Promise.all(promises);

  const totalBalance = balances
    .map((b) => {
      const balance = b.find((a) => isCCDAO(a));
      if (balance && balance.value) {
        return balance.value;
      }
      return "0";
    })
    .reduce((a, b) => {
      return new BigNumber(a).plus(b).toString(10);
    });

  const volume = new BigNumber(totalBalance).div(0.002).toString(10);
  return volume;
};

module.exports = {
  fetchPrice,
  fetchVolume,
};
