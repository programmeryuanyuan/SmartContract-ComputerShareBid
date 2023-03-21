const NeverPay = artifacts.require('../contracts/NeverPay.sol')
const SophisticatedInvestorCertificateAuthorityRegistry = artifacts.require('../contracts/SophisticatedInvestorCertificateAuthorityRegistry.sol')
const { assert } = require('console');
const truffleAssert = require('truffle-assertions');
const web3 = new Web3(ganache.provider());


// time stamp
let round1EndTime = 1650499199
let round2EndTime = 1651103999

// Bidding amount placeholders in ether for fast modification.
let BID1 = 1
let BID2 = 2
let BID3 = 3

// Account placeholders for user accounts for testing
let NPay = accounts[0]
let ASIC = accounts[1]
let ACC2 = accounts[2]
let ACC3 = accounts[3]
let ACC4 = accounts[4]
let ACC5 = accounts[5]

contract("NeverPay", (accounts) => {
    beforeEach('Setup contract for each test', async function () {
        neverPay = await NeverPay.deployed();
        sICAR = await SophisticatedInvestorCertificateAuthorityRegistry.deployed();
    });
    
    describe("Initialization", async () => {
        // before provide initial setting
        before("", async () => {

        });
        it('deploys a contract', () => {
            assert.isTrue(_addressToShares[NPay] == total_supply);
        });
        it('Success on initialization to bidding phase.', async function () {
            assert.isTrue(Date.now() < round1EndTime);
        });
    });

    describe('Bidding Phase.', async () => {
        before("let ACC2 to be sophiscated investor", async () => {
            // let sICAR.addressToPublicKey[ACC2] = ad7c5bef027816a800da1736444fb58a807ef4c9603b7848673f7e3a68eb14a5
            
        });
        it('Success on single bid.', async function () {
            let hashValue = web3.utils.keccak256(1,2,true,secretmessage);
            await neverPay.bid(hashValue, 2, ad7c5bef027816a800da1736444fb58a807ef4c9603b7848673f7e3a68eb14a5,{from: ACC2});

        });
        it('Failure on bid in invalid state.', async function () {
            let hashValue = web3.utils.keccak256(1, 3, true, 3222);
            await neverPay.bid(hashValue, 2, aaaa5bef027816a800da1736444fb58a807ef4c9603b7848673f7e3a68eb14a5, { from: ACC3 });
        });
    });
})