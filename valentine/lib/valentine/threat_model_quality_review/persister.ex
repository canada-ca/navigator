defmodule Valentine.ThreatModelQualityReview.Persister do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Valentine.Composer
  alias Valentine.Repo

  def persist(run_id, findings) do
    Multi.new()
    |> Multi.delete_all(
      :delete_existing_findings,
      from(finding in Valentine.Composer.ThreatModelQualityReviewFinding,
        where: finding.run_id == ^run_id
      )
    )
    |> add_findings(run_id, findings)
    |> Repo.transaction()
    |> case do
      {:ok, _changes} -> :ok
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp add_findings(multi, run_id, findings) do
    findings
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {finding, index}, acc ->
      Multi.insert(acc, {:finding, index}, fn _changes ->
        Composer.change_threat_model_quality_review_finding(
          %Valentine.Composer.ThreatModelQualityReviewFinding{},
          Map.merge(finding, %{run_id: run_id, display_order: index})
        )
      end)
    end)
  end
end
