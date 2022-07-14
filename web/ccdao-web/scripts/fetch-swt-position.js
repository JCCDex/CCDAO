const BigNumber = require("bignumber.js").default;
const fetch = require("./service");

const fetchBalance = async (address) => {
  const res = await fetch({
    url: "https://swtcscan.jccdex.cn/wallet/balance/" + address,
    methods: "get",
    params: {
      w: address,
    },
  });
  const data = res.data;
  delete data._id;
  delete data.feeflag;
  const balances = [];
  for (const key in data) {
    if (Object.hasOwnProperty.call(data, key)) {
      const d = data[key];
      if (key === "SWTC") {
        balances.push(Object.assign(d, { currency: "SWT", issuer: "" }));
      } else {
        balances.push(Object.assign(d, { currency: key.split("_")[0], issuer: key.split("_")[1] }));
      }
    }
  }
  return balances;
};

const fetchPosition = async () => {
  const contract = {
    ETH: "jsk45ksJZUB7durZrLt5e86Eu2gtiXNRN4",
    BSC: "j9z82uwmvZ7WUHRrfXWKuRCJiXHXXh9Js",
    HECO: "jse3Ph2DP7zRnBXAXvLduoWr6Fag2iqevH",
    Polygon: "jBttJkCeeXPfiL7Wa7gGmC5EKCAYuK3qGS",
  };

  const promises = [];

  for (const c in contract) {
    promises.push(fetchBalance(contract[c]));
  }

  const balances = await Promise.all(promises);

  const totalBalance = balances
    .map((b) => {
      const balance = b.find((a) => a.currency === "CCDAO" && a.issuer === "jGa9J9TkqtBcUoHe2zqhVFFbgUVED6o9or");
      if (balance && balance.value) {
        return balance.value;
      }
      return "0";
    })
    .reduce((a, b) => {
      return new BigNumber(a).plus(b).toString(10);
    });

  const totalSupply = new BigNumber(1000000000);

  return totalSupply.minus(totalBalance).toString(10);
};

module.exports = fetchPosition;
