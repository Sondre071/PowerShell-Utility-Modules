# Sondre's PowerShell Modules

- A collection of Modules I began working on during the christmas of 2024, when I swapped from Bash to PowerShell and took a strong liking to the syntax and simplicity that is PowerShell ✨

## Installation

- Clone the repo and add the `Modules` folder to your PSModulePath environment variable.
- Add data of your choice into the 'config.json' file and remove the underscore from its name.

## Modules

### LLM

- Capable of sending prompts to OpenRouter, provided you supply your own api key.
- Initiated by simply typing 'OR'.

### Actions

- Capable of doing simple operations on paths you supply in your config.json file.
- Example usecases:
  - Open website link in the browser of your choice
  - Open directory in VSCode
  - Open directory in explorer
  - Open directory in terminal
  - Run file

- Requires paths added to config.json file in the root directory.
