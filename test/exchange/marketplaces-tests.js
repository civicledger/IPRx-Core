import { Marketplaces } from '../_lib/artifacts';
import { ipOrganisationAddScenario, ipOrganisationAuthoriseScenario } from '../ip-organisations/ip-organisations-scenarios';
import { assertThrows } from '../_lib/helpers';

export default function({owner}){

    const buildMarketplace = (values) => { return {name: values[0], website: values[1], address: values[2], ipoIndex: values[3]}; };

    contract("Marketplaces - administration", async (accounts) => {

        let marketplaces;
        let ipoIndex;
        let ipoAdminAddress;
        let randomAddress;
        let marketplaceAddress = '0x1111111111111111111111111111111111111111';
        before(async () => {
            marketplaces = await Marketplaces.deployed();

            // add an ip organisation (index 0)
            await ipOrganisationAddScenario({owner});

            // authorise an account to be used as IPO admin address
            ipoIndex = 0;
            ipoAdminAddress = accounts[1];
            randomAddress = accounts[2];
            await ipOrganisationAuthoriseScenario({ipOrgIndex: ipoIndex, authAddress: ipoAdminAddress, owner});
        });

        it('An authorised IPO can register a new marketplace', async () => {
            const name = 'some marketplace';
            const website = 'http://somemarketplace.com';

            // register a new marketplace using ipo admin account
            await marketplaces.register(name, website, marketplaceAddress, ipoIndex, {from: ipoAdminAddress});

            // check that the marketplace metadata was recorded
            let recordedMarketplace = buildMarketplace(await marketplaces.byIndex(0));
            assert.equal(recordedMarketplace.name, name, 'Marketplace name not recorded');
            assert.equal(recordedMarketplace.website, website, 'Marketplace website not recorded');
            assert.equal(recordedMarketplace.address, marketplaceAddress, 'Marketplace address not recorded');
            assert.equal(recordedMarketplace.ipoIndex.valueOf(), ipoIndex, 'Marketplace IPO index not recorded');
        });

        it('Random user cannot register a new marketplace', async () => {
            const name = 'some marketplace';
            const website = 'http://somemarketplace.com';

            // try to register a new marketplace with a random address
            await assertThrows(marketplaces.register(name, website, marketplaceAddress, ipoIndex, {from: randomAddress}));
        });

        it('Anyone can check that an address is a registered marketplace', async () => {

            // is a known registered marketplace registered? hope so...
            assert.isTrue(await marketplaces.isRegistered(marketplaceAddress));

            // is a known unregisterd marketplace registed? hope not...
            assert.isFalse(await marketplaces.isRegistered(randomAddress));

        });

    });

}