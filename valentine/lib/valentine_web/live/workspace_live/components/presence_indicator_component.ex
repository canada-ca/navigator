defmodule ValentineWeb.WorkspaceLive.Components.PresenceIndicatorComponent do
  use Phoenix.Component
  use PrimerLive

  attr :active_module, :any, default: nil
  attr :current_user, :string, default: ""
  attr :presence, :map, default: %{}
  attr :workspace_id, :any, default: nil

  def render(assigns) do
    ~H"""
    <div class="presence-list">
      <ul>
        <%= for {{key, %{metas: metas}}, index} <- @presence |> Enum.with_index() do %>
          <li :if={is_active(hd(metas), @active_module, @workspace_id)} title={get_name(key, index)}>
            <.counter style={"color: #{get_colour(key)}; background-color: #{get_colour(key)}; #{get_border(key, @current_user)}"}>
              {index}
            </.counter>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  defp is_active(_, nil, nil), do: true

  defp is_active(%{workspace_id: workspace_id}, nil, workspace),
    do: workspace_id == workspace

  defp is_active(%{module: module, workspace_id: workspace_id}, active_module, workspace)
       when is_list(active_module),
       do: module in active_module && workspace_id == workspace

  defp is_active(%{module: module, workspace_id: workspace_id}, active_module, workspace),
    do: module == active_module && workspace_id == workspace

  defp get_border(key, user_id) do
    if key == user_id do
      "border: 2px solid #fff;"
    else
      ""
    end
  end

  defp get_colour(id) do
    id
    |> String.downcase()
    |> hash_string()
    |> hash_to_hsl()
    |> hsl_to_rgb()
    |> rgb_to_hex()
  end

  defp get_name("||" <> _key, index) do
    [
      "Adventurous Ant",
      "Bashful Bumblebee",
      "Clever Caterpillar",
      "Daring Dragonfly",
      "Eager Earwig",
      "Friendly Firefly",
      "Gentle Grasshopper",
      "Happy Hornet",
      "Inquisitive Inchworm",
      "Jolly Junebug",
      "Kindly Katydid",
      "Lively Ladybug",
      "Merry Mosquito",
      "Nice Nematode"
    ]
    |> Enum.at(index)
  end

  defp get_name(key, _index), do: key

  defp hash_string(str) do
    str
    |> String.to_charlist()
    |> Enum.reduce(0, fn char, acc ->
      # Similar to Java's string hash function
      rem(acc * 31 + char, 2_147_483_647)
    end)
    |> abs()
  end

  defp hash_to_hsl(hash) do
    # Hue: 0-360 degrees
    hue = rem(hash, 360)
    # Saturation: 60-90%
    saturation = 60 + rem(hash, 30)
    # Lightness: 45-65%
    lightness = 45 + rem(hash, 20)

    {hue, saturation, lightness}
  end

  defp hsl_to_rgb({h, s, l}) do
    s = s / 100
    l = l / 100

    chroma = (1 - abs(2 * l - 1)) * s
    x = chroma * (1 - abs(rem(trunc(h / 60), 2) - 1))
    m = l - chroma / 2

    {r1, g1, b1} = get_rgb_components(h, chroma, x)

    r = round((r1 + m) * 255)
    g = round((g1 + m) * 255)
    b = round((b1 + m) * 255)

    {r, g, b}
  end

  defp get_rgb_components(h, c, x) when h < 60, do: {c, x, 0}
  defp get_rgb_components(h, c, x) when h < 120, do: {x, c, 0}
  defp get_rgb_components(h, c, x) when h < 180, do: {0, c, x}
  defp get_rgb_components(h, c, x) when h < 240, do: {0, x, c}
  defp get_rgb_components(h, c, x) when h < 300, do: {x, 0, c}
  defp get_rgb_components(_, c, x), do: {c, 0, x}

  def rgb_to_hex({r, g, b}) do
    "##{to_hex(r)}#{to_hex(g)}#{to_hex(b)}"
  end

  defp to_hex(n) do
    n
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
    |> String.upcase()
  end
end
