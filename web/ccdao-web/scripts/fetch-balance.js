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

module.exports = fetchBalance;
