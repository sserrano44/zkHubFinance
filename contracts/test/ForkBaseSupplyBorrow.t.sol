// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestBase} from "./utils/TestBase.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {ITokenRegistry} from "../src/interfaces/ITokenRegistry.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

import {TokenRegistry} from "../src/hub/TokenRegistry.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";
import {KinkInterestRateModel} from "../src/hub/KinkInterestRateModel.sol";
import {HubMoneyMarket} from "../src/hub/HubMoneyMarket.sol";
import {HubRiskManager} from "../src/hub/HubRiskManager.sol";
import {IPriceOracle} from "../src/interfaces/IPriceOracle.sol";

interface IERC20Minimal {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IWETH9 {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ForkBaseSupplyBorrowTest is TestBase {
    // Canonical Base token contracts.
    address internal constant BASE_WETH = 0x4200000000000000000000000000000000000006;

    bool internal forkReady;

    address internal user;
    address internal usdc;

    TokenRegistry internal registry;
    MockOracle internal oracle;
    KinkInterestRateModel internal rateModel;
    HubMoneyMarket internal market;
    HubRiskManager internal risk;
    MockERC20 internal mockUsdc;

    function setUp() external {
        // Keep default unit-test runs stable: fork tests run only when explicitly enabled.
        if (!_isForkModeEnabled()) {
            forkReady = false;
            return;
        }

        string memory forkUrl = _readForkUrl();
        vm.createSelectFork(forkUrl);
        forkReady = true;

        user = vm.addr(0xA11CE);

        registry = new TokenRegistry(address(this));
        oracle = new MockOracle(address(this));

        rateModel = new KinkInterestRateModel(
            address(this),
            3_170_979_198_000_000_000,
            6_341_958_396_000_000_000,
            19_025_875_190_000_000_000,
            800_000_000_000_000_000_000_000_000,
            100_000_000_000_000_000_000_000_000
        );

        market = new HubMoneyMarket(address(this), registry, rateModel);
        risk = new HubRiskManager(address(this), registry, market, IPriceOracle(address(oracle)));

        // Keep WETH canonical from Base fork, but deploy borrow-side USDC mock for deterministic liquidity.
        mockUsdc = new MockERC20("USD Coin", "USDC", 6);
        usdc = address(mockUsdc);

        _configureAsset(BASE_WETH, 18, 7500, 8000, 10500, 100_000 ether, 80_000 ether);
        _configureAsset(usdc, 6, 7500, 8000, 10500, 100_000_000e6, 80_000_000e6);

        market.setRiskManager(address(risk));

        oracle.setPrice(BASE_WETH, 3_000e8);
        oracle.setPrice(usdc, 1e8);

        // Seed market liquidity directly for fork integration (USDC borrow leg).
        mockUsdc.mint(address(market), 5_000_000e6);
    }

    function test_fork_supplyEthAndBorrowUsdc() external {
        if (!forkReady) {
            return;
        }

        uint256 supplyEthAmount = 1 ether;
        uint256 borrowUsdcAmount = 500e6; // 500 USDC

        vm.deal(user, 10 ether);

        vm.startPrank(user);
        IWETH9(BASE_WETH).deposit{value: supplyEthAmount}();
        IWETH9(BASE_WETH).approve(address(market), type(uint256).max);
        market.supply(BASE_WETH, supplyEthAmount, user);

        uint256 supplied = market.getUserSupply(user, BASE_WETH);
        assertEq(supplied, supplyEthAmount, "weth collateral should be credited");

        uint256 usdcBefore = IERC20Minimal(usdc).balanceOf(user);
        market.borrow(usdc, borrowUsdcAmount, user);
        vm.stopPrank();

        uint256 usdcAfter = IERC20Minimal(usdc).balanceOf(user);
        assertEq(usdcAfter, usdcBefore + borrowUsdcAmount, "user should receive usdc borrow");

        uint256 debt = market.getUserDebt(user, usdc);
        assertEq(debt, borrowUsdcAmount, "debt accounting should match borrow amount");
    }

