# NASA Fuel Calculator

A Phoenix LiveView application that calculates the required fuel for interplanetary space travel. Users dynamically build flight paths (sequences of launch/land actions across planets) and see real-time fuel calculations.

## Requirements

- Erlang/OTP 25
- Elixir 1.15
- Phoenix 1.8.0-rc

## Setup

### macOS

```bash
bin/setup-macos.sh
```

### Ubuntu

```bash
bin/setup-ubuntu.sh
```

### Manual

```bash
asdf install
cd nasa_fuel_calculator
mix deps.get
mix compile
```

## Running

```bash
cd nasa_fuel_calculator
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000).

## Tests

```bash
cd nasa_fuel_calculator
mix test
```

### Coverage

```bash
cd nasa_fuel_calculator
MIX_ENV=test mix coveralls.json
```

## Code Quality

```bash
cd nasa_fuel_calculator
mix code.check
MIX_ENV=dev mix dialyzer --format raw
```

Or use the script:

```bash
bin/code-check.sh
```

## Fuel Calculation

Fuel is calculated recursively -- each step's fuel adds weight to the spacecraft, requiring additional fuel until the additional amount is zero or negative.

**Formulas:**

- Launch: `mass * gravity * 0.042 - 33` (rounded down)
- Landing: `mass * gravity * 0.033 - 42` (rounded down)

**Supported planets (gravity):**

| Planet | Gravity |
| ------ | ------- |
| Earth  | 9.807   |
| Moon   | 1.62    |
| Mars   | 3.711   |

## Example Scenarios

| Mission        | Path                                                                     | Mass (kg) | Fuel (kg) |
| -------------- | ------------------------------------------------------------------------ | --------- | --------- |
| Apollo 11      | Launch Earth, Land Moon, Launch Moon, Land Earth                         | 28,801    | 51,898    |
| Mars Mission   | Launch Earth, Land Mars, Launch Mars, Land Earth                         | 14,606    | 33,388    |
| Passenger Ship | Launch Earth, Land Moon, Launch Moon, Land Mars, Launch Mars, Land Earth | 75,432    | 212,161   |

## Project Structure

```txt
nasa_fuel_calculator/
  lib/
    nasa_fuel_calculator/
      fuel.ex                  # Core fuel calculation engine
    nasa_fuel_calculator_web/
      live/
        fuel_calculator_live.ex  # LiveView interface
  test/
    nasa_fuel_calculator/
      fuel_test.exs            # Fuel engine unit tests
    nasa_fuel_calculator_web/
      live/
        fuel_calculator_live_test.exs  # LiveView tests
  bin/
    setup-macos.sh             # macOS setup script
    setup-ubuntu.sh            # Ubuntu setup script
    code-check.sh              # Code quality checks
```

## Tech Stack

- Elixir 1.15 / OTP 25
- Phoenix 1.8.0-rc with LiveView
- DaisyUI 5 + Tailwind CSS v4
