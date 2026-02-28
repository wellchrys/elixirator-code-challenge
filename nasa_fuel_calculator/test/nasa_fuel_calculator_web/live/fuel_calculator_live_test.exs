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

    test "starts with two default flight steps", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Launch"
      assert html =~ "Land"
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

      assert view |> has_element?("span.badge", "2")
      refute view |> has_element?("span.badge", "3")

      view
      |> element("button", "Add Step")
      |> render_click()

      assert view |> has_element?("span.badge", "3")
    end

    test "removes a step from the flight path", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      assert view |> has_element?("span.badge", "2")

      [id | _] =
        Regex.scan(~r/name="step_id" value="([^"]+)"/, html, capture: :all_but_first)
        |> List.flatten()

      render_click(view, "remove_step", %{"id" => id})

      refute view |> has_element?("span.badge", "2")
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

  describe "mission scenarios" do
    test "Apollo 11: full path produces 51,898 kg of fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("input[name=mass]") |> render_keyup(%{"value" => "28801"})

      # Add steps 3 and 4 (defaults to Launch Earth)
      view |> element("button", "Add Step") |> render_click()
      view |> element("button", "Add Step") |> render_click()

      step_ids = extract_step_ids(render(view))

      # Step 1: Launch Earth (already default)
      # Step 2: Land Moon (already default)
      # Step 3: Launch Moon
      render_change(view, "update_step", %{
        "step_id" => Enum.at(step_ids, 2),
        "action" => "launch",
        "planet" => "moon"
      })

      # Step 4: Land Earth
      html =
        render_change(view, "update_step", %{
          "step_id" => Enum.at(step_ids, 3),
          "action" => "land",
          "planet" => "earth"
        })

      assert html =~ "51,898"
    end

    test "Mars mission: full path produces 33,388 kg of fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("input[name=mass]") |> render_keyup(%{"value" => "14606"})

      view |> element("button", "Add Step") |> render_click()
      view |> element("button", "Add Step") |> render_click()

      step_ids = extract_step_ids(render(view))

      # Step 2: Land Mars
      render_change(view, "update_step", %{
        "step_id" => Enum.at(step_ids, 1),
        "action" => "land",
        "planet" => "mars"
      })

      # Step 3: Launch Mars
      render_change(view, "update_step", %{
        "step_id" => Enum.at(step_ids, 2),
        "action" => "launch",
        "planet" => "mars"
      })

      # Step 4: Land Earth
      html =
        render_change(view, "update_step", %{
          "step_id" => Enum.at(step_ids, 3),
          "action" => "land",
          "planet" => "earth"
        })

      assert html =~ "33,388"
    end

    test "Passenger ship: full path produces 212,161 kg of fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("input[name=mass]") |> render_keyup(%{"value" => "75432"})

      # Add steps 3 through 6
      view |> element("button", "Add Step") |> render_click()
      view |> element("button", "Add Step") |> render_click()
      view |> element("button", "Add Step") |> render_click()
      view |> element("button", "Add Step") |> render_click()

      step_ids = extract_step_ids(render(view))

      # Step 3: Launch Moon
      render_change(view, "update_step", %{
        "step_id" => Enum.at(step_ids, 2),
        "action" => "launch",
        "planet" => "moon"
      })

      # Step 4: Land Mars
      render_change(view, "update_step", %{
        "step_id" => Enum.at(step_ids, 3),
        "action" => "land",
        "planet" => "mars"
      })

      # Step 5: Launch Mars
      render_change(view, "update_step", %{
        "step_id" => Enum.at(step_ids, 4),
        "action" => "launch",
        "planet" => "mars"
      })

      # Step 6: Land Earth
      html =
        render_change(view, "update_step", %{
          "step_id" => Enum.at(step_ids, 5),
          "action" => "land",
          "planet" => "earth"
        })

      assert html =~ "212,161"
    end
  end

  defp extract_step_ids(html) do
    Regex.scan(~r/name="step_id" value="([^"]+)"/, html, capture: :all_but_first)
    |> List.flatten()
  end
end
