#!/usr/bin/env node
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawn, spawnSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");

main().catch((error) => {
  console.error("[e2e-circuit:one-shot] failed:", error.message);
  process.exit(1);
});

async function main() {
  const prepared = runPrepareJson();
  const env = { ...process.env, ...prepared };

  console.log("[e2e-circuit:one-shot] prepared circuit env; starting E2E run");
  await run("node", ["./scripts/e2e-fork-circuit.mjs"], {
    cwd: rootDir,
    env
  });
}

function runPrepareJson() {
  const result = spawnSync(
    "node",
    ["./scripts/e2e-fork-circuit-prepare.mjs", "--json"],
    {
      cwd: rootDir,
      encoding: "utf8",
      stdio: ["inherit", "pipe", "pipe"]
    }
  );

  if (result.stderr) {
    process.stderr.write(result.stderr);
  }

  if (result.error) {
    throw new Error(`prepare step failed: ${result.error.message}`);
  }
  if (result.status !== 0) {
    throw new Error(
      `prepare step failed with exit code ${result.status}.\n${result.stdout ?? ""}`
    );
  }

  const stdout = (result.stdout ?? "").trim();
  if (!stdout) {
    throw new Error("prepare step returned empty output (expected JSON env payload).");
  }

  try {
    const parsed = JSON.parse(stdout);
    if (typeof parsed !== "object" || parsed === null) {
      throw new Error("JSON output was not an object.");
    }
    return parsed;
  } catch (error) {
    throw new Error(
      `could not parse prepare JSON output.\nstdout:\n${stdout}\nparse error: ${error.message}`
    );
  }
}

async function run(cmd, args, options) {
  await new Promise((resolve, reject) => {
    const child = spawn(cmd, args, {
      cwd: options.cwd,
      env: options.env ?? process.env,
      stdio: "inherit"
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve(undefined);
      else reject(new Error(`${cmd} ${args.join(" ")} failed with exit code ${code}`));
    });
  });
}
