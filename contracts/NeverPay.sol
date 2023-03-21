// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./interface/IERC20.sol";
import "./interface/IERC2612.sol";
import "./ERC20.sol";
import "./ERC2612.sol";
import "./SafeMath.sol";
import "./SophisticatedInvestorCertificateAuthorityRegistry.sol";

interface TokenRecipient {
    function tokensReceived(address from, uint amount) external returns (bool);
} 

contract NeverPay is TokenRecipient, SophisticatedInvestorCertificateAuthorityRegistry {
    using SafeMath for uint;

    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }
    mapping(address => Bid[]) public bids; 

    struct ValidBid {
        address validBidder;
        uint256 numberOfShares;
        uint pricePerShare;
    }

    ValidBid[] public validBids;
    ValidBid[] public sortedBids;

    //for sorting
    mapping (uint => uint) validBidCurrentIndexToSortedBidIndex;
    address[] public investor;

    address payable NeverPayAddress;
    uint public round1EndTime = 1650499199; // Unix time stamp. 20 Apr 2022 23:59:59 GMT
    uint public round2EndTime = 1651103999; // Unix time stamp. 27 Apr 2022 23:59:59 GMT
    bool public ended;

    mapping(address => uint) pendingReturns;
    mapping(address => uint) staked;
    modifier isOwner() {
        require(msg.sender == NeverPayAddress);
        _;
    }

    event AuctionSuccess(address winner, uint256 numberOfShares, uint pricePerShare);

    constructor () ERC2612("NeverPayShares", "NPS") {
        NeverPayAddress = payable(msg.sender);
        _mint(msg.sender, 10000);
        _addressToShares[NeverPayAddress] = 10000;
    }

    // The investor makes a bid._blindedBid = keccak256(numberOfShares, pricePerShare, fake, secret)
    // If fake is set to true, a false bid can be made
    // secret is secret message that only the investor knows
    // The deposit is returned only if the bid is correct
    // The key is the public key the investor kept to verify their identity of sophisticated investor.
    function bid(bytes32 _blindedBid, uint _deposit, bytes32 key) public {
        require(_isAuthorized(key));
        require(block.timestamp <= round1EndTime, "Round 1 has ended.");
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: _deposit
        }));
    }

    function withdrawAllBid() public {
        require(block.timestamp <= round1EndTime, "Round 1 has ended.");
        require(bids[msg.sender].length != 0);
        delete bids[msg.sender];
    }

    function revealCommitment(uint256[] memory _numberOfShares, uint[] memory _pricePerShare, 
    bool[] memory _fake, bytes32[] memory _secret) public {
        require(block.timestamp >= round1EndTime, "Please reveal after Round 1.");
        require(block.timestamp <= round2EndTime, "Round 2 has ended.");
        uint length = bids[msg.sender].length;
        require(_numberOfShares.length == length);
        require(_pricePerShare.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            bytes32 check = bids[msg.sender][i].blindedBid;
            uint check_deposit = bids[msg.sender][i].deposit;
            (uint numberOfShares, uint pricePerShare, bool fake, bytes32 secret) =
                    (_numberOfShares[i], _pricePerShare[i], _fake[i], _secret[i]);
            // If bid is not correct，there will be no refund
            if (check != keccak256(abi.encode(numberOfShares, pricePerShare, fake, secret))) {
                continue;
            }

            refund += check_deposit;
            // Handle real bid and avoid deposit is larger than value to pay.
            if (!fake && check_deposit >= numberOfShares.mul(pricePerShare)) {
                if (_placeBid(numberOfShares, pricePerShare))
                    refund.sub(numberOfShares.mul(pricePerShare));
            }
            // Avoid reclaim.
            bids[msg.sender][i].blindedBid = bytes32(0);
        }
        // Complete payment.
        // It may fallback if we did not set bids[msg.sender][i].blindedBid to zero.
        transferETH(refund);
    }
 
    // Transfer ETH to Neverpay.
    function transferETH(uint value) public payable {
        require(msg.sender.balance >= value);
        NeverPayAddress.transfer(value);
    }

    function _placeBid(uint256 _numberOfShares, uint _pricePerShare) internal returns (bool) {
        require(_numberOfShares > 0, "The number of shares must larger than 0");
        require(_pricePerShare >= 1, "The price per share must larger than or equal to 1");
        validBids.push(ValidBid(msg.sender, _numberOfShares, _pricePerShare));
        return true;
    }


    function auctionEnd() public isOwner() {
        require(block.timestamp > round2EndTime, "Auction has not ended.");
        ended = true;
        _sortBid();
        for (uint i = sortedBids.length; i > 0; i--) {
            if (total_Supply >= sortedBids[i].numberOfShares) {
                transfer(sortedBids[i].validBidder, sortedBids[i].numberOfShares);
                total_Supply.sub(sortedBids[i].numberOfShares);
                emit AuctionSuccess(sortedBids[i].validBidder, sortedBids[i].numberOfShares, sortedBids[i].pricePerShare);
            } else {
                // Return the deposit to the person who didn't get the shares at auction
                payable(sortedBids[i].validBidder).transfer(sortedBids[i].numberOfShares.mul(sortedBids[i].pricePerShare));
                // pendingReturns[sortedBids[i].validBidder].add(sortedBids[i].numberOfShares.mul(sortedBids[i].pricePerShare));
            }
        }
    }

    function _sortBid() private isOwner() {
        for (uint i = 0; i < sortedBids.length; i++) {
            validBidCurrentIndexToSortedBidIndex[i] = 0;
            for (uint j = 0; j < i; j++) {
                if (sortedBids[i].pricePerShare < sortedBids[j].pricePerShare) {
                    if (validBidCurrentIndexToSortedBidIndex[i] == 0) {
                        validBidCurrentIndexToSortedBidIndex[i] = validBidCurrentIndexToSortedBidIndex[j];
                    }
                    validBidCurrentIndexToSortedBidIndex[j] = validBidCurrentIndexToSortedBidIndex[j].add(1);
                }
            }
            if (validBidCurrentIndexToSortedBidIndex[i] == 0) {
                validBidCurrentIndexToSortedBidIndex[i] = i.add(1);
            }
        }

        uint lengthSortedBids = sortedBids.length;
        for (uint i = 0; i < validBids.length; i++) {
            if (i < lengthSortedBids) continue;
            sortedBids.push(ValidBid(msg.sender, 0, 0));
        }

        for (uint i = 0; i < validBids.length; i++) {
            sortedBids[validBidCurrentIndexToSortedBidIndex[i].sub(1)] = validBids[i];
        }
    }

    function tokensReceived(address from, uint amount) external override returns (bool) {
        require(msg.sender == NeverPayAddress);

        staked[from] += amount;
        return true;
    }
}
