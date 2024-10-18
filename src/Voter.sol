// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IVotingEscrow } from './interfaces/IVotingEscrow.sol';

contract Voter is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant PERIOD_DURATION = 7 days;
    uint256 private constant WEEK = 86400 * 7;
    uint256 private constant UNIT = 1e18;
    uint256 private constant MAX_TOKEN_ID_LENGTH = 10;
    uint256 private constant MAX_WEIGHT = 10000; // 100% in BPS

    address public immutable ve;
    IERC20 public immutable baseAsset;

    bool public isDepositFrozen;

    address[] public gauges;

    uint256 public voteDelay = 1 hours; // To prevent spamming votes

    struct Vote { // TODO : better struct packing for gas savings
        uint256 weight;
        uint256 votes;
    }

    struct CastedVote {
        address gauge;
        uint256 weight;
        uint256 votes;
    }

    // timestamp => budget amount
    mapping(uint256 => uint256) public periodBudget;
    // gauge => index
    mapping(address => uint256) public gaugeIndex;
    // gauge => label
    mapping(address => string) public gaugeLabel;
    // gauge => next period the gauge can claim rewards
    mapping(address => uint256) public gaugesDistributionTimestamp;
    // nft => timestamp => gauge => votes
    mapping(uint256 => mapping(uint256 => mapping(address => Vote))) public votes;
    // nft => timestamp => gauges
    mapping(uint256 => mapping(uint256 => address[])) public gaugeVote;
    // timestamp => gauge => votes
    mapping(uint256 => mapping(address => uint256)) public votesPerPeriod;
    // timestamp => total votes
    mapping(uint256 => uint256) public totalVotesPerPeriod;
    // nft => timestamp
    mapping(uint256 => uint256) public lastVoted;
    // nft => timestamp => bool
    mapping(uint256 => mapping(uint256 => bool)) public voteCastedPeriod;
    // gauge => boolean [is a gauge?]
    mapping(address => bool) public isGauge;
    // gauge => boolean [is the gauge alive?]
    mapping(address => bool) public isAlive;

    event GaugeAdded(address indexed gauge);
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(address indexed voter, uint256 indexed tokenId, address indexed gauge, uint256 weight, uint256 votes);
    event VoteReseted(address indexed voter, uint256 indexed tokenId, address indexed gauge);
    event BudgetDeposited(address indexed depositor, uint256 indexed period, uint256 amount);
    event RewardClaimed(address indexed gauge, uint256 amount);
    event VoteDelayUpdated(uint256 oldVoteDelay, uint256 newVoteDelay);
    event DepositFreezeTriggered(bool frozen);

    error InvalidParameter();
    error NullAmount();
    error ZeroAddress();
    error ArrayLengthMismatch();
    error MaxArraySizeExceeded();
    error GaugeNotListed();
    error GaugeAlreadyListed();
    error KilledGauge();
    error GaugeAlreadyKilled();
    error GaugeNotKilled();
    error VoteDelayNotExpired();
    error CannotVoteWithNft();
    error NoVotingPower();
    error VoteWeightOverflow();
    error NoVoteToRecast();
    error DepositFrozen();

    constructor(
        address _owner,
        address _ve,
        address _baseAsset
    ) Ownable(_owner) {
        ve = _ve;
        baseAsset = IERC20(_baseAsset);
    }

    function currentPeriod() public view returns(uint256) {
        return(block.timestamp / WEEK) * WEEK;
    }

    function gaugesCount() external view returns (uint256) {
        return gauges.length;
    }

    function getNftCurrentVotes(uint256 tokenId) external view returns (CastedVote[] memory) {
        uint256 nextPeriod = currentPeriod() + WEEK;
        address[] memory _gauges = gaugeVote[tokenId][nextPeriod];
        uint256 length = _gauges.length;
        CastedVote[] memory _votes = new CastedVote[](length);

        for(uint256 i = 0; i < length; i++) {
            address gauge = _gauges[i];
            Vote memory voteData = votes[tokenId][nextPeriod][gauge];
            _votes[i] = CastedVote(gauge, voteData.weight, voteData.votes);
        }

        return _votes;
    }

    function getNftCurrentVotesAtPeriod(uint256 tokenId, uint256 ts) external view returns (CastedVote[] memory) {
        ts = (ts / WEEK) * WEEK;
        address[] memory _gauges = gaugeVote[tokenId][ts];
        uint256 length = _gauges.length;
        CastedVote[] memory _votes = new CastedVote[](length);

        for(uint256 i = 0; i < length; i++) {
            address gauge = _gauges[i];
            Vote memory voteData = votes[tokenId][ts][gauge];
            _votes[i] = CastedVote(gauge, voteData.weight, voteData.votes);
        }

        return _votes;
    }

    function getTotalVotes() external view returns (uint256) {
        return totalVotesPerPeriod[currentPeriod() + WEEK];
    }

    function getGaugeVotes(address gauge) external view returns (uint256) {
        return votesPerPeriod[currentPeriod() + WEEK][gauge];
    }

    function getNftVotesOnGauge(uint256 tokenId, address gauge) external view returns (uint256) {
        return votes[tokenId][currentPeriod() + WEEK][gauge].votes;
    }

    function getTotalVotesAtPeriod(uint256 ts) external view returns (uint256) {
        ts = (ts / WEEK) * WEEK;
        return totalVotesPerPeriod[ts];
    }

    function getGaugeVotesAtPeriod(address gauge, uint256 ts) external view returns (uint256) {
        ts = (ts / WEEK) * WEEK;
        return votesPerPeriod[ts][gauge];
    }

    function getNftVotesOnGaugeAtPeriod(uint256 tokenId, address gauge, uint256 ts) external view returns (uint256) {
        ts = (ts / WEEK) * WEEK;
        return votes[tokenId][ts][gauge].votes;
    }

    function _getGaugeRelativeWeight(address gauge, uint256 period) internal view returns (uint256) {
        if(!isGauge[gauge] || !isAlive[gauge]) return 0;
        uint256 totalVotes = totalVotesPerPeriod[period];
        if(totalVotes == 0) return 0;
        uint256 gaugeVotes = votesPerPeriod[period][gauge];
        return (gaugeVotes * UNIT) / totalVotes;
    }

    function getGaugeRelativeWeight(address gauge) external view returns (uint256) {
        return _getGaugeRelativeWeight(gauge, currentPeriod() + WEEK);
    }

    function getGaugeRelativeWeightAtPeriod(address gauge, uint256 ts) external view returns (uint256) {
        ts = (ts / WEEK) * WEEK;
        return _getGaugeRelativeWeight(gauge, ts);
    }

    function _voteDelay(uint256 tokenId) internal view {
        if(block.timestamp <= lastVoted[tokenId] + voteDelay) revert VoteDelayNotExpired();
    }

    function _reset(address voter, uint256 tokenId) internal {
        uint256 nextPeriod = currentPeriod() + WEEK;
        if(voteCastedPeriod[tokenId][nextPeriod]) { // otherwise, no vote casted for that period yet, nothing to reset
            address[] memory _gauges = gaugeVote[tokenId][nextPeriod];
            uint256 length = _gauges.length;
            uint256 totalVotesRemoved;
            for(uint256 i; i < length;) {
                address gauge = _gauges[i];
                uint256 voteAmount = votes[tokenId][nextPeriod][gauge].votes;
                votesPerPeriod[nextPeriod][gauge] -= voteAmount;
                totalVotesRemoved += voteAmount;
                delete votes[tokenId][nextPeriod][gauge];

                emit VoteReseted(voter, tokenId, gauge);

                unchecked { i++; }
            }
            delete gaugeVote[tokenId][nextPeriod];
            totalVotesPerPeriod[nextPeriod] -= totalVotesRemoved;
        }
        voteCastedPeriod[tokenId][nextPeriod] = false;
    }

    function _vote(address voter, uint256 tokenId, address[] memory gaugeList, uint256[] memory weights) internal {
        uint256 nextPeriod = currentPeriod() + WEEK;
        uint256 length = gaugeList.length;

        uint256 _votes = IVotingEscrow(ve).balanceOfNFT(tokenId);
        if(_votes == 0) revert NoVotingPower();
        uint256 totalUsedWeights;
        uint256 totalVotesCasted;
        
        for(uint256 i; i < length;) {
            address gauge = gaugeList[i];
            if(gauge == address(0)) revert ZeroAddress();
            if(!isGauge[gauge]) revert GaugeNotListed();
            if(!isAlive[gauge]) revert KilledGauge();

            uint256 gaugeVotes = (_votes * weights[i]) / MAX_WEIGHT;
            totalUsedWeights += weights[i];
            totalVotesCasted += gaugeVotes;

            gaugeVote[tokenId][nextPeriod].push(gauge);

            votesPerPeriod[nextPeriod][gauge] += gaugeVotes;
            votes[tokenId][nextPeriod][gauge] = Vote(weights[i], gaugeVotes);

            emit Voted(voter, tokenId, gauge, weights[i], gaugeVotes);

            unchecked { i++; }
        }

        if(totalUsedWeights > MAX_WEIGHT) revert VoteWeightOverflow();
        if(totalUsedWeights > 0) IVotingEscrow(ve).voting(tokenId);

        totalVotesPerPeriod[nextPeriod] += totalVotesCasted;

        voteCastedPeriod[tokenId][nextPeriod] = true;
    }

    function vote(uint256 tokenId, address[] calldata gaugeList, uint256[] calldata weights) public nonReentrant {
        _voteDelay(tokenId);
        if(!IVotingEscrow(ve).isVotingApprovedOrOwner(msg.sender, tokenId)) revert CannotVoteWithNft();
        if(gaugeList.length != weights.length) revert ArrayLengthMismatch();
        _reset(msg.sender, tokenId);
        _vote(msg.sender, tokenId, gaugeList, weights);
        
        lastVoted[tokenId] = block.timestamp;
    }

    function reset(uint256 tokenId) public nonReentrant {
        _voteDelay(tokenId);
        if(!IVotingEscrow(ve).isVotingApprovedOrOwner(msg.sender, tokenId)) revert CannotVoteWithNft();
        _reset(msg.sender, tokenId);
        IVotingEscrow(ve).abstain(tokenId);
        
        lastVoted[tokenId] = block.timestamp;
    }

    function recast(uint256 tokenId) public nonReentrant {
        _voteDelay(tokenId);
        if(!IVotingEscrow(ve).isVotingApprovedOrOwner(msg.sender, tokenId)) revert CannotVoteWithNft();

        address[] memory _gauges = gaugeVote[tokenId][currentPeriod()];
        uint256 length = _gauges.length;
        if(length == 0) revert NoVoteToRecast();
        uint256[] memory weights = new uint256[](length);
        for(uint256 i; i < length;) {
            weights[i] = votes[tokenId][currentPeriod()][_gauges[i]].weight;
            unchecked { i++; }
        }
        _reset(msg.sender, tokenId);
        _vote(msg.sender, tokenId, _gauges, weights);
        
        lastVoted[tokenId] = block.timestamp;
    }

    function voteMultiple(uint256[] calldata tokenIds, address[] calldata gaugeList, uint256[] calldata weights) external {
        uint256 length = tokenIds.length;
        if(length > MAX_TOKEN_ID_LENGTH) revert MaxArraySizeExceeded();
        for(uint256 i; i < length;) {
            vote(tokenIds[i], gaugeList, weights);
            unchecked { i++; }
        }
    }

    function resetMultiple(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        if(length > MAX_TOKEN_ID_LENGTH) revert MaxArraySizeExceeded();
        for(uint256 i; i < length;) {
            reset(tokenIds[i]);
            unchecked { i++; }
        }
    }

    function recastMultiple(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        if(length > MAX_TOKEN_ID_LENGTH) revert MaxArraySizeExceeded();
        for(uint256 i; i < length;) {
            recast(tokenIds[i]);
            unchecked { i++; }
        }
    }

    function depositBudget(uint256 amount) external nonReentrant {
        if(amount == 0) revert NullAmount();
        if(isDepositFrozen) revert DepositFrozen();

        baseAsset.safeTransferFrom(msg.sender, address(this), amount);

        uint256 depositPeriod = (currentPeriod() + (WEEK * 2));
        periodBudget[depositPeriod] += amount;

        emit BudgetDeposited(msg.sender, depositPeriod, amount);
    }

    function claimGaugeRewards(address gauge) external nonReentrant returns (uint256 claimedAmount) {
        uint256 _currentPeriod = currentPeriod();
        // Fetch the next period the gauge can claim rewards, from the last time it claimed.
        uint256 period = gaugesDistributionTimestamp[gauge];
        while(period <= _currentPeriod) {
            uint256 relativeWeight = _getGaugeRelativeWeight(gauge, period);

            claimedAmount += (relativeWeight * periodBudget[period]) / UNIT;

            // TODO: do we want a tracking of how much claimed per period per gauge ?

            period += WEEK;
        }

        // Next time the gauge can claim will be after the current period vote is over.
        gaugesDistributionTimestamp[gauge] = _currentPeriod + WEEK;

        if(claimedAmount > 0) {
            baseAsset.safeTransfer(gauge, claimedAmount);

            emit RewardClaimed(gauge, claimedAmount);
        }
    }

    function addGauge(address gauge, string memory label) external onlyOwner returns (uint256 index) {
        if(isGauge[gauge]) revert GaugeAlreadyListed();
        if(gauge == address(0)) revert ZeroAddress();

        isGauge[gauge] = true;
        isAlive[gauge] = true;

        index = gauges.length;
        gauges.push(gauge);


        gaugeIndex[gauge] = index;
        gaugeLabel[gauge] = label;

        uint256 _currentPeriod = currentPeriod();
        gaugesDistributionTimestamp[gauge] = _currentPeriod;

        emit GaugeAdded(gauge);
    }

    function killGauge(address gauge) external onlyOwner {
        if(gauge == address(0)) revert ZeroAddress();
        if(!isGauge[gauge]) revert GaugeNotListed();
        if(!isAlive[gauge]) revert GaugeAlreadyKilled();
        isAlive[gauge] = false;

        emit GaugeKilled(gauge);
    }

    function reviveGauge(address gauge) external onlyOwner {
        if(gauge == address(0)) revert ZeroAddress();
        if(!isGauge[gauge]) revert GaugeNotListed();
        if(isAlive[gauge]) revert GaugeNotKilled();
        isAlive[gauge] = true;
        
        emit GaugeRevived(gauge);
    }

    function updateVoteDelay(uint256 newVoteDelay) external onlyOwner {
        if(newVoteDelay >= 7 days) revert InvalidParameter();

        uint256 oldVoteDelay = voteDelay;
        voteDelay = newVoteDelay;

        emit VoteDelayUpdated(oldVoteDelay, newVoteDelay);
    }

    function triggerDepositFreeze() external onlyOwner {
        isDepositFrozen = !isDepositFrozen;

        emit DepositFreezeTriggered(isDepositFrozen);
    }

}