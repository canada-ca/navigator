defmodule Valentine.ThreatModelQualityReview.Generator do
  @moduledoc false

  import ReqLLM.Context

  alias Valentine.Composer.ThreatModelQualityReviewFinding

  @segments [
    %{
      id: :coverage,
      categories: [:duplicate_threat, :stride_gap, :informational],
      focus:
        "Review threat coverage quality. Look for materially overlapping threats and clear STRIDE coverage gaps.",
      max_findings: 3
    },
    %{
      id: :linkage,
      categories: [:orphaned_mitigation, :assumption_gap, :informational],
      focus:
        "Review linkage quality. Look for mitigations that are disconnected from threats or assumptions, and assumptions with unclear security impact or weak linkage.",
      max_findings: 3
    },
    %{
      id: :consistency,
      categories: [:artifact_contradiction, :informational],
      focus:
        "Review consistency across the workspace narrative. Look for contradictions between application information, architecture, data flow, threats, mitigations, assumptions, and evidence.",
      max_findings: 3
    }
  ]

  @severity_rank %{high: 0, medium: 1, low: 2, info: 3}
  @segment_rank @segments
                |> Enum.with_index()
                |> Map.new(fn {segment, index} -> {segment.id, index} end)

  defmodule ReviewResult do
    @enforce_keys [:findings]
    defstruct [:findings]
  end

  def review(snapshot, model_spec, opts) do
    findings =
      @segments
      |> Enum.flat_map(fn segment ->
        context =
          ReqLLM.Context.new([
            system(system_prompt(segment)),
            user(user_prompt(snapshot, segment))
          ])

        response =
          ReqLLM.generate_object!(model_spec, context, json_schema(segment), request_opts(opts))

        normalize_findings(response["findings"] || [], segment)
      end)
      |> dedupe_findings()
      |> merge_overlapping_findings()
      |> sort_findings()

    %ReviewResult{
      findings: findings
    }
  end

  defp system_prompt(segment) do
    category_list = Enum.map_join(segment.categories, ", ", &Atom.to_string/1)

    """
    You are an expert threat modeling reviewer. Review the provided Navigator workspace snapshot and identify only high-signal quality issues in the threat model itself.

    Requirements:
    - Keep the review diagnostic and read-only. Do not propose direct edits as if they have already been applied.
    - Focus on this segment only: #{segment.id}.
    - Allowed categories for this segment: #{category_list}.
    - Prefer fewer, higher-confidence findings over broad generic criticism.
    - Use severity values info, low, medium, or high.
    - A duplicate_threat finding should only be used when threats materially overlap in actor, action, impact, or assets.
    - A stride_gap finding should only be used when the workspace context strongly suggests a missing STRIDE category or materially weak coverage.
    - An orphaned_mitigation finding should only be used when a mitigation is not linked to any threat or assumption in a way that reduces review clarity.
    - An assumption_gap finding should only be used when an assumption appears security-relevant but has unclear linkage to threats, mitigations, or evidence.
    - An artifact_contradiction finding should only be used when architecture, DFD, threats, or related records tell materially inconsistent stories.
    - Use informational findings sparingly for low-confidence but notable gaps.
    - Each finding must include a concise title, clear rationale, and a suggested next action for a human reviewer.
    - If the workspace is sparse, prefer a small number of informational findings instead of overstated errors.
    - Return at most #{segment.max_findings} findings for this segment.
    """
  end

  defp user_prompt(snapshot, segment) do
    encoded_snapshot = Jason.encode!(segment_snapshot(snapshot, segment), pretty: true)

    """
    Review this Navigator workspace snapshot segment for threat model quality issues.

    Segment focus:
    #{segment.focus}

    Output instructions:
    - Return only findings grounded in the supplied workspace data.
    - If there are no actionable findings, return an empty findings array.
    - Use metadata to include any related record identifiers when helpful, such as threat IDs, mitigation IDs, assumption IDs, or DFD node IDs.
    - Do not emit categories outside this segment's allowed categories.

    Workspace snapshot:
    #{encoded_snapshot}
    """
  end

  defp json_schema(segment) do
    %{
      "type" => "object",
      "properties" => %{
        "findings" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "title" => %{"type" => "string"},
              "category" => %{
                "type" => "string",
                "enum" => Enum.map(segment.categories, &Atom.to_string/1)
              },
              "severity" => %{
                "type" => "string",
                "enum" =>
                  Enum.map(ThreatModelQualityReviewFinding.severities(), &Atom.to_string/1)
              },
              "rationale" => %{"type" => "string"},
              "suggested_action" => %{"type" => "string"},
              "metadata" => %{"type" => "object"}
            },
            "required" => [
              "title",
              "category",
              "severity",
              "rationale",
              "suggested_action",
              "metadata"
            ],
            "additionalProperties" => false
          }
        }
      },
      "required" => ["findings"],
      "additionalProperties" => false
    }
  end

  defp request_opts(opts) do
    Keyword.put_new(opts, :temperature, 0.0)
  end

  defp normalize_findings(findings, segment) do
    Enum.map(findings, fn finding ->
      category = normalize_category(finding["category"])

      metadata =
        finding["metadata"]
        |> normalize_metadata()
        |> Map.put_new("segment", Atom.to_string(segment.id))

      %{
        title: canonical_title(category, finding["title"] || "Untitled finding"),
        category: category,
        severity: normalize_severity(finding["severity"]),
        rationale: finding["rationale"] || "No rationale provided",
        suggested_action:
          canonical_suggested_action(
            category,
            finding["suggested_action"] || "Review the related records manually"
          ),
        metadata: metadata
      }
    end)
  end

  defp normalize_metadata(metadata) when is_map(metadata), do: metadata
  defp normalize_metadata(_metadata), do: %{}

  defp segment_snapshot(snapshot, %{id: :coverage}) do
    %{
      workspace: snapshot.workspace,
      application_information: snapshot.application_information,
      architecture: snapshot.architecture,
      dfd: snapshot.dfd,
      threats: snapshot.threats
    }
  end

  defp segment_snapshot(snapshot, %{id: :linkage}) do
    %{
      workspace: snapshot.workspace,
      threats: snapshot.threats,
      assumptions: snapshot.assumptions,
      mitigations: snapshot.mitigations,
      evidence: snapshot.evidence
    }
  end

  defp segment_snapshot(snapshot, %{id: :consistency}) do
    %{
      workspace: snapshot.workspace,
      application_information: snapshot.application_information,
      architecture: snapshot.architecture,
      dfd: snapshot.dfd,
      threats: snapshot.threats,
      assumptions: snapshot.assumptions,
      mitigations: snapshot.mitigations,
      evidence: snapshot.evidence
    }
  end

  defp dedupe_findings(findings) do
    findings
    |> Enum.reduce(%{}, fn finding, acc ->
      Map.put_new(acc, dedupe_key(finding), finding)
    end)
    |> Map.values()
  end

  defp dedupe_key(finding) do
    ids =
      finding.metadata
      |> Enum.filter(fn {key, value} -> String.ends_with?(key, "_ids") and is_list(value) end)
      |> Enum.sort_by(fn {key, _value} -> key end)
      |> Enum.flat_map(fn {key, value} -> [key | Enum.sort(value)] end)

    {
      finding.category,
      normalize_text(finding.title),
      normalize_text(finding.rationale),
      ids
    }
  end

  defp merge_overlapping_findings(findings) do
    findings
    |> Enum.group_by(&merge_key/1)
    |> Enum.map(fn {_key, grouped_findings} -> merge_group(grouped_findings) end)
  end

  defp merge_key(finding) do
    subject_signature = subject_signature(finding.metadata)

    {
      finding.category,
      if(subject_signature == [], do: normalize_text(finding.title), else: subject_signature)
    }
  end

  defp merge_group([finding]), do: finding

  defp merge_group(findings) do
    primary =
      findings
      |> Enum.sort_by(fn finding ->
        {
          Map.get(@severity_rank, finding.severity, 99),
          normalize_segment_rank(finding.metadata["segment"]),
          normalize_text(finding.title)
        }
      end)
      |> List.first()

    merged_segments =
      findings
      |> Enum.map(& &1.metadata["segment"])
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort_by(&normalize_segment_rank/1)

    %{
      primary
      | severity: highest_severity(findings),
        rationale: merge_rationales(findings),
        metadata:
          findings
          |> Enum.map(& &1.metadata)
          |> merge_metadata()
          |> Map.put("merged_count", length(findings))
          |> Map.put("segment", List.first(merged_segments))
          |> Map.put("merged_segments", merged_segments)
    }
  end

  defp highest_severity(findings) do
    findings
    |> Enum.min_by(&Map.get(@severity_rank, &1.severity, 99))
    |> Map.fetch!(:severity)
  end

  defp merge_rationales(findings) do
    findings
    |> Enum.map(& &1.rationale)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(&normalize_text/1)
    |> Enum.sort_by(&normalize_text/1)
    |> Enum.join(" ")
  end

  defp merge_metadata(metadata_list) do
    Enum.reduce(metadata_list, %{}, fn metadata, acc ->
      Enum.reduce(metadata, acc, fn {key, value}, inner_acc ->
        if key in ["segment", "merged_count", "merged_segments"] do
          inner_acc
        else
          Map.update(inner_acc, key, value, &merge_metadata_values(&1, value))
        end
      end)
    end)
  end

  defp merge_metadata_values(left, right) when is_list(left) or is_list(right) do
    left
    |> List.wrap()
    |> Kernel.++(List.wrap(right))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp merge_metadata_values(left, right) when left == right, do: left

  defp merge_metadata_values(left, right) do
    [left, right]
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp subject_signature(metadata) do
    metadata
    |> Enum.reject(fn {key, _value} -> key in ["segment", "merged_count", "merged_segments"] end)
    |> Enum.map(fn {key, value} -> {key, normalize_metadata_value(value)} end)
    |> Enum.reject(fn {_key, value} -> value in [nil, "", []] end)
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  defp normalize_metadata_value(value) when is_list(value) do
    value
    |> Enum.map(&normalize_scalar/1)
    |> Enum.sort()
  end

  defp normalize_metadata_value(value), do: normalize_scalar(value)

  defp normalize_scalar(value) when is_binary(value), do: normalize_text(value)

  defp normalize_scalar(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_text()

  defp normalize_scalar(value) when is_integer(value), do: Integer.to_string(value)
  defp normalize_scalar(value) when is_float(value), do: :erlang.float_to_binary(value)
  defp normalize_scalar(value), do: value

  defp sort_findings(findings) do
    Enum.sort_by(findings, fn finding ->
      segment = finding.metadata["segment"] |> normalize_segment_rank()

      {
        segment,
        Map.get(@severity_rank, finding.severity, 99),
        normalize_text(Atom.to_string(finding.category)),
        normalize_text(finding.title)
      }
    end)
  end

  defp normalize_segment_rank(nil), do: 99

  defp normalize_segment_rank(segment) when is_binary(segment) do
    segment
    |> String.to_existing_atom()
    |> then(&Map.get(@segment_rank, &1, 99))
  rescue
    ArgumentError -> 99
  end

  defp normalize_text(text) when is_binary(text) do
    text
    |> String.downcase()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp normalize_text(_text), do: ""

  defp canonical_title(:duplicate_threat, _fallback), do: "Potential duplicate threats"
  defp canonical_title(:stride_gap, _fallback), do: "Weak STRIDE coverage"
  defp canonical_title(:orphaned_mitigation, _fallback), do: "Orphaned mitigations"
  defp canonical_title(:assumption_gap, _fallback), do: "Assumptions with unclear risk linkage"
  defp canonical_title(:artifact_contradiction, _fallback), do: "Contradictory model artifacts"
  defp canonical_title(_category, fallback), do: fallback

  defp canonical_suggested_action(:duplicate_threat, _fallback),
    do: "Merge, rewrite, or remove overlapping threat statements."

  defp canonical_suggested_action(:stride_gap, _fallback),
    do: "Review the missing STRIDE areas and add or refine threat coverage."

  defp canonical_suggested_action(:orphaned_mitigation, _fallback),
    do:
      "Link the mitigation to the threats or assumptions it addresses, or remove it if it is out of scope."

  defp canonical_suggested_action(:assumption_gap, _fallback),
    do:
      "Clarify the assumption's risk impact and link it to related threats, mitigations, or evidence."

  defp canonical_suggested_action(:artifact_contradiction, _fallback),
    do: "Reconcile the conflicting workspace artifacts so they describe the same system behavior."

  defp canonical_suggested_action(_category, fallback), do: fallback

  defp normalize_category(value) when is_binary(value) do
    value
    |> String.to_existing_atom()
  rescue
    ArgumentError -> :informational
  end

  defp normalize_category(value) when is_atom(value), do: value
  defp normalize_category(_value), do: :informational

  defp normalize_severity(value) when is_binary(value) do
    value
    |> String.to_existing_atom()
  rescue
    ArgumentError -> :info
  end

  defp normalize_severity(value) when is_atom(value), do: value
  defp normalize_severity(_value), do: :info
end
