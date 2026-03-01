#!/bin/bash

cd nasa_fuel_calculator

mix clean && mix compile --force && \
  mix code.check && MIX_ENV=dev mix dialyzer --format raw
