# Sondre's PowerShell Modules

- A collection of Modules I began working on during christmas break of 2024, when I swapped from Bash to PowerShell and fell in love ✨

## Installation

- Clone the repo and add the `Modules` folder to your PSModulePath environment variable.
- Add data of your choice into the 'config.json' file and remove the underscore from its name.

## Utilization

- Instructions will come simply by invoking the name of each module within your terminal.

## Modules

### LLM

- Capable of sending prompts to OpenRouter, provided you supply your own api key.
- Initiated by simply typing 'LLM'.

### Actions

- Capable of doing simple operations on paths you supply to your config.json file.
- Supplies the following actions:
  - Open website link in the browser of your choice
  - Open directory in VSCode
  - Open directory in explorer
  - Open directory in terminal
  - Run file

- Requires paths added to config.json file in the root directory.
