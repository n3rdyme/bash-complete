# Bash Complete

Bash Complete is a customizable command autocompletion system for Bash, designed to enhance the user experience by providing autocompletion suggestions for specific commands (by default, `yarn`). This project consists of a set of scripts that work together to support directory-specific and nested command autocompletion for complex workflows.

---

## Install Instructions

### Quick Install

You can install Bash Complete directly using `npx`:

```bash
npx bash-complete
```

### Manual Install

Alternatively, you can clone the repository and run the `install.sh` script:

```bash
./install.sh
```

The installation script performs the following actions:

1. Copies `.bash-complete.sh` and `.bash-complete-update.cjs` to the user’s home directory.
2. Creates `.bash-complete.json` in the home directory with default content (`{}`) if it doesn't already exist.
3. Updates `.bashrc` to source `.bash-complete.sh` for loading autocompletion on new shell sessions.

Once installed, open a new terminal session to start using Bash Complete.

---

## How to Use

After installation, you can use Bash Complete for autocompletion with `yarn` (or any command specified in the `SUPPORTED_COMMANDS` array).

- **Autocompletion**: Start typing a supported command, followed by a partial command or subcommand, and press `Tab` to see autocomplete suggestions. For example:

  ```bash
  yarn workspace @local/package <Tab><Tab>
  build
  ```

- **Automatic Command Logging**: Run `yarn --auto` to automatically populate the autocompletion data for the current directory’s `package.json` scripts, as well as workspaces and their scripts. This will capture available commands and subcommands and store them in `.bash-complete.json` for the current project directory and any workspaces it contains.

---

## Customization: Adding More Commands

By default, the script only supports `yarn` as a command. To enable autocompletion for additional commands:

1. Open `.bash-complete.sh` in your home directory:

   ```bash
   nano ~/.bash-complete.sh
   ```

2. Locate the `SUPPORTED_COMMANDS` array near the top of the file:

   ```bash
   SUPPORTED_COMMANDS=("yarn")
   ```

3. Add any additional commands to the array, separated by spaces. For example:

   ```bash
   SUPPORTED_COMMANDS=("yarn" "npm" "my_custom_command")
   ```

4. Save the file, and new commands will be supported automatically in new terminal sessions.

---

## What This Project Does

1. **Custom Command Autocompletion**: Supports autocompletion for a specified list of commands in Bash, using data stored in `.bash-complete.json`.
2. **Directory-Specific Suggestions**: The autocompletion suggestions are context-aware, providing different options based on the current directory.
3. **Nested Command Support**: Handles nested commands with complex structures (e.g., `yarn workspace @local/package build`) and supports autocompletion for each part of the command.

---

## File Details

### `.bash-complete.sh`

This is the main script responsible for setting up command overrides and defining the autocompletion function:

- **Overrides Commands** in `SUPPORTED_COMMANDS`, allowing autocompletion and logging.
- **Autocompletion Logic**: Looks up suggestions in `.bash-complete.json` based on the current directory and command structure.

### `.bash-complete-update.cjs`

This Node.js script updates `.bash-complete.json` with the current command structure:

- **Logging Commands**: Every time a supported command runs, `.bash-complete-update.cjs` updates the command tree in `.bash-complete.json`.
- **Directory-Specific Data**: Each directory gets its own set of command suggestions in the JSON file.

### `.bash-complete.json`

This JSON file stores the command structure used by the autocompletion function:

- **Format**: Directory paths are top-level keys, with command structures nested within each path.
- **Example Structure**:
  ```json
  {
    "/home/user/project": {
      "yarn": {
        "build": {
          "dev": {},
          "prod": {}
        },
        "test": {
          "unit": {},
          "integration": {}
        }
      }
    }
  }
  ```

### `install.sh`

Automates the setup process:

- **Copies Required Files** to the home directory.
- **Adds Source Entry to `.bashrc`**: Ensures `.bash-complete.sh` is loaded for each new terminal session.
- **Dependency Check**: Verifies `jq` is installed.

### `package.json`

Defines project metadata and dependencies. If the project expands to include additional Node modules, you can manage them here.

---

## Uninstallation

To remove Bash Complete:

1. Delete the installed files:

   ```bash
   rm ~/.bash-complete.json ~/.bash-complete.sh ~/.bash-complete-update.cjs
   ```

2. Remove the `source` line from `.bashrc`:

   ```bash
   nano ~/.bashrc
   ```

   Delete the following lines:

   ```bash
   # bash-complete setup
   source ~/.bash-complete.sh
   ```

3. Open a new terminal session to apply changes.

---

## License

This project is open-source under the MIT License.
