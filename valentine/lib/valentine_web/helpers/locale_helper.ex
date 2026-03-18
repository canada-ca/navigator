defmodule ValentineWeb.Helpers.LocaleHelper do
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, params, session, socket) do
    locale =
      params["locale"] || Valentine.Cache.get({socket.id, :locale}) || session["locale"] || "en"

    Gettext.put_locale(ValentineWeb.Gettext, locale)

    {:cont,
     socket
     |> attach_hook(:locale, :handle_event, &maybe_receive_locale/3)
     |> maybe_attach_current_path_hook()
     |> assign(:locale, locale)}
  end

  defp maybe_receive_locale("change_locale", %{"locale" => locale}, socket) do
    Valentine.Cache.put({socket.id, :locale}, locale, expire: :timer.hours(48))
    Gettext.put_locale(ValentineWeb.Gettext, locale)

    socket =
      socket
      |> assign(:locale, locale)
      |> push_event("session", %{locale: locale})

    case localized_path(socket.assigns[:current_path], locale) do
      nil -> {:halt, socket}
      path -> {:halt, redirect(socket, to: path)}
    end
  end

  defp maybe_receive_locale(_, _, socket), do: {:cont, socket}

  defp maybe_attach_current_path_hook(socket) do
    attach_hook(socket, :locale_current_path, :handle_params, &store_current_path/3)
  rescue
    RuntimeError -> socket
  end

  defp store_current_path(_params, url, socket) do
    locale = locale_from_path(url) || socket.assigns[:locale] || "en"
    Gettext.put_locale(ValentineWeb.Gettext, locale)

    {:cont,
     socket
     |> assign(:locale, locale)
     |> assign(:current_path, current_path(url))}
  end

  defp current_path(nil), do: nil

  defp current_path(url) do
    uri = URI.parse(url)

    case {uri.path, uri.query} do
      {nil, _} -> nil
      {path, nil} -> path
      {path, query} -> path <> "?" <> query
    end
  end

  defp locale_from_path(nil), do: nil

  defp locale_from_path(path) do
    path
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> nil
      query -> URI.decode_query(query)["locale"]
    end
  end

  defp localized_path(nil, _locale), do: nil

  defp localized_path(path, locale) do
    uri = URI.parse(path)
    query = URI.decode_query(uri.query || "") |> Map.put("locale", locale)
    query_string = URI.encode_query(query)

    case {uri.path, query_string} do
      {nil, _} -> nil
      {clean_path, ""} -> clean_path
      {clean_path, encoded_query} -> clean_path <> "?" <> encoded_query
    end
  end
end
