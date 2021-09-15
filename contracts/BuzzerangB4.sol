
import "./B4Vault.sol";

pragma solidity 0.6.12;

interface B4VaultUser {
    function getMembershipBalance(uint8 slot) external view returns (uint);
    function storeVaultTRX(uint8 slot) external payable;
    function activeMembership(uint8 membership, uint membershipPrice) external payable;
}

contract BuzzerangB4 {
    //Modifiers
    modifier onlyOwner() virtual{
        require(msg.sender == buzz, "You're not the buzz of the contract");
        _;
    }
    //Reentrancy
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _status;

    modifier nonReEntrant() virtual{
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    //Maintenance
    uint256 internal state;
    modifier maintenance() {
        require(state == 0, "The contract is under maintenance.");
        _;
    }

    //Store the membership prices
    mapping(uint8 => uint) public membershipPrice;
    //Payout for each person
    mapping(uint8 => uint) public membershipPay;

    mapping(uint8 => uint) internal bonusTRX;

    mapping(uint8 => uint) internal vaultPay;
    //Renewal address
    address internal renewalAddress;
    uint trxCost = 15000000000 wei;
    address public vaultAddress;
    //External contract addresses
    address public buzzerangAddress;

    //User data structure
    struct User {
        //User ID
        uint id;
        //Direct Partner or up line
        address sponsor;
        //Buzzerang vault storage contract
        address buzzVault;
        mapping(uint8 => uint32) period;
        //Active programs
        mapping(uint8 => bool) activeB4Slots;
        //Programs storing
        mapping(uint8 => B4) b4;
        // Membership times
        mapping(uint8 => uint256) membershipTime;
        mapping(uint8 => bool) activeMembershipSlots;
        
    }
    // Smart Plus program data
    struct B4 {
        address currentSponsor;
        address currentParent;
        uint32 currentId;
        uint32 countReferrals;
        uint32 countLevel;
        uint32 memCount;
        mapping(uint32 => mapping(uint8 => uint32)) membershipActive;
        mapping(uint32 => address) referrals;
    }
    // Initial number of slots
    uint8 public LAST_SLOT = 5;
    // Store the users
    mapping(address => User) public users;
    // Store address to convert to id
    mapping(uint => address) public idToAddress;
    // Store the usernames of the users
    mapping(string => address) private usernameToAddress;
    // Store the username of the users
    mapping(address => string) private addressToUsername;
    // Store the balances of the users
    mapping(address => mapping(uint => mapping(uint => uint))) internal balances;
    mapping(address => uint) private renew;
    // Last registered user
    uint public lastUserId = 1;
    // Global Income
    uint internal globalIncome = 0;
    // Owner (buzz) of the smart contract
    address payable public buzz;
    
    uint private decimals = 1000000000000000000;

    // Store the slot prices
    mapping(uint8 => uint) public slotPrice;
    // Store the slot prices
    mapping(uint8 => uint8) public b4Percentage;
    // Store the slot prices
    mapping(uint8 => uint8) public b4buzzPercentage;
    
    BUSDInterface internal BUSD;

    // Buzzerang events
    event Registration(uint userId, uint sponsorId);
    event Upgrade(uint userId, uint sponsorId, uint8 slot);
    event Placement(uint userId, uint parentId, uint8 slot, uint position);
    event Username(string username, address indexed userAddress);
    event MissedSlot(uint userId, uint fromId, uint8 slot);
    event ExtraSlot(uint userId, uint fromId, uint8 slot);
    event Membership(uint userId, uint32 period, uint8 slot);
    event Renew(uint userId, uint membership, uint time);
    
    constructor(address payable buzzAddress, uint buzzId, string memory buzzUsername, address busdAddess) public {
        //Modifiers status
        _status = _NOT_ENTERED;
        state = 0;
        //Slot prices
        bonusTRX[1] = 200000000000000000;
        bonusTRX[2] = 390000000000000000;
        bonusTRX[3] = 780000000000000000;
        bonusTRX[4] = 1560000000000000000;
        bonusTRX[5] = 3130000000000000000;
        //Slot prices
        slotPrice[1] = 499 * decimals / 100;
        slotPrice[2] = 999 * decimals / 100;
        slotPrice[3] = 3999 * decimals / 100;
        slotPrice[4] = 7999 * decimals / 100;
        slotPrice[5] = 29999 * decimals / 100;
        //Membership prices
        membershipPrice[1] = 499 * decimals / 100;
        membershipPrice[2] = 999 * decimals / 100;
        membershipPrice[3] = 3999 * decimals / 100;
        membershipPrice[4] = 7999 * decimals / 100;
        membershipPrice[5] = 29999 * decimals / 100;
        //Membership payouts  /15
        membershipPay[1] = 332666666666666666;
        membershipPay[2] = 666000000000000000;
        membershipPay[3] = 2666000000000000000;
        membershipPay[4] = 5332666666666666666;
        membershipPay[5] = 19999333333333333333;
        //Vault payouts
        vaultPay[1] = 4657333333333333334;
        vaultPay[2] = 9324000000000000000;
        vaultPay[3] = 37324000000000000000;
        vaultPay[4] = 74657333333333333334;
        vaultPay[5] = 279990666666666666667;
        //B4 parent and buzz percentage
        uint8 percentage = 80;
        for (uint8 i = 1; i <= 10; i++) {
            if (i < 3) {
                b4Percentage[i] = 10 * i;
            } else if (i < 8) {
                b4Percentage[i] = 4;
            } else {
                b4Percentage[i] = 5 * (i - 7);
            }
            percentage -= b4Percentage[i - 1];
            b4buzzPercentage[i] = percentage;
        }
        // buzz address
        buzz = buzzAddress;
        // Renewal Contract
        renewalAddress = buzzAddress;
        // Save the user data
        users[buzzAddress] = User({
            id : buzzId,
            sponsor : buzzAddress,
            buzzVault : buzzAddress
        });
        // Store the buzz converts
        idToAddress[buzzId] = buzzAddress;
        usernameToAddress[buzzUsername] = buzzAddress;
        addressToUsername[buzzAddress] = buzzUsername;
        //Active all slots
        for (uint8 slot = 1; slot <= LAST_SLOT; slot++) {
            users[buzzAddress].activeB4Slots[slot] = true;
            users[buzzAddress].b4[slot].currentSponsor = buzzAddress;
            users[buzzAddress].b4[slot].currentParent = buzzAddress;
            users[buzzAddress].b4[slot].memCount = 1;
        }
        // Emit the buzz registration event
        emit Registration(buzzId, 0);

        //Init BUSD interface
        BUSD = BUSDInterface(busdAddess);
    }
    
    //Fallback function
    fallback() external payable{
        revert();
    }
    //Registration for B4 slot
    function registrationExt(address sponsorAddress,uint userId, string calldata username) external payable returns (bool) {
        require(msg.sender == buzzerangAddress, "Only can register with Buzzerang Contract");
        registration(tx.origin, sponsorAddress,userId,username);
        return true;
    }
    // Activate user subscription
    function activationExt(uint8 membership) external payable nonReEntrant maintenance returns (bool) {
        require(msg.sender == tx.origin, "Smart Contract is not an user");
        activateMembership(tx.origin, membership);
        return true;
    }
    // Activate user subscription only for user vault
    function activationVault(uint8 membership) external payable returns (uint) {
        require(msg.sender == users[tx.origin].buzzVault, "Only can activate an register user");
        activateMembership(tx.origin, membership);
        return membershipPrice[membership];
    }
    // Activate user subscription with the balance of the user vault
    function activationVaultExt(uint8 membership) external payable nonReEntrant maintenance returns (bool) {
        require(msg.sender == tx.origin, "Only an user can activate vault");
        require(isUserExists(tx.origin), "Only can activate with Buzzerang Contract");
        require(membership <= LAST_SLOT && membership >= 1, "Incorrect membership");
        require(BUSD.balanceOf(msg.sender) + getMembershipBalance(tx.origin, membership) >= membershipPrice[membership], "Incorrect membership amount");
        B4VaultUser(users[tx.origin].buzzVault).storeVaultTRX.value(slotPrice[membership])(membership);
        B4VaultUser(users[tx.origin].buzzVault).activeMembership(membership,membershipPrice[membership]);
        return true;
    }
    
    // Buy new slot users to any slot onlyOwner
    function buySlotCreator(address userAddress, uint8 slot) external onlyOwner nonReEntrant returns (string memory) {
        buyNewSlotInternal(userAddress, slot);
        return "Slot bought successfully";
    }
    // Upgrade user to any slot
    function buyNewSlot(uint8 slot) external payable nonReEntrant maintenance returns (string memory) {
        buyNewSlotInternal(msg.sender, slot);
        return "Slot bought successfully";
    }
    // Internal upgrade user to any slot
    function buyNewSlotInternal(address user, uint8 slot) private {
        require(isUserExists(user), "User is not exists. Register first.");
        if (!(msg.sender == buzz)) require(BUSD.balanceOf(msg.sender) >= slotPrice[slot], "Invalid price");
        require(slot >= 2 && slot <= LAST_SLOT, "Invalid slot");
        require(!users[user].activeB4Slots[slot], "Slot already activated");
        address freeB4Sponsor = findFreeB4Sponsor(user, slot);
        if(freeB4Sponsor != users[user].sponsor){
            emit ExtraSlot(users[freeB4Sponsor].id, users[user].id, slot);
        }
        users[user].activeB4Slots[slot] = true;
        users[user].b4[slot].memCount = 1;
        updateB4Sponsor(user, freeB4Sponsor, slot);
        emit Upgrade(users[user].id, users[freeB4Sponsor].id, slot);
        globalIncome += slotPrice[slot];
    }
    // Register user with the sponsor address
    function registration(address userAddress, address sponsorAddress, uint userId, string memory username) private {
        if (!(msg.sender == buzz)) require(BUSD.balanceOf(msg.sender) >= slotPrice[1], "Invalid registration amount");
        require(!isUserExists(userAddress), "User already exists");
        require(isUserExists(sponsorAddress), "Sponsor not exists");
        lastUserId++;
        // Assign user first data
        address buzzVault = address(new B4Vault(userAddress, address(this)));
        users[userAddress] = User({
            id : userId,
            sponsor : sponsorAddress,
            buzzVault : buzzVault
        });
        idToAddress[userId] = userAddress;
        usernameToAddress[username] = userAddress;
        addressToUsername[userAddress] = username;
        users[userAddress].sponsor = sponsorAddress;
        users[userAddress].activeB4Slots[1] = true;
        users[userAddress].b4[1].memCount = 1;
        updateB4Sponsor(userAddress, sponsorAddress, 1);
        emit Registration(users[userAddress].id, users[sponsorAddress].id);
        emit Username(username,userAddress);
    }

    function updateB4Sponsor(address userAddress, address sponsorAddress, uint8 slot) private {
        users[userAddress].b4[slot].currentSponsor = sponsorAddress;
        uint32 currentId = getB4FreeID(sponsorAddress, slot);
        if (currentId > 3) {
            if (currentId % 3 == 1) {
                users[userAddress].b4[slot].currentParent = users[sponsorAddress].b4[slot].referrals[(currentId - 1) / 3];
                users[userAddress].b4[slot].currentId = 1;
            } else if (currentId % 3 == 2) {
                users[userAddress].b4[slot].currentParent = users[sponsorAddress].b4[slot].referrals[(currentId - 2) / 3];
                users[userAddress].b4[slot].currentId = 2;
            } else {
                users[userAddress].b4[slot].currentParent = users[sponsorAddress].b4[slot].referrals[(currentId - 3) / 3];
                users[userAddress].b4[slot].currentId = 3;
            }
        } else {
            if (currentId == 0) {
                return updateB4Sponsor(userAddress, users[sponsorAddress].b4[slot].referrals[1], slot);
            }
            users[userAddress].b4[slot].currentParent = sponsorAddress;
            users[userAddress].b4[slot].currentId = currentId;
        }
        address parent = users[userAddress].b4[slot].currentParent;
        currentId = users[userAddress].b4[slot].currentId;
        uint income = 0;
        uint32 countID = 0;
        if(sponsorAddress != buzz){
            if (getMembershipBalance(sponsorAddress,slot) >= membershipPrice[slot] && users[sponsorAddress].membershipTime[slot] >= now) {
                income = (slotPrice[slot] * 20) / 100;
                balances[sponsorAddress][1][slot] += income;
                sendTrxDividends(sponsorAddress,income);
            } else {
                B4VaultUser(users[sponsorAddress].buzzVault).storeVaultTRX.value((slotPrice[slot] * 20) / 100)(slot);
            }
        }else{
            sendTrxDividends(buzz,(slotPrice[slot] * 20) / 100);
        }
        for (uint8 i = 1; i <= 10; i++) {
            countID += pow(3, i - 1) * currentId;
            users[parent].b4[slot].referrals[countID] = userAddress;
            users[parent].b4[slot].countReferrals += 1;
            if (parent == buzz) {
                return sendTrxDividends(buzz,(slotPrice[slot] * b4buzzPercentage[i]) / 100);
            } else {
                if (getMembershipBalance(parent,slot) >= membershipPrice[slot] + trxCost && users[parent].membershipTime[slot] >= now) {
                    income = (slotPrice[slot] * b4Percentage[i]) / 100;
                    balances[parent][1][slot] += income;
                    if(renew[userAddress] == 0){
                        renew[userAddress] = 1;
                        emit Renew(users[userAddress].id,slot,users[userAddress].membershipTime[slot]);
                    }
                    sendTrxDividends(parent, income);
                } else {
                    B4VaultUser(users[parent].buzzVault).storeVaultTRX.value((slotPrice[slot] * b4Percentage[i]) / 100)(slot);
                }
                emit Placement(users[userAddress].id,users[parent].id,slot,countID);
            }
            currentId = users[parent].b4[slot].currentId;
            parent = users[parent].b4[slot].currentParent;
        }
    }

    // Register user with the sponsor address
    function activateMembership(address userAddress, uint8 slot) private {
        if (!(msg.sender == buzz)) {
            require(BUSD.balanceOf(msg.sender) >= membershipPrice[slot], "Invalid membership amount");
        }
        require(isUserExists(userAddress), "User not exists");
        require(slot >= 1 && slot <= LAST_SLOT, "Invalid slot");
        require(users[userAddress].activeB4Slots[slot], "Slot not activated");
        if (users[userAddress].membershipTime[slot] != 0) {
            require(now > users[userAddress].membershipTime[slot] - 3 days, "Membership is active");
        }

        if (now > users[userAddress].membershipTime[slot]) {
            users[userAddress].membershipTime[slot] = now;
        }
        users[userAddress].membershipTime[slot] += 30 days;
        assert(users[userAddress].membershipTime[slot] >= (now + 30 days));
        if (!users[userAddress].activeMembershipSlots[slot]) {
            users[userAddress].activeMembershipSlots[slot] = true;
        }
        renew[userAddress] = 0;
        users[userAddress].period[slot] += 1;
        uint32 period = users[userAddress].period[slot];
        address parent = users[userAddress].b4[slot].currentParent;
        address sponsor = users[userAddress].b4[slot].currentSponsor;
        uint balancing = vaultPay[slot];
        for (uint8 level = 1; level <= 10; level++) {
            users[parent].b4[slot].membershipActive[period][level + ((slot - 1) * 10)] += 1;
            if (parent == buzz) {
                  sendTrxDividends(buzz,membershipPay[slot]);
            } else {
                if (users[parent].membershipTime[slot] >= now) {
                    if (getMembershipBalance(parent,slot) >= membershipPrice[slot] + trxCost) {
                        balances[parent][2][slot] += membershipPay[slot];
                        if(renew[userAddress] == 0){
                            renew[userAddress] = 1;
                            emit Renew(users[userAddress].id,slot,users[userAddress].membershipTime[slot]);
                        }
                        sendTrxDividends(parent,membershipPay[slot]);
                    } else {
                        B4VaultUser(users[parent].buzzVault).storeVaultTRX.value(membershipPay[slot])(slot);
                    }
                } else {
                    balancing += membershipPay[slot];
                }
            }
            parent = users[parent].b4[slot].currentParent;
        }
        sendTrxDividends(vaultAddress,balancing);
        emit Membership(users[userAddress].id, period, slot);
        globalIncome += slotPrice[slot];
    }
    //Utils
    function pow(uint32 base, uint32 exponent) private pure returns (uint32) {
        if (exponent == 0) {
            return 1;
        }
        else if (exponent == 1) {
            return base;
        }
        else if (base == 0 && exponent != 0) {
            return 0;
        }
        else {
            return base ** exponent;
        }
    }
    function getB4FreeID(address sponsorAddress, uint8 slot) private returns (uint32){
        for (uint32 b4Id = users[sponsorAddress].b4[slot].memCount; b4Id < 88573; b4Id++) {
            if (users[sponsorAddress].b4[slot].referrals[b4Id] == address(0)) {
                users[sponsorAddress].b4[slot].memCount = b4Id + 1;
                return b4Id;
            }
        }
        return 0;
    }

    function findFreeB4Sponsor(address userAddress, uint8 slot) public returns (address) {
        while (true) {
            if (users[users[userAddress].sponsor].activeB4Slots[slot]) {
                break;
            }
            emit MissedSlot(users[users[userAddress].sponsor].id, users[userAddress].id, slot);
            userAddress = users[userAddress].sponsor;
        }
        return users[userAddress].sponsor;
    }
    // Search if the user exists in the Smart Tron platform
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    //Generate the payout for the B4 program
    function sendTrxDividends(address receiver,uint amount) private {
        if (msg.sender != buzz)
        {
            bool success =  BUSD.transfer(receiver, amount);
            require(success, "Insufficient Gas.");
        }
    }

    function getMembershipBalance(address userAddress, uint8 membership) public view returns (uint){
        return B4VaultUser(users[userAddress].buzzVault).getMembershipBalance(membership);
    }
    

    function getTotalBalance(uint id) external view returns(uint totalBalance){
        address userAddress = idToAddress[id];
        for(uint program = 1; program < 3; program++){
            for (uint8 slot = 1; slot <= LAST_SLOT; slot++) {
                totalBalance += balances[userAddress][program][slot];
            }
        }
        for (uint8 slot = 1; slot <= LAST_SLOT; slot++) {
            totalBalance += getMembershipBalance(userAddress,slot);
        }
        return totalBalance;
    }

}

interface BUSDInterface {
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
}