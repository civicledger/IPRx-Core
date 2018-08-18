import { IPOrganisations } from '../_lib/artifacts';
import { assertThrows } from '../_lib/helpers';

export default function({owner}){

    contract("IPOrganisations - administration", async (accounts) => {

        let randomAccount = accounts[1];
        let authorisedAdminAddress = accounts[2];

        let buildIPOrganisation = (ipoValues) => { return { name: ipoValues[0], websiteUrl: ipoValues[1] } };
        let buildIPType = (typeValues) => { return {name: typeValues[0], address: typeValues[1]} };

        let iPOrganisations;
        before(async () => {
            iPOrganisations = await IPOrganisations.deployed();
        });

        it('IPRx owner can add new IP organisation', async () => {
            let ipOrganisationName = 'IP Australia';
            let ipOrganisationWebsite = 'https://www.ipaustralia.gov.au/';
            
            // Add the new IP organisation
            await iPOrganisations.add(ipOrganisationName, ipOrganisationWebsite, {from: owner});

            // Check it was stored and can be retrieved
            let recordedIPOrganisation = buildIPOrganisation(await iPOrganisations.atIndex(0));
            assert.equal(recordedIPOrganisation.name, ipOrganisationName, 'IP Organisation name doesn\'t match');
            assert.equal(recordedIPOrganisation.websiteUrl, ipOrganisationWebsite, 'IP Organisation name doesn\'t match');
        });

        it('IPRx owner can authorise an address for administration', async () => {
            let ipOrganisationIndex = 0;            

            // Authorise address for administration
            await iPOrganisations.addressAuthorise(ipOrganisationIndex, authorisedAdminAddress, {from: owner});

            // Check that the address is authorised
            let isAuthorised = await iPOrganisations.isAddressAuthorised(ipOrganisationIndex, authorisedAdminAddress);
            assert.isTrue(isAuthorised);
        });

        it('Random user cannot add a new IP Organisation', async () => {
            let ipOrganisationName = 'Some Random';
            let ipOrganisationWebsite = 'https://www.somerandom.com/';
            
            // Add the new IP organisation - should revert because randomAccount is not an IPRx owner
            await assertThrows(iPOrganisations.add(ipOrganisationName, ipOrganisationWebsite, {from: randomAccount}));
        });

        it('IPO administrator can add an IP right type token', async () => {
            let ipOrganisationIndex = 0;
            let newTokenName = 'Patent';
            let newTokenAddress = '0x1111111111111111111111111111111111111111'; // Random address

            // add the new token type
            await iPOrganisations.ipTypeAdd(ipOrganisationIndex, newTokenName, newTokenAddress, {from: authorisedAdminAddress});

            // check that the token was recorded
            let recordedIPType = buildIPType(await iPOrganisations.ipTypeAtIndex(ipOrganisationIndex, 0));
            assert.equal(recordedIPType.name, newTokenName, 'IP type name not recorded');
            assert.equal(recordedIPType.address, newTokenAddress, 'IP type address not recorded');
        });

    });

}