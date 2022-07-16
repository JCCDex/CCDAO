const fs = require("fs");
const path = require("path");
const file = path.join(__dirname, "..", "./public/config.json");
const fetchEthereumPosition = require("./fetch-ethereum-position");
const fetchSwtPosition = require("./fetch-swt-position");
const { fetchPrice, fetchVolume } = require("../scripts/fetch-ticker");
const fetchBscPosition = require("./fetch-bsc-position");
const fetchPolygonPosition = require("./fetch-polygon-position");
const fetchHecoPosition = require("./fetch-heco-position");
const BigNumber = require("bignumber.js").default;

const sync = async () => {
  try {
    const price = await fetchPrice();
    const volume = await fetchVolume();
    const ethereumPosition = await fetchEthereumPosition();
    const swtPosition = await fetchSwtPosition();
    const polygonPosition = await fetchPolygonPosition();
    const bscPosition = await fetchBscPosition();
    const hecoPosition = await fetchHecoPosition();
    const data = {
      totalVolumeTraded: new BigNumber(volume).toFixed(0),
      fullyDilutedValuation: new BigNumber(2e9).times(price).toFixed(0),
      ethereumPosition: ethereumPosition,
      swtPosition,
      bscPosition,
      polygonPosition,
      hecoPosition,
    };
    fs.writeFileSync(file, JSON.stringify(data, null, 2), "utf-8");
  } catch (error) {
    console.error("sync error: ", error);
  }
};

sync();
