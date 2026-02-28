#!/bin/bash

which -s brew
if [[ $? != 0 ]] ; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew info asdf
if [[ $? != 0 ]] ; then
  brew install asdf
fi

asdf plugin-add erlang
asdf plugin-add elixir
asdf install

cd nasa_fuel_calculator

mix local.hex --force
mix local.rebar --force
mix deps.get
mix compile
