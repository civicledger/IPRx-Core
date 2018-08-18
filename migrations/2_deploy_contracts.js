const Web3Utils = require('web3-utils');

const KeyValueStorage = artifacts.require('./storage/KeyValueStorage.sol');

const IPOrganisations = artifacts.require('./ip-organisations/IPOrganisations.sol');
const PatentToken = artifacts.require('./ip-organisations/australia/patents/PatentToken.sol');
const PatentRegistration = artifacts.require('./ip-organisations/australia/patents/PatentRegistration.sol');

const Exchange = artifacts.require('./exchange/Exchange.sol');
const ExchangeSubmitOrder = artifacts.require('./exchange/ExchangeSubmitOrder.sol');
const Marketplaces = artifacts.require('./exchange/Marketplaces.sol');

const accounts = web3.eth.accounts;
const owner = accounts[0];

module.exports = function(deployer, network) {
    return deployer
        .deploy(KeyValueStorage)
        .then(async () => {
            return deployer.deploy([
                [IPOrganisations, KeyValueStorage.address],
                [PatentToken, KeyValueStorage.address],
                [PatentRegistration, KeyValueStorage.address],
                [Exchange, KeyValueStorage.address],
                [ExchangeSubmitOrder, KeyValueStorage.address],
                [Marketplaces, KeyValueStorage.address]
            ]);
        })
        .then(async () => {
            // Post deployment steps
            let storageContract = await KeyValueStorage.deployed();

            // Setup contract addresses

            // IP Organisations
            let ipOrganisationContract = await IPOrganisations.deployed();
            //   Get contract by name
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.name', 'IPOrganisations'), ipOrganisationContract.address);
            //   Check contract is an authorised contract
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.address', ipOrganisationContract.address), ipOrganisationContract.address);

            // Marketplaces
            let marketplacesContract = await Marketplaces.deployed();
            //   Get contract by name
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.name', 'Marketplaces'), marketplacesContract.address);
            //   Check contract is an authorised contract
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.address', marketplacesContract.address), marketplacesContract.address);

            // Exchange
            let exchangeContract = await Exchange.deployed();
            //   Get contract by name
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.name', 'Exchange'), exchangeContract.address);
            //   Check contract is an authorised contract
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.address', exchangeContract.address), exchangeContract.address);

            // Exchange Submit Order
            let exchangeSubmitOrderContract = await ExchangeSubmitOrder.deployed();
            //   Get contract by name
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.name', 'ExchangeSubmitOrder'), exchangeSubmitOrderContract.address);
            //   Check contract is an authorised contract
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.address', exchangeSubmitOrderContract.address), exchangeSubmitOrderContract.address);

            // Australian Patent IP right type
            let ipoIndex = 0;
            let iprTypeName = "Patent";

            // Patent registration
            let patentRegistrationContract = await PatentRegistration.deployed();
            //   Get contract by name
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.name', 'Registration', ipoIndex, iprTypeName), patentRegistrationContract.address);
            //   Check contract is an authorised contract
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.address', patentRegistrationContract.address), patentRegistrationContract.address);

            // Australian Patent Token
            let patentTokenContract = await PatentToken.deployed();
            //   Get contract by name
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.name', 'Token', ipoIndex, iprTypeName), patentTokenContract.address);
            //   Check contract is an authorised contract
            await storageContract.setAddress(Web3Utils.soliditySha3('contract.address', patentTokenContract.address), patentTokenContract.address);            


            /// ** Insert dummy data **


            if (network == 'integration'){
                let ipOwner1 = accounts[4];
                let ipOwner2 = accounts[5];
                let ipOwner3 = accounts[6];
                let authorisedIPOAdmin = accounts[7];
                let marketplaceAccount = accounts[8];
                
                console.log('Dummy Data - Patents');

                let ipIndex1 = 1;
                await patentRegistrationContract.claimIP({from: ipOwner1});
                await patentTokenContract.setLicensable(ipIndex1, true, {from: ipOwner1});
               
                let ipIndex2 = 2;
                await patentRegistrationContract.claimIP({from: ipOwner2});
                await patentTokenContract.setLicensable(ipIndex2, true, {from: ipOwner2});
                
                let ipIndex3 = 3;
                await patentRegistrationContract.claimIP({from: ipOwner3});
                // non-licensable patent
                await patentTokenContract.setLicensable(ipIndex3, false, {from: ipOwner3});

                console.log('Dummy Data - IPO');
                // create Australian IPO - will be created at index 0
                await ipOrganisationContract.add('IP Australia', 'https://www.ipaustralia.gov.au/', {from: owner});
                
                let ipoIndex = 0;
                console.log(`Dummy Data - IPO Admin ${authorisedIPOAdmin}`);
                await ipOrganisationContract.addressAuthorise(ipoIndex, authorisedIPOAdmin, {from: owner});

                console.log(`Dummy Data - IP Right Type (Patent) ${patentTokenContract.address}`);
                await ipOrganisationContract.ipTypeAdd(ipoIndex, 'Patent', patentTokenContract.address, {from: authorisedIPOAdmin});

                console.log(`Dummy Data - Marketplace ${marketplaceAccount}`);
                await marketplacesContract.register('name', 'website', marketplaceAccount, ipoIndex, {from: authorisedIPOAdmin});
            }
            
        });
};
  