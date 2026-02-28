defmodule NasaFuelCalculator.FuelTest do
  use ExUnit.Case, async: true

  alias NasaFuelCalculator.Fuel

  describe "gravity/1" do
    test "returns correct gravity for Earth" do
      assert Fuel.gravity(:earth) == 9.807
    end

    test "returns correct gravity for Moon" do
      assert Fuel.gravity(:moon) == 1.62
    end

    test "returns correct gravity for Mars" do
      assert Fuel.gravity(:mars) == 3.711
    end

    test "raises for unknown planet" do
      assert_raise KeyError, fn -> Fuel.gravity(:jupiter) end
    end
  end

  describe "calculate_step/3" do
    test "calculates fuel for landing on Earth with mass 28_801" do
      assert Fuel.calculate_step(:land, :earth, 28_801) == 13_447
    end

    test "calculates fuel for launching from Earth" do
      assert Fuel.calculate_step(:launch, :earth, 28_801) > 0
    end

    test "calculates fuel for landing on Moon" do
      assert Fuel.calculate_step(:land, :moon, 28_801) > 0
    end

    test "calculates fuel for launching from Moon" do
      assert Fuel.calculate_step(:launch, :moon, 28_801) > 0
    end
  end

  describe "calculate/2" do
    test "Apollo 11 mission: launch Earth, land Moon, launch Moon, land Earth with mass 28_801" do
      path = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]

      assert Fuel.calculate(28_801, path) == 51_898
    end

    test "Mars mission: launch Earth, land Mars, launch Mars, land Earth with mass 14_606" do
      path = [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :earth}]

      assert Fuel.calculate(14_606, path) == 33_388
    end

    test "Passenger ship: multi-planet trip with mass 75_432" do
      path = [
        {:launch, :earth},
        {:land, :moon},
        {:launch, :moon},
        {:land, :mars},
        {:launch, :mars},
        {:land, :earth}
      ]

      assert Fuel.calculate(75_432, path) == 212_161
    end

    test "returns 0 for empty flight path" do
      assert Fuel.calculate(28_801, []) == 0
    end

    test "single step path returns expected fuel" do
      path = [{:land, :earth}]
      assert Fuel.calculate(28_801, path) == 13_447
    end
  end

  describe "calculate_step/3 edge cases" do
    test "returns 0 when mass is too small to produce fuel" do
      assert Fuel.calculate_step(:land, :moon, 1) == 0
    end

    test "returns 0 for launch with very small mass" do
      assert Fuel.calculate_step(:launch, :moon, 1) == 0
    end
  end
end
