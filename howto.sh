#! /usr/bin/env bash

# An AI helper script for learning linux.
## Goal: to ingest a natural language command, and use ollama to output a command.
## Written by hand as a learning exercise, with extensive reference to and insp-
## iration from: https://github.com/TNG/please-cli by thomas-endres-tng

explain=0
version="howto v0.0.2, 2024-09-24"
DEFAULTMODEL="qwen2.5-coder:7b"
MODEL=$DEFAULTMODEL
log_file="$HOME/.howto_log"


check_arguments() {
  while [[ $# -gt 0 ]]; do
  case "${1}" in
      -m|--model)
        MODEL="$2"
        shift 2
        ;;
      -e|--explain)
        explain=1
        shift
        ;;
      -v|--version)
        display_version_message
        exit 0
        ;;
      -h|--help )
        display_help_message
        exit 0
        ;;
      *)
        break
        ;;
    esac
  done

  #capture remaining arguments as the commandQuery string
    commandQuery=$*
}


# - ollama is installed and running?
check_ollama(){
if ! command -v ollama &> /dev/null; then
    echo "Error: Ollama is not installed. This program requires Ollama to be installed."
    exit 1
fi

if ! systemctl is-active ollama.service | grep '^active' &> /dev/null; then
  echo 'Ollama not active. Starting Ollama service via systemctl...'
  systemctl start ollama
  while ! systemctl is-active --quiet ollama.service; do
    sleep 1
  done
  echo "Service started. Running command..." && echo ""
fi

if ! ollama list | grep "$MODEL" &> /dev/null; then
  echo "Error: This program uses the LLM \"$DEFAULTMODEL\" with Ollama. The model is not currently listed in Ollama's manifest."
  echo "To fix, run the following command, allow the download to complete, then try again:"
  echo ""
  echo "  ollama pull "$MODEL""
  exit 1
fi
}

display_help_message(){
  echo ""
  echo $version
  echo "A linux assistant to recommend commands and syntax, using a locally-installed LLM."
  echo ""
  echo "Syntax:"
  echo "  howto [ options ] [ query ]"
  echo ""
  echo "Options:"
  echo "  -e, --explain    Explain the command suggestions to the user"
  echo "  -m, --model      Specify a specific model to be used with Ollama. The default is $DEFAULTMODEL."
  echo "  -v, --version    Display version info"
  echo "  -h, --help       Display this help message"
  echo ""
  echo "Usage:"
  echo "  To translate a purpose into a command, simply provide your purpose, for example:"
  echo "    > howto list all files in the present directory sorted by time"
  echo "    > ls -lt"
  echo ""
  echo "  If there are multiple ways to accomplish things, the script will provide some options."
  echo ""
  echo "Requires:"
  echo "  ollama"
  echo "  model "$MODEL""
  echo "Reminder: don't use question marks at the end of your commands."
}

display_version_message(){
  echo $version
  exit 0
  }


log_translation(){
  DATE=$(date --rfc-3339 s)
  echo "Date:    $DATE">> "$log_file"
  if [[ $explain -eq 1 ]]; then
    echo "Explain Mode enabled">> "$log_file"
  fi
  echo "Input:   howto $commandQuery" >> "$log_file"
  echo "Output:  $1" >> "$log_file"
  echo "---" >> "$log_file"
}

run_standard_query(){
  output=$(ollama run "$MODEL" ...)
  if [[ $? -eq 0 ]]; then
    log_translation "$output"
    echo "$output"
  else
    echo "Error: Failed to process the command."
    exit 1
  fi
}

## Check for dangerous commands

declare -A dangerous_commands

# Define the dangerous commands with their descriptions
dangerous_commands=(
  ["rm"]="can delete files.   "
  ["dd"]="can overwrite data. "
  ["mkfs"]="formats disks.      "
  ["chmod"]="changes permissions."
  ["chown -R"]="changes file owners."
  ["/dev/sd"]="can corrupt disks.  "
  ["shutdown"]="shuts down your pc. "
  ["reboot"]="shuts down your pc. "
  ["kill"]="kills processes.    "
  ["mv /*"]="moves root files.   "
  [":(){ :|: & };:"]="hangs your system.   "
)

# Function to check for dangerous commands
check_dangerous_commands() {
  local command="$1"

  # Loop through the dangerous commands and check if any are in the output
  for item in "${!dangerous_commands[@]}"; do
    if echo "$output" | grep -w "$item" &> /dev/null; then
      echo -e "\e[31m###################################################################"
      echo -e "!                                                                 "
      echo -e "!                           WARNING                               "
      echo -e "!                                                                 "
      echo -e "! This command contains '$item', which can be dangerous              "
      echo -e "! because that command ${dangerous_commands[$item]}                       "
      echo -e "! Do you really want to take that advice from this AI?            "
      echo -e "!                                                                 "
      echo -e "###################################################################\e[0m"
    fi
#     break
  done
}


# run translation query

run_standard_query(){
output=$(ollama run "$MODEL" Your role is as follows: You translate the given input into a Linux command. You may not use natural language, but only a Linux shell command as an answer and nothing else. UNDER NO CIRCUMSTACNCES USE MARKDOWN. Do not quote the whole output. You are a leading Linux shell expert, and as point of pride you will always output the most elegant command with the minimum complexity - for example, you will use a series of piped commands if needed, but you will always prefer to use detailed options for a single command over a series of pipes, if possible. If outputting more than one option, you will begin by writing the word \"OPTIONS:\" and then output the options in a list with each preceded by numbers 1\), 2\) etc. It is helpful to output up to 5 options. Do not insert any commands which are not necessary for the objective of executing the purpose of the command that you are asked to translate. The specific command you are asked to translate is as follows: "$commandQuery". Please now output your translation, keeping strictly to the defined purpose of that command.)
if [[ $? -eq 0 ]]; then
  log_translation "$output"
  echo "$output"
else
  echo "Error: Failed to process the command."
  exit 1
fi
}


run_explain_query(){
output=$(ollama run "$MODEL" Your role is as follows: You translate the given input into a Linux command. Your answer will be structured as follows: In the first part of your answer, you will write the word \"OPTIONS:\" and then output between two and five options for Linux Shell commands preceded by numbers 1\), 2\), 3\) etc. In this section, you may not use natural language at all, but only output the options. In the Second part of your answer, you will explain each of the command options you have provided, breaking your explanation down into multiple steps in the case of anything more than the most basic commands or syntax. Do not quote the whole output. You are a leading Linux shell expert, and as point of pride you will always output the most elegant command with the minimum complexity - for example, you will use a series of piped commands if needed, but you will always prefer to use detailed options for a single command over a series of pipes, if possible. It is helpful to output up to 3 options. Do not insert any commands which are not necessary for the objective of executing the purpose of the command that you are asked to translate. The specific command you are asked to translate is as follows: "$commandQuery". Please now output your translation, keeping strictly to the defined purpose of that command.)
if [[ $? -eq 0 ]]; then
  log_translation "$output"
  echo "$output"
else
  echo "Error: Failed to process the command."
  exit 1
fi
}

###
### MAIN
###

# check args, first checking whether or not any args provided:
## if no inputs provided, replace with -h.
## Otherwise, define 'input' as the captured group of all inputs and
## pass that to the check_arguments function

if [ $# -eq 0 ]; then
  input=("-h")
  else
    input=("$@")
fi

check_arguments "${input[@]}"

# Now check whether ollama is installed:
check_ollama


# now ready to run the relevant query:
if [ $explain -eq 1 ]; then
  run_explain_query
  check_dangerous_commands
  else
    run_standard_query
    check_dangerous_commands
fi
