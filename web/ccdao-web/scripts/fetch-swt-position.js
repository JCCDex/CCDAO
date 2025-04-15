const BigNumber = require("bignumber.js").default;
const fetchBalance = require("./fetch-balance");
const { isCCDAO } = require("./utils");

const fetchPosition = async () => {
  const contract = {
    ETH: "jsk45ksJZUB7durZrLt5e86Eu2gtiXNRN4",
    BSC: "j9z82uwmvZ7WUHRrfXWKuRCJiXHXXh9Js",
    Polygon: "jBttJkCeeXPfiL7Wa7gGmC5EKCAYuK3qGS",
  };

  const promises = [];

  for (const c in contract) {
    promises.push(fetchBalance(contract[c]));
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

  const totalSupply = new BigNumber(1000000000);

  return totalSupply.minus(totalBalance).toString(10);
};

module.exports = fetchPosition;
