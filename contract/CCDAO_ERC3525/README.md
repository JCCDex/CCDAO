# AVA Fund Contract

AVA 基金合约是基于ERC3525标准基础开发的一个SFT实现

ERC3525 & ERC721 均为 [solv-finance](https://github.com/solv-finance/erc-3525)的实现代码移植到Foundry开发环境。

## 构建开发环境

clone本项目代码，安装Foundry开发环境，在本目录下

```bash
forge install install OpenZeppelin/openzeppelin-contracts
forge install install OpenZeppelin/openzeppelin-contracts-upgradeable
```

执行单元测试

```bash
forge test
```

