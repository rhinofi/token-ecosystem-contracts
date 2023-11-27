/* global artifacts, config, web3 */
const DVF = artifacts.require('DeversiFi.sol')
const xDVF = artifacts.require('./StakedDVF.sol')


const makeDeployer = deployer => async (contract, args) => {
  await deployer.deploy(contract, ...args)
  return contract.deployed()
}

module.exports = async function (deployer, network, accounts) {
  if (deployer.network === 'test') {
    // No migrations in test network
    return
  }

  const deploy = makeDeployer(deployer)

  console.log(accounts[0])
  // const tx = await deploy(DVF, [accounts[0]])
  const tx = await deploy(xDVF, ['0x142c917cCb8dDDbA12086C4dd96aC743F96Cc708'])
}
