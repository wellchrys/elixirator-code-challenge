defmodule NasaFuelCalculator.Fuel do
  @moduledoc """
  Calculates fuel required for interplanetary space missions.

  Fuel is computed recursively — each step's fuel adds weight to the spacecraft,
  which in turn requires additional fuel, until the additional fuel is zero or negative.
  """

  @type action :: :launch | :land
  @type planet :: :earth | :moon | :mars
  @type flight_step :: {action(), planet()}

  @gravities %{earth: 9.807, moon: 1.62, mars: 3.711}

  @doc """
  Returns the gravity constant for a given planet.

  ## Examples

      iex> NasaFuelCalculator.Fuel.gravity(:earth)
      9.807

      iex> NasaFuelCalculator.Fuel.gravity(:mars)
      3.711
  """
  @spec gravity(planet()) :: float()
  def gravity(planet), do: Map.fetch!(@gravities, planet)

  @doc """
  Calculates total fuel for an entire flight path.

  The path is processed in reverse because fuel compounds — later legs add mass
  that earlier legs must account for.

  ## Examples

      iex> path = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
      iex> NasaFuelCalculator.Fuel.calculate(28801, path)
      51898

      iex> NasaFuelCalculator.Fuel.calculate(14606, [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :earth}])
      33388

      iex> NasaFuelCalculator.Fuel.calculate(75432, [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :mars}, {:launch, :mars}, {:land, :earth}])
      212161
  """
  @spec calculate(non_neg_integer(), [flight_step()]) :: non_neg_integer()
  def calculate(_mass, []), do: 0

  def calculate(mass, flight_path) do
    flight_path
    |> Enum.reverse()
    |> Enum.reduce(mass, fn {action, planet}, total_mass ->
      step_fuel = calculate_step(action, planet, total_mass)
      total_mass + step_fuel
    end)
    |> Kernel.-(mass)
  end

  @doc """
  Calculates fuel for a single flight step, including recursive fuel-for-fuel.

  ## Examples

      iex> NasaFuelCalculator.Fuel.calculate_step(:land, :earth, 28801)
      13447
  """
  @spec calculate_step(action(), planet(), non_neg_integer()) :: non_neg_integer()
  def calculate_step(action, planet, mass) do
    gravity = gravity(planet)
    fuel = base_fuel(action, gravity, mass)
    max(0, fuel + fuel_for_fuel(action, gravity, fuel))
  end

  defp fuel_for_fuel(_action, _gravity, fuel) when fuel <= 0, do: 0

  defp fuel_for_fuel(action, gravity, fuel) do
    additional = base_fuel(action, gravity, fuel)

    case additional > 0 do
      true -> additional + fuel_for_fuel(action, gravity, additional)
      false -> 0
    end
  end

  defp base_fuel(:launch, gravity, mass), do: floor(mass * gravity * 0.042 - 33)
  defp base_fuel(:land, gravity, mass), do: floor(mass * gravity * 0.033 - 42)
end
