const DataWalletToken = artifacts.require('./helpers/DataWalletToken.sol')

const assertFail = require('./helpers/assertFail.js')
const { increaseTimeTo } = require('./helpers/increaseTime')
const { latestTime, duration } = require('./helpers/latestTime')

contract('DataWalletToken', (accounts) => {

  beforeEach(async () => {
    this.token = await DataWalletToken.new({ from: accounts[0] })
  })

  it('should have the name DataWallet Token', async () => {
    assert.equal(await this.token.name.call(), 'DataWallet Token', "DataWallet Token wasn't the name")
  })

  it('should have the symbol DXT', async () => {
    assert.equal(await this.token.symbol.call(), 'DXT', "DXT wasn't the symbol")
  })

  it('should have decimals set to 8', async () => {
    assert.equal(await this.token.decimals.call(), 8, "8 wasn't the value of decimals")
  })

  it('should have INITIAL_SUPPLY set to 1 bilion dxt', async () => {
    assert.equal(await this.token.INITIAL_SUPPLY.call(), 1000000000 * (10**8), "1e17 wasn't the value of INITIAL_SUPPLY units")
  })

  it('should set totalSupply to 1 bilion dxt', async () => {
    assert.equal(await this.token.totalSupply.call(), 1000000000 * (10**8), "1e17 wasn't the value of totalSupply units")
  })


  it('should be able to transfer 100 if transfers are unpaused', async () => {
    await this.token.pause({ from: accounts[0] })
    await this.token.unpause({ from: accounts[0] })

    const startingBalance = await this.token.balanceOf(accounts[0])
    await this.token.transfer(accounts[1], 100, { from: accounts[0] })

    const balance0 = await this.token.balanceOf(accounts[0])
    assert.equal(balance0.toNumber(), startingBalance - 100)

    const balance1 = await this.token.balanceOf(accounts[1])
    assert.equal(balance1.toNumber(), 100)
  })

  it('should throw an error trying to transfer while transactions are paused', async () => {
    await this.token.pause()

    try {
      await this.token.transfer(accounts[1], 100)
      
      await this.token.transfer(accounts[2], 50, { from: accounts[1] })
      assert.fail('should have thrown before')
    } catch (error) {
      assert.isAbove(error.message.search('invalid opcode'), -1, 'Invalid opcode error must be returned');
    }
  })

  it('should throw an error trying to transfer from another account while transactions are paused', async () => {
    await this.token.pause()
    try {
      await this.token.transferFrom(accounts[0], accounts[1], 100)
      
      assert.fail('should have thrown before')
    } catch (error) {
      assert.isAbove(error.message.search('invalid opcode'), -1, 'Invalid opcode error must be returned');
    }
  })
  
  it('should transfer tokens to someone if owner', async () => {
    await this.token.transfer(accounts[2], 50)
    const balance2 = await this.token.balanceOf(accounts[2])

    assert.equal(balance2.toNumber(), 50)
  })

  it('owner should be able to burn tokens', async () => {
    const { logs } = await this.token.burn(1000000000, { from: accounts[0] });
    const balance = await this.token.balanceOf(accounts[0]);

    assert.equal(balance, 1000000000 * (10**8) - 1000000000, 'should be the same')

    const event = logs.find(e => e.event === 'Burn');

    assert.isNotNull(event)
  })

  it('cannot burn more tokens than your balance', async () => {
    try {
      await this.token.burn(2e17, { from: accounts[0] })
      
      assert.fail('should have thrown before')
    } catch (error) {
      assert.isAbove(error.message.search('invalid opcode'), -1, 'Invalid opcode error must be returned');
    }
  })

})