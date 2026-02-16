"use client";

import { useAccount, useConnect, useDisconnect } from "wagmi";

export function WalletControls() {
  const { address, chain } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();

  if (!address) {
    return (
      <button className="btn" onClick={() => connect({ connector: connectors[0] })}>
        Connect Wallet
      </button>
    );
  }

  return (
    <div className="wallet-chip">
      <span>{address.slice(0, 6)}...{address.slice(-4)}</span>
      <span className="chain-pill">{chain?.name ?? "Unknown chain"}</span>
      <button className="btn btn-ghost" onClick={() => disconnect()}>
        Disconnect
      </button>
    </div>
  );
}
