// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.13;
pragma abicoder v2;
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

/***
When trading from a smart contract, the most important thing to keep 
in mind is that access to an external 
price source is required. Without this, trades can be 
frontrun for considerable loss. */
contract DAOSwapEx {
    /***
    1. Take input token address from user and chain ID ( Binance or Ethereum)
Transfer token to contract address
2. Check if enough liquidity is added on PancakeSwap or Uniswap for no Slippage

3.  If added, try to swap it with native currency or Stable coin */

/**
Uniswap  eth/govToken 
Call contract and see if there is enough token to swap
With no slippage, oracle patter?

If so, 
Approve uniswap for the tokens I now possess
swap for stable token/eth
 */

    address public immutable DAO_Token;
    address public immutable WETH;
    address public immutable StableCoin;
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    ISwapRouter public immutable swapRouter;

    constructor(
        ISwapRouter _swapRouter,
        address _daoToken,
        address _eth,
        address _stableCoin
    ) {
        swapRouter = _swapRouter;
        DAO_Token = _daoToken;
        WETH = _eth;
        StableCoin = _stableCoin;
    }

event GovTokenDeposit(uint amountDeposited, address govTokenAddess, address wethaddress, uint fee);
    function swapInputSingle(uint256 _daoTokensIn) external returns (uint256 amountOut) {
        //msgSender must approve (this) contract to withdraw tokens from their account
        TransferHelper.safeTransferFrom(DAO_Token, msg.sender, address(this), _daoTokensIn);
        //approve swapRouter to trade DAO token
        TransferHelper.safeApprove(DAO_Token, address(swapRouter), _daoTokensIn);
        uint256 minimumAmountOut = _getAmountOutMin(_daoTokensIn);
        // We set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: DAO_Token,
            tokenOut: WETH,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minimumAmountOut,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInput(params);
    }

    function multiTokenSwap(uint256 _daoTokensIn) external returns (amountOut) {
        //again msg.sender musy appove token amount to (this) contract

        TransferHelper.safeTransfer(DAO_Token, address(this), _daoTokensId);
        TransferHelper.safeApprove(DAO_Token, address(swapRouter), _doaTokensIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut)
            // where tokenIn/tokenOut parameter is the shared token across the pools.
            path: abi.encodePacked(DAO_Token, poolFee, WETH, poolFee, StableCoin),
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minimumAmountOut
        });

        amountOut = swapRouter.exactInput(params);
    }

    function _getAmountOutMin(uint256 _daoTokensIn) view returns (uint256) {
        //minAmount is product of offcahin rate
        //In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        //check pools, getRateFromOracle
        uint256 poolWeiPerToken = _getPoolRate(DAO_Token, WETH);
        uint256 oracleWeiPerToken = _getOracleRate(DAO_Token, WETH);
        uint256 oracleTokenAmount = poolWeiPerToken * _daoTokensIn;
        uint256 poolTokenAmount = poolWeiPerToken * _daoTokensIn;
        require(oracleTokenAmount >= poolTokenAmount, "slippage Occurred");
        return poolTokenAmount;
    }

    function _getPoolRate(
        address tokenA,
        address tokenB,
        uint256 tokenAmount
    ) internal view returns (uint256) {}

    function _getOracleRate(
        address tokenA,
        address tokenB,
        uint256 tokenAmount
    ) internal view returns (uint256) {}
}

    function swapWithAlphaRouter(uint _govTokenIn) external {
    
        TransferHelper.safeTransfer(DAO_Token, address(this), _govTokenIn);
       emit GovTokenDeposit(_govTokenIn, DAO_Token, poolFee);
}
