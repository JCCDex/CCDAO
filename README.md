# CCDAO

Cross Chain DAO

## Contract address

- ETH: [0x1487Bd704Fa05A222B0aDB50dc420f001f003045](https://cn.etherscan.com/token/0x1487Bd704Fa05A222B0aDB50dc420f001f003045)
- BSC: [0x200f73aba0d6f8919086f64035ef900669ea2de2](https://www.bscscan.com/token/0x200f73aba0d6f8919086f64035ef900669ea2de2)
- ~~HECO: [0xd4d0e5651debcab0d7abfd549bbf2c4154a3442c](https://hecoinfo.com/token/0xd4d0e5651debcab0d7abfd549bbf2c4154a3442c)~~
- Polygon: [0xee546f831533a913848b72f36a9d5e437f63dbb9](https://polygonscan.com/token/0xee546f831533a913848b72f36a9d5e437f63dbb9)

## common command tool

```bash
jcc-ethereum-tool --abi build/contracts/ERC20Factory.json --contractAddr 0x1487bd704fa05a222b0adb50dc420f001f003045 --method "name"

jcc-ethereum-tool --abi build/contracts/ERC20Factory.json --contractAddr 0x1487Bd704Fa05A222B0aDB50dc420f001f003045 --method "burn" --parameters '"0x3907ACb4C1818ADf72d965c08E0a79aF16E7ffB8", web3.utils.toWei("50000000")' --config config.main.json --keystore 0xaaaaa

jcc-ethereum-tool --abi build/contracts/ERC20Factory.json --contractAddr 0x200f73aba0d6f8919086f64035ef900669ea2de2 --method "mint" --parameters '"0xf2fa7c80f7f5272a820981c8168859242525b807", web3.utils.toWei("50000000")' --config config.bsc.json --keystore 0xbbbbb

```
