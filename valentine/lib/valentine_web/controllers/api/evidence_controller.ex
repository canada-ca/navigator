defmodule ValentineWeb.Api.EvidenceController do
  use ValentineWeb, :controller

  alias Valentine.Composer

  def create(conn, %{"evidence" => evidence_params} = params) do
    api_key = conn.assigns[:api_key]
    workspace_id = api_key.workspace_id

    # Extract linking parameters
    linking_opts = %{
      assumption_id: get_in(params, ["linking", "assumption_id"]),
      threat_id: get_in(params, ["linking", "threat_id"]),
      mitigation_id: get_in(params, ["linking", "mitigation_id"]),
      use_ai: get_in(params, ["linking", "use_ai"]) || false
    }

    # Add workspace_id to evidence params
    evidence_attrs = Map.put(evidence_params, "workspace_id", workspace_id)

    case Composer.create_evidence_with_linking(evidence_attrs, linking_opts) do
      {:ok, evidence_with_associations} ->
        conn
        |> put_status(:created)
        |> json(%{
          evidence: evidence_with_associations,
          message: "Evidence created successfully"
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
