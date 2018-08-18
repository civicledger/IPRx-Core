var RLP = require('rlp');
import { Exchange, PatentToken, PatentRegistration, Marketplaces } from '../_lib/artifacts';
import { ipOrganisationAddScenario, ipOrganisationAuthoriseScenario, ipOrganisationTypeAddScenario } from '../ip-organisations/ip-organisations-scenarios';
import { assertThrows } from '../_lib/helpers';
import { soliditySha3 } from '../_lib/sha3';
import rawSign from '../_lib/sign';

export default function({owner}){

    contract("Exchange", async (accounts) => {

        let ipOrgAuthorisedAdmin = accounts[1];
        let patentRightOwner = accounts[2];
        let marketplaceAccount = accounts[3];        
        const orderTakerPrivateKey = 'c6d2ac9b00bd599c4ce9d3a69c91e496eb9e79781d9dc84c79bafa7618f45f37';

        let nonce = 1;
        const getSampleOrder = () => { return [
            0,                                              // ipOrganisationIndex
            0,                                              // ipTypeIndex
            1,                                              // ipIndex
            '0xe6ed92d26573c67af5eca7fb2a49a807fb8f88db',   // orderTakerAddress
            marketplaceAccount,                             // marketplaceAddress 
            2,                                              // orderType
            5,                                              // paymentCurrency
            '0x7e9ea400443957be3918acfbd1f57cf6d3f5126a',   // paymentTokenAddress
            6,                                              // paymentAmountInWei
            nonce,                                          // nonce
            1530184331,                                     // timestamp
            '0x24fbed7ecd625d3f0fd19a6c9113ded436172294',   // feeRecipientAddress
            8                                               // feeAmountInWei               
        ]};   

        const buildOrder = (values) => {
            return {
                ipOrganisationIndex: values[0].valueOf(),
                ipTypeIndex: values[1].valueOf(),
                ipIndex: values[2].valueOf(),
                orderTakerAddress: values[3],
                marketplaceAddress: values[4],
                orderType: values[5].valueOf(),                
                nonce: values[6].valueOf(),
                timestamp: values[7].valueOf(),
                feeRecipientAddress: values[8],
                feeAmountInWei: values[9].valueOf()
            }
        };

        const buildOrderPayment = (values) => {
            return {
                paymentCurrency: values[0].valueOf(),
                paymentTokenAddress: values[1],
                paymentAmountInWei: values[2].valueOf()
            }
        }

        const buildOrderSig = (values) => {
            return {
                v: values[0].valueOf(),
                r: values[1],
                s: values[2],
                signerAddress: values[3]
            }
        };
        
        let patentRightIndex;
        let exchange;
        let patentToken;
        let patentRegistration;
        let marketplaces;
        before(async () => {
            exchange = await Exchange.deployed();
            patentToken = await PatentToken.deployed();
            patentRegistration = await PatentRegistration.deployed();
            marketplaces = await Marketplaces.deployed();

            // add an ip organisation
            await ipOrganisationAddScenario({owner});
            // authorise an admin user
            await ipOrganisationAuthoriseScenario({ipOrgIndex: 0, authAddress: ipOrgAuthorisedAdmin, owner});
            // add an ip right type
            await ipOrganisationTypeAddScenario({ipOrganisationIndex: 0, newTokenAddress: patentToken.address, authorisedAdminAddress: ipOrgAuthorisedAdmin});
        
            // register a new patent
            await patentRegistration.claimIP({from: patentRightOwner});

            // assert that the patent exists
            patentRightIndex = 1;
            assert.isTrue(await patentToken.exists(patentRightIndex));

            // set the patent as licensable
            await patentToken.setLicensable(patentRightIndex, true, {from: patentRightOwner});

            await marketplaces.register('name', 'website', marketplaceAccount, 0, {from: ipOrgAuthorisedAdmin});
        });

        it('marketplace can submit an order for execution', async () => {
            
            let orderParams = getSampleOrder();

            let orderHash = soliditySha3(...orderParams);
            let signatureObj = rawSign(orderHash, orderTakerPrivateKey);
            orderParams.push('0x'+signatureObj.v);
            orderParams.push('0x'+signatureObj.r);
            orderParams.push('0x'+signatureObj.s)

            var encodedList = RLP.encode(orderParams);
            await exchange.submitOrder('0x'+encodedList.toString('hex'), {from: owner, gas: 1000000});

            let orderIndex = 0;

            // increment the nonce so that we can execute other orders
            nonce += 1;

            let recordedOrder = buildOrder(await exchange.orderAtIndex(marketplaceAccount, orderIndex));
            assert.equal(recordedOrder.ipOrganisationIndex, orderParams[0]);
            assert.equal(recordedOrder.ipTypeIndex, orderParams[1]);
            assert.equal(recordedOrder.ipIndex, orderParams[2]);
            assert.equal(recordedOrder.orderTakerAddress, orderParams[3]);
            assert.equal(recordedOrder.marketplaceAddress, orderParams[4]);
            assert.equal(recordedOrder.orderType, orderParams[5]);            
            assert.equal(recordedOrder.nonce, orderParams[9]);
            assert.equal(recordedOrder.timestamp, orderParams[10]);
            assert.equal(recordedOrder.feeRecipientAddress, orderParams[11]);
            assert.equal(recordedOrder.feeAmountInWei, orderParams[12]);

            let recordedPayment = buildOrderPayment(await exchange.orderPaymentAtIndex(marketplaceAccount, orderIndex))
            assert.equal(recordedPayment.paymentCurrency, orderParams[6]);
            assert.equal(recordedPayment.paymentTokenAddress, orderParams[7]);
            assert.equal(recordedPayment.paymentAmountInWei, orderParams[8]);

            let recordedSig = buildOrderSig(await exchange.orderSigAtIndex(marketplaceAccount, orderIndex));
            assert.equal(web3.toHex(recordedSig.v), orderParams[13]);
            assert.equal(recordedSig.r, orderParams[14]);
            assert.equal(recordedSig.s, orderParams[15]);
            assert.equal(recordedSig.signerAddress, orderParams[3]); // order taker address

            const STATUS_PENDING = 1;
            let recordedStatus = parseInt(await exchange.orderStatusAtIndex(marketplaceAccount, orderIndex));
            assert.equal(recordedStatus, STATUS_PENDING);
            
        });

        it('marketplace cannot submit an order where the signature is not the order takers', async () => {
            const randomPrivateKey = '759b3437ff0fd1af70a5a367ac281c73f6dca2e17a4650a7f939fb50ad15f6cd';

            let orderParams = getSampleOrder();
            let orderHash = soliditySha3(...orderParams);
            let signatureObj = rawSign(orderHash, randomPrivateKey);
            orderParams.push('0x'+signatureObj.v);
            orderParams.push('0x'+signatureObj.r);
            orderParams.push('0x'+signatureObj.s)

            var encodedList = RLP.encode(orderParams);
            await assertThrows(exchange.submitOrder('0x'+encodedList.toString('hex'), {from: owner, gas: 1000000}));
        });

        it('marketplace cannot submit an order more than once (replay attack)', async () => {

            let orderParams = getSampleOrder();

            // decrement nonce - effectively replaying an old order
            orderParams[9] = nonce - 1;

            let orderHash = soliditySha3(...orderParams);
            let signatureObj = rawSign(orderHash, orderTakerPrivateKey);
            orderParams.push('0x'+signatureObj.v);
            orderParams.push('0x'+signatureObj.r);
            orderParams.push('0x'+signatureObj.s)            

            var encodedList = RLP.encode(orderParams);
            await assertThrows(exchange.submitOrder('0x'+encodedList.toString('hex'), {from: owner, gas: 1000000}));
        });

        it('marketplace cannot submit an order where the order has been tampered with after signing', async () => {
            let orderParams = getSampleOrder();

            let orderHash = soliditySha3(...orderParams);
            let signatureObj = rawSign(orderHash, orderTakerPrivateKey);
            orderParams.push('0x'+signatureObj.v);
            orderParams.push('0x'+signatureObj.r);
            orderParams.push('0x'+signatureObj.s)

            // tamper with the order after signing
            orderParams[10] += 1; // change the timestamp

            var encodedList = RLP.encode(orderParams);
            await assertThrows(exchange.submitOrder('0x'+encodedList.toString('hex'), {from: owner, gas: 1000000}));
        });

        it('ip right owner can approve a pending order', async () => {
            await exchange.approveOrder(marketplaceAccount, 0, {from: patentRightOwner, gas: 1000000});

            const STATUS_APPROVED = 2;
            let recordedStatus = parseInt(await exchange.orderStatusAtIndex(marketplaceAccount, 0));
            assert.equal(recordedStatus, STATUS_APPROVED);
        });

        it('ip right owner can reject a pending order', async () => {
            // submit another order

            let orderParams = getSampleOrder();

            let orderHash = soliditySha3(...orderParams);
            let signatureObj = rawSign(orderHash, orderTakerPrivateKey);
            orderParams.push('0x'+signatureObj.v);
            orderParams.push('0x'+signatureObj.r);
            orderParams.push('0x'+signatureObj.s)

            var encodedList = RLP.encode(orderParams);
            await exchange.submitOrder('0x'+encodedList.toString('hex'), {from: owner, gas: 1000000});

            // reject it - should be index 1
            let orderIndex = 1;
            await exchange.rejectOrder(marketplaceAccount, orderIndex, {from: patentRightOwner, gas: 1000000});

            // make sure it got rejected
            const STATUS_REJECTED = 3;
            let recordedStatus = parseInt(await exchange.orderStatusAtIndex(marketplaceAccount, orderIndex));
            assert.equal(recordedStatus, STATUS_REJECTED);
        });


    });

}