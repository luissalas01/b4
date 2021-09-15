/*
 /$$$$$$$
| $$__  $$
| $$  \ $$ /$$   /$$ /$$$$$$$$ /$$$$$$$$  /$$$$$$   /$$$$$$  /$$$$$$  /$$$$$$$   /$$$$$$
| $$$$$$$ | $$  | $$|____ /$$/|____ /$$/ /$$__  $$ /$$__  $$|____  $$| $$__  $$ /$$__  $$
| $$__  $$| $$  | $$   /$$$$/    /$$$$/ | $$$$$$$$| $$  \__/ /$$$$$$$| $$  \ $$| $$  \ $$
| $$  \ $$| $$  | $$  /$$__/    /$$__/  | $$_____/| $$      /$$__  $$| $$  | $$| $$  | $$
| $$$$$$$/|  $$$$$$/ /$$$$$$$$ /$$$$$$$$|  $$$$$$$| $$     |  $$$$$$$| $$  | $$|  $$$$$$$
|_______/  \______/ |________/|________/ \_______/|__/      \_______/|__/  |__/ \____  $$
                                                                                /$$  \ $$
                                                                               |  $$$$$$/
                                                                                \______/
*/
// You're not the vault owner 1
//Insufficient Funds 2
//Only Renewal can access to refund gas cost 3
//Insufficient Gas 4
pragma solidity 0.6.12;

interface B4Interface {
    function activationVault(uint8 membership) external payable returns (uint);
    function getRenewalAddress() external view returns (address);
}

contract B4Vault {
    address private vaultOwner;
    address private b4Address;
    mapping(uint8 => uint) private membershipBalances;

    fallback() external payable {
        revert();
    }

    function storeVaultTRX(uint8 slot) external payable {
        membershipBalances[slot] += msg.value;
//        B4Interface(b4Address).autoRenewal(vaultOwner,membershipBalances[slot],slot);
    }

    constructor(address owner, address contractAddress) public {
        vaultOwner = owner;
        b4Address = contractAddress;
    }
    // Activate the membership to complete the balance
    function activeMembership(uint8 membership, uint membershipPrice) external payable {
        require(msg.sender == b4Address || tx.origin == vaultOwner , "1");
        require(membershipBalances[membership] >= membershipPrice, "2");
        membershipBalances[membership] -= membershipPrice;
        B4Interface(b4Address).activationVault.value(membershipPrice)(membership);
    }
    //Refund the cost of the membership for auto renewal
    function refundGas(uint gasCost,uint8 membership) external {
        require(msg.sender == B4Interface(b4Address).getRenewalAddress(), "3");
        uint amount = gasCost;
        membershipBalances[membership] -= amount;
        (bool success, ) = tx.origin.call.value(amount)("");
        require(success, "4");
    }
    // Retrieve the balance of each Membership in the vault
    function getMembershipBalance(uint8 slot) external view returns (uint){
        return membershipBalances[slot];
    }
}
