// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./DTRUSTFactory.sol";
import "./DTtoken.sol";

contract Governance {
    IERC20 public dttoken;
    address[] public voters;

    Proposal[] public proposals;

    uint256 public constant votePeriod = 90 days;

    // voter => deposit
    mapping(address => uint256) public deposits;

    mapping(address => bool) public isVoter;

    // Voter => Withdraw timestamp
    mapping(address => uint256) public withdrawTimes;

    struct Proposal {
        Result result;
        ProposalType proposalType;
        bytes32 proposalContentOfQuestion;
        uint256 proposalBasisPoint;
        address proposer;
        uint256 startTime;
        uint256 yesCount;
        uint256 noCount;
    }

    enum Result {
        Pending,
        Yes,
        No
    }

    enum ProposalType {
        BasisPoint,
        Question
    }

    event Execute(uint256 indexed proposalId);
    event Propose(uint256 indexed proposalId, address indexed proposer);
    event Terminate(uint256 indexed proposalId, Result result);
    event Vote(
        uint256 indexed proposalId,
        address indexed voter,
        bool approve,
        uint256 weight
    );
    event SplitAnnualFee(uint256 totalOfDTtoken, uint256 lengthOfVoter);

    modifier onlyVoter() {
        require(isVoter[msg.sender], "Error: The caller is not voter!");
        _;
    }

    function registerDTtoken(IERC20 _DTtoken) external {
        dttoken = _DTtoken;
    }

    function deposit(uint256 _amount) external {
        voters.push(msg.sender);
        deposits[msg.sender] += _amount;
        dttoken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) external onlyVoter {
        deposits[msg.sender] -= deposits[msg.sender];
        dttoken.transfer(msg.sender, _amount);
    }

    function splitAnnualFee(uint256 _annualAmount) external {
        uint256 totalOfDTtoken = dttoken.totalSupply();
        uint256 lengthOfVoter = voters.length;
        for (uint256 i = 0; i < lengthOfVoter; i++) {
            uint256 fee = _annualAmount *
                (deposits[voters[i]] * totalOfDTtoken);
            deposits[voters[i]] += fee;
        }
        emit SplitAnnualFee(totalOfDTtoken, lengthOfVoter);
    }

    function proposeForDtrustBasisPoint(uint256 _basisPoint)
        external
        onlyVoter
        returns (uint256)
    {
        uint256 proposalId = proposals.length;

        Proposal memory proposal;
        proposal.proposalType = ProposalType.BasisPoint;
        proposal.proposalBasisPoint = _basisPoint;
        proposal.proposer = msg.sender;
        proposal.startTime = block.timestamp;

        proposals.push(proposal);

        emit Propose(proposalId, msg.sender);

        return proposalId;
    }

    function proposeForDTrustQuestionOfContent(bytes32 _content)
        external
        onlyVoter
        returns (uint256)
    {
        uint256 proposalId = proposals.length;

        Proposal memory proposal;
        proposal.proposalType = ProposalType.Question;
        proposal.proposalContentOfQuestion = _content;
        proposal.proposer = msg.sender;
        proposal.startTime = block.timestamp;

        proposals.push(proposal);

        emit Propose(proposalId, msg.sender);

        return proposalId;
    }

    function voteYes(uint256 _proposalId) external onlyVoter {
        Proposal storage proposal = proposals[_proposalId];

        uint256 _deposit = deposits[msg.sender];
        uint256 fee = (_deposit * 3) / 4;
        require(_deposit > fee, "Not enough amount in your balance");
        deposits[msg.sender] -= fee;
        proposal.yesCount += 1;

        emit Vote(_proposalId, msg.sender, true, fee);
    }

    function voteNo(uint256 _proposalId) external onlyVoter {
        Proposal storage proposal = proposals[_proposalId];
        require(
            proposal.result == Result.Pending,
            "Proposal is already finalized"
        );

        uint256 _deposit = deposits[msg.sender];
        uint256 fee = (_deposit * 3) / 4;
        deposits[msg.sender] -= fee;
        proposal.noCount += 1;

        emit Vote(_proposalId, msg.sender, false, fee);
    }

    function finalize(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        DTRUSTFactory dtrustFactory;
        require(
            proposal.result == Result.Pending,
            "Proposal is already finalized"
        );
        if (proposal.yesCount > proposal.noCount) {
            require(
                block.timestamp > proposal.startTime + votePeriod,
                "Proposal cannot be executed until end of vote period"
            );
            if (proposal.proposalType == ProposalType.BasisPoint) {
                dtrustFactory.updateBasisPoint(proposal.proposalBasisPoint);
            } else if (proposal.proposalType == ProposalType.Question) {
                dtrustFactory.updateQuestion(
                    proposal.proposalContentOfQuestion
                );
            }
            proposal.result = Result.Yes;

            emit Execute(_proposalId);
        } else {
            require(
                block.timestamp > proposal.startTime + votePeriod,
                "Proposal cannot be terminated until end of yes vote period"
            );

            proposal.result = Result.No;

            emit Terminate(_proposalId, proposal.result);
        }
    }

    function getProposal(uint256 _proposalId)
        external
        view
        onlyVoter
        returns (Proposal memory)
    {
        return proposals[_proposalId];
    }

    function getProposalsCount() external view onlyVoter returns (uint256) {
        return proposals.length;
    }
}