    function test_fork_supplyBorrowRepayAndWithdraw() external {
        if (!forkReady) {
            return;
        }

        uint256 supplyEthAmount = 2 ether;
        uint256 borrowUsdcAmount = 800e6; // 800 USDC

        vm.deal(user, 10 ether);

        vm.startPrank(user);
        IWETH9(BASE_WETH).deposit{value: supplyEthAmount}();
        IWETH9(BASE_WETH).approve(address(market), type(uint256).max);
        market.supply(BASE_WETH, supplyEthAmount, user);

        market.borrow(usdc, borrowUsdcAmount, user);
        IERC20Minimal(usdc).approve(address(market), type(uint256).max);

        uint256 repaid = market.repay(usdc, borrowUsdcAmount, user);
        assertEq(repaid, borrowUsdcAmount, "repay amount should match borrowed principal");

        uint256 debtAfterRepay = market.getUserDebt(user, usdc);
        assertEq(debtAfterRepay, 0, "debt should be zero after full repay");

        uint256 wethBeforeWithdraw = IWETH9(BASE_WETH).balanceOf(user);
        market.withdraw(BASE_WETH, supplyEthAmount, user);
        uint256 wethAfterWithdraw = IWETH9(BASE_WETH).balanceOf(user);
        vm.stopPrank();

        assertEq(
            wethAfterWithdraw,
            wethBeforeWithdraw + supplyEthAmount,
            "user should receive weth back after withdraw"
        );

        uint256 remainingSupply = market.getUserSupply(user, BASE_WETH);
        assertEq(remainingSupply, 0, "supply should be fully withdrawn");
    }

    function test_fork_liquidateEthPositionAfterPriceDrop() external {
        if (!forkReady) {
            return;
        }

        address liquidator = vm.addr(0xBEEF);
        uint256 supplyEthAmount = 1 ether;
        uint256 borrowUsdcAmount = 1_800e6; // 1,800 USDC debt
        uint256 liquidationRepayAmount = 600e6; // liquidator repays 600 USDC

        vm.deal(user, 10 ether);

        vm.startPrank(user);
        IWETH9(BASE_WETH).deposit{value: supplyEthAmount}();
        IWETH9(BASE_WETH).approve(address(market), type(uint256).max);
        market.supply(BASE_WETH, supplyEthAmount, user);
        market.borrow(usdc, borrowUsdcAmount, user);
        vm.stopPrank();

        // Force under-collateralization by reducing ETH oracle price.
        oracle.setPrice(BASE_WETH, 1_500e8);
        assertTrue(risk.isLiquidatable(user), "user should be liquidatable after price drop");

        mockUsdc.mint(liquidator, liquidationRepayAmount);

        uint256 debtBefore = market.getUserDebt(user, usdc);
        uint256 collateralBefore = market.getUserSupply(user, BASE_WETH);
        uint256 liquidatorWethBefore = IWETH9(BASE_WETH).balanceOf(liquidator);

        vm.startPrank(liquidator);
        IERC20Minimal(usdc).approve(address(market), type(uint256).max);
        market.liquidate(user, usdc, liquidationRepayAmount, BASE_WETH);
        vm.stopPrank();

        uint256 debtAfter = market.getUserDebt(user, usdc);
        uint256 collateralAfter = market.getUserSupply(user, BASE_WETH);
        uint256 liquidatorWethAfter = IWETH9(BASE_WETH).balanceOf(liquidator);

        assertEq(debtAfter, debtBefore - liquidationRepayAmount, "user debt should be reduced by repay amount");
        assertTrue(collateralAfter < collateralBefore, "user collateral should decrease after liquidation");
        assertTrue(liquidatorWethAfter > liquidatorWethBefore, "liquidator should receive seized weth");
    }

    function _configureAsset(
        address asset,
        uint8 decimals,
        uint256 ltvBps,
        uint256 liquidationThresholdBps,
        uint256 liquidationBonusBps,
        uint256 supplyCap,
        uint256 borrowCap
    ) internal {
        DataTypes.RiskParams memory riskParams = DataTypes.RiskParams({
            ltvBps: ltvBps,
            liquidationThresholdBps: liquidationThresholdBps,
            liquidationBonusBps: liquidationBonusBps,
            supplyCap: supplyCap,
            borrowCap: borrowCap
        });

        registry.registerToken(
            ITokenRegistry.TokenConfig({
                hubToken: asset,
                spokeToken: asset,
                decimals: decimals,
                risk: riskParams,
                bridgeAdapterId: keccak256("fork-base"),
                enabled: true
            })
        );

        risk.setRiskParams(asset, riskParams);
        market.initializeMarket(asset);
    }

    function _isForkModeEnabled() internal returns (bool) {
        try vm.envString("RUN_FORK_TESTS") returns (string memory value) {
            return keccak256(bytes(value)) == keccak256(bytes("1"));
        } catch {
            return false;
        }
    }

    function _readForkUrl() internal returns (string memory) {
        try vm.envString("BASE_FORK_URL") returns (string memory value) {
            return value;
        } catch {
            try vm.envString("BASE_RPC_URL") returns (string memory fallbackValue) {
                return fallbackValue;
            } catch {
                revert("Set BASE_FORK_URL or BASE_RPC_URL");
            }
        }
    }
}
