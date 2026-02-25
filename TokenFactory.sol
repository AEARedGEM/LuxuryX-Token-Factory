// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LuxuryX Token Factory
 * @dev Factory contract for deploying all 4 programmable token types
 * Fully optimized and compatible with all LuxuryX token standards
 */
contract LuxuryXTokenFactory is Ownable, ReentrancyGuard {
    using Clones for address;

    // ============ Constants ============
    
    bytes32 public constant ERC20_TOKEN = keccak256("ERC20_PROGRAMMABLE");
    bytes32 public constant ERC721_TOKEN = keccak256("ERC721_PROGRAMMABLE");
    bytes32 public constant ERC1155_TOKEN = keccak256("ERC1155_PROGRAMMABLE");
    bytes32 public constant ERC1400_TOKEN = keccak256("ERC1400_PROGRAMMABLE");

    // ============ Structs ============

    struct TokenInfo {
        bytes32 tokenType;
        string name;
        string symbol;
        address deployer;
        address owner;
        uint256 deploymentTime;
        address implementation;
        uint256 chainId;
    }

    // ERC20 Parameters - EXACT match with ERC20Programmable's InitParams
    struct ERC20InitParams {
        address initialOwner;
        string name;
        string symbol;
        uint256 initialSupply;
        uint8 decimals;
        uint256 maxSupply;
        uint16 buyTaxBps;
        uint16 sellTaxBps;
        uint16 maxTaxBps;
        address taxCollector;
        uint256 maxWalletAmount;
        uint256 maxTransactionAmount;
        uint256 minTransferDelay;
    }

    // ERC721 Parameters - EXACT match with ERC721Programmable's InitParams
    struct ERC721InitParams {
        address initialOwner;
        string name;
        string symbol;
        string baseURI;
        uint256 maxSupply;
        uint16 royaltyBps;
        uint16 maxRoyaltyBps;
        address royaltyRecipient;
        bool isSoulbound;
        uint256 mintPrice;
        bool onlyWhitelisted;
    }

    // ERC1155 Parameters - EXACT match with ERC1155Programmable's InitParams
    struct ERC1155InitParams {
        address initialOwner;
        string name;
        string symbol;
        string baseURI;
    }

    // ERC1400 Parameters - EXACT match with ERC1400Programmable's InitParams
    struct ERC1400InitParams {
        address initialOwner;
        string name;
        string symbol;
        uint8 decimals;
        uint256 initialSupply;
        string securityIdentifier_;      // Added underscore to match token
        uint256 issuanceDate_;           // Added underscore to match token
        uint256 maturityDate_;           // Added underscore to match token
        uint256 couponRate_;             // Added underscore to match token
        uint256 maxHolders_;             // Added underscore to match token
        uint256 maxHoldingPercentage_;   // Added underscore to match token
        uint256 minHoldingPeriod_;       // Added underscore to match token
    }

    // ============ State Variables ============

    // Implementation contracts
    address public erc20Implementation;
    address public erc721Implementation;
    address public erc1155Implementation;
    address public erc1400Implementation;

    // Token registry
    address[] public deployedTokens;
    mapping(address => TokenInfo) public tokenRegistry;
    mapping(address => bool) public isDeployedToken;
    mapping(bytes32 => address) public implementations;

    // Chain ID
    uint256 public immutable chainId;

    // ============ Events ============

    event ImplementationSet(bytes32 indexed tokenType, address indexed implementation);
    event TokenCreated(address indexed token, bytes32 indexed tokenType, address indexed owner);

    // ============ Constructor ============

    constructor(uint256 _chainId) Ownable(msg.sender) {
        chainId = _chainId;
    }

    // ============ Deployment Functions ============

    /**
     * @dev Deploy a new ERC20 programmable token
     * @param params Complete ERC20 initialization parameters
     * @return address of the newly deployed token
     */
    function deployERC20(ERC20InitParams calldata params) external nonReentrant returns (address) {
        require(erc20Implementation != address(0), "ERC20 not set");
        require(params.initialOwner != address(0), "Invalid owner");

        address token = erc20Implementation.clone();

        bytes memory initData = abi.encodeWithSignature(
            "initialize((address,string,string,uint256,uint8,uint256,uint16,uint16,uint16,address,uint256,uint256,uint256))",
            params
        );

        (bool success, ) = token.call(initData);
        require(success, "Init failed");

        _registerToken(token, ERC20_TOKEN, params.name, params.symbol, params.initialOwner);
        
        emit TokenCreated(token, ERC20_TOKEN, params.initialOwner);
        return token;
    }

    /**
     * @dev Deploy a new ERC721 programmable token
     * @param params Complete ERC721 initialization parameters
     * @return address of the newly deployed token
     */
    function deployERC721(ERC721InitParams calldata params) external nonReentrant returns (address) {
        require(erc721Implementation != address(0), "ERC721 not set");
        require(params.initialOwner != address(0), "Invalid owner");

        address token = erc721Implementation.clone();

        bytes memory initData = abi.encodeWithSignature(
            "initialize((address,string,string,string,uint256,uint16,uint16,address,bool,uint256,bool))",
            params
        );

        (bool success, ) = token.call(initData);
        require(success, "Init failed");

        _registerToken(token, ERC721_TOKEN, params.name, params.symbol, params.initialOwner);
        
        emit TokenCreated(token, ERC721_TOKEN, params.initialOwner);
        return token;
    }

    /**
     * @dev Deploy a new ERC1155 programmable token
     * @param params Complete ERC1155 initialization parameters
     * @return address of the newly deployed token
     */
    function deployERC1155(ERC1155InitParams calldata params) external nonReentrant returns (address) {
        require(erc1155Implementation != address(0), "ERC1155 not set");
        require(params.initialOwner != address(0), "Invalid owner");

        address token = erc1155Implementation.clone();

        bytes memory initData = abi.encodeWithSignature(
            "initialize((address,string,string,string))",
            params
        );

        (bool success, ) = token.call(initData);
        require(success, "Init failed");

        _registerToken(token, ERC1155_TOKEN, params.name, params.symbol, params.initialOwner);
        
        emit TokenCreated(token, ERC1155_TOKEN, params.initialOwner);
        return token;
    }

    /**
     * @dev Deploy a new ERC1400 programmable token
     * @param params Complete ERC1400 initialization parameters
     * @return address of the newly deployed token
     */
    function deployERC1400(ERC1400InitParams calldata params) external nonReentrant returns (address) {
        require(erc1400Implementation != address(0), "ERC1400 not set");
        require(params.initialOwner != address(0), "Invalid owner");

        address token = erc1400Implementation.clone();

        bytes memory initData = abi.encodeWithSignature(
            "initialize((address,string,string,uint8,uint256,string,uint256,uint256,uint256,uint256,uint256,uint256))",
            params
        );

        (bool success, ) = token.call(initData);
        require(success, "Init failed");

        _registerToken(token, ERC1400_TOKEN, params.name, params.symbol, params.initialOwner);
        
        emit TokenCreated(token, ERC1400_TOKEN, params.initialOwner);
        return token;
    }

    // ============ Internal Functions ============

    /**
     * @dev Register a deployed token in the factory registry
     */
    function _registerToken(
        address token,
        bytes32 tokenType,
        string memory name,
        string memory symbol,
        address owner
    ) internal {
        require(token != address(0), "Invalid token");
        require(!isDeployedToken[token], "Already registered");

        tokenRegistry[token] = TokenInfo({
            tokenType: tokenType,
            name: name,
            symbol: symbol,
            deployer: msg.sender,
            owner: owner,
            deploymentTime: block.timestamp,
            implementation: _getImplementation(tokenType),
            chainId: chainId
        });

        deployedTokens.push(token);
        isDeployedToken[token] = true;
    }

    /**
     * @dev Get implementation address by token type
     */
    function _getImplementation(bytes32 tokenType) internal view returns (address) {
        if (tokenType == ERC20_TOKEN) return erc20Implementation;
        if (tokenType == ERC721_TOKEN) return erc721Implementation;
        if (tokenType == ERC1155_TOKEN) return erc1155Implementation;
        if (tokenType == ERC1400_TOKEN) return erc1400Implementation;
        return address(0);
    }

    // ============ Admin Functions ============

    /**
     * @dev Set implementation contract for a token type
     * @param tokenType The type of token (ERC20_TOKEN, ERC721_TOKEN, etc.)
     * @param implementation Address of the implementation contract
     */
    function setImplementation(bytes32 tokenType, address implementation) external onlyOwner {
        require(implementation != address(0), "Invalid implementation");
        require(implementation.code.length > 0, "Not a contract");

        if (tokenType == ERC20_TOKEN) {
            erc20Implementation = implementation;
        } else if (tokenType == ERC721_TOKEN) {
            erc721Implementation = implementation;
        } else if (tokenType == ERC1155_TOKEN) {
            erc1155Implementation = implementation;
        } else if (tokenType == ERC1400_TOKEN) {
            erc1400Implementation = implementation;
        } else {
            revert("Unknown token type");
        }

        implementations[tokenType] = implementation;
        emit ImplementationSet(tokenType, implementation);
    }

    // ============ View Functions ============

    /**
     * @dev Get total number of deployed tokens
     */
    function getDeployedTokensCount() external view returns (uint256) {
        return deployedTokens.length;
    }

    /**
     * @dev Get deployed token address by index
     * @param index Index in the deployed tokens array
     */
    function getDeployedToken(uint256 index) external view returns (address) {
        require(index < deployedTokens.length, "Index out of bounds");
        return deployedTokens[index];
    }

    /**
     * @dev Get detailed information about a deployed token
     * @param token Address of the deployed token
     */
    function getTokenInfo(address token) external view returns (TokenInfo memory) {
        require(isDeployedToken[token], "Token not deployed");
        return tokenRegistry[token];
    }

    /**
     * @dev Get all tokens deployed by a specific address
     * @param deployer Address of the deployer
     */
    function getTokensByDeployer(address deployer) external view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < deployedTokens.length; i++) {
            if (tokenRegistry[deployedTokens[i]].deployer == deployer) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < deployedTokens.length; i++) {
            if (tokenRegistry[deployedTokens[i]].deployer == deployer) {
                result[index] = deployedTokens[i];
                index++;
            }
        }

        return result;
    }
}