"use client";

import { createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { baseLocal, worldLocal } from "./chains";

export const wagmiConfig = createConfig({
  chains: [baseLocal, worldLocal],
  connectors: [injected()],
  transports: {
    [baseLocal.id]: http(baseLocal.rpcUrls.default.http[0]),
    [worldLocal.id]: http(worldLocal.rpcUrls.default.http[0])
  }
});
