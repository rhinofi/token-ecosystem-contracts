# Ecosystem Contracts for DVF

## DVF

DVF is the governance token for the DeversiFi L2 protocol. It is deployed at the following address: [0xdddddd4301a082e62e84e43f474f044423921918](https://etherscan.io/address/0xdddddd4301a082e62e84e43f474f044423921918)

The token itself is ERC20 with the following extensions:
1.  Permit - allowing users to skip on-chain approval transactions via making an off-chain signature
2.  Burnable - allowing tokens to be destroyed in a neat way

These extensions give the token the flexibility to adapt to future token economics changes which are made by governance.

In order to avoid overburdening the main ERC20 token with logic that might in future become redundant it is anticipated that all other logic related to token economics and governance should exist in separate ecosystem contracts.

## xDVF

DVF can be staked to create xDVF.

xDVF provides a wrapper around DVF, which can imbue it with additional token features, and functionality. This includes the ability to receive protocol fee rewards, which are distributed to the xDVF contract as DVF.

Governance is also conducted using xDVF.

TODO:
- xDVF can be upgraded in future by a governance vote, possibly automatically migrate token holders over?

## Supporter Vesting

Tokens of early token holders will be locked up for 12 months, followed by a 24 month linear unlock period.

Whilst locked they can be staked to generate xDVF and participate in governance.

At any point after the initial 12 months tokens can be unstaked and then withdrawn.

TODOs:
- For simplicity we could find a way to stake all vested tokens on behalf of the user at the start.
- We may want to have some delegation mechanism for them to choose the address that will vote on their behalf?


## Treasury Vesting

50% of token funds will be held by a treasury / DAO.

TreasuryVester will hold all of the treasury funds, with a 3 year vesting period on them. These tokens will be able to be claimed periodically which will send them to the Timelock.

The Timelock will initially have a multisig set as its owner. Later on it will instead have a governance module as its owner.


## Governance

### Phase 1 - to go live with the rest of the contracts here

Phase 1 of governance will involve the following:
- xDVF balances used on L2 to adjust certain guage parameters, with weekly adjustments (implementation TODO)
- xDVF balances used on L2 to weight rewards on AMM token pairs, with weekly adjustment snapshots (implementation TODO)
- a multisig will be the owner of the Timelock contract (which holds spendable treasury funds)
- off-chain voting for major proposals will be done on snapshot.org using xDVF balances
- the multisig can be replaced by a vote of the multisig or by an on-chain vote of xDVF holders with 30% quorum

**Phase 1A - major proposals**

A Gnosis multisig will be used, and will implement anything approved by snapshot.org.

TODO:
- Using snapshot.org if your balances are held on L2?
- Need to create a forum, and document these processes somewhere nice / knowledge base

**Phase 1B - guage adjustments on L2**

- Design voting on L2 for gauge parameters? Realistically centralised. We could give everyone extra vaults for xDVF? They also own those but transfer there? Conditional transaction that relies on there to be an onchain transaction?

Gauge params:
- Fee split to operator vs token holders. Split initially can be between 0 and 50%
- Transfer fee. Can be between 1 and 5 dollars.
- AMM base fee. Can be between 0.1 and 0.5%
- Overall liquidity mining distribution rate
- Weighting between each pool

Will have our own dashboard. Done via DeversiFi website / app (but different section?)
- Sign something? Trust us that we adjust based on your voting...?
- How do you signal on L1...? What about L2...?
- We read your balance on L1 as well as L2 at the time of weekly snaps at midnight sunday?
- Take weighted adjustments

- Overall liquidity mining distribution rate: THIS ONE NEEDS TO BE SENT FROM L1 ?

We will need to publish some governance documentation!

### Phase

### Phase 2

After Phase 2:
- The multisig would be replaced by a more sophisticated voting mechanism, with an L2 component for voting to reduce gas cost
- Governance will also control the upgrade switch for the main protocol L1 smart-contract (via the Timelock contract)

### Future Direction

Beyond this stage DVF holders will have full ability to upgrade the governance process as they see fit. We would anticipate a push to all governance functionality implemented in Cairo so that it all takes places on L2 without gas cost.
