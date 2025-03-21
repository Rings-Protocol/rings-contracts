// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "solady/utils/ReentrancyGuard.sol";
import { IVotingEscrow } from "./interfaces/IVotingEscrow.sol";

/// @title Voter contract
/// @author Rings Protocol
/// @notice This contract allows users to vote on gauges to distribute rewards
/// it is a fork of Thena's Voter contract
contract Voter is Ownable2Step, ReentrancyGuard {
    using SafeTransferLib for address;

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Vote struct
     * @param weight The weight of the vote
     * @param votes The votes amount
     */
    struct Vote {
        uint256 weight;
        uint256 votes;
    }

    /**
     * @notice Gauge status struct
     * @param isGauge The gauge status
     * @param isAlive The gauge status
     */
    struct GaugeStatus {
        bool isGauge;
        bool isAlive;
    }

    /**
     * @notice Casted vote struct
     * @param gauge The gauge address
     * @param weight The weight of the vote
     * @param votes The votes amount
     */
    struct CastedVote {
        address gauge;
        uint256 weight;
        uint256 votes;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a gauge is added
    event GaugeAdded(address indexed gauge, uint256 cap);
    /// @notice Emitted when a gauge is killed
    event GaugeKilled(address indexed gauge);
    /// @notice Emitted when a gauge is revived
    event GaugeRevived(address indexed gauge);
    /// @notice Emitted when a gauge cap is updated
    event GaugeCapUpdated(address indexed gauge, uint256 newCap);
    /// @notice Emitted when a vote is casted
    event Voted(
        address indexed voter, uint256 indexed tokenId, address indexed gauge, uint256 ts, uint256 weight, uint256 votes
    );
    /// @notice Emitted when a vote is reseted
    event VoteReseted(address indexed voter, uint256 indexed tokenId, address indexed gauge);
    /// @notice Emitted when a budget is deposited
    event BudgetDeposited(address indexed depositor, uint256 indexed period, uint256 amount);
    /// @notice Emitted when a reward is claimed
    event RewardClaimed(address indexed gauge, uint256 amount);
    /// @notice Emitted when the vote delay is updated
    event VoteDelayUpdated(uint256 oldVoteDelay, uint256 newVoteDelay);
    /// @notice Emitted when the deposit freeze is triggered
    event DepositFreezeTriggered(bool frozen);
    /// @notice Emitted when the default gauge cap is updated
    event DefaultCapUpdated(uint256 newCap);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

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
    error InvalidCap();

    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant PERIOD_DURATION = 7 days;
    uint256 private constant WEEK = 86_400 * 7;
    uint256 private constant UNIT = 1e18;
    uint256 private constant MAX_TOKEN_ID_LENGTH = 10;
    uint256 private constant MAX_WEIGHT = 10_000; // 100% in BPS

    address public immutable ve;
    address public immutable baseAsset;

    /*//////////////////////////////////////////////////////////////
                            MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    bool public isDepositFrozen;
    address[] public gauges;

    uint256 public voteDelay = 1 hours; // To prevent spamming votes

    uint256 public defaultCap = 0.1e18;

    // timestamp => budget amount
    mapping(uint256 => uint256) public periodBudget;
    // gauge => index
    mapping(address => uint256) public gaugeIndex;
    // gauge => label
    mapping(address => string) public gaugeLabel;
    // gauge => cap
    mapping(address => uint256) public gaugeCaps;
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
    // gauge => status (isAlive and isGauge)
    mapping(address => GaugeStatus) public gaugeStatus;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, address _ve, address _baseAsset) Ownable(_owner) {
        ve = _ve;
        baseAsset = _baseAsset;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current period timestamp
     * @return uint256
     */
    function currentPeriod() public view returns (uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }

    /**
     * @notice Returns the number of gauges
     * @return uint256
     */
    function gaugesCount() external view returns (uint256) {
        return gauges.length;
    }

    /**
     * @notice Returns true if the gauge is listed
     * @return bool
     */
    function isGauge(address gauge) external view returns (bool) {
        return gaugeStatus[gauge].isGauge;
    }

    /**
     * @notice Returns true if the gauge is alive
     * @return bool
     */
    function isAlive(address gauge) external view returns (bool) {
        return gaugeStatus[gauge].isAlive;
    }

    /**
     * @notice Returns the casted voted for a specific NFT
     * @param tokenId The NFT id
     * @return CastedVote[] memory
     */
    function getNftCurrentVotes(uint256 tokenId) external view returns (CastedVote[] memory) {
        uint256 nextPeriod = currentPeriod() + WEEK;
        address[] memory _gauges = gaugeVote[tokenId][nextPeriod];
        uint256 length = _gauges.length;
        CastedVote[] memory _votes = new CastedVote[](length);

        for (uint256 i = 0; i < length; ++i) {
            address gauge = _gauges[i];
            Vote memory voteData = votes[tokenId][nextPeriod][gauge];
            _votes[i] = CastedVote(gauge, voteData.weight, voteData.votes);
        }

        return _votes;
    }

    /**
     * @notice Returns the casted voted for a specific NFT at a specific period
     * @param tokenId The NFT id
     * @param ts The timestamp
     * @return CastedVote[] memory
     */
    function getNftCurrentVotesAtPeriod(uint256 tokenId, uint256 ts) external view returns (CastedVote[] memory) {
        ts = (ts / WEEK) * WEEK;
        address[] memory _gauges = gaugeVote[tokenId][ts];
        uint256 length = _gauges.length;
        CastedVote[] memory _votes = new CastedVote[](length);

        for (uint256 i = 0; i < length; ++i) {
            address gauge = _gauges[i];
            Vote memory voteData = votes[tokenId][ts][gauge];
            _votes[i] = CastedVote(gauge, voteData.weight, voteData.votes);
        }

        return _votes;
    }

    /**
     * @notice Returns the total votes for the current period
     * @return uint256
     */
    function getTotalVotes() external view returns (uint256) {
        return totalVotesPerPeriod[currentPeriod() + WEEK];
    }

    /**
     * @notice Returns the votes for a specific gauge for the current period
     * @param gauge The gauge address
     * @return uint256
     */
    function getGaugeVotes(address gauge) external view returns (uint256) {
        return votesPerPeriod[currentPeriod() + WEEK][gauge];
    }

    /**
     * @notice Returns the votes for a specific NFT on a specific gauge for the current period
     * @param tokenId The NFT id
     * @param gauge The gauge address
     * @return uint256
     */
    function getNftVotesOnGauge(uint256 tokenId, address gauge) external view returns (uint256) {
        return votes[tokenId][currentPeriod() + WEEK][gauge].votes;
    }

    /**
     * @notice Returns the total votes for a specific period
     * @param ts The timestamp
     * @return uint256
     */
    function getTotalVotesAtPeriod(uint256 ts) external view returns (uint256) {
        ts = (ts / WEEK) * WEEK;
        return totalVotesPerPeriod[ts];
    }

    /**
     * @notice Returns the votes for a specific gauge for a specific period
     * @param gauge The gauge address
     * @param ts The timestamp
     * @return uint256
     */
    function getGaugeVotesAtPeriod(address gauge, uint256 ts) external view returns (uint256) {
        ts = (ts / WEEK) * WEEK;
        return votesPerPeriod[ts][gauge];
    }

    /**
     * @notice Returns the votes for a specific NFT on a specific gauge for a specific period
     * @param tokenId The NFT id
     * @param gauge The gauge address
     * @param ts The timestamp
     * @return uint256
     */
    function getNftVotesOnGaugeAtPeriod(uint256 tokenId, address gauge, uint256 ts) external view returns (uint256) {
        ts = (ts / WEEK) * WEEK;
        return votes[tokenId][ts][gauge].votes;
    }

    /**
     * @notice Returns the relative weight of a gauge for the current period
     * @param gauge The gauge address
     * @return uint256
     */
    function getGaugeRelativeWeight(address gauge) external view returns (uint256) {
        return _getGaugeRelativeWeight(gauge, currentPeriod() + WEEK);
    }

    /**
     * @notice Returns the relative weight of a gauge for a specific period
     * @param gauge The gauge address
     * @param ts The timestamp
     * @return uint256
     */
    function getGaugeRelativeWeightAtPeriod(address gauge, uint256 ts) external view returns (uint256) {
        ts = (ts / WEEK) * WEEK;
        return _getGaugeRelativeWeight(gauge, ts);
    }

    /**
     * @notice Returns the cap of a gauge (returns the default cap if the gauge cap is 0)
     * @param gauge The gauge address
     * @return uint256
     */
    function getGaugeCap(address gauge) public view returns (uint256) {
        uint256 cap = gaugeCaps[gauge];
        return cap == 0 ? defaultCap : cap;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Vote on gauges for a specific NFT
     * @param tokenId The NFT id
     * @param gaugeList The list of gauges to vote on
     * @param weights The weights for each gauge
     */
    function vote(uint256 tokenId, address[] calldata gaugeList, uint256[] calldata weights) public nonReentrant {
        _voteDelay(tokenId);
        if (!IVotingEscrow(ve).isVotingApprovedOrOwner(msg.sender, tokenId)) revert CannotVoteWithNft();
        if (gaugeList.length != weights.length) revert ArrayLengthMismatch();
        _reset(msg.sender, tokenId);
        _vote(msg.sender, tokenId, gaugeList, weights);

        lastVoted[tokenId] = block.timestamp;
    }

    /**
     * @notice Reset the votes for a specific NFT
     * @param tokenId The NFT id
     */
    function reset(uint256 tokenId) public nonReentrant {
        _voteDelay(tokenId);
        if (!IVotingEscrow(ve).isVotingApprovedOrOwner(msg.sender, tokenId)) revert CannotVoteWithNft();
        _reset(msg.sender, tokenId);
        IVotingEscrow(ve).abstain(tokenId);

        lastVoted[tokenId] = block.timestamp;
    }

    /**
     * @notice Recast the votes for a specific NFT
     * @param tokenId The NFT id
     */
    function recast(uint256 tokenId) public nonReentrant {
        _voteDelay(tokenId);
        if (!IVotingEscrow(ve).isVotingApprovedOrOwner(msg.sender, tokenId)) revert CannotVoteWithNft();

        address[] memory _gauges = gaugeVote[tokenId][currentPeriod()];
        uint256 length = _gauges.length;
        if (length == 0) revert NoVoteToRecast();
        uint256[] memory weights = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            weights[i] = votes[tokenId][currentPeriod()][_gauges[i]].weight;
        }
        _reset(msg.sender, tokenId);
        _vote(msg.sender, tokenId, _gauges, weights);

        lastVoted[tokenId] = block.timestamp;
    }

    /**
     * @notice Vote on gauges for multiple NFTs
     * @param tokenIds The list of NFT ids
     * @param gaugeList The list of gauges to vote on
     * @param weights The weights for each gauge
     */
    function voteMultiple(uint256[] calldata tokenIds, address[] calldata gaugeList, uint256[] calldata weights)
        external
    {
        uint256 length = tokenIds.length;
        if (length > MAX_TOKEN_ID_LENGTH) revert MaxArraySizeExceeded();
        for (uint256 i; i < length; ++i) {
            vote(tokenIds[i], gaugeList, weights);
        }
    }

    /**
     * @notice Reset the votes for multiple NFTs
     * @param tokenIds The list of NFT ids
     */
    function resetMultiple(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        if (length > MAX_TOKEN_ID_LENGTH) revert MaxArraySizeExceeded();
        for (uint256 i; i < length; ++i) {
            reset(tokenIds[i]);
        }
    }

    /**
     * @notice Recast the votes for multiple NFTs
     * @param tokenIds The list of NFT ids
     */
    function recastMultiple(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        if (length > MAX_TOKEN_ID_LENGTH) revert MaxArraySizeExceeded();
        for (uint256 i; i < length; ++i) {
            recast(tokenIds[i]);
        }
    }

    /**
     * @notice Deposit budget for a specific period
     * @param amount The amount to deposit
     */
    function depositBudget(uint256 amount) external nonReentrant {
        if (amount == 0) revert NullAmount();
        if (isDepositFrozen) revert DepositFrozen();

        baseAsset.safeTransferFrom(msg.sender, address(this), amount);

        uint256 depositPeriod = (currentPeriod() + (WEEK * 2));
        periodBudget[depositPeriod] += amount;

        emit BudgetDeposited(msg.sender, depositPeriod, amount);
    }

    /**
     * @notice Claim rewards for a specific gauge
     * @param gauge The gauge address
     * @return claimedAmount The claimed amount
     */
    function claimGaugeRewards(address gauge) external nonReentrant returns (uint256 claimedAmount) {
        uint256 _currentPeriod = currentPeriod();
        // Fetch the next period the gauge can claim rewards, from the last time it claimed.
        uint256 period = gaugesDistributionTimestamp[gauge];
        while (period <= _currentPeriod) {
            uint256 cap = getGaugeCap(gauge);
            uint256 relativeWeight = _getGaugeRelativeWeight(gauge, period);
            if (relativeWeight > cap) {
                uint256 excessWeight = relativeWeight - cap;
                relativeWeight = cap;

                // If the weight exceeds the cap for the gauge, take back the excess
                // budget, and recycle it.
                uint256 excessAmount = (excessWeight * periodBudget[period]) / UNIT;
                uint256 depositPeriod = (currentPeriod() + (WEEK * 2));
                periodBudget[depositPeriod] += excessAmount;
            }

            claimedAmount += (relativeWeight * periodBudget[period]) / UNIT;
            period += WEEK;
        }

        // Next time the gauge can claim will be after the current period vote is over.
        gaugesDistributionTimestamp[gauge] = _currentPeriod + WEEK;

        if (claimedAmount > 0) {
            baseAsset.safeTransfer(gauge, claimedAmount);

            emit RewardClaimed(gauge, claimedAmount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Add a gauge to the list
     * @param gauge The gauge address
     * @param label The gauge label
     * @param cap The gauge cap (can be 0 to use the default cap)
     * @return index The gauge index
     *
     * @custom:require onlyOwner
     */
    function addGauge(address gauge, string memory label, uint256 cap) external onlyOwner returns (uint256 index) {
        if (gauge == address(0)) revert ZeroAddress();
        GaugeStatus storage status = gaugeStatus[gauge];
        if (status.isGauge) revert GaugeAlreadyListed();
        if (cap > UNIT) revert InvalidCap();

        status.isGauge = true;
        status.isAlive = true;

        index = gauges.length;
        gauges.push(gauge);

        gaugeIndex[gauge] = index;
        gaugeLabel[gauge] = label;
        gaugeCaps[gauge] = cap;

        uint256 _currentPeriod = currentPeriod();
        gaugesDistributionTimestamp[gauge] = _currentPeriod;

        emit GaugeAdded(gauge, cap);
    }

    /**
     * @notice Remove a gauge from the list
     * @param gauge The gauge address
     *
     * @custom:require onlyOwner
     */
    function killGauge(address gauge) external onlyOwner {
        if (gauge == address(0)) revert ZeroAddress();
        GaugeStatus storage status = gaugeStatus[gauge];
        if (!status.isGauge) revert GaugeNotListed();
        if (!status.isAlive) revert GaugeAlreadyKilled();
        status.isAlive = false;

        emit GaugeKilled(gauge);
    }

    /**
     * @notice Revive a gauge that has been killed previously
     * @param gauge The gauge address
     *
     * @custom:require onlyOwner
     */
    function reviveGauge(address gauge) external onlyOwner {
        if (gauge == address(0)) revert ZeroAddress();
        GaugeStatus storage status = gaugeStatus[gauge];
        if (!status.isGauge) revert GaugeNotListed();
        if (status.isAlive) revert GaugeNotKilled();
        status.isAlive = true;

        emit GaugeRevived(gauge);
    }

    /**
     * @notice Update the cap of a gauge
     * @param gauge The gauge address
     * @param cap The gauge cap (can be 0 to use the default cap)
     *
     * @custom:require onlyOwner
     *
     * @dev Need to call claimGaugeRewards() before the update to avoid any cases were the gauge
     * ends up claiming more or less than supposed on past periods
     */
    function updateGaugeCap(address gauge, uint256 cap) external onlyOwner {
        if (gauge == address(0)) revert ZeroAddress();
        GaugeStatus storage status = gaugeStatus[gauge];
        if (!status.isGauge) revert GaugeNotListed();
        if (!status.isAlive) revert KilledGauge();
        if (cap > UNIT) revert InvalidCap();

        gaugeCaps[gauge] = cap;

        emit GaugeCapUpdated(gauge, cap);
    }

    /**
     * @notice Update the vote delay
     * @param newVoteDelay The new vote delay
     *
     * @custom:require onlyOwner
     */
    function updateVoteDelay(uint256 newVoteDelay) external onlyOwner {
        if (newVoteDelay >= PERIOD_DURATION) revert InvalidParameter();

        uint256 oldVoteDelay = voteDelay;
        voteDelay = newVoteDelay;

        emit VoteDelayUpdated(oldVoteDelay, newVoteDelay);
    }

    /**
     * @notice Trigger the deposit freeze in case of emergency
     *
     * @custom:require onlyOwner
     */
    function triggerDepositFreeze() external onlyOwner {
        isDepositFrozen = !isDepositFrozen;

        emit DepositFreezeTriggered(isDepositFrozen);
    }

    function updatedefaultCap(uint256 _defaultCap) external onlyOwner {
        defaultCap = _defaultCap;

        emit DefaultCapUpdated(_defaultCap);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _voteDelay(uint256 tokenId) internal view {
        if (block.timestamp <= lastVoted[tokenId] + voteDelay) revert VoteDelayNotExpired();
    }

    function _getGaugeRelativeWeight(address gauge, uint256 period) internal view returns (uint256) {
        GaugeStatus memory status = gaugeStatus[gauge];
        if (!status.isGauge || !status.isAlive) return 0;
        uint256 totalVotes = totalVotesPerPeriod[period];
        if (totalVotes == 0) return 0;
        uint256 gaugeVotes = votesPerPeriod[period][gauge];
        return (gaugeVotes * UNIT) / totalVotes;
    }

    function _reset(address voter, uint256 tokenId) internal {
        uint256 nextPeriod = currentPeriod() + WEEK;
        if (voteCastedPeriod[tokenId][nextPeriod]) {
            // otherwise, no vote casted for that period yet, nothing to reset
            address[] memory _gauges = gaugeVote[tokenId][nextPeriod];
            uint256 length = _gauges.length;
            uint256 totalVotesRemoved;
            for (uint256 i; i < length; ++i) {
                address gauge = _gauges[i];
                uint256 voteAmount = votes[tokenId][nextPeriod][gauge].votes;
                votesPerPeriod[nextPeriod][gauge] -= voteAmount;
                totalVotesRemoved += voteAmount;
                delete votes[tokenId][nextPeriod][gauge];

                emit VoteReseted(voter, tokenId, gauge);
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
        if (_votes == 0) revert NoVotingPower();
        uint256 totalUsedWeights;
        uint256 totalVotesCasted;

        for (uint256 i; i < length; ++i) {
            address gauge = gaugeList[i];
            if (gauge == address(0)) revert ZeroAddress();
            GaugeStatus memory status = gaugeStatus[gauge];
            if (!status.isGauge) revert GaugeNotListed();
            if (!status.isAlive) revert KilledGauge();

            uint256 gaugeVotes = (_votes * weights[i]) / MAX_WEIGHT;
            totalUsedWeights += weights[i];
            totalVotesCasted += gaugeVotes;

            if (votes[tokenId][nextPeriod][gauge].weight == 0) {
                gaugeVote[tokenId][nextPeriod].push(gauge);
            }

            votesPerPeriod[nextPeriod][gauge] += gaugeVotes;
            votes[tokenId][nextPeriod][gauge].weight += weights[i];
            votes[tokenId][nextPeriod][gauge].votes += gaugeVotes;

            emit Voted(voter, tokenId, gauge, block.timestamp, weights[i], gaugeVotes);
        }

        if (totalUsedWeights > MAX_WEIGHT) revert VoteWeightOverflow();
        if (totalUsedWeights > 0) IVotingEscrow(ve).voting(tokenId);

        totalVotesPerPeriod[nextPeriod] += totalVotesCasted;

        voteCastedPeriod[tokenId][nextPeriod] = true;
    }
}
