//const IERC20 = artifacts.require("./contracts/interface/IERC20.sol");
//const IERC2612 = artifacts.require("./contracts/interface/IERC2612.sol");
const ERC20 = artifacts.require("./contracts/ERC20.sol");
//const ERC2612 = artifacts.require("./contracts/ERC2612.sol");
//const SophisticatedInvestorCertificateAuthorityRegistry = artifacts.require("./contracts/SophisticatedInvestorCertificateAuthorityRegistry.sol");
const NeverPay = artifacts.require("./contracts/NeverPay.sol");

module.exports = async function (deployer) {
    //await deployer.deploy(IERC20);
    await deployer.deploy(ERC20, "NeverPayShares", "NPS");
    //await deployer.deploy(IERC2612);
    //await deployer.deploy(ERC2612, ERC20.address, IERC2612.address);
    //await deployer.deploy(SophisticatedInvestorCertificateAuthorityRegistry);
    await deployer.deploy(NeverPay);
};