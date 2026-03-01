#!/bin/bash

menu() {
  echo
  echo
  echo "=== NASA Fuel Calculator Setup Script - Ubuntu ==="
  echo
  echo "1 - Start Script"
  echo "2 - Exit Script"
  echo
  echo -n "Type an option: "
  read option

  case $option in
    1) start_script ;;
    2) exit_script ;;
    *) echo "Invalid option! Please try again..."; menu ;;
  esac
}

start_script() {
  script_dependencies
  echo
  script_asdf
  echo
  script_project_setup
  echo
}

exit_script() {
  echo
  echo "Exiting..."
  exit 0
}

script_dependencies() {
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y curl gnupg git unzip build-essential libssl-dev
  sudo apt-get -y install build-essential autoconf m4 libncurses-dev openjdk-11-jdk
}

script_asdf() {
  if ! command -v asdf &> /dev/null; then
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.15.0
    echo -e '\n. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
    echo -e '\n. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
    source ~/.bashrc
    if command -v asdf &> /dev/null; then
      echo "Asdf installed successfully!"
    else
      echo "Error installing asdf. Please run 'source ~/.bashrc' and the script again."
      exit 1
    fi
  else
    echo "Asdf already installed."
  fi

  asdf plugin add erlang
  asdf plugin add elixir
  asdf install
}

script_project_setup() {
  cd nasa_fuel_calculator

  mix local.hex --force
  mix local.rebar --force
  mix deps.get
  mix compile
}

menu
