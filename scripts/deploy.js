const fs = require('fs');
const path = require('path');
const ethers = require('ethers');
const dotenv = require('dotenv');
dotenv.config();

const artifactPath = path.join(__dirname, '..', 'artifacts', 'contracts', 'bountyfactory.sol', 'BountyFactory.json');

async function main() {
    console.log("deploying...")
    const contractData = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
    const contractABI = contractData.abi;
    const contractBytecode = contractData.bytecode;

    const provider = new ethers.JsonRpcProvider("https://testnet-rpc.monad.xyz");
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    const factory = new ethers.ContractFactory(contractABI, contractBytecode, wallet);
    const contract = await factory.deploy(wallet.address);
    await contract.waitForDeployment();
    console.log(`Contract deployed at address: ${contract.target}`);
}

module.exports = main;
