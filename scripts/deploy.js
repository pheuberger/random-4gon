async function main() {
  const contractFactory = await hre.ethers.getContractFactory('Random4Gon')
  const contract = await contractFactory.deploy()

  // Waiting to mine.
  await contract.deployed()
  console.log('contract deployed to:', contract.address)

  //   let txn = await contract.mint()
  //   await txn.wait()
  //   console.log('Minted NFT #1')

  //   txn = await contract.mint()
  //   await txn.wait()
  //   console.log('Minted NFT #2')

  //   txn = await contract.mint()
  //   await txn.wait()
  //   console.log('Minted NFT #3')
}

main()
