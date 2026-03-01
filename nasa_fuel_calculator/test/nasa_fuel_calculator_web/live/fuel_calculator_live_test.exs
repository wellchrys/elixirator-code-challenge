defmodule NasaFuelCalculatorWeb.FuelCalculatorLiveTest do
  use NasaFuelCalculatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "mount" do
    test "renders the fuel calculator page", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      assert html =~ "NASA Fuel Calculator"
      assert html =~ "Spacecraft Mass"
      assert html =~ "Flight Path"
      assert has_element?(view, "select")
      assert has_element?(view, "input[name=mass]")
    end

    test "starts with Apollo 11 preset as default", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      assert html =~ "Total Fuel Required"
      assert html =~ "51,898"
      assert has_element?(view, "input[name=mass][value='28801']")
      assert has_element?(view, "span.badge", "4")
    end
  end

  describe "update_mass" do
    test "calculates fuel when mass is entered", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("input[name=mass]")
        |> render_keyup(%{"value" => "28801"})

      assert html =~ "Total Fuel Required"
    end

    test "shows error for negative mass", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("input[name=mass]")
        |> render_keyup(%{"value" => "-100"})

      assert html =~ "Mass must be a positive number"
    end

    test "shows error for non-numeric mass", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("input[name=mass]")
        |> render_keyup(%{"value" => "abc"})

      assert html =~ "Please enter a valid number"
    end

    test "hides result when mass is cleared", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("input[name=mass]")
      |> render_keyup(%{"value" => "28801"})

      html =
        view
        |> element("input[name=mass]")
        |> render_keyup(%{"value" => ""})

      refute html =~ "Total Fuel Required"
    end
  end

  describe "flight path management" do
    test "adds a new step to the flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert view |> has_element?("span.badge", "4")
      refute view |> has_element?("span.badge", "5")

      view
      |> element("button", "Add Step")
      |> render_click()

      assert view |> has_element?("span.badge", "5")
    end

    test "removes a step from the flight path", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      assert view |> has_element?("span.badge", "4")

      [id | _] =
        Regex.scan(~r/name="step_id" value="([^"]+)"/, html, capture: :all_but_first)
        |> List.flatten()

      render_click(view, "remove_step", %{"id" => id})

      refute view |> has_element?("span.badge", "4")
    end

    test "updates step action", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      [id | _] =
        Regex.scan(~r/name="step_id" value="([^"]+)"/, html, capture: :all_but_first)
        |> List.flatten()

      render_change(view, "update_step", %{
        "step_id" => id,
        "action" => "land",
        "planet" => "earth"
      })

      assert has_element?(view, "select[name='action']")
    end

    test "updates step planet", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      [id | _] =
        Regex.scan(~r/name="step_id" value="([^"]+)"/, html, capture: :all_but_first)
        |> List.flatten()

      render_change(view, "update_step", %{
        "step_id" => id,
        "action" => "launch",
        "planet" => "mars"
      })

      assert has_element?(view, "select[name='planet']")
    end

    test "recalculates after updating step with mass set", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("input[name=mass]")
      |> render_keyup(%{"value" => "28801"})

      html = render(view)

      [id | _] =
        Regex.scan(~r/name="step_id" value="([^"]+)"/, html, capture: :all_but_first)
        |> List.flatten()

      html =
        render_change(view, "update_step", %{
          "step_id" => id,
          "action" => "launch",
          "planet" => "mars"
        })

      assert html =~ "Total Fuel Required"
    end

    test "shows zero mass error for mass 0", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("input[name=mass]")
        |> render_keyup(%{"value" => "0"})

      assert html =~ "Mass must be a positive number"
    end
  end

  describe "preset missions" do
    test "loads Apollo 11 preset", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "load_preset", %{"preset" => "apollo_11"})

      assert html =~ "51,898"
      assert html =~ "Total Fuel Required"
    end

    test "loads Mars Mission preset", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "load_preset", %{"preset" => "mars_mission"})

      assert html =~ "33,388"
    end

    test "loads Passenger Ship preset", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "load_preset", %{"preset" => "passenger_ship"})

      assert html =~ "212,161"
    end

    test "preset buttons are visible", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "button", "Apollo 11")
      assert has_element?(view, "button", "Mars Mission")
      assert has_element?(view, "button", "Passenger Ship")
    end
  end

  describe "fuel breakdown" do
    test "shows fuel breakdown table when mass is set", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "load_preset", %{"preset" => "apollo_11"})

      assert html =~ "Fuel Breakdown"
      assert html =~ "32,988"
      assert html =~ "2,462"
      assert html =~ "3,001"
      assert html =~ "13,447"
    end

    test "shows journey visualization when mass is set", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = render_click(view, "load_preset", %{"preset" => "apollo_11"})

      assert html =~ "Journey Visualization"
    end
  end

  describe "mission scenarios" do
    test "Apollo 11: full path produces 51,898 kg of fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        setup_flight_path(view, "28801", [
          {"launch", "earth"},
          {"land", "moon"},
          {"launch", "moon"},
          {"land", "earth"}
        ])

      assert html =~ "51,898"
    end

    test "Mars mission: full path produces 33,388 kg of fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        setup_flight_path(view, "14606", [
          {"launch", "earth"},
          {"land", "mars"},
          {"launch", "mars"},
          {"land", "earth"}
        ])

      assert html =~ "33,388"
    end

    test "Passenger ship: full path produces 212,161 kg of fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        setup_flight_path(view, "75432", [
          {"launch", "earth"},
          {"land", "moon"},
          {"launch", "moon"},
          {"land", "mars"},
          {"launch", "mars"},
          {"land", "earth"}
        ])

      assert html =~ "212,161"
    end
  end

  defp setup_flight_path(view, mass, steps) do
    view |> element("input[name=mass]") |> render_keyup(%{"value" => mass})

    default_steps = 4
    extra_steps = length(steps) - default_steps

    for _ <- 1..extra_steps//1 do
      view |> element("button", "Add Step") |> render_click()
    end

    step_ids = extract_step_ids(render(view))

    steps
    |> Enum.with_index()
    |> Enum.reduce(nil, fn {{action, planet}, index}, _acc ->
      render_change(view, "update_step", %{
        "step_id" => Enum.at(step_ids, index),
        "action" => action,
        "planet" => planet
      })
    end)
  end

  defp extract_step_ids(html) do
    Regex.scan(~r/name="step_id" value="([^"]+)"/, html, capture: :all_but_first)
    |> List.flatten()
  end
end
