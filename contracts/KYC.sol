// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract KYC {

    address private _admin;

    struct Customer {
        string userName;
        string data;
        bool kycStatus;
        uint downVotes;
        uint upVotes;
        address bank;
    }

    struct Bank {
        string name;
        address ethAddress;
        uint complaintsReported;
        uint KYC_count;
        bool isAllowedToVote;
        string regNumber;
    }

    struct KycRequest {
        string userName;
        address bankAddress;
        string customerData;
    }

    constructor () {
        _admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin is allowed to operate this functionality");
        _;
    }

    modifier onlyEnlistedBank() {
        require(banks[msg.sender].ethAddress == msg.sender, "Bank not present in the network");
        _;
    }

    mapping(string => Customer) public customers;

    mapping(address => Bank) public banks;

    mapping(string => KycRequest) public kycRequests;

    function addRequest(string memory _customerName, string memory _customerData) public  onlyEnlistedBank {
        require(kycRequests[_customerName].bankAddress == address(0),"KYC request already present");
        kycRequests[_customerName].userName = _customerName;
        kycRequests[_customerName].bankAddress = msg.sender;
        kycRequests[_customerName].customerData = _customerData;
    }

    function removeRequest(string memory _customerName) public onlyEnlistedBank {
        require(kycRequests[_customerName].bankAddress != address(0),"KYC request not found");
        delete kycRequests[_customerName];
    }
    function addCustomer(string memory _userName, string memory _customerData) public onlyEnlistedBank {
        require(customers[_userName].bank == address(0), "Customer is already present, please call modifyCustomer to edit the customer data");
        customers[_userName].userName = _userName;
        customers[_userName].data = _customerData;
        customers[_userName].bank = msg.sender;
    }

    function viewCustomer(string memory _userName) public onlyEnlistedBank view returns (string memory, string memory, address)  {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        return (customers[_userName].userName, customers[_userName].data, customers[_userName].bank);
    }

    function upvoteCustomer(string memory _userName) public onlyEnlistedBank {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        customers[_userName].upVotes += 1;
    }

    function downvoteCustomer(string memory _userName) public onlyEnlistedBank {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        customers[_userName].downVotes += 1;
    }

    function modifyCustomer(string memory _userName, string memory _newcustomerData) public onlyEnlistedBank {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        customers[_userName].data = _newcustomerData;
        customers[_userName].upVotes = 0;
        customers[_userName].downVotes = 0;
        delete kycRequests[_userName];
    }

    function getBankComplaints(address _bankAddress) public view returns (uint) {
        require(banks[_bankAddress].ethAddress != address(0), "Bank is not present in the database");
        return banks[_bankAddress].complaintsReported;
    }

    function viewBankDetails(address _bankAddress) public view returns (Bank memory) {
        require(banks[_bankAddress].ethAddress != address(0), "Bank is not present in the database");
        return banks[_bankAddress];
    }

    function reportBank(address _bankAddress, string memory _bankName) public onlyEnlistedBank {
        require(banks[_bankAddress].ethAddress != address(0), "Bank is not present in the database");
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].isAllowedToVote = false;
    }

    function addBank(string memory _bankName, address _bankAddress, string memory _regNumber) public onlyAdmin {
        require(banks[_bankAddress].ethAddress == address(0), "Bank is already in the database. Please call modifyBank to update details");
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].regNumber = _regNumber;
        banks[_bankAddress].isAllowedToVote = true;
        banks[_bankAddress].complaintsReported = 0;
        banks[_bankAddress].KYC_count = 0;
    }


    function modifyBank(address _bankAddress, bool _isAllowedToVote) public onlyAdmin {
        require(banks[_bankAddress].ethAddress != address(0), "Bank is not present in the database");
        banks[_bankAddress].isAllowedToVote = _isAllowedToVote;
    }

    function removeBank(address _bankAddress) public onlyAdmin {
        require(banks[_bankAddress].ethAddress != address(0), "Bank is not present in the database");
        delete banks[_bankAddress];
    }


}


