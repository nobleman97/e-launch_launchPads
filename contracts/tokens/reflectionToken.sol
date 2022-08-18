
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router02.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 */
contract CregitechReflection is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTOTAL = 225 * 1e6 * 10**_DECIMALS;
    uint256 private _rTotal = (MAX - (MAX % _tTOTAL));
    uint256 private _tFeeTotal;

    /**
     * @dev Sets the values for {NAME} and {SYMBOL}, and {DECIMALS}
     *
     * All three of these values are constants: they can only be set once during
     * construction.
     */
    string private constant _NAME = "Cregitech Reflection";
    string private constant _SYMBOL = "CTR";
    uint8 private constant _DECIMALS = 18;
    
    /**
     * @dev Percentage of the static reflection fee.
     */        
    uint256 public _taxFee = 7;
    uint256 private _previousTaxFee = _taxFee;

    /**
     * @dev Percentage of the liquidity fee.
     */           
    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;

    /**
     * @dev Percentage of the auto burn fee.
     */   
    uint256 public _burnFee = 1;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD; 
    uint256 private _previousBurnFee = _burnFee;

    /**
     * @dev Percentage of the marketing, development, and team fee.
     */   
    uint256 public _developmentFee = 1;
    address public developmentWallet = 0xd8764B01dD3A77211a4437d1768F598Cb249E33B;
    uint256 private _previousDevelopmentFee = _developmentFee;

    IUniswapV2Router02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    /**
     * @dev The maximum transaction amount to minimize and break the impact of 
     * Whale actions.
     */       
    uint256 public _maxTxAmount = 1e6 * 10**_DECIMALS;
    
    /**
     * @dev The number of tokens sell, to add to the liquidity.
     */     
    uint256 public numTokensSellToAddToLiquidity = 1e5 * 10**_DECIMALS;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(uint256 tokenAmount, uint256 bnbAmount);
    event SwapAndLiquifyStatus(string status);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiquidity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _pancakeswapV2Router =
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a pancakeswap pair for this new token
        pancakeswapV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory()).createPair(
            address(this),
            _pancakeswapV2Router.WETH()
        );

        // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTOTAL);
    }

    /**
     * @dev See {IERC20-name}.
     */
    function name() external pure /**override*/ returns (string memory) {
        return _NAME;
    }

    /**
     * @dev See {IERC20-symbol}.
     */
    function symbol() external pure /**override*/ returns (string memory) {
        return _SYMBOL;
    }

    /**
     * @dev See {IERC20-decimals}.
     */
    function decimals() external pure /**override*/ returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external pure override returns (uint256) {
        return _tTOTAL;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as mitigation for
     * problems described in {IERC20-approve}.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as mitigation for
     * problems described in {IERC20-approve}.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

	function totalBurned() external view returns (uint256) {
		return balanceOf(BURN_ADDRESS);
	}

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTOTAL, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    
    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner() {
        require(
            account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 
            'We can not exclude Pancake router.'
        );
        require(
            !_isExcluded[account],
            "Account is already excluded"
        );
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
     * @dev limit excluded addresses list to avoid aborting functions with 
     * "out-of-gas" exception.
     */   
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(
        address sender, 
        address recipient, 
        uint256 tAmount
    ) private {
        (uint256 rAmount,
        uint256 rTransferAmount,
        uint256 rFee,
        uint256 tTransferAmount, 
        uint256 tFee, 
        uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    //to receive BNB from pancakeswapV2Router when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) =
            _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount) 
        private 
        view 
        returns (
            uint256, 
            uint256, 
            uint256
        ) 
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**
     * @dev limit excluded addresses list to avoid aborting functions with 
     * "out-of-gas" exception.
     */   
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTOTAL;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTOTAL);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTOTAL)) return (_rTotal, _tTOTAL);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
        _developmentFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = 7;
        _liquidityFee = 1;
        _burnFee = 1;
        _developmentFee = 1;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve` and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer} and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` / `from` cannot be the zero address.
     * - `recipient` / `to` cannot be the zero address.
     * - `sender` / `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,  // sender
        address to,  // recipient
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates and does not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half); // this breaks the BNB 

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to Pancakeswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    // @dev The swapAndLiquify function uses this for swap to BNB
    function swapTokensForBnb(uint256 tokenAmount) private returns (bool status){

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        // A reliable Oracle is to be introduced to avoid possible sandwich attacks.
        try pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        ) {
            emit SwapAndLiquifyStatus("Success");
            return true;
        }   
        catch {
            emit SwapAndLiquifyStatus("Failed");
            return false;
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add liquidity and get LP tokens to contract itself
        // A reliable Oracle is to be introduced to avoid possible sandwich attacks.
        pancakeswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
        emit LiquidityAdded(tokenAmount, bnbAmount);        
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            removeAllFee();
        }
        else{
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
        }
        
        //Calculate burn amount and development amount
        uint256 burnAmt = amount.mul(_burnFee).div(100);
        uint256 developmentAmt = amount.mul(_developmentFee).div(100);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, (amount.sub(burnAmt).sub(developmentAmt)));
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, (amount.sub(burnAmt).sub(developmentAmt)));
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, (amount.sub(burnAmt).sub(developmentAmt)));
        } else {
            _transferStandard(sender, recipient, (amount.sub(burnAmt).sub(developmentAmt)));
        }
        
        //Temporarily remove fees to transfer to burn address and development wallet
        _taxFee = 0;
        _liquidityFee = 0;

        //Send transfers to burn address and development wallet
        _transferStandard(sender, BURN_ADDRESS, burnAmt);
        _transferStandard(sender, developmentWallet, developmentAmt);

        //Restore tax and liquidity fees
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount, 
            uint256 rTransferAmount, 
            uint256 rFee, 
            uint256 tTransferAmount, 
            uint256 tFee, 
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount, 
            uint256 rTransferAmount, 
            uint256 rFee, 
            uint256 tTransferAmount, 
            uint256 tFee, 
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev The owner can withdraw BNB collected in the contract from 
     * `swapAndLiquify` or if someone sends BNB directly to the contract.
     * 
     * The swapAndLiquify function converts half of the contractTokenBalance 
     * tokens to BNB. For every swapAndLiquify function call, a small amount 
     * of BNB remains in the contract. This amount grows over time with the 
     * swapAndLiquify function being called throughout the life of the contract.
     * 
     * This amount will migrate via the Multi-Signature owner's wallet and
     * be used for charity purposes according to public consent. 
     */
    function migrateLeftoverBnb(
        address payable recipient, 
        uint256 amount
    ) external onlyOwner nonReentrant{
        require(recipient != address(0), 
            "BEP20: recipient cannot be the zero address");
        require(amount <= address(this).balance, 
            "BEP20: amount should not exceed the contract balance."
        );
        recipient.transfer(amount);
    }

    /**
     * @dev The owner can exclude specific accounts from Fees.
     */   
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

     /**
     * @dev The owner can include specific accounts in Fees.
     */           
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    /**
     * @dev Call this function to disable all Fees.
     * It will be necessary during the Presale stage.
     */
    function disableAllFees() external onlyOwner() {
        _taxFee = 0;
        _previousTaxFee = _taxFee;
        _liquidityFee = 0;
        _previousLiquidityFee = _liquidityFee;
        _burnFee = 0;
        _previousBurnFee = _burnFee;
        _developmentFee = 0;
        _previousDevelopmentFee = _developmentFee;
        emit SwapAndLiquifyEnabledUpdated(false);        
    }

    /**
     * @dev Call this function to enable Fees after finalizing the Presale.
     */
    function enableAllFees() external onlyOwner() {
        _taxFee = 7;
        _previousTaxFee = _taxFee;
        _liquidityFee = 1;
        _previousLiquidityFee = _liquidityFee;
        _burnFee = 1;
        _previousBurnFee = _burnFee;
        _developmentFee = 1;
        _previousDevelopmentFee = _developmentFee;
        emit SwapAndLiquifyEnabledUpdated(false);
    }

    /**
     * @dev Call this function to enable Swap and Liquify.
     */  
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    /**
     * @dev This function can be used to change burnFee to zero percentage upon a 
     * certain amount of tokens are burned.
     */
    function stopAutoBurn() external onlyOwner() {
        _burnFee = 0;
    }
    
    /**
     * @dev Update the amount of "numTokensSellToAddToLiquidity".
     * 
     * Requirements:
     *
     * The new amount must be less than or equal to one million.
     */   
    function setNumTokensSellToAddToLiquidity(uint256 newAmount) external onlyOwner() {
        require(newAmount <= 1e6 * 10**_DECIMALS, 
            "BEP20: the amount must be lesser than or equal to one million."
        );      
        numTokensSellToAddToLiquidity = newAmount;
    }

    /**
     * @dev Call this function to change the Max transaction amount.
     * Adjusting of 'maxTxAmount' will be required during the initial stage.
     * 
     * Requirements:
     *
     * The new amount must be greater than or equal to one million to avoid misuse 
     * of the function.
     */      
    function setMaxTxAmount(uint256 newAmount) external onlyOwner() {
        require(newAmount >= 1e6 * 10**_DECIMALS, 
            "BEP20: the amount must be greater than or equal to one million."
        );        
        _maxTxAmount = newAmount;
    }

    /**
     * @dev Call this function if required to set a different Development 
     * wallet address.
     *
     * Requirements:
     *
     * The development wallet cannot be the zero address.
     */
    function setDevelopmentWallet(address newWallet) external onlyOwner() {
        require(newWallet != address(0), 
            "BEP20: the new wallet cannot be the zero address."
        );
        developmentWallet = newWallet;
    }
    
    /**
     * @dev Update the Router address if Pancakeswap upgrades to a 
     * newer version.
     */
    function setRouterAddress(address newRouter) external onlyOwner {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(
            address(this), _newRouter.WETH()
        );
        //checks if pair already exists
        if (get_pair == address(0)) {
            pancakeswapV2Pair = IUniswapV2Factory(_newRouter.factory()).createPair(
                address(this), _newRouter.WETH()
            );
        }
        else {
            pancakeswapV2Pair = get_pair;
        }
            pancakeswapV2Router = _newRouter;
    }    
}