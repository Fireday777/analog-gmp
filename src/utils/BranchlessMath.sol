// SPDX-License-Identifier: MIT
// Analog's Contracts (last updated v0.1.0) (src/utils/BranchlessMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Utilities for branchless operations, useful when a constant gas cost is required.
 */
library BranchlessMath {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return ternary(x < y, x, y);
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return ternary(x > y, x, y);
    }

    /**
     * @dev If `condition` is true returns `a`, otherwise returns `b`.
     */
    function ternary(bool condition, uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // branchless select, works because:
            // b ^ (a ^ b) == a
            // b ^ 0 == b
            //
            // This is better than doing `condition ? a : b` because:
            // - Consumes less gas
            // - Constant gas cost regardless the inputs
            // - Reduces the final bytecode size
            return b ^ ((a ^ b) * toUint(condition));
        }
    }

    /**
     * @dev If `condition` is true returns `a`, otherwise returns `b`.
     * see `BranchlessMath.ternary`
     */
    function ternary(bool condition, address a, address b) internal pure returns (address r) {
        assembly {
            r := xor(b, mul(xor(a, b), condition))
        }
    }

    /**
     * @dev If `condition` is true returns `a`, otherwise returns `b`.
     * see `BranchlessMath.ternary`
     */
    function ternary(bool condition, bytes32 a, bytes32 b) internal pure returns (bytes32 r) {
        assembly {
            r := xor(b, mul(xor(a, b), condition))
        }
    }

    /**
     * @dev If `condition` is true returns `a`, otherwise returns `b`.
     * see `BranchlessMath.ternary`
     */
    function ternaryU128(bool condition, uint128 a, uint128 b) internal pure returns (uint128 r) {
        assembly {
            r := xor(b, mul(xor(a, b), condition))
        }
    }

    /**
     * @dev If `condition` is true returns `a`, otherwise returns `b`.
     * see `BranchlessMath.ternary`
     */
    function ternaryU64(bool condition, uint64 a, uint64 b) internal pure returns (uint64 r) {
        assembly {
            r := xor(b, mul(xor(a, b), condition))
        }
    }

    /**
     * @dev If `condition` is true returns `a`, otherwise returns `b`.
     * see `BranchlessMath.ternary`
     */
    function ternaryU32(bool condition, uint32 a, uint32 b) internal pure returns (uint32 r) {
        assembly {
            r := xor(b, mul(xor(a, b), condition))
        }
    }

    /**
     * @dev If `condition` is true returns `a`, otherwise returns `b`.
     * see `BranchlessMath.ternary`
     */
    function ternaryU8(bool condition, uint8 a, uint8 b) internal pure returns (uint8 r) {
        assembly {
            r := xor(b, mul(xor(a, b), condition))
        }
    }

    /**
     * @dev If `condition` is true return `value`, otherwise return zero.
     * see `BranchlessMath.ternary`
     */
    function selectIf(bool condition, uint256 value) internal pure returns (uint256) {
        unchecked {
            return value * toUint(condition);
        }
    }

    /**
     * @dev Unsigned saturating addition, bounds to UINT256 MAX instead of overflowing.
     * equivalent to:
     * uint256 r = x + y;
     * return r >= x ? r : UINT256_MAX;
     */
    function saturatingAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            x = x + y;
            y = 0 - toUint(x < y);
            return x | y;
        }
    }

    /**
     * @dev Unsigned saturating subtraction, bounds to zero instead of overflowing.
     * equivalent to: x > y ? x - y : 0
     */
    function saturatingSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // equivalent to: a > b ? a - b : 0
            return (a - b) * toUint(a > b);
        }
    }

    /**
     * @dev Unsigned saturating multiplication, bounds to `2 ** 256 - 1` instead of overflowing.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a * b;
            bool success;
            assembly {
                // Only true when the multiplication doesn't overflow
                // (c / a == b) || (a == 0)
                success := or(eq(div(c, a), b), iszero(a))
            }
            return c | (toUint(success) - 1);
        }
    }

    /**
     * @dev Unsigned saturating division, bounds to UINT256 MAX instead of overflowing.
     */
    function saturatingDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Solidity reverts with a division by zero error, while using inline assembly division does
            // not revert, it returns zero.
            // Reference: https://github.com/ethereum/solidity/issues/15200
            r := div(x, y)
        }
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // The following calculation ensures accurate ceiling division without overflow.
            // Since a is non-zero, (a - 1) / b will not overflow.
            // The largest possible result occurs when (a - 1) / b is type(uint256).max,
            // but the largest value we can obtain is type(uint256).max - 1, which happens
            // when a = type(uint256).max and b = 1.
            return selectIf(a > 0, ((a - 1) / b + 1));
        }
    }

    /**
     * @dev Unsigned saturating left shift, bounds to UINT256 MAX instead of overflowing.
     */
    function saturatingShl(uint256 x, uint8 shift) internal pure returns (uint256 r) {
        assembly {
            // Detect overflow by checking if (x >> (256 - shift)) > 0
            r := gt(shr(sub(256, shift), x), 0)

            // Bounds to `type(uint256).max` if an overflow happened
            r := or(shl(shift, x), sub(0, r))
        }
    }

    /**
     * @dev Cast a boolean (false or true) to a uint256 (0 or 1) with no jump.
     */
    function toUint(bool b) internal pure returns (uint256 u) {
        /// @solidity memory-safe-assembly
        assembly {
            u := iszero(iszero(b))
        }
    }

    /**
     * @dev Cast an address to uint256
     */
    function toUint(address addr) internal pure returns (uint256) {
        return uint256(uint160(addr));
    }
}
