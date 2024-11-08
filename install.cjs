#!/usr/bin/env node
const path = require("path");
const { execFileSync } = require("child_process");

execFileSync("./install.sh", [], {
  encoding: "utf8",
  stdio: "inherit",
  cwd: path.resolve(__dirname),
});
