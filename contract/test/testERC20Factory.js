const ERC20Factory = artifacts.require("ERC20Factory");
const ERC223Recipient = artifacts.require("MockERC223Recipient");
const assertRevert = require('./helpers/assertRevert');
const zeroAccount = require('./helpers/zeroAccount');

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("ERC20Factory", function (accounts) {
  let erc20;
  it('erc20 minable is false', async () => {
    erc20 = await ERC20Factory.new("JC Token", "JCC", 18, 2000000000, false);
    let total = await erc20.totalSupply();
    assert.equal(total.toString(), "2000000000000000000000000000");

    // test transfer administrator
    let owner = await erc20.owner();
    let admin = await erc20.admin();
    assert.equal(owner, admin);

    await erc20.transferAdministrator(accounts[1], { from: accounts[0] });
    admin = await erc20.admin();
    assert.equal(accounts[0], owner);
    assert.equal(accounts[1], admin);


    let { logs } = await erc20.transfer(accounts[2], web3.utils.toWei('1000000000'), { from: accounts[0] });
    Events = logs.find(e => e.event === 'Transfer');
    assert.notEqual(Events, undefined);
    let b0 = await erc20.balanceOf(accounts[0]);
    let b2 = await erc20.balanceOf(accounts[2]);
    assert.equal(b0.toString(), b2.toString());

    // test zero account transfer
    await assertRevert(erc20.transfer(zeroAccount, web3.utils.toWei('1000000000'), { from: accounts[2] }));

    // transfer with insufficient balance
    await assertRevert(erc20.transfer(accounts[0], web3.utils.toWei('1000000001'), { from: accounts[2] }));

    // test approve function
    await erc20.approve(accounts[1], web3.utils.toWei('1000000000'), { from: accounts[2] });
    let allow = await erc20.allowance(accounts[2], accounts[1]);
    assert.equal(web3.utils.fromWei(allow).toString(), '1000000000');

    await erc20.transferFrom(accounts[2], accounts[3], web3.utils.toWei('500000000'), { from: accounts[1] })
    let b3 = await erc20.balanceOf(accounts[3]);
    assert.equal(web3.utils.fromWei(b3).toString(), '500000000');
    allow = await erc20.allowance(accounts[2], accounts[1]);
    assert.equal(web3.utils.fromWei(allow).toString(), '500000000');

    // adjust allowance
    await erc20.increaseAllowance(accounts[1], web3.utils.toWei('250000000'), { from: accounts[2] });
    allow = await erc20.allowance(accounts[2], accounts[1]);
    assert.equal(web3.utils.fromWei(allow).toString(), '750000000');

    await erc20.decreaseAllowance(accounts[1], web3.utils.toWei('50000000'), { from: accounts[2] });
    allow = await erc20.allowance(accounts[2], accounts[1]);
    assert.equal(web3.utils.fromWei(allow).toString(), '700000000');

    // test burn
    await assertRevert(erc20.burn(accounts[2], web3.utils.toWei('25000000'), { from: accounts[1] }));
    total = await erc20.totalSupply();
    assert.equal(web3.utils.fromWei(total).toString(), '2000000000');
    b2 = await erc20.balanceOf(accounts[2]);
    assert.equal(web3.utils.fromWei(b2).toString(), '500000000');

    // test black list
    await erc20.addBlackList(accounts[2], { from: accounts[1] });
    assert.equal(await erc20.getBlackListStatus(accounts[2]), true);
    // burn fail when minable is false
    b2 = await erc20.balanceOf(accounts[2]);
    await assertRevert(erc20.burn(accounts[2], b2), { from: accounts[1] });
    b2 = await erc20.balanceOf(accounts[2]);
    assert.equal(web3.utils.fromWei(b2).toString(), '500000000');
    await erc20.removeBlackList(accounts[2], { from: accounts[1] });
    assert.equal(await erc20.getBlackListStatus(accounts[2]), false);
  });

  it('erc20 minable is true', async () => {
    erc20 = await ERC20Factory.new("JC Token", "JCC", 18, 2000000000, true);
    let total = await erc20.totalSupply();
    assert.equal(total.toString(), "0");

    // test transfer administrator
    let owner = await erc20.owner();
    let admin = await erc20.admin();
    assert.equal(owner, admin);

    await erc20.transferAdministrator(accounts[1], { from: accounts[0] });
    admin = await erc20.admin();
    assert.equal(accounts[0], owner);
    assert.equal(accounts[1], admin);

    // test mint
    let { logs } = await erc20.mint(accounts[2], web3.utils.toWei('1000000000'), { from: accounts[0] });
    let Events = logs.find(e => e.event === 'Mint');
    assert.notEqual(Events, undefined);
    Events = logs.find(e => e.event === 'Transfer');
    assert.notEqual(Events, undefined);

    let ret = await erc20.transfer(accounts[3], web3.utils.toWei('500000000'), { from: accounts[2] });
    Events = ret.logs.find(e => e.event === 'Transfer');
    assert.notEqual(Events, undefined);
    let b2 = await erc20.balanceOf(accounts[2]);
    let b3 = await erc20.balanceOf(accounts[3]);
    assert.equal(b2.toString(), b3.toString());

    // test zero account transfer
    await assertRevert(erc20.transfer(zeroAccount, web3.utils.toWei('500000000'), { from: accounts[2] }));

    // transfer with insufficient balance
    await assertRevert(erc20.transfer(accounts[0], web3.utils.toWei('500000001'), { from: accounts[2] }));

    // test approve function
    await erc20.approve(accounts[1], web3.utils.toWei('500000000'), { from: accounts[2] });
    let allow = await erc20.allowance(accounts[2], accounts[1]);
    assert.equal(web3.utils.fromWei(allow).toString(), '500000000');

    await erc20.transferFrom(accounts[2], accounts[4], web3.utils.toWei('250000000'), { from: accounts[1] })
    let b4 = await erc20.balanceOf(accounts[4]);
    assert.equal(web3.utils.fromWei(b4).toString(), '250000000');
    allow = await erc20.allowance(accounts[2], accounts[1]);
    assert.equal(web3.utils.fromWei(allow).toString(), '250000000');

    // adjust allowance
    await erc20.increaseAllowance(accounts[1], web3.utils.toWei('250000000'), { from: accounts[2] });
    allow = await erc20.allowance(accounts[2], accounts[1]);
    assert.equal(web3.utils.fromWei(allow).toString(), '500000000');

    await erc20.decreaseAllowance(accounts[1], web3.utils.toWei('250000000'), { from: accounts[2] });
    allow = await erc20.allowance(accounts[2], accounts[1]);
    assert.equal(web3.utils.fromWei(allow).toString(), '250000000');

    // test burn
    ret = await erc20.burn(accounts[2], web3.utils.toWei('250000000'), { from: accounts[1] });
    Events = ret.logs.find(e => e.event === 'Burn');
    assert.notEqual(Events, undefined);
    total = await erc20.totalSupply();
    assert.equal(web3.utils.fromWei(total).toString(), '750000000');
    b3 = await erc20.balanceOf(accounts[3]);
    assert.equal(web3.utils.fromWei(b3).toString(), '500000000');

    // test black list
    await erc20.addBlackList(accounts[3], { from: accounts[1] });
    assert.equal(await erc20.getBlackListStatus(accounts[3]), true);

    b3 = await erc20.balanceOf(accounts[3]);
    await erc20.burn(accounts[3], b3, { from: accounts[1] });
    b3 = await erc20.balanceOf(accounts[3]);
    assert.equal(web3.utils.fromWei(b3).toString(), '0');
    total = await erc20.totalSupply();
    assert.equal(web3.utils.fromWei(total).toString(), '250000000');

    await erc20.removeBlackList(accounts[3], { from: accounts[1] });
    assert.equal(await erc20.getBlackListStatus(accounts[3]), false);

    // test erc223
    let receiver = await ERC223Recipient.new();
    ret = await erc20.methods['transfer(address,uint256,bytes)'](receiver.address, web3.utils.toWei('100000000'), "0x2233", { from: accounts[4] });
    Events = ret.logs.find(e => e.event === 'TransferData');
    assert.notEqual(Events, undefined);
    let br = await erc20.balanceOf(receiver.address);
    assert.equal(web3.utils.fromWei(br).toString(), '100000000');
  });
});
