# Sondre's PowerShell Modules

## Installation

- Clone the repo and add the `Modules` folder to your PSModulePath environment variable
- You may alternatively copy the contents of the `Modules` folder into another directory within the PSModulePath

## Utilization

- Instructions will come simply by invoking the name of each module within your terminal.

## Modules

### LLM

- Capable of sending prompts to OpenRouter, provided you supply your own api key.
- Type 'LLM' for further instructions.

### Actions

- Capable of doing simple operations on paths you supply to your config.json file.
- Supplies the following actions:
  - Open website link in the browser of your choice
  - Open directory in VSCode
  - Open directory in explorer
  - Open directory in terminal
  - Run file

- Requires paths added to config.json file in the root directory.
