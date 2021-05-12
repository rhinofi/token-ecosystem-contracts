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

})
