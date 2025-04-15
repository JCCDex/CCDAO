const Web3 = require("web3");
const { SwapBalance, SwapContract, Token, SwapMulticall, ERC20 } = require("@jccdex/ethereum-contract");
const { Web3Provider } = require("@ethersproject/providers");
const BigNumber = require("bignumber.js").default;

const CCDAO_CONTRACT = "0xee546f831533a913848b72f36a9d5e437f63dbb9";

const CCDAO_FINGATE = "0x49243438d1E20a9e1C338112e72c6A788f5fb0cC";

const multicall = "0x11ce4B23bD875D7F5C6a31084f55fDe1e9A87507";

const chainId = 137;

const web3 = new Web3(new Web3.providers.HttpProvider("https://rpc-mainnet.matic.quiknode.pro"));

const library = new Web3Provider(web3.currentProvider, chainId);
const swapContract = new SwapContract(CCDAO_FINGATE, multicall, library);
const swapMulticall = new SwapMulticall(chainId, web3, swapContract);
const swapBalance = new SwapBalance(swapMulticall);

const token = new Token(chainId, CCDAO_CONTRACT, 18, "CCDAO", "Cross Chain DAO");
const erc20 = new ERC20(CCDAO_FINGATE, token, swapMulticall, swapContract);

const fetchPosition = async () => {
  // 获取银关合约持有数量
  const balance = await swapBalance.useTokenBalance(CCDAO_FINGATE, token);
  // 发行总量
  const totalSupply = await erc20.totalSupply();
  // 流通量
  const circulation = new BigNumber(totalSupply).minus(balance.toSignificant(6)).toString(10);
  return circulation;
};

module.exports = fetchPosition;
