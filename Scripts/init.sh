#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312

set -u

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
# shellcheck disable=SC2292
if [ -z "${BASH_VERSION:-}" ]
then
  abort "Bash is required to interpret this script."
fi

# string formatters
if [[ -t 1 ]]
then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")" >&2
}

################################################################################

usage() {
  cat <<EOS
Homebrew Installer
Usage: [NONINTERACTIVE=1] [CI=1] install.sh [options]
    -h, --help       Display this message.
    NONINTERACTIVE   Install without prompting for user input
    CI               Install in CI mode (e.g. do not prompt for user input)
EOS
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]
do
  case "$1" in
    -h | --help) usage ;;
    *)
      warn "Unrecognized option: '$1'"
      usage 1
      ;;
  esac
done

# check OS.
OS="$(uname)"
if [[ "${OS}" == "Linux" ]]
then
  CYNGULAR_ON_LINUX=1
elif [[ "${OS}" == "Darwin" ]]
then
  CYNGULAR_ON_MACOS=1
else
  abort "Homebrew is only supported on macOS and Linux."
fi

################################################################################
# Terraform configuration bootstrap
################################################################################

# Detect a safe downloader (curl preferred, wget fallback)
download_file() {
  local url=$1
  local dest=$2

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest" || abort "Failed to download $url"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url" || abort "Failed to download $url"
  else
    abort "Neither curl nor wget is available. Please install one of them and rerun this script."
  fi
}

bootstrap_terraform_files() {
  # Allow overriding branch with GITHUB_BRANCH env; default to main
  local branch=${GITHUB_BRANCH:-main}
  local repo_raw_base="https://raw.githubusercontent.com/cyngularsecurity/terraform-azure-onboarding/${branch}"

  # Files to fetch (paths are relative to repo root)
  local root_main_tf="main.tf"
  local example_main_tf="examples/base/main.tf"
  local example_tfvars="tfvars/avona.tfvars"

  # Do not clobber existing files unless FORCE_DOWNLOAD=1
  if [[ -f ${root_main_tf} && -z "${FORCE_DOWNLOAD:-}" ]]; then
    warn "${root_main_tf} already exists, skipping download (set FORCE_DOWNLOAD=1 to overwrite)."
  else
    echo "Downloading root ${root_main_tf} from GitHub..."
    download_file "${repo_raw_base}/${root_main_tf}" "${root_main_tf}"
  fi

  if [[ -f ${example_main_tf} && -z "${FORCE_DOWNLOAD:-}" ]]; then
    warn "${example_main_tf} already exists, skipping download (set FORCE_DOWNLOAD=1 to overwrite)."
  else
    mkdir -p "$(dirname "${example_main_tf}")"
    echo "Downloading example ${example_main_tf} from GitHub..."
    download_file "${repo_raw_base}/${example_main_tf}" "${example_main_tf}"
  fi

  # Prepare a terraform.tfvars based on the example tfvars, if available
  if [[ -f terraform.tfvars && -z "${FORCE_DOWNLOAD:-}" ]]; then
    warn "terraform.tfvars already exists, leaving it untouched (set FORCE_DOWNLOAD=1 to overwrite)."
  else
    if download_file "${repo_raw_base}/${example_tfvars}" "terraform.tfvars.tmp" 2>/dev/null; then
      mv terraform.tfvars.tmp terraform.tfvars
      echo "Created terraform.tfvars from example (${example_tfvars})."
    else
      warn "Could not download ${example_tfvars}. Creating a minimal terraform.tfvars template instead."
      cat > terraform.tfvars <<'EOF_TFVARS'
# Required variables – fill these for your environment
client_name         = ""
main_subscription_id = ""
application_id      = ""
locations           = ["westeurope"]
EOF_TFVARS
    fi
  fi

  cat <<'EOF_INSTRUCTIONS'

Next steps:
  1. Open terraform.tfvars in your editor.
  2. Set the REQUIRED variables:
       - client_name          : Company name (lowercase letters and digits only).
       - main_subscription_id : Your main Azure subscription ID for ARM authentication.
       - application_id       : Application (client) ID of the multi-tenant service principal (UUID).
       - locations            : List of Azure regions where you operate.
  3. (Optional) Review examples/main/main.tf to see how the module is wired.
  4. Run:
       terraform init
       terraform plan -var-file="terraform.tfvars"
       terraform apply -var-file="terraform.tfvars"
EOF_INSTRUCTIONS
}


###### ----- start ops ----- ######

# Run bootstrap step when this script is invoked directly (and not sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  bootstrap_terraform_files
fi


required_providers=(
  "Microsoft.Storage"
  "Microsoft.Web"
  "Microsoft.KeyVault"
  "Microsoft.ManagedIdentity"
  "Microsoft.Insights"
  "Microsoft.OperationalInsights"
  "Microsoft.Authorization"
  "Microsoft.Resources"
  "Microsoft.Network"
  "Microsoft.ContainerService"
  "Microsoft.DevTestLab"
  "Microsoft.MachineLearningServices"
  "Microsoft.Blueprint"
  "Microsoft.HealthcareApis"
  "Microsoft.SignalRService"
  "Microsoft.Cdn"
  "Microsoft.Maintenance"
  "Microsoft.Automation"
  "Microsoft.DataMigration"
  "Microsoft.DBforMariaDB"
  "Microsoft.Relay"
  "Microsoft.DataFactory"
  "Microsoft.EventGrid"
  "Microsoft.Databricks"
  "Microsoft.AppPlatform"
  "Microsoft.AppConfiguration"
  "Microsoft.CognitiveServices"
  "Microsoft.DocumentDB"
  "Microsoft.Maps"
  "Microsoft.ServiceBus"
  "Microsoft.ApiManagement"
  "Microsoft.DataProtection"
)

for provider in ${required_providers[@]}
do
  az provider register --namespace $provider
done


for provider in ${required_providers[@]}
do
  az provider show --namespace $provider --query "registrationState"
done

