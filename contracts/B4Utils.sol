import "./BuzzerangB4.sol";

pragma solidity 0.6.12;

abstract contract B4Util is BuzzerangB4{

    modifier onlyOwner() override{
        require(msg.sender == buzz, "You're not the buzz of the contract");
        _;
    }

    modifier nonReEntrant() override{
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function maintenanceState() public onlyOwner{
        if(state == 1){
            state = 0;
        }else{
            state = 1;
        }
    }

    function setVault(address vault) public {
        require(msg.sender == buzz, "Only buzz can set Buzzerang");
        vaultAddress = vault;
    }
    function setBuzzerang(address buzzerang) public {
        require(msg.sender == buzz, "Only buzz can set Buzzerang");
        buzzerangAddress = buzzerang;
    }

    // Register paid users to all
    // Withdraw the contract funds
    function withdrawLostTRXFromBalance() public onlyOwner {
        (bool success, ) = vaultAddress.call.value(address(this).balance)("");
        require(success, "Insufficient Gas.");
    }

    function addSlot(uint slotPricing, uint slotMembershipPrice, uint membershipPayout) public onlyOwner {
        require(slotPricing > slotPrice[LAST_SLOT], 'Invalid slot price amount');
        require(slotMembershipPrice > membershipPrice[LAST_SLOT], 'Invalid membership slot amount');
        require(membershipPayout > membershipPay[LAST_SLOT], 'Invalid membership payout slot amount');
        LAST_SLOT++;
        slotPrice[BuzzerangB4.LAST_SLOT] = slotPricing;
        membershipPrice[BuzzerangB4.LAST_SLOT] = slotMembershipPrice;
        membershipPay[BuzzerangB4.LAST_SLOT] = membershipPayout;
        users[BuzzerangB4.buzz].activeB4Slots[BuzzerangB4.LAST_SLOT] = true;
        users[BuzzerangB4.buzz].b4[LAST_SLOT].currentSponsor = buzz;
        users[BuzzerangB4.buzz].b4[LAST_SLOT].currentParent = buzz;
        users[BuzzerangB4.buzz].b4[LAST_SLOT].referrals[0] = buzz;
        users[BuzzerangB4.buzz].b4[LAST_SLOT].memCount = 1;
    }

     function changePrices(uint price, uint bonus, uint priceMembership, uint payMembership, uint payVault, uint8 slot) public onlyOwner{
        slotPrice[slot] = price;
        bonusTRX[slot] = bonus;
        membershipPrice[slot] = priceMembership;
        membershipPay[slot] = payMembership;
        vaultPay[slot] = payVault;
    }

    function activationRenewal(address userAddress, uint8 membership) external payable nonReEntrant returns (bool) {
        require(msg.sender == renewalAddress, "Only can activate an register user");
        B4VaultUser(users[userAddress].buzzVault).activeMembership(membership,membershipPrice[membership]);
        return true;
    }

    function usersActiveB4Slots(uint id, uint8 slot) public view returns (bool) {
        address userAddress = idToAddress[id];
        return users[userAddress].activeB4Slots[slot];
    }

    function usersB4(uint id, uint8 slot) public view returns (uint, uint, uint[12] memory, uint32) {
        address userAddress = idToAddress[id];
        uint[12] memory referrals;
        for(uint32 i=0; i<12;i++){
            referrals[i] = users[users[userAddress].b4[slot].referrals[i+1]].id;
        }
        return (users[users[userAddress].b4[slot].currentSponsor].id,
        users[users[userAddress].b4[slot].currentParent].id,
        referrals,
        users[userAddress].b4[slot].countReferrals);
    }

    function viewSlotsB4(address user) external view returns (bool[10] memory b4Slots, uint8 b4LastActive)
    {
        for (uint8 i = 1; i <= LAST_SLOT; i++) {
            b4Slots[i-1] = users[user].activeB4Slots[i];
            if (b4Slots[i-1]) b4LastActive = i;
        }
    }

    function viewMemberships(uint id, uint32 period, uint8 slot) public view returns (uint[10] memory membership)
    {
        for (uint8 level = 1; level <= 10; level++) {
            membership[level-1] = users[idToAddress[id]].b4[slot].membershipActive[period][level + ((slot - 1) * 10)];
        }
    }

    function activeMemberships(address userAddress) external view returns (bool[5] memory memberships) {
        for(uint8 membership=1;membership<=LAST_SLOT;membership++){
            if(users[userAddress].membershipTime[membership] >= now){
                memberships[membership-1] = true;
            }else{
                memberships[membership-1] = false;
            }
        }
        return memberships;
    }

    function isActiveOneMembership(address userAddress) external view returns (bool,uint) {
        for(uint8 membership=1;membership<6;membership++){
            if(users[userAddress].membershipTime[membership] >= now){
                return (true,users[userAddress].membershipTime[membership]);
            }
        }
        return (false,users[userAddress].membershipTime[1]);
    }

    function lastDaysMembership(address userAddress, uint8 membership) external view returns(uint){
        if(users[userAddress].membershipTime[membership] > 0){
            return (now - users[userAddress].membershipTime[membership]) / 1 days;
        }else{
            return 0;
        }
    }

    function getBalance(uint id, uint program, uint8 slot) public view returns(uint){
        address userAddress = idToAddress[id];
        return balances[userAddress][program][slot];
    }

    function getMembershipBalances(address userAddress) public view returns (uint[5] memory accountBalance){
        for (uint8 membership = 1; membership <= LAST_SLOT; membership++) {
            accountBalance[membership - 1] = B4VaultUser(users[userAddress].buzzVault).getMembershipBalance(membership);
        }
        return accountBalance;
    }

    function setRenewalAddress(address newAddress) public onlyOwner{
        require(newAddress != renewalAddress);
        renewalAddress = newAddress;
    }
    
    function getRenewalAddress() external view returns (address){
        return renewalAddress;
    }
    
    function getCurrentUserPeriod(address user, uint8 slot) external view returns (uint32){
        return users[user].period[slot];
    }
    
    function isActiveMembership(address userAddress, uint8 membership) external view returns (bool,uint) {
        if(users[userAddress].membershipTime[membership] >= now){
            return (true,users[userAddress].membershipTime[membership]);
        }
        return (false,users[userAddress].membershipTime[membership]);
    }

    function getVaultAddress(address user) external view returns(address){
        return users[user].buzzVault;
    }

    function getGlobalIncome() external view returns(uint){
        return globalIncome;
    }

    
    function idAddress(uint id) external view returns(address){
        return idToAddress[id];
    }
}