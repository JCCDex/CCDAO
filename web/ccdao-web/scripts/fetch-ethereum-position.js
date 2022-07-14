const Web3 = require("web3");
const { SwapBalance, SwapContract, Token, SwapMulticall } = require("@jccdex/ethereum-contract");
const { Web3Provider } = require("@ethersproject/providers");
const BigNumber = require("bignumber.js").default;

/**
 * @url [CCDAO合约地址](https://cn.etherscan.com/token/0x1487Bd704Fa05A222B0aDB50dc420f001f003045)
 */
const CCDAO_CONTRACT = "0x1487Bd704Fa05A222B0aDB50dc420f001f003045";

/**
 * @url [CCDAO银关地址](https://cn.etherscan.com/token/0x3907acb4c1818adf72d965c08e0a79af16e7ffb8)
 */
const CCDAO_FINGATE = "0x3907acb4c1818adf72d965c08e0a79af16e7ffb8";

const multicall = "0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696";

const chainId = 1;

const web3 = new Web3(new Web3.providers.HttpProvider("https://etha.jccdex.cn"));

const library = new Web3Provider(web3.currentProvider, chainId);
const swapContract = new SwapContract(CCDAO_FINGATE, multicall, library);
const swapMulticall = new SwapMulticall(chainId, web3, swapContract);
const swapBalance = new SwapBalance(swapMulticall);

const token = new Token(chainId, CCDAO_CONTRACT, 18, "CCDAO", "Cross Chain DAO");

const fetchPosition = async () => {
  // 获取银关合约持有数量
  const balance = await swapBalance.useTokenBalance(CCDAO_FINGATE, token);
  // 发行总量
  const totalSupply = new BigNumber(1000000000);
  // 流通量
  const circulation = totalSupply.minus(balance.toSignificant(6)).toString(10);
  return circulation;
};

module.exports = fetchPosition;
