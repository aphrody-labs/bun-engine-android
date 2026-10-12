#!/usr/bin/env bun

type Repo = {
  root: string;
  remote: string;
  branch: string;
  dirty: boolean;
  worktrees: number;
};

const apply = Bun.argv.includes("--apply");
const push = Bun.argv.includes("--push");
const root = Bun.argv.includes("--root")
  ? Bun.argv[Bun.argv.indexOf("--root") + 1]
  : "C:\\android";
const branch = `safe/consolidation-${new Date().toISOString().slice(0, 10)}`;

function run(args: string[], cwd = root) {
  const p = Bun.spawnSync(args, { cwd, stdout: "pipe", stderr: "pipe" });
  return {
    code: p.exitCode,
    stdout: new TextDecoder().decode(p.stdout).trim(),
    stderr: new TextDecoder().decode(p.stderr).trim(),
  };
}

function remoteKey(remote: string) {
  return remote
    .replace(/^git@github\.com:/, "https://github.com/")
    .replace(/\.git$/, "")
    .replace(/[^a-zA-Z0-9._-]+/g, "_");
}

const list = run(["fd", "--hidden", "--no-ignore", "--type", "d", "^\\.git$", "C:\\", "--exclude", "Windows", "--exclude", "Program Files\\WindowsApps"]);
const gitDirs = list.stdout.split(/\r?\n/).filter(Boolean);
const repos: Repo[] = [];
for (const gitDir of gitDirs) {
  const repo = gitDir.replace(/[\\/]$/, "").replace(/\\.git$/, "");
  const top = run(["git", "-C", repo, "rev-parse", "--show-toplevel"]);
  if (top.code !== 0 || !top.stdout) continue;
  const remote = run(["git", "-C", repo, "remote", "get-url", "origin"]).stdout;
  if (!remote) continue;
  const dirty = Boolean(run(["git", "-C", repo, "status", "--porcelain"]).stdout);
  const worktrees = (run(["git", "-C", repo, "worktree", "list", "--porcelain"]).stdout.match(/^worktree /gm) ?? []).length;
  if (!repos.some((x) => x.root.toLowerCase() === top.stdout.toLowerCase())) {
    repos.push({ root: top.stdout, remote, branch: run(["git", "-C", repo, "branch", "--show-current"]).stdout, dirty, worktrees });
  }
}

const report = { generatedAt: new Date().toISOString(), apply, push, branch, repos };
await Bun.write(`${root}\\target\\git-consolidation-report.json`, JSON.stringify(report, null, 2));
console.log(`Repos détectés: ${repos.length}`);
console.log(`Sales: ${repos.filter((x) => x.dirty || x.worktrees > 1).length}`);

if (!apply) {
  console.log("Mode audit בלבד: relancer avec --apply pour nettoyer/consolider.");
  process.exit(0);
}

const safe = repos.filter((x) => !x.dirty && x.worktrees <= 1);
const skipped = repos.filter((x) => !safe.includes(x));
console.log(`Repos traitables: ${safe.length}; ignorés: ${skipped.length}`);

for (const repo of safe) {
  const cleanup = ["node_modules", "target"];
  for (const name of cleanup) {
    const path = `${repo.root}\\${name}`;
    if (path.toLowerCase() === root.toLowerCase()) continue;
    const p = Bun.spawnSync(["cmd.exe", "/c", "if", "exist", path, "rmdir", "/s", "/q", path]);
    if (p.exitCode === 0) console.log(`Nettoyé: ${path}`);
  }
  run(["git", "-C", repo.root, "clean", "-fdX", "--", ".cargo-cache"], root);
}

const groups = new Map<string, Repo[]>();
for (const repo of safe) groups.set(remoteKey(repo.remote), [...(groups.get(remoteKey(repo.remote)) ?? []), repo]);
const out = `${root}\\consolidated`;
for (const [key, group] of groups) {
  const destination = `${out}\\${key}`;
  Bun.spawnSync(["cmd.exe", "/c", "if", "not", "exist", destination, "mkdir", destination]);
  await Bun.write(`${destination}\\README.md`, `Remote: ${group[0].remote}\nGenerated: ${new Date().toISOString()}\nRepositories: ${group.length}\n`);
}

run(["git", "-C", root, "checkout", "-b", branch]);
run(["git", "-C", root, "add", "scripts/git-consolidate.ts", "target/git-consolidation-report.json"]);
const commit = run(["git", "-C", root, "commit", "-m", "chore: add safe git consolidation workflow"]);
console.log(commit.stdout || commit.stderr);
if (push && commit.code === 0) {
  const pushed = run(["git", "-C", root, "push", "--set-upstream", "origin", branch]);
  console.log(pushed.stdout || pushed.stderr);
}
