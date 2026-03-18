defmodule ValentineWeb.Helpers.LocaleHelperTest do
  use ValentineWeb.ConnCase

  alias ValentineWeb.Helpers.LocaleHelper

  setup do
    socket = %Phoenix.LiveView.Socket{
      private: %{
        live_temp: %{},
        lifecycle: %{handle_event: []}
      }
    }

    %{socket: socket}
  end

  describe "on_mount/4" do
    test "sets the locale from parameters", %{socket: socket} do
      {:cont, socket} = LocaleHelper.on_mount(:default, %{"locale" => "de"}, %{}, socket)

      assert socket.assigns.locale == "de"
    end

    test "sets the locale from session", %{socket: socket} do
      {:cont, socket} = LocaleHelper.on_mount(:default, %{}, %{"locale" => "de"}, socket)

      assert socket.assigns.locale == "de"
    end

    test "does not set a locale if none is provided", %{socket: socket} do
      {:cont, socket} = LocaleHelper.on_mount(:default, %{}, %{}, socket)

      assert socket.assigns.locale == "en"
    end
  end
end
