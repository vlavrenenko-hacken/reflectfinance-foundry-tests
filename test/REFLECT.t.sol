// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/REFLECT.sol";
import "forge-std/console.sol";

contract ReflectTest is Test {
    REFLECT reflect;
    address private constant OWNER = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;

    // Users
    address bob = address(0x1);
    address marty = address(0x2);
    // OWNER = 0xb4c79dab8f259c7aee6e5b2aa729821864227e84

    function setUp() public {
        reflect = new REFLECT();
    }

    function testState() public {
        string memory name = reflect.name();
        string memory symbol = reflect.symbol();
        uint8 decimals = reflect.decimals();
        uint256 totalSupply = reflect.totalSupply();
        uint256 totalFees = reflect.totalFees();

        assertEq(name, "reflect.finance");
        assertEq(symbol, "RFI");
        assertEq(decimals, 9);
        assertEq(totalSupply, 10e15);
        assertEq(totalFees, 0);
    }

    function testTransferFromExcluded() public {
        // MATH BEFORE:
        // rOwned[sender] = rTotal = 115792089237316195423570985008687907853269984665640564039457580000000000000000 in reflections or 10,000,000,000,000,000 in tokens
       
        // tAmount = 2 * 10^9
        // tFee = tAmount / 100 = 2 * 10^7
        // tTransferAmount = 2 * 10^9 - 2 * 10^7 = 1980000000
        // rate = rTotal / tTotal = 115792089237316195423570985008687907853269984665640564039457580000000000000000 / 10e15 = 11579208923731619542357098500868790785326998466564056403945758
        // rAmount = tAmount * rate = 2 * 10^9 * 11579208923731619542357098500868790785326998466564056403945758 = 23158417847463239084714197001737581570653996933128112807891516000000000
        // rFee = tFee * rate = rAmount/100 = 231584178474632390847141970017375815706539969331281128078915160000000
        // rTransferAmount = rAmount - rFee = 23158417847463239084714197001737581570653996933128112807891516000000000 - 231584178474632390847141970017375815706539969331281128078915160000000 
        // = 22,926,833,668,988,606,693,867,055,031,720,205,754,947,456,963,796,831,679,812,600,840,000,000
        uint tAmount = 2e9;
        uint tFee = tAmount / 100; // 20000000
        uint rAmount = 23158417847463239084714197001737581570653996933128112807891516000000000;
        uint rate = 11579208923731619542357098500868790785326998466564056403945758; // since rSupply < _rTotal/_tTotal => _getCurrentSupply returns _rTotal and _tTotal

        reflect.excludeAccount(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84); // OWNER
        bool isExcluded = reflect.isExcluded(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        assertEq(isExcluded, true);
        reflect.transfer(bob, tAmount);

        // MATH AFTER:
        // 1) _rTotal = _rTotal - _rFee = 115792089237316195423570985008687907853269984665640564039457580000000000000000 
        // - 231584178474632390847141970017375815706539969331281128078915160000000 =
        // = 115792089005732016948938594161545937835894168959100594708176451921084840000000
        // 2) _tTotal = 10e15;
        // 3) _tFeeTotal = 20000000
        // 4) rOwned[sender] = rOwned[sender] - rAmount =  115792089237316195423570985008687907853269984665640564039457580000000000000000 - 23158417847463239084714197001737581570653996933128112807891516000000000 = 
        // = 115792066078898347960331900294490906115688414011643630911344772108484000000000                                                
        // 5) tOwned[sender] = tOwned[sender] - tAmount = 10e15 - 2e9 = 9999998000000000
        // 6) rOwned[recipient] = rOwned[recipient] + rAmount = 22926833668988606693867055031720205754947456963796831679812600840000000
        // 7) tOwned[recipient] = 0
        // 8) rate1 = (_rTotal - rOwned[excluded]) /(_tTotal - tOwned[excluded]) =  (115792089005732016948938594161545937835894168959100594708176451921084840000000-115792066078898347960331900294490906115688414011643630911344772108484000000000) / 10e15 - 9999998000000000 = 22,926,833,668,988,606,693,867,055,031,720,205,754,947,456,963,796,831,679,812,600,840,000,000 / 2000000000 
        // = 11,463,416,834,494,303,346,933,527,515,860,102,877,473,728,481,898,415,839,906,300
        uint rTotal = reflect._rTotal();
        uint tTotal = reflect._tTotal();
        uint tFeeTotal = reflect._tFeeTotal();
        uint rOwnedSender = reflect._rOwned(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        uint tOwnedSender = reflect._tOwned(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);

        uint rOwnedRecipient = reflect._rOwned(bob);
        uint tOwnedRecipient = reflect._tOwned(bob);
        uint rate1 = reflect._getRate();

        assertEq(rTotal, 115792089005732016948938594161545937835894168959100594708176451921084840000000);
        assertEq(tTotal, 10e15);
        assertEq(tFeeTotal, 20000000);
        assertEq(rOwnedSender, 115792066078898347960331900294490906115688414011643630911344772108484000000000); 
        assertEq(tOwnedSender, 9999998000000000);
        assertEq(rOwnedRecipient, 22926833668988606693867055031720205754947456963796831679812600840000000);
        assertEq(tOwnedRecipient, 0);
        assertEq(rate1, 11463416834494303346933527515860102877473728481898415839906300);
    }

    function testTransferStandard() public {
        // MATH BEFORE:
        // rOwned[sender] = rTotal = 115792089237316195423570985008687907853269984665640564039457580000000000000000 in reflections or 10,000,000,000,000,000 in tokens
       
        // tAmount = 2 * 10^9
        // tFee = tAmount / 100 = 2 * 10^7
        // tTransferAmount = 2 * 10^9 - 2 * 10^7 = 1980000000
        // rate = rTotal / tTotal = 115792089237316195423570985008687907853269984665640564039457580000000000000000 / 10e15 = 11579208923731619542357098500868790785326998466564056403945758
        // rAmount = tAmount * rate = 2 * 10^9 * 11579208923731619542357098500868790785326998466564056403945758 = 23158417847463239084714197001737581570653996933128112807891516000000000
        // rFee = tFee * rate = rAmount/100 = 231584178474632390847141970017375815706539969331281128078915160000000
        // rTransferAmount = rAmount - rFee = 23158417847463239084714197001737581570653996933128112807891516000000000 - 231584178474632390847141970017375815706539969331281128078915160000000 
        // = 22,926,833,668,988,606,693,867,055,031,720,205,754,947,456,963,796,831,679,812,600,840,000,000
        
        uint tAmount = 2e9;
        uint tFee = tAmount / 100; // 20000000
        uint rAmount = 22926833668988606693867055031720205754947456963796831679812600840000000;
        uint rate = 11579208923731619542357098500868790785326998466564056403945758;
        reflect.transfer(bob, tAmount);
        
        // MATH AFTER:
        // 1) _rTotal = _rTotal - _rFee = 115792089237316195423570985008687907853269984665640564039457580000000000000000 - 231584178474632390847141970017375815706539969331281128078915160000000 = 115792089005732016948938594161545937835894168959100594708176451921084840000000
        // 2) _tTotal = 10e15
        // 3) _tFeeTotal = 20000000
        // 4) rOwned[sender] = rOwned[sender] - rAmount = 115792089237316195423570985008687907853269984665640564039457580000000000000000 - 23158417847463239084714197001737581570653996933128112807891516000000000 = 115792066078898347960331900294490906115688414011643630911344772108484000000000
        // 5) tOwned[sender] = 0
        // 6) rOwned[recipient] = rOwned[recipient] + rAmount = 22926833668988606693867055031720205754947456963796831679812600840000000
        // 7) tOwned[recipient] = 0
        // 8) rate1 = 115792089005732016948938594161545937835894168959100594708176451921084840000000 / 10e15 = 11579208900573201694893859416154593783589416895910059470817645

        uint rTotal = reflect._rTotal();
        uint tTotal = reflect._tTotal();
        uint tFeeTotal = reflect._tFeeTotal();
        uint rOwnedSender = reflect._rOwned(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        uint tOwnedSender = reflect._tOwned(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);

        uint rOwnedRecipient = reflect._rOwned(bob);
        uint tOwnedRecipient = reflect._tOwned(bob);
        uint rate1 = reflect._getRate();

        
        assertEq(rTotal, 115792089005732016948938594161545937835894168959100594708176451921084840000000);
        assertEq(tTotal, 10000000000000000);
        assertEq(tFeeTotal, 20000000);
        assertEq(rOwnedSender, 115792066078898347960331900294490906115688414011643630911344772108484000000000);
        assertEq(tOwnedSender, 0);
        assertEq(rOwnedRecipient, 22926833668988606693867055031720205754947456963796831679812600840000000);
        assertEq(tOwnedRecipient, 0);
        assertEq(rate1, 11579208900573201694893859416154593783589416895910059470817645);
    }

    function testIsExcluded() public {
        reflect.excludeAccount(OWNER); // OWNER
        bool isExcluded = reflect.isExcluded(OWNER);
        assertEq(isExcluded, true);
    }

    function testTokenFromReflection() public {
        // MATH
        // tAmount = 2 * 10^9
        // rate = rTotal / tTotal = 115792089237316195423570985008687907853269984665640564039457580000000000000000 / 10e15 = 11579208923731619542357098500868790785326998466564056403945758
        // rAmount = tAmount * rate = 2 * 10^9 * 11579208923731619542357098500868790785326998466564056403945758 = 23158417847463239084714197001737581570653996933128112807891516000000000
        uint256 tAmount = 2e9;
        uint256 rAmount = 23158417847463239084714197001737581570653996933128112807891516000000000;
        uint tokenFromReflection = reflect.tokenFromReflection(rAmount);
        assertEq(tokenFromReflection, tAmount);
    }

    function testReflectionFromTokenWithoutFee() public {
        // MATH
        // tAmount = 2 * 10^9
        // rate = rTotal / tTotal = 115792089237316195423570985008687907853269984665640564039457580000000000000000 / 10e15 = 11579208923731619542357098500868790785326998466564056403945758
        // rAmount = tAmount * rate = 2 * 10^9 * 11579208923731619542357098500868790785326998466564056403945758 = 23158417847463239084714197001737581570653996933128112807891516000000000
        uint256 tAmount = 2e9;
        uint256 rAmount = 23158417847463239084714197001737581570653996933128112807891516000000000;
        bool deductTransferFee = false;
        uint reflectionFromToken = reflect.reflectionFromToken(tAmount, deductTransferFee);
        assertEq(reflectionFromToken, rAmount);
    }
    
    function testReflectionFromTokenWithFee() public {
        // MATH
        // tAmount = 2 * 10^9
        // tFee = tAmount / 100 = 2 * 10^7
        // rate = rTotal / tTotal = 115792089237316195423570985008687907853269984665640564039457580000000000000000 / 10e15 = 11579208923731619542357098500868790785326998466564056403945758
        // rAmount = tAmount * rate = 2 * 10^9 * 11579208923731619542357098500868790785326998466564056403945758 = 23158417847463239084714197001737581570653996933128112807891516000000000
        // rFee = tFee * rate = rAmount/100 = 231584178474632390847141970017375815706539969331281128078915160000000
        // rTransferAmount = rAmount - rFee = 23158417847463239084714197001737581570653996933128112807891516000000000 - 231584178474632390847141970017375815706539969331281128078915160000000 
        // = 22,926,833,668,988,606,693,867,055,031,720,205,754,947,456,963,796,831,679,812,600,840,000,000
        uint256 tAmount = 2e9;
        uint256 rTransferAmount = 22926833668988606693867055031720205754947456963796831679812600840000000;
        bool deductTransferFee = true;
        uint reflectionFromToken = reflect.reflectionFromToken(tAmount, deductTransferFee);
        assertEq(reflectionFromToken, rTransferAmount);
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    function testEmitsApproval() public {
        vm.expectEmit(true, true, false, true, address(reflect));
        emit Approval(OWNER, bob, 10);
        reflect.approve(bob, 10);
    }
    function testCannotExcludeAlreadyExcludedAccount() public {
        reflect.excludeAccount(OWNER);
        vm.expectRevert(abi.encodePacked("Account is already excluded"));
        reflect.excludeAccount(OWNER);
    }
}
