const fs = require("fs");
const path = require("path");
const file = path.join(__dirname, "..", "./public/config.json");
const CronJob = require("cron").CronJob;
const fetchTicker = require("./fetch-ticker");
const fetchEthereumPosition = require("./fetch-ethereum-position");
const fetchSwtPosition = require("./fetch-swt-position");

const sync = async () => {
  try {
    const ticker = await fetchTicker();
    const ethereumPosition = await fetchEthereumPosition();
    const swtPosition = await fetchSwtPosition();

    const data = {
      totalVolumeTraded: ticker.totalVolumeTraded,
      fullyDilutedValuation: ticker.fullyDilutedValuation,
      ETH: ethereumPosition,
      SWT: swtPosition,
    };
    fs.writeFileSync(file, JSON.stringify(data, null, 2), "utf-8");
  } catch (error) {
    console.error("sync error: ", error);
  }
};

const job = new CronJob(
  "1 */10 * * * *",
  () => {
    sync();
  },
  null,
  true
);
job.start();
