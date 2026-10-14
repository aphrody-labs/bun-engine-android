import { resolve } from "node:path";

const sdk = process.env.ANDROID_HOME ?? process.env.ANDROID_SDK_ROOT ?? resolve(import.meta.dir, "../../../sdk");
const exe = process.platform === "win32" ? ".exe" : "";
const javaHome = process.env.JAVA_HOME ?? resolve(import.meta.dir, "../../../tools/jdk");
const java = await Bun.file(resolve(javaHome, `bin/java${exe}`)).exists()
  ? resolve(javaHome, `bin/java${exe}`)
  : (Bun.which("java") ?? "java");
const environment = { ...process.env, JAVA_HOME: javaHome };
const adb = resolve(sdk, `platform-tools/adb${exe}`);
const android = resolve(sdk, `cmdline-tools/latest/bin/android${exe}`);
const [action = "doctor", ...args] = Bun.argv.slice(2);
const commands: Record<string, string[]> = {
  devices: [adb, "devices", "-l"],
  install: [adb, "install", "-r", ...args],
  logcat: [adb, "logcat", ...args],
  sdk: [android, "--no-metrics", `--sdk=${sdk}`, "sdk", ...args.length ? args : ["list"]],
  ndk: ["cargo", "ndk", ...args.length ? args : ["--help"]],
};
if (action === "doctor") {
  console.log(JSON.stringify({ bun: Bun.version, revision: Bun.revision, sdk, adb, android, androidRuntime: false }, null, 2));
  for (const command of [[adb, "version"], [java, "-version"], ["rustc", "--version"], ["cargo", "ndk", "--help"]]) {
    try {
      const child = Bun.spawn(command, { env: environment, stdout: "inherit", stderr: "inherit" });
      if (await child.exited) process.exitCode = 1;
    } catch (error) {
      console.error(String(error));
      process.exitCode = 1;
    }
  }
} else {
  if (!commands[action]) throw new Error(`Unknown command ${action}`);
  if (action === "install" && args.length !== 1) throw new Error("Usage: bun run android:install path/to/app.apk");
  const child = Bun.spawn(commands[action], { env: environment, stdout: "inherit", stderr: "inherit", stdin: "inherit" });
  process.exitCode = await child.exited;
}
