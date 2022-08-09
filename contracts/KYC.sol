// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract KYC {

    address private _admin;
    uint8 private _bankCount;

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
        _bankCount = 0;
    }
    // modifier for admin
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin is allowed to operate this functionality");
        _;
    }
    // modifier for valid bank
    modifier onlyEnlistedBank() {
        require(banks[msg.sender].ethAddress == msg.sender, "Bank not present in the network");
        _;
    }

    // mapping to maintain customer list
    mapping(string => Customer) internal customers;

    // mapping to maintain bank list
    mapping(address => Bank) public banks;

    // mapping to maintain kycRequest list
    mapping(string => KycRequest) internal kycRequests;

    /*
    Function allows to add kyc request
    Condition verified is that kycrequest is not already present in the list
    we also add 1 to kyc count of the bank which calls the method
    Input: customerName and customerHashData
    */
    function addRequest(string memory _customerName, string memory _customerData) public  onlyEnlistedBank {
        require(
            kycRequests[_customerName].bankAddress == address(0),
            "KYC request already present"
        );
        kycRequests[_customerName].userName = _customerName;
        kycRequests[_customerName].bankAddress = msg.sender;
        kycRequests[_customerName].customerData = _customerData;
        banks[msg.sender].KYC_count += 1;
    }

    /*
    Function allows to remove kyc request
    Conditions verified is kycrequest is already present in the list
    Input: customerName
    */
    function removeRequest(string memory _customerName) public onlyEnlistedBank {
        require(
            kycRequests[_customerName].bankAddress != address(0),
            "KYC request not found"
        );
        delete kycRequests[_customerName];
    }

    /*
    conditions verified are
        1. customer is not already present in the list
        2. customer kyc request has been raised.
        3. Bank is allowed to vote or add a customer
    whenever we add a customer, we add 1 to the upvotes and remove the customer from the kyc request list
    Input: customerName and customerHashData
    */
    function addCustomer(string memory _customerName, string memory _customerData) public onlyEnlistedBank {
        require(
            customers[_customerName].bank == address(0),
            "Customer is already present, please call modifyCustomer to edit the customer data"
        );
        require(
            banks[msg.sender].isAllowedToVote == true,
            "Bank is not allowed to add a customer"
        );
        require(
            stringsEquals(kycRequests[_customerName].userName, _customerName),
            "KYC must be raised before adding customers"
        );
        customers[_customerName].userName = _customerName;
        customers[_customerName].data = _customerData;
        customers[_customerName].bank = msg.sender;
        customers[_customerName].upVotes += 1;

        removeRequest(_customerName);
    }

    /*
    Function allows to view details of the customer
    Condition verified is customer is already present in the list
    Input: customerName
    Output: each variable of the customer struct

    */
    function viewCustomer(string memory _customerName) public onlyEnlistedBank view returns (
        string memory,
        string memory,
        address,
        bool,
        uint,
        uint)  {
        require(
            customers[_customerName].bank != address(0),
            "Customer is not present in the database"
        );
        return (
        customers[_customerName].userName,
        customers[_customerName].data,
        customers[_customerName].bank,
        customers[_customerName].kycStatus,
        customers[_customerName].downVotes,
        customers[_customerName].upVotes
        );
    }

    /*
    Function allows to upvote a customer
    Condition verified are
        1. customer is already present in the list
        2. bank is allowed to upvote a customer
    it accepts the customer details and acknowledges the kyc done
    when a bank upvotes a customer, customers upvote count is increased by 1.
    it then calls a method to set the kycstatus of the customer
    Input: customerName
    */
    function upvoteCustomer(string memory _customerName) public onlyEnlistedBank {
        require(
            customers[_customerName].bank != address(0),
            "Customer is not present in the database"
        );

        require(
            banks[msg.sender].isAllowedToVote == true,
            "Bank is not allowed to upvote"
        );

        customers[_customerName].upVotes += 1;
        setKycStatus(_customerName);
    }
    /*
    Function allows to set kysStatus based on number of upVotes and downVotes
    Condition verified is customer is already present in the list
    if upVotes > downVotes, customers kycStatus is set to true
    if upVotes >= 50% of all bank counts, kycStatus is set to true
    if downVotes >= 50% of all bank counts, kycStatus is set to false.
    */
    function setKycStatus(string memory _customerName) internal onlyEnlistedBank {
        require(
            customers[_customerName].bank != address(0),
            "Customer is not present in the database"
        );
        if(customers[_customerName].upVotes > customers[_customerName].downVotes){
            customers[_customerName].kycStatus = true;
        }
        uint rating = (uint(customers[_customerName].upVotes * 10**2) / uint(_bankCount));
        if(rating >= 50){
            customers[_customerName].kycStatus = true;
        }
        rating = (uint(customers[_customerName].downVotes * 10**2) / uint(_bankCount));
        if(rating >= 50){
            customers[_customerName].kycStatus = false;
        }
    }

    /*
    Function allows to downvote a customer
    Condition verified are
        1. customer is already present in the list
        2. bank is allowed to upvote a customer
    when a bank downvotes a customer, customers downvote count is increased by 1.
    it then calls a method to set the kycstatus of the customer
    Input: customerName
    */
    function downvoteCustomer(string memory _customerName) public onlyEnlistedBank {
        require(
            customers[_customerName].bank != address(0),
            "Customer is not present in the database"
        );

        require(
            banks[msg.sender].isAllowedToVote == true,
            "Bank is not allowed to downvote a customer"
        );
        customers[_customerName].downVotes += 1;
        setKycStatus(_customerName);
    }

    /*
    Function allows to modify a customer
    Condition verified is customer is already present in the list
    it updates new customer data and sets upVotes, downVotes to 0
    its bank address is set to the msg.sender
    removes the customer from the kyc request list
    Input: customerName and updated customerHashData
    */
    function modifyCustomer(string memory _customerName, string memory _newcustomerData) public onlyEnlistedBank {
        require(
            customers[_customerName].bank != address(0),
            "Customer is not present in the database"
        );
        customers[_customerName].data = _newcustomerData;
        customers[_customerName].upVotes = 0;
        customers[_customerName].downVotes = 0;
        customers[_customerName].bank = msg.sender;
        delete kycRequests[_customerName];
    }

    /*
    Function returns the number of complaints against a bank
    Condition verified is that bank is already present in the list
    Input: bankAddress
    it returns complaintsReported against a bank
    */
    function getBankComplaints(address _bankAddress) public view returns (uint) {
        require(
            banks[_bankAddress].ethAddress != address(0),
            "Bank is not present in the database"
        );
        return banks[_bankAddress].complaintsReported;
    }

    /*
    Function return the details of the bank
    Condition verified is bank is already present in the list
    Input: Bank Address
    returns bank object.
    */

    function viewBankDetails(address _bankAddress) public view returns (Bank memory) {
        require(
            banks[_bankAddress].ethAddress != address(0),
            "Bank is not present in the database"
        );
        return banks[_bankAddress];
    }
    /*
    Function is used to report a bank by other banks
    increments complaintsReported count by 1.
    if complaintsReported is more than 1/3 of the banks, isAllowedToVote is set to false.
    */
    function reportBank(address _bankAddress, string memory _bankName) public onlyEnlistedBank {
        require(
            banks[_bankAddress].ethAddress != address(0),
            "Bank is not present in the database"
        );
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].complaintsReported += 1;
        uint rating = (uint(banks[_bankAddress].complaintsReported* 10**2) / uint(_bankCount));
        if(rating >= 30){
            banks[_bankAddress].isAllowedToVote = false;
        }
    }

    // Admin Interface

    /*
    Function adds bank to the database
    only admin has access to this method
    Condition verified is bank should not be already present in the list
    set the details of the bank
    Inputs: bankName, address and regNumber,
    by default set isAllowedToVote to true, complaintReported = 0 and kycCount = 0
    also, increments bankCount
    */
    function addBank(string memory _bankName, address _bankAddress, string memory _regNumber) public onlyAdmin {
        require(
            banks[_bankAddress].ethAddress == address(0),
            "Bank is already in the database. Please call modifyBank to update details"
        );
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].regNumber = _regNumber;
        banks[_bankAddress].isAllowedToVote = true;
        banks[_bankAddress].complaintsReported = 0;
        banks[_bankAddress].KYC_count = 0;
        _bankCount++;
    }

    /*
    Function modifies a bank access to vote.
    only admin has access to this method.
    Condition verified is only bank should already be present in the list
    Input: bankaddress and isAllowedtoVote flag.
    updates isAllowedToVote flag of a bank
    */
    function modifyBank(address _bankAddress, bool _isAllowedToVote) public onlyAdmin {
        require(
            banks[_bankAddress].ethAddress == _bankAddress,
            "Bank is not present in the database"
        );
        banks[_bankAddress].isAllowedToVote = _isAllowedToVote;
    }

    /*
    Function removes a bank from the list
    only admin has access to this method.
    Condition verified is bank should already be present in the list
    Input: bankAddress
    removes bank from the list
    removes total bank count.
    */
    function removeBank(address _bankAddress) public onlyAdmin {
        require(
            banks[_bankAddress].ethAddress == _bankAddress,
            "Bank is not present in the database"
        );
        delete banks[_bankAddress];
        _bankCount--;

    }

    // utility method to compare strings, used in require statements above
    function stringsEquals(string storage _str1, string memory _str2) internal view returns (bool) {
        bytes storage str1 = bytes(_str1);
        bytes memory str2 = bytes(_str2);
        if (str1.length != str2.length)
            return false;
        for (uint i = 0; i < str1.length; i ++){
            if (str1[i] != str2[i])
                return false;
        }
        return true;
    }

}