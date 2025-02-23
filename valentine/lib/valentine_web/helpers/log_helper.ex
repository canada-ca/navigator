defmodule ValentineWeb.Helpers.LogHelper do
  require Logger

  def log(level, actor, action, target, type) do
    Logger.log(level, %{actor: actor, action: action, target: target, type: type})
  end
end
