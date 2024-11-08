#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

// Define the path for JSON storage and get the current working directory
const jsonPath = path.resolve(__dirname, ".bash-complete.json");

// Load the command tree from JSON or initialize it if it doesn't exist
function loadCommandTree() {
  if (fs.existsSync(jsonPath)) {
    const data = fs.readFileSync(jsonPath, "utf8");
    return JSON.parse(data);
  }
  return {}; // Initialize an empty object if the JSON file doesn't exist
}

// Save the updated command tree to JSON
function saveCommandTree(tree) {
  fs.writeFileSync(jsonPath, JSON.stringify(tree, null, 2));
}

// Update the command tree with provided arguments
// Modifies the tree in place and returns true if the tree was modified, false otherwise
function updateCommandTree(tree, cwd, args) {
  // Ensure the root for the current directory exists in the command tree
  if (!tree[cwd]) {
    tree[cwd] = {};
  }

  // Traverse or create entries in the command tree based on arguments
  let currentNode = tree[cwd];
  let isModified = false;

  for (const arg of args) {
    if (!currentNode[arg]) {
      if (arg.includes(" ")) {
        break;
      }
      currentNode[arg] = {};
      isModified = true; // Mark as modified if a new entry is added
    }
    currentNode = currentNode[arg];
  }

  // Return true if any changes were made, false otherwise
  return isModified;
}

function addScriptsFromPackageJson(tree, cwd, pkgPath, args) {
  if (!fs.existsSync(pkgPath)) return;
  const pkgJson = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
  const scripts = Object.keys(pkgJson.scripts || {});
  scripts.forEach((script) => updateCommandTree(tree, cwd, [...args, script]));
  return pkgJson;
}

function populateCommandTree(tree, cwd, args) {
  const pkgJson = addScriptsFromPackageJson(
    tree,
    cwd,
    path.join(cwd, "package.json"),
    args
  );
  // Add just the common root "internal" yarn commands
  let help = [
    "add",
    "install",
    "remove",
    "upgrade",
    "upgrade-interactive",
    "version",
    "workspace",
    "workspaces",
  ];
  help.forEach((script) => updateCommandTree(tree, cwd, [...args, script]));

  // Discover workspaces
  if (pkgJson.workspaces) {
    // Figure out what version we are dealing with
    const versionText = execFileSync("yarn", ["--version"], {
      encoding: "utf8",
    });
    const version = versionText.includes("1.") ? 1 : 2;
    let workspaces = {};
    try {
      // Get the workspaces
      const wkspArg =
        version === 1
          ? ["workspaces", "info"]
          : ["workspaces", "list", "--json"];

      workspaces = execFileSync("yarn", wkspArg, { encoding: "utf8" });
      if (version === 1) {
        const ixStartJson = workspaces.indexOf("{");
        const ixEndJson = workspaces.lastIndexOf("}");
        workspaces = workspaces.slice(ixStartJson, ixEndJson + 1);
        workspaces = JSON.parse(workspaces);
      } else {
        workspaces = JSON.parse(
          `[${workspaces.split("\n").filter(Boolean).join(",")}]`
        )
          .filter(({ location }) => location !== ".")
          .reduce((acc, { name, location }) => {
            acc[name] = { location };
            return acc;
          }, {});
      }
    } catch (e) {
      workspaces = {};
    }

    // Add workspace scripts
    for (const [name, { location }] of Object.entries(workspaces)) {
      addScriptsFromPackageJson(
        tree,
        cwd,
        path.join(cwd, location, "package.json"),
        [...args, "workspace", name]
      );
    }
  }
}

function main() {
  const cwd = process.cwd(); // Automatically use the current working directory
  const args = process.argv.slice(2); // Command arguments after program name

  // Run the update and conditionally save if changes were made
  try {
    const tree = loadCommandTree(); // Load the current command tree
    if (args[0] === "yarn" && args[args.length - 1] === "--auto") {
      populateCommandTree(tree, cwd, args.slice(0, -1));
      saveCommandTree(tree);
    } else if (updateCommandTree(tree, cwd, args)) {
      // Only save if updateCommandTree returned true
      saveCommandTree(tree);
    }
  } catch (error) {
    console.error("Error updating autocomplete command tree:", error);
  }
}

main();
