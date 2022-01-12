async function main() {
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

  // Waiting to deploy
  await contract.deployed()
  console.log('contract deployed to:', contract.address)
}

main()
