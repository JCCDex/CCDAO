const Web3 = require("web3");
const { SwapBalance, SwapContract, Token, SwapMulticall, ERC20 } = require("@jccdex/ethereum-contract");
const { Web3Provider } = require("@ethersproject/providers");
const BigNumber = require("bignumber.js").default;

const CCDAO_CONTRACT = "0x200f73aba0d6f8919086f64035ef900669ea2de2";

const CCDAO_FINGATE = "0xf2fa7c80f7f5272a820981c8168859242525b807";

const multicall = "0x41263cba59eb80dc200f3e2544eda4ed6a90e76c";

const chainId = 56;

const web3 = new Web3(new Web3.providers.HttpProvider("https://bsc-dataseed3.defibit.io"));

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
