/* global it, contract, artifacts, assert, web3 */
const DVF = artifacts.require('DeversiFi.sol')
const StakedDVF = artifacts.require('./StakedDVF.sol')
const SupporterVester = artifacts.require('./SupporterVester.sol')

const catchRevert = require('./helpers/exceptions').catchRevert
const { moveForwardTime, assertEventOfType } = require('./helpers/utils')
const BN = web3.utils.BN
const _1e18 = new BN('1000000000000000000')

contract('SupporterVester', (accounts) => {

  let vester, xdvf, dvf, vestingStartTime

  beforeEach('redeploy contracts', async function () {
    dvf = await DVF.new(accounts[0])
    xdvf = await StakedDVF.new(dvf.address)
    // Start of vesting is 10 minutes after deployment
    // Cliff length is 0
    // Completion of vesting is 30 minutes after deployment
    vestingStartTime = Math.floor(Date.now() / 1000) + 10 * 60
    vester = await SupporterVester.new(
      dvf.address,
      xdvf.address,
      accounts[1],
      vestingStartTime,
      0,
      20 * 60
    )
  })

  it('deploy: vesting contract gets deployed and has correct beneficiary and parameters', async () => {
    const beneficiary = await vester.beneficiary()
    assert.equal(beneficiary, accounts[1], 'Beneficiary not set')

    const startTime = await vester.start()
    assert.equal(vestingStartTime, startTime, 'Start time not correct')
  })

  it('release: correct amounts can be released during vesting period', async () => {
    await dvf.transfer(vester.address, _1e18.mul(new BN(10000)))

    // Initially no releasable amount
    await catchRevert(vester.release({ from: accounts[1] }))

    const currentTime = Math.floor(Date.now() / 1000)
    await moveForwardTime(vestingStartTime - currentTime - 1)

    // Still no releasable amount after 10 minutes
    await catchRevert(vester.release({ from: accounts[1] }))

    await moveForwardTime(10 * 60 + 1)

    // 50% vested after 20 minutes
    await vester.release({ from: accounts[1] })
    const releasedAmount = await vester.released()
    assert.equal(releasedAmount.toString(), _1e18.mul(new BN(5000)).toString(), 'Half the tokens not released after half vesting period')
  })

  it('stake: vested tokens can be staked and unstaked', async () => {
    await dvf.transfer(vester.address, _1e18.mul(new BN(10000)))

    await vester.stake({from: accounts[1]})

    const stakedBalance = await xdvf.balanceOf(vester.address)
    assert.equal(stakedBalance.toString(), _1e18.mul(new BN(10000)).toString(), 'Not staked')

    await vester.unstake({from: accounts[1]})
  })

})
