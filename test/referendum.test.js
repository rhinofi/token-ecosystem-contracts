/* global it, contract, artifacts, assert, web3 */
const DVF = artifacts.require('DeversiFi.sol')
const StakedDVF = artifacts.require('./StakedDVF.sol')
const ReferendumManager = artifacts.require('./ReferendumManager.sol')
const Timelock = artifacts.require('./Timelock.sol')

const catchRevert = require('./helpers/exceptions').catchRevert
const { moveForwardTime, assertEventOfType } = require('./helpers/utils')
const BN = web3.utils.BN
const _1e18 = new BN('1000000000000000000')

contract('ReferendumManager', (accounts) => {

  let xdvf, dvf, refMan, timelock

  beforeEach('redeploy contracts', async function () {
    dvf = await DVF.new(accounts[0])
    xdvf = await StakedDVF.new(dvf.address)
    timelock = await Timelock.new(accounts[9], 4 * 24 * 60 * 60)
    refMan = await ReferendumManager.new(timelock.address, xdvf.address)
    timelock.setReferendumManager(refMan.address, { from: accounts[9] })
  })

  it('deploy: timelock and refmanager contracts deployed with correct parameters', async () => {
    const rm = await timelock.referendumManager()
    assert.equal(rm, refMan.address, 'RM not set')

    const admin = await timelock.admin()
    assert.equal(admin, accounts[9], 'Admin not set')

    const r = await refMan.votingPeriod()
    assert.equal(r.toString(), 17280, 'Voting period not set')

    const votingToken = await refMan.xdvf()
    assert.equal(votingToken, xdvf.address, 'xdvf not set')
  })

  it('initiateReplaceAdminReferendum: creates referendum and takes snapshot', async () => {
    // Make three accounts which hold xDVF prior to proposals
    await dvf.approve(xdvf.address, _1e18.mul(new BN(100000)))
    await xdvf.enter(_1e18.mul(new BN(100000)))
    await xdvf.transfer(accounts[5], _1e18.mul(new BN(1000)))
    await xdvf.transfer(accounts[6], _1e18.mul(new BN(2000)))
    await xdvf.transfer(accounts[7], _1e18.mul(new BN(2000)))

    // Then create proposal
    await refMan.initiateReplaceAdminReferendum(accounts[8], 'Multisig has gone rogue, replace it!')

    const snapId = (await refMan.referendums(1)).votesSnapId

    // Then check whether snapshotted balances are correctly reflected
    await xdvf.transfer(accounts[8], _1e18.mul(new BN(1000)), {from: accounts[7]})
    const voteBalanceAcc6 = await refMan.getVotesForReferendum(accounts[6], snapId)
    const voteBalanceAcc7 = await refMan.getVotesForReferendum(accounts[7], snapId)
    const voteBalanceAcc8 = await refMan.getVotesForReferendum(accounts[8], snapId)
    assert.equal(voteBalanceAcc6.toString(), _1e18.mul(new BN(2000)).toString(), 'votes incorrect')
    assert.equal(voteBalanceAcc7.toString(), _1e18.mul(new BN(2000)).toString(), 'votes incorrect')
    assert.equal(voteBalanceAcc8.toString(), (new BN(0)).toString(), 'votes incorrect')
  })


})
