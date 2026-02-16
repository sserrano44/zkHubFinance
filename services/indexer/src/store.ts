import fs from "node:fs";
import path from "node:path";
import type { IntentLifecycle, IntentStatus } from "@hubris/sdk";

export type DepositState = {
  depositId: number;
  user: `0x${string}`;
  intentType: number;
  token: `0x${string}`;
  amount: string;
  status: "initiated" | "bridged" | "settled";
  metadata?: Record<string, unknown>;
  updatedAt: string;
};

type IndexerDb = {
  intents: Record<string, IntentLifecycle>;
  deposits: Record<string, DepositState>;
};

const DEFAULT_DB: IndexerDb = {
  intents: {},
  deposits: {}
};

export class JsonIndexerStore {
  private readonly filePath: string;
  private state: IndexerDb;

  constructor(filePath: string) {
    this.filePath = filePath;
    this.state = this.load();
  }

  upsertIntent(intent: IntentLifecycle): IntentLifecycle {
    const current = this.state.intents[intent.intentId];
    const merged: IntentLifecycle = {
      ...current,
      ...intent,
      metadata: {
        ...(current?.metadata ?? {}),
        ...(intent.metadata ?? {})
      },
      updatedAt: new Date().toISOString()
    };
    this.state.intents[intent.intentId] = merged;
    this.save();
    return merged;
  }

  updateIntentStatus(intentId: `0x${string}`, status: IntentStatus, patch?: Partial<IntentLifecycle>): IntentLifecycle | null {
    const current = this.state.intents[intentId];
    if (!current) return null;

    const updated: IntentLifecycle = {
      ...current,
      ...patch,
      status,
      metadata: {
        ...(current.metadata ?? {}),
        ...(patch?.metadata ?? {})
      },
      updatedAt: new Date().toISOString()
    };

    this.state.intents[intentId] = updated;
    this.save();
    return updated;
  }

  getIntent(intentId: string): IntentLifecycle | null {
    return this.state.intents[intentId] ?? null;
  }

  listIntents(user?: string): IntentLifecycle[] {
    return Object.values(this.state.intents)
      .filter((intent) => (user ? intent.user.toLowerCase() === user.toLowerCase() : true))
      .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  }

  upsertDeposit(dep: DepositState): DepositState {
    const current = this.state.deposits[String(dep.depositId)];
    const merged: DepositState = {
      ...current,
      ...dep,
      metadata: {
        ...(current?.metadata ?? {}),
        ...(dep.metadata ?? {})
      },
      updatedAt: new Date().toISOString()
    };
    this.state.deposits[String(dep.depositId)] = merged;
    this.save();
    return merged;
  }

  getDeposit(depositId: number): DepositState | null {
    return this.state.deposits[String(depositId)] ?? null;
  }

  private load(): IndexerDb {
    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    if (!fs.existsSync(this.filePath)) {
      fs.writeFileSync(this.filePath, JSON.stringify(DEFAULT_DB, null, 2));
      return structuredClone(DEFAULT_DB);
    }

    try {
      const raw = fs.readFileSync(this.filePath, "utf8");
      return { ...DEFAULT_DB, ...JSON.parse(raw) } as IndexerDb;
    } catch {
      return structuredClone(DEFAULT_DB);
    }
  }

  private save() {
    fs.writeFileSync(this.filePath, JSON.stringify(this.state, null, 2));
  }
}
