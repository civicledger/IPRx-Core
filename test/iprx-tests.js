import exchangeTests from './exchange/exchange-tests';
import marketplacesTests from './exchange/marketplaces-tests';
import ipOrganisationsTests from './ip-organisations/ip-organisations-tests';
import australianPatentTokenTests from './ip-organisations/australia/patents/patent-token-tests';
import australianPatentRegistrationTests from './ip-organisations/australia/patents/patent-registration-tests';

// set the owner account to be used for testing
const owner = web3.eth.coinbase;

// Exchange - pending orders, confirmation of orders
exchangeTests({owner});

// Marketplace administration/metadata tests
marketplacesTests({owner});

// IPOrganisations - administration of IPOs, IP type metadata and routing
ipOrganisationsTests({owner});

// Australian Patent Token - ownership & transfer of patents
australianPatentTokenTests({owner});

// Australian Patent Registration - registration process for Australian patents
australianPatentRegistrationTests({owner});
