async function main() {
  const [owner, randomPerson, anotherRando] = await hre.ethers.getSigners()
  const utilContractFactory = await hre.ethers.getContractFactory('Util')
  const utilContract = await utilContractFactory.deploy()
  await utilContract.deployed()
  console.log('util contract addr', utilContract.address)

  const svgToolsContractFactory = await hre.ethers.getContractFactory('SvgTools', {
    libraries: {
      Util: utilContract.address,
    },
  })
  const svgToolsContract = await svgToolsContractFactory.deploy()
  await svgToolsContract.deployed()
  console.log('svg tools contract addr', svgToolsContract.address)

  const nftBuilderContractFactory = await hre.ethers.getContractFactory('NFTBuilder', {
    libraries: {
      SvgTools: svgToolsContract.address,
      Util: utilContract.address,
    },
  })
  const nftBuilderContract = await nftBuilderContractFactory.deploy()
  await nftBuilderContract.deployed()
  console.log('nft builder contract addr', nftBuilderContract.address)

  const mainContractFactory = await hre.ethers.getContractFactory('Random4Gon', {
    libraries: {
      NFTBuilder: nftBuilderContract.address,
    },
  })
  const contract = await mainContractFactory.deploy()

  // Waiting to mine.
  await contract.deployed()
  console.log('we running', contract.address)
  console.log('deployed by', owner.address)

  await logStats(contract)
  // 0
  let txn = await contract.connect(randomPerson).mint()
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

  let yes = await contract.ownerOf(0)
  console.log('owner ', yes)

  console.log('ehm', owner.address, randomPerson.address)

  txn = await contract
    .connect(randomPerson)
    ['safeTransferFrom(address,address,uint256)'](randomPerson.address, owner.address, 0)
  await txn.wait()

  console.log('after transfer')
  await logStats(contract)

  console.log('before combine')
  await logStats(contract)
  txn = await contract.combine()
  await txn.wait()

  console.log('after combine')
  await logStats(contract)

  yes = await contract.ownerOf(0)
  console.log('owner ', yes)
}

async function logStats(contract) {
  const result = await contract.getTokensForSender()
  console.log(
    'sender tokens',
    result.map(el => el.tokenId.toString())
  )
}

main()
