defmodule NasaFuelCalculatorWeb.FuelCalculatorLive do
  @moduledoc """
  LiveView for calculating fuel required for interplanetary space missions.
  """

  use NasaFuelCalculatorWeb, :live_view

  alias NasaFuelCalculator.Fuel

  @planets [{"Earth", "earth"}, {"Moon", "moon"}, {"Mars", "mars"}]
  @actions [{"Launch", "launch"}, {"Land", "land"}]

  @presets %{
    "apollo_11" => %{
      name: "Apollo 11",
      mass: "28801",
      steps: [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
    },
    "mars_mission" => %{
      name: "Mars Mission",
      mass: "14606",
      steps: [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :earth}]
    },
    "passenger_ship" => %{
      name: "Passenger Ship",
      mass: "75432",
      steps: [
        {:launch, :earth},
        {:land, :moon},
        {:launch, :moon},
        {:land, :mars},
        {:launch, :mars},
        {:land, :earth}
      ]
    }
  }

  @impl true
  def mount(_params, _session, socket) do
    preset = @presets["apollo_11"]
    flight_path = Enum.map(preset.steps, fn {action, planet} -> new_step(action, planet) end)

    socket =
      socket
      |> assign(
        mass: preset.mass,
        flight_path: flight_path,
        total_fuel: nil,
        fuel_breakdown: [],
        error: nil
      )

    {:ok, recalculate(socket)}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, planets: @planets, actions: @actions, presets: @presets)

    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        NASA Fuel Calculator
        <:subtitle>Calculate fuel required for interplanetary space travel</:subtitle>
      </.header>

      <div class="grid grid-cols-1 lg:grid-cols-5 gap-6">
        <%!-- Left Column: Inputs (2 cols) --%>
        <div class="lg:col-span-2 space-y-4">
          <div class="card bg-base-200 shadow-sm">
            <div class="card-body">
              <h2 class="card-title">Spacecraft Mass</h2>
              <fieldset class="fieldset">
                <label>
                  <span class="fieldset-label mb-1">Mass (kg)</span>
                  <input
                    type="number"
                    name="mass"
                    value={@mass}
                    min="1"
                    placeholder="e.g. 28801"
                    phx-keyup="update_mass"
                    phx-debounce="300"
                    class={["w-full input", @error && "input-error"]}
                  />
                </label>
                <p :if={@error} class="mt-1.5 flex gap-2 items-center text-sm text-error">
                  <.icon name="hero-exclamation-circle-mini" class="size-5" />
                  {@error}
                </p>
              </fieldset>

              <div class="mt-2">
                <span class="fieldset-label mb-1">Preset Missions</span>
                <div class="flex flex-wrap gap-2">
                  <button
                    :for={{key, preset} <- @presets}
                    class="btn btn-outline btn-sm"
                    phx-click="load_preset"
                    phx-value-preset={key}
                  >
                    {preset.name}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div class="card bg-base-200 shadow-sm">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <h2 class="card-title">Flight Path</h2>
                <button class="btn btn-primary btn-sm" phx-click="add_step">
                  <.icon name="hero-plus-mini" class="size-4" /> Add Step
                </button>
              </div>

              <div class="space-y-3 mt-2">
                <form
                  :for={{step, index} <- Enum.with_index(@flight_path)}
                  phx-change="update_step"
                  class="flex items-end gap-3"
                >
                  <input type="hidden" name="step_id" value={step.id} />
                  <span class="badge badge-neutral mb-2">{index + 1}</span>

                  <fieldset class="fieldset flex-1">
                    <label>
                      <span class="fieldset-label mb-1">Action</span>
                      <select name="action" class="w-full select">
                        {Phoenix.HTML.Form.options_for_select(@actions, to_string(step.action))}
                      </select>
                    </label>
                  </fieldset>

                  <fieldset class="fieldset flex-1">
                    <label>
                      <span class="fieldset-label mb-1">Planet</span>
                      <select name="planet" class="w-full select">
                        {Phoenix.HTML.Form.options_for_select(@planets, to_string(step.planet))}
                      </select>
                    </label>
                  </fieldset>

                  <button
                    :if={length(@flight_path) > 1}
                    type="button"
                    class="btn btn-error btn-soft btn-sm mb-2"
                    phx-click="remove_step"
                    phx-value-id={step.id}
                  >
                    <.icon name="hero-trash-mini" class="size-4" />
                  </button>
                </form>
              </div>
            </div>
          </div>
        </div>

        <%!-- Right Column: Results (3 cols) --%>
        <div class="lg:col-span-3 space-y-4 lg:sticky lg:top-20 lg:self-start">
          <div :if={@total_fuel} class="card bg-primary text-primary-content shadow-sm">
            <div class="card-body text-center">
              <h2 class="card-title justify-center text-2xl">Total Fuel Required</h2>
              <p class="text-5xl font-bold">{format_number(@total_fuel)} kg</p>
              <div class="divider divider-primary my-1"></div>
              <p class="text-sm opacity-80">
                Spacecraft mass: {format_number(String.to_integer(@mass))} kg |
                Flight steps: {length(@flight_path)}
              </p>
            </div>
          </div>

          <div :if={@total_fuel} class="card bg-base-200 shadow-sm">
            <div class="card-body">
              <h2 class="card-title">Journey Visualization</h2>
              <div class="flex flex-col items-center py-4">
                <.journey_node
                  :for={{step, index} <- Enum.with_index(@flight_path)}
                  step={step}
                  index={index}
                  last={index == length(@flight_path) - 1}
                />
              </div>
            </div>
          </div>

          <div :if={@fuel_breakdown != []} class="card bg-base-200 shadow-sm">
            <div class="card-body">
              <h2 class="card-title">Fuel Breakdown</h2>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>Step</th>
                      <th>Action</th>
                      <th>Planet</th>
                      <th class="text-right">Fuel (kg)</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={{{action, planet, fuel}, index} <- Enum.with_index(@fuel_breakdown, 1)}>
                      <td>{index}</td>
                      <td class="capitalize">{action}</td>
                      <td class="capitalize">{planet}</td>
                      <td class="text-right font-mono">{format_number(fuel)}</td>
                    </tr>
                  </tbody>
                  <tfoot>
                    <tr class="font-bold">
                      <td colspan="3">Total</td>
                      <td class="text-right font-mono">{format_number(@total_fuel)} kg</td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp journey_node(assigns) do
    ~H"""
    <div class="flex flex-col items-center w-full">
      <div class="flex items-center gap-2 py-1">
        <span class={[
          "badge",
          action_badge_class(@step.action)
        ]}>
          {if @step.action == :launch, do: "Launch", else: "Land"}
        </span>
        <span class="font-semibold capitalize">{@step.planet}</span>
      </div>
      <div :if={!@last} class="w-0.5 h-8 bg-base-300"></div>
    </div>
    """
  end

  defp action_badge_class(:launch), do: "badge-success"
  defp action_badge_class(:land), do: "badge-info"

  @impl true
  def handle_event("update_mass", %{"value" => value}, socket) do
    {:noreply, socket |> assign(mass: value) |> recalculate()}
  end

  @impl true
  def handle_event("load_preset", %{"preset" => key}, socket) do
    preset = Map.fetch!(@presets, key)
    flight_path = Enum.map(preset.steps, fn {action, planet} -> new_step(action, planet) end)

    socket =
      socket
      |> assign(mass: preset.mass, flight_path: flight_path)
      |> recalculate()

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_step", _params, socket) do
    flight_path = socket.assigns.flight_path ++ [new_step(:launch, :earth)]
    {:noreply, socket |> assign(flight_path: flight_path) |> recalculate()}
  end

  @impl true
  def handle_event("remove_step", %{"id" => id}, socket) do
    flight_path = Enum.reject(socket.assigns.flight_path, &(&1.id == id))
    {:noreply, socket |> assign(flight_path: flight_path) |> recalculate()}
  end

  @impl true
  def handle_event(
        "update_step",
        %{"step_id" => id, "action" => action, "planet" => planet},
        socket
      ) do
    flight_path = update_step_in_list(socket.assigns.flight_path, id, action, planet)

    {:noreply, socket |> assign(flight_path: flight_path) |> recalculate()}
  end

  defp update_step_in_list(steps, id, action, planet) do
    Enum.map(steps, &do_update_step(&1, id, action, planet))
  end

  defp do_update_step(%{id: id} = step, id, action, planet) do
    %{step | action: String.to_existing_atom(action), planet: String.to_existing_atom(planet)}
  end

  defp do_update_step(step, _id, _action, _planet), do: step

  defp recalculate(socket) do
    case parse_mass(socket.assigns.mass) do
      {:ok, mass} ->
        path =
          Enum.map(socket.assigns.flight_path, fn step ->
            {step.action, step.planet}
          end)

        total_fuel = Fuel.calculate(mass, path)
        fuel_breakdown = Fuel.calculate_breakdown(mass, path)
        assign(socket, total_fuel: total_fuel, fuel_breakdown: fuel_breakdown, error: nil)

      {:error, reason} ->
        assign(socket, total_fuel: nil, fuel_breakdown: [], error: reason)
    end
  end

  defp parse_mass(""), do: {:error, nil}

  defp parse_mass(value) do
    case Integer.parse(value) do
      {mass, ""} when mass > 0 -> {:ok, mass}
      {mass, ""} when mass <= 0 -> {:error, "Mass must be a positive number"}
      _ -> {:error, "Please enter a valid number"}
    end
  end

  defp new_step(action, planet) do
    %{id: generate_id(), action: action, planet: planet}
  end

  defp generate_id, do: [:positive] |> System.unique_integer() |> Integer.to_string()

  defp format_number(number) do
    number
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end
end
