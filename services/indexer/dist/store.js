import fs from "node:fs";
import path from "node:path";
const DEFAULT_DB = {
    intents: {},
    deposits: {}
};
export class JsonIndexerStore {
    filePath;
    state;
    constructor(filePath) {
        this.filePath = filePath;
        this.state = this.load();
    }
    upsertIntent(intent) {
        const current = this.state.intents[intent.intentId];
        const merged = {
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
    updateIntentStatus(intentId, status, patch) {
        const current = this.state.intents[intentId];
        if (!current)
            return null;
        const updated = {
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
    getIntent(intentId) {
        return this.state.intents[intentId] ?? null;
    }
    listIntents(user) {
        return Object.values(this.state.intents)
            .filter((intent) => (user ? intent.user.toLowerCase() === user.toLowerCase() : true))
            .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
    }
    upsertDeposit(dep) {
        const current = this.state.deposits[String(dep.depositId)];
        const merged = {
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
    getDeposit(depositId) {
        return this.state.deposits[String(depositId)] ?? null;
    }
    load() {
        fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
        if (!fs.existsSync(this.filePath)) {
            fs.writeFileSync(this.filePath, JSON.stringify(DEFAULT_DB, null, 2));
            return structuredClone(DEFAULT_DB);
        }
        try {
            const raw = fs.readFileSync(this.filePath, "utf8");
            return { ...DEFAULT_DB, ...JSON.parse(raw) };
        }
        catch {
            return structuredClone(DEFAULT_DB);
        }
    }
    save() {
        fs.writeFileSync(this.filePath, JSON.stringify(this.state, null, 2));
    }
}
//# sourceMappingURL=store.js.map