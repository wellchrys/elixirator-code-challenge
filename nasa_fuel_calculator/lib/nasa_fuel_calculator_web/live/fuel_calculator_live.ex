defmodule NasaFuelCalculatorWeb.FuelCalculatorLive do
  @moduledoc """
  LiveView for calculating fuel required for interplanetary space missions.
  """

  use NasaFuelCalculatorWeb, :live_view

  alias NasaFuelCalculator.Fuel

  @planets [{"Earth", "earth"}, {"Moon", "moon"}, {"Mars", "mars"}]
  @actions [{"Launch", "launch"}, {"Land", "land"}]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        mass: "",
        flight_path: [new_step(:launch, :earth), new_step(:land, :moon)],
        total_fuel: nil,
        error: nil
      )

    {:ok, recalculate(socket)}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, planets: @planets, actions: @actions)

    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        NASA Fuel Calculator
        <:subtitle>Calculate fuel required for interplanetary space travel</:subtitle>
      </.header>

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
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("update_mass", %{"value" => value}, socket) do
    {:noreply, socket |> assign(mass: value) |> recalculate()}
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
        assign(socket, total_fuel: total_fuel, error: nil)

      {:error, reason} ->
        assign(socket, total_fuel: nil, error: reason)
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
