const Web3 = require("web3");
const { SwapBalance, SwapContract, Token, SwapMulticall, ERC20 } = require("@jccdex/ethereum-contract");
const { Web3Provider } = require("@ethersproject/providers");
const BigNumber = require("bignumber.js").default;

const CCDAO_CONTRACT = "0xd4d0e5651debcab0d7abfd549bbf2c4154a3442c";

const CCDAO_FINGATE = "0x1cda44Da59E8e621088a06756Eb772eF1a6024D9";

const multicall = "0x2C55D51804CF5b436BA5AF37bD7b8E5DB70EBf29";

const chainId = 128;

const web3 = new Web3(new Web3.providers.HttpProvider("https://http-mainnet-node.defibox.com"));

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
