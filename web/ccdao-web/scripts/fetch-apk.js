#!/usr/bin/env node

/**
 * APK 更新脚本
 * 从 GitLab 获取最新版本 APK，解压到 public 目录供网站下载
 */

const axios = require("axios");
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

// 读取 .env 文件
const envPath = path.join(__dirname, "..", ".env");
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, "utf-8");
  envContent.split("\n").forEach((line) => {
    if (line.startsWith("#") || !line.trim()) return;
    const match = line.match(/^([^=]+)=(.*)$/);
    if (match) {
      const key = match[1].trim();
      const value = match[2].trim().replace(/^["']|["']$/g, "");
      if (!process.env[key]) {
        process.env[key] = value;
      }
    }
  });
}

// 配置
const GITLAB_URL = process.env.GITLAB_URL || "http://192.168.66.246";
const GITLAB_TOKEN = process.env.GITLAB_TOKEN;
const PROJECT_ID = "chtian%2Fwodecards";
const BRANCH = "apk";
const APK_DIR = "apk/ccdao/release";
const LOCAL_APK_DIR = path.join(__dirname, "..", "public");
const VERSION_FILE = path.join(LOCAL_APK_DIR, "version.json");

if (!GITLAB_TOKEN) {
  console.error("❌ 请设置 GITLAB_TOKEN（在 .env 文件中）");
  process.exit(1);
}

const gitlab = axios.create({
  baseURL: `${GITLAB_URL}/api/v4`,
  headers: { "PRIVATE-TOKEN": GITLAB_TOKEN },
  timeout: 60000,
});

// 获取远程版本列表
async function getRemoteVersions() {
  const response = await gitlab.get(`/projects/${PROJECT_ID}/repository/tree`, {
    params: { path: APK_DIR, ref: BRANCH, per_page: 100 },
  });
  return response.data
    .filter((item) => item.type === "tree")
    .map((item) => item.name)
    .sort((a, b) => {
      const va = a.split(".").map(Number);
      const vb = b.split(".").map(Number);
      for (let i = 0; i < 3; i++) {
        if (va[i] !== vb[i]) return vb[i] - va[i];
      }
      return 0;
    });
}

// 获取版本目录下的文件列表
async function getVersionFiles(version) {
  const response = await gitlab.get(`/projects/${PROJECT_ID}/repository/tree`, {
    params: { path: `${APK_DIR}/${version}`, ref: BRANCH },
  });
  return response.data.map((item) => item.name);
}

// 下载文件
async function downloadFile(filePath, destPath) {
  const response = await gitlab.get(`/projects/${PROJECT_ID}/repository/files/${encodeURIComponent(filePath)}/raw`, {
    params: { ref: BRANCH },
    responseType: "arraybuffer",
  });
  fs.writeFileSync(destPath, response.data);
  console.log(`✅ 已下载: ${path.basename(destPath)}`);
}

// 递归清理 macOS 垃圾文件
function cleanMacOSArtifacts(dir) {
  // 清理 __MACOSX
  const macosx = path.join(dir, "__MACOSX");
  if (fs.existsSync(macosx)) {
    fs.rmSync(macosx, { recursive: true, force: true });
    console.log("🗑️  已清理 __MACOSX");
  }
  // 清理隐藏文件
  const entries = fs.readdirSync(dir);
  for (const entry of entries) {
    if (entry.startsWith(".")) {
      fs.rmSync(path.join(dir, entry), { recursive: true, force: true });
    }
  }
}

// 解压压缩包，将内容直接放到 destDir
function extractAndFlatten(archivePath, destDir) {
  const tempDir = path.join(destDir, ".temp_extract");
  if (fs.existsSync(tempDir)) {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
  fs.mkdirSync(tempDir, { recursive: true });

  const ext = path.extname(archivePath);
  if (ext === ".zip") {
    execSync(`unzip -o "${archivePath}" -d "${tempDir}"`, { stdio: "pipe" });
  } else if (archivePath.endsWith(".tar.gz") || archivePath.endsWith(".tgz")) {
    execSync(`tar -xzf "${archivePath}" -C "${tempDir}"`, { stdio: "pipe" });
  } else {
    throw new Error(`不支持的压缩格式: ${ext}`);
  }

  // 清理 macOS 垃圾
  cleanMacOSArtifacts(tempDir);

  // 找到实际内容：如果只有一个子目录，取其内容
  let sourceDir = tempDir;
  const dirs = fs
    .readdirSync(tempDir, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name);

  if (dirs.length === 1) {
    sourceDir = path.join(tempDir, dirs[0]);
  }

  // 将文件移到目标目录
  const files = fs.readdirSync(sourceDir);
  const movedFiles = [];

  for (const file of files) {
    if (file.startsWith(".") || file === "__MACOSX") continue;
    const src = path.join(sourceDir, file);
    const dest = path.join(destDir, file);

    // 如果目标已存在同名文件，先删除
    if (fs.existsSync(dest)) {
      fs.rmSync(dest, { recursive: true, force: true });
    }
    fs.renameSync(src, dest);
    movedFiles.push(file);
    console.log(`📄 已提取: ${file}`);
  }

  // 清理临时目录
  fs.rmSync(tempDir, { recursive: true, force: true });
  // 删除压缩包
  fs.unlinkSync(archivePath);

  return movedFiles;
}

// 读取本地版本
function getLocalVersion() {
  try {
    if (fs.existsSync(VERSION_FILE)) {
      return JSON.parse(fs.readFileSync(VERSION_FILE, "utf-8")).version;
    }
  } catch {}
  return null;
}

// 解析 checksums 文件
function parseChecksums() {
  const file = path.join(LOCAL_APK_DIR, "checksums.txt");
  if (!fs.existsSync(file)) return null;

  const result = {};
  fs.readFileSync(file, "utf-8")
    .split("\n")
    .forEach((line) => {
      const match = line.match(/^([^=]+)=(.*)$/);
      if (match) result[match[1].trim()] = match[2].trim();
    });
  return Object.keys(result).length ? result : null;
}

// 保存版本信息
function saveVersionInfo(version, files) {
  const info = {
    version,
    updateTime: new Date().toISOString(),
    files: files.map((f) => {
      const fp = path.join(LOCAL_APK_DIR, f);
      return {
        name: f,
        size: fs.existsSync(fp) ? fs.statSync(fp).size : 0,
      };
    }),
  };
  const checksums = parseChecksums();
  if (checksums) info.checksums = checksums;
  fs.writeFileSync(VERSION_FILE, JSON.stringify(info, null, 2), "utf-8");
}

// 主流程
async function main() {
  console.log("🔍 检查 APK 更新...\n");

  const versions = await getRemoteVersions();
  if (versions.length === 0) {
    console.log("❌ 未找到任何版本");
    return;
  }

  const latestVersion = versions[0];
  console.log(`📦 最新版本: ${latestVersion}`);

  const localVersion = getLocalVersion();
  if (localVersion === latestVersion) {
    console.log(`✅ 已是最新版本: ${latestVersion}`);
    return;
  }

  console.log(`🔄 发现更新: ${localVersion || "无"} → ${latestVersion}\n`);

  const files = await getVersionFiles(latestVersion);
  console.log("📄 版本文件:", files);

  if (!fs.existsSync(LOCAL_APK_DIR)) {
    fs.mkdirSync(LOCAL_APK_DIR, { recursive: true });
  }

  const extractedFiles = [];

  for (const file of files) {
    const remotePath = `${APK_DIR}/${latestVersion}/${file}`;
    const localPath = path.join(LOCAL_APK_DIR, file);

    await downloadFile(remotePath, localPath);

    if (file.endsWith(".zip") || file.endsWith(".tar.gz") || file.endsWith(".tgz")) {
      console.log(`\n📦 解压 ${file}...`);
      const extracted = extractAndFlatten(localPath, LOCAL_APK_DIR);
      extractedFiles.push(...extracted);
    } else {
      extractedFiles.push(file);
    }
  }

  // 重命名 checksums 文件为 checksums.txt
  const checksumsFile = extractedFiles.find((f) => f.startsWith("checksums-") && f.endsWith(".txt"));
  if (checksumsFile) {
    const oldPath = path.join(LOCAL_APK_DIR, checksumsFile);
    const newPath = path.join(LOCAL_APK_DIR, "checksums.txt");
    if (fs.existsSync(oldPath)) {
      fs.renameSync(oldPath, newPath);
      const idx = extractedFiles.indexOf(checksumsFile);
      if (idx > -1) extractedFiles[idx] = "checksums.txt";
      console.log(`📝 重命名: ${checksumsFile} → checksums.txt`);
    }
  }

  saveVersionInfo(latestVersion, extractedFiles);

  console.log(`\n✅ 更新完成！`);
  console.log(`📁 文件位置: ${LOCAL_APK_DIR}`);
  console.log(`📋 可用文件:`, extractedFiles);
}

main().catch((error) => {
  console.error("\n❌ 脚本执行失败:", error.message);
  process.exit(1);
});
