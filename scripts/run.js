async function main() {
  const [owner, randomPerson, anotherRando] = await hre.ethers.getSigners()
  const contractFactory = await hre.ethers.getContractFactory('Random4Gon')
  const contract = await contractFactory.deploy()

  // Waiting to mine.
  await contract.deployed()
  console.log('we running', contract.address)
  console.log('deployed by', owner.address)

  // 0
  let txn = await contract.mint()
  await txn.wait()

  // 1
  txn = await contract.mint()
  await txn.wait()

  // 2
  txn = await contract.connect(randomPerson).mint()
  await txn.wait()

  // 3
  txn = await contract.mint()
  await txn.wait()

  // 4
  txn = await contract.connect(randomPerson).mint()
  await txn.wait()

  // 5
  txn = await contract.connect(randomPerson).mint()
  await txn.wait()

  // 6
  txn = await contract.connect(anotherRando).mint()
  await txn.wait()

  // 7
  txn = await contract.mint()
  await txn.wait()

  // 8
  txn = await contract.mint()
  await txn.wait()

  const [fgTokens, bgTokens] = await contract.tokensOfOwner()
  console.log(
    'fg tokens',
    fgTokens.map(el => el.tokenId.toString())
  )
  console.log(
    'bg tokens',
    bgTokens.map(el => el.tokenId.toString())
  )
}

main()
