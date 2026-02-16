// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract EIP712 {
    bytes32 private immutable _nameHash;
    bytes32 private immutable _versionHash;
    bytes32 private immutable _typeHash;

    constructor(string memory name, string memory version) {
        _nameHash = keccak256(bytes(name));
        _versionHash = keccak256(bytes(version));
        _typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        return keccak256(
            abi.encode(_typeHash, _nameHash, _versionHash, block.chainid, address(this))
        );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }
}
