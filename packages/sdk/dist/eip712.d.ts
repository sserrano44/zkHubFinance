import type { Intent } from "./types";
export declare const intentTypes: {
    readonly Intent: readonly [{
        readonly name: "intentType";
        readonly type: "uint8";
    }, {
        readonly name: "user";
        readonly type: "address";
    }, {
        readonly name: "inputChainId";
        readonly type: "uint256";
    }, {
        readonly name: "outputChainId";
        readonly type: "uint256";
    }, {
        readonly name: "inputToken";
        readonly type: "address";
    }, {
        readonly name: "outputToken";
        readonly type: "address";
    }, {
        readonly name: "amount";
        readonly type: "uint256";
    }, {
        readonly name: "recipient";
        readonly type: "address";
    }, {
        readonly name: "maxRelayerFee";
        readonly type: "uint256";
    }, {
        readonly name: "nonce";
        readonly type: "uint256";
    }, {
        readonly name: "deadline";
        readonly type: "uint256";
    }];
};
export declare function getIntentTypedData(chainId: number, intentInbox: `0x${string}`, intent: Intent): {
    domain: {
        name: string;
        version: string;
        chainId: number;
        verifyingContract: `0x${string}`;
    };
    types: {
        readonly Intent: readonly [{
            readonly name: "intentType";
            readonly type: "uint8";
        }, {
            readonly name: "user";
            readonly type: "address";
        }, {
            readonly name: "inputChainId";
            readonly type: "uint256";
        }, {
            readonly name: "outputChainId";
            readonly type: "uint256";
        }, {
            readonly name: "inputToken";
            readonly type: "address";
        }, {
            readonly name: "outputToken";
            readonly type: "address";
        }, {
            readonly name: "amount";
            readonly type: "uint256";
        }, {
            readonly name: "recipient";
            readonly type: "address";
        }, {
            readonly name: "maxRelayerFee";
            readonly type: "uint256";
        }, {
            readonly name: "nonce";
            readonly type: "uint256";
        }, {
            readonly name: "deadline";
            readonly type: "uint256";
        }];
    };
    primaryType: "Intent";
    message: Intent;
};
export declare function rawIntentId(intent: Intent): `0x${string}`;
