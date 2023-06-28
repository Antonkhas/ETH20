// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    // сколько нулей после запятой будет у токена
    function decimals() external pure returns (uint256);

    //  сообщает, сколько токенов есть в обороте
    function totalSupply() external view returns (uint256);

    // принимает адрес контракта и сообщает, сколько есть токенов на этом аккаунте
    function balanceOf(address account) external view returns (uint256);

    // с помощью этой функции будем обмениваться токенами между аккаунтами
    function transfer(address to, uint256 amount) external returns (bool);

    // функция, чтобы проверить, можно ли со счета владельца на счет получателя какое то кол-во токенов
    function allowance(address owner, address spender) external view returns (uint256);

    // ^ дополнение к предыдущему. принимает адрес того, в чью пользу будут сприсаны токены и кол-во которое нужно списать
    function approve(address spender, uint256 amount) external returns (bool);

    // будет брать токены с sender и пересылать на resipient (функция которую могут вызывать другие смарт контракты, 
    // чтобы брать и пересылать на другой акк, если это разрешено
    function transferFrom( address from, address to, uint256 amount ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value
    );
}

contract ERC20 is IERC20 {
    uint256 totalTokens;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) public allowances;
    string public name = "GilToken";
    string public symbol = "GTK";

    constructor(uint256 initialSupply) {
        mint(initialSupply);
    }

    modifier enoughTokens(address _from, uint256 _amount) {
        require(balanceOf(_from) >= _amount, "Not enough tokens!");
        _;
    }

    function decimals() public pure returns (uint256) {
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) external enoughTokens(msg.sender, amount) returns (bool) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public enoughTokens(from, amount) returns (bool) {
        allowances[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(uint256 amount) public {
        balances[msg.sender] += amount;
        totalTokens += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) internal enoughTokens(msg.sender, amount) {
        balances[msg.sender] -= amount;
        totalTokens -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    fallback() external payable {}

    receive() external payable {}
}

contract TokenSell {
    IERC20 public token;
    address owner;
    address thisAddr = address(this);

    event Bougth(address indexed buyer, uint256 amount);
    event Sell(address indexed seller, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function balance() public view returns (uint256) {
        return thisAddr.balance;
    }

    function buy() external payable {
        require(msg.value >= _rate(), "Incorrect sum");
        uint256 tokensAvaliable = token.balanceOf(thisAddr);
        uint256 tokensToBuy = msg.value / _rate();
        require(tokensToBuy <= tokensAvaliable, "Not enough tokens!");
        token.transfer(msg.sender, tokensToBuy);
        emit Bougth(msg.sender, tokensToBuy);
    }

    function sell(uint256 amount) external {
        require(amount > 0, "Tokens must be greater then zero");
        uint256 allowance = token.allowance(msg.sender, thisAddr);
        require(allowance >= amount, "Wrong allowance");
        token.transferFrom(msg.sender, thisAddr, amount);
        payable(msg.sender).transfer(amount * _rate());
        emit Sell(msg.sender, amount);
    }

    function withdraw(uint amount) public onlyOwner{
        require(amount <= balance(), "Not enough funds!");
        payable(msg.sender).transfer(amount);
    }

    function _rate() private pure returns (uint256) {
        return 1 ether;
    }
}