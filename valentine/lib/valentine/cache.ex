defmodule Valentine.Cache do
  @moduledoc """
  Wrapper cache module for Valentine
  """

  def get(key) do
    case Cachex.get(:valentine, key) do
      {:ok, value} -> value
      {:error, _} -> nil
    end
  end

  def put(key, value, options \\ []) do
    case Cachex.put(:valentine, key, value, options) do
      {:ok, true} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def delete(key) do
    case Cachex.del(:valentine, key) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def clear do
    case Cachex.clear(:valentine) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
