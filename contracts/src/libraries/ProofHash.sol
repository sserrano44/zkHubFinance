// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Constants} from "./Constants.sol";

/// @notice Field-safe hash helpers used for settlement proof public inputs.
/// @dev This intentionally stays SNARK-field compatible (`< SNARK_SCALAR_FIELD`) so Groth16 verifiers can consume it.
library ProofHash {
    uint256 internal constant HASH_BETA = 1_315_423_911;
    uint256 internal constant HASH_C = 11_400_714_819_323_198_485;

    function toField(uint256 value) internal pure returns (uint256) {
        return value % Constants.SNARK_SCALAR_FIELD;
    }

    function hashPair(uint256 left, uint256 right) internal pure returns (uint256) {
        uint256 t = addmod(
            addmod(toField(left), mulmod(toField(right), HASH_BETA, Constants.SNARK_SCALAR_FIELD), Constants.SNARK_SCALAR_FIELD),
            HASH_C,
            Constants.SNARK_SCALAR_FIELD
        );

        // Quintic S-Box in the SNARK field: t^5 mod p.
        uint256 t2 = mulmod(t, t, Constants.SNARK_SCALAR_FIELD);
        uint256 t4 = mulmod(t2, t2, Constants.SNARK_SCALAR_FIELD);
        return mulmod(t4, t, Constants.SNARK_SCALAR_FIELD);
    }
}
