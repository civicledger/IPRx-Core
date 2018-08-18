import { IPOrganisations } from '../_lib/artifacts';

export async function ipOrganisationAddScenario({name = 'IP Australia', website = 'https://www.ipaustralia.gov.au/', owner}){
    const ipOrganisations = await IPOrganisations.deployed();

    // add the ipo
    await ipOrganisations.add(name, website, {from: owner});     
}

export async function ipOrganisationAuthoriseScenario({ipOrgIndex, authAddress, owner}){
    const ipOrganisations = await IPOrganisations.deployed();

    // authorise address for administration
    await ipOrganisations.addressAuthorise(ipOrgIndex, authAddress, {from: owner});
}

export async function ipOrganisationTypeAddScenario({ipOrganisationIndex = 0, newTokenName = 'Patent', newTokenAddress = '0x1111111111111111111111111111111111111111', authorisedAdminAddress}){
    const ipOrganisations = await IPOrganisations.deployed();
    // add the new token type
    await ipOrganisations.ipTypeAdd(ipOrganisationIndex, newTokenName, newTokenAddress, {from: authorisedAdminAddress});
}