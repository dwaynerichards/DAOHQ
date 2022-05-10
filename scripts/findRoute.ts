import { AlphaRouter, ChainId } from '@uniswap/smart-order-router';
import { Token, CurrencyAmount, BigNumber, Percent, TradeType, JSBI } from '@uniswap/sdk-core';
import dotenv from 'dotenv';
import { ethers } from 'hardhat';
import { abi as QuoterABI } from '@uniswap/v3-periphery/artifacts/contracts/lens/Quoter.sol/Quoter.json';
const success = dotenv.config();
success.error
  ? console.log('problem parsing .env', success.error)
  : console.log('.env parsed successfully');

async (DAOSwapContractAdress: string) => {
  const V3_SWAP_ROUTER_ADDRESS = '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45';
  const DAOSwapContract = DAOSwapContractAdress;
  const provider = new ethers.providers.EtherscanProvider(
    'mainnet',
    process.env.MAINNET_INFURA_KEY
  );

  const DOASwapContract = new ethers.Contract(DAOSwapContract, DAOSwapABI, signer);
  const router = new AlphaRouter({ chainId: 1, provider });
  const quoterContract = new ethers.Contract(quoterAddress, QuoterABI, provider);

  DOASwapContract.on(
    'GovTokenDeposit',
    async (amountDeposited, govTokenAddress, wethAddress, fee) => {
      const WETH = new Token(1, wethAddress, 18, 'WETH');
      const govToken = new Token(1, govTokenAddress, 18);

      /***
       * To get a quote for a swap,
       * we will call the Quoter contract's quoteExactInputSingle function,
       */
      /**
     *    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
     */
      const quotedAmountOut = await quoterContract.callStatic.quoteExactInputSingle(
        govTokenAddress,
        wethAddress,
        fee,
        amountDeposited,
        0
      );

      //=> We've returned the quoted amount for the trade, which would allow us to see if there is slippage
      //if we have access the the actual price
      const route = await router.route(amountDeposited, WETH, TradeType.EXACT_INPUT, {
        recipient: DOASwapContract.toString(),
        slippageTolerance: new Percent(0, 100), //Slippage set to 0
        deadline: Math.floor(Date.now() / 1000 + 1800),
      });

      console.log(`Quote Exact In: ${route!.quote.toFixed(2)}`);
      console.log(`Gas Adjusted Quote In: ${route!.quoteGasAdjusted.toFixed(2)}`);
      console.log(`Gas Used USD: ${route!.estimatedGasUsedUSD.toFixed(6)}`);

      const transaction = {
        data: route!.methodParameters!.calldata,
        to: V3_SWAP_ROUTER_ADDRESS,
        value: BigNumber.from(route!.methodParameters!.value),
        from: DAOSwapContract,
        gasPrice: BigNumber.from(route!.gasPriceWei),
      };
      await provider.sendTransaction(transaction);
    }
  );
};
//get quote, if quote is price you wanted, eecute trade
