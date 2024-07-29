// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract SolidLuxuryNFT is ERC1155, Ownable, ERC1155Burnable {
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => uint256) public totalSupply; // track total supply on each nft(id)
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // track all owners of each token ID
    mapping(uint256 => address[]) private _owners;
    mapping(uint256 => mapping(address => bool)) private _ownerExists;

    string public name;
    string public symbol;
    uint256 public constant MAX_SUPPLY_PER_ID = 10;

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialOwner
    ) ERC1155("") Ownable() {
        name = _name;
        symbol = _symbol;
        transferOwnership(_initialOwner);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        require( totalSupply[id] + amount <= MAX_SUPPLY_PER_ID, "Minting limit exceeded");

        totalSupply[id] += amount;
        _mint(account, id, amount, data);
        _addOwner(id, account, amount);
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function _addOwner(uint256 id, address owner, uint256 amount) internal {
        if (!_ownerExists[id][owner]) {
            _owners[id].push(owner);
            _ownerExists[id][owner] = true;
        }
         _balances[id][owner] += amount;
    }

    function _removeOwner(uint256 id, address owner) internal {
        if (_ownerExists[id][owner]) {
            _balances[id][owner] = 0;
            _ownerExists[id][owner] = false;
            // Remove owner from _owners list
            address[] storage owners = _owners[id];
            for (uint i = 0; i < owners.length; i++) {
                if (owners[i] == owner) {
                    owners[i] = owners[owners.length - 1];
                    owners.pop();
                    break;
                }
            }
        }
    }

    function _safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) internal virtual override {
        super._safeTransferFrom(from, to, id, value, data);

        if (from != address(0)) { // From address is not zero, meaning it's a transfer or burn
            _balances[id][from] -= value;
            if (_balances[id][from] == 0) {
                _removeOwner(id, from);
            }
        }

        if (to != address(0)) { // To address is not zero, meaning it's a transfer or mint
            if (!_ownerExists[id][to]) {
                _owners[id].push(to);
                _ownerExists[id][to] = true;
            }
            _balances[id][to] += value;
        }
    }
    
    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI[_id];
    }

    function balanceOf(address account, uint256 id)
        public
        view
        override
        returns (uint256)
    {
        return _balances[id][account];
    }

    function ownersOf(uint256 id) external view returns (address[] memory) {
        return _owners[id];
    }
}
