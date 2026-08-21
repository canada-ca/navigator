defmodule Valentine.Composer do
  @moduledoc """
  Compatibility facade for Composer domain capabilities.

  Existing callers can continue using this module. New code may depend on a
  capability-focused module under `Valentine.Composer` when a narrower
  dependency makes ownership clearer.
  """

  defdelegate add_assumption_to_evidence(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate add_assumption_to_mitigation(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate add_assumption_to_threat(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate add_mitigation_to_assumption(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate add_mitigation_to_evidence(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate add_mitigation_to_threat(arg1, arg2), to: Valentine.Composer.Relationships

  defdelegate add_reference_pack_item_to_workspace(arg1, arg2),
    to: Valentine.Composer.ReferencePacks

  defdelegate add_threat_to_assumption(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate add_threat_to_evidence(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate add_threat_to_mitigation(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate apply_evidence_linking(arg1, arg2), to: Valentine.Composer.EvidenceManagement
  defdelegate assign_to_cluster(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate change_api_key(arg1), to: Valentine.Composer.ApiKeys
  defdelegate change_api_key(arg1, arg2), to: Valentine.Composer.ApiKeys
  defdelegate change_application_information(arg1), to: Valentine.Composer.Documents
  defdelegate change_application_information(arg1, arg2), to: Valentine.Composer.Documents
  defdelegate change_architecture(arg1), to: Valentine.Composer.Documents
  defdelegate change_architecture(arg1, arg2), to: Valentine.Composer.Documents
  defdelegate change_assumption(arg1), to: Valentine.Composer.Assumptions
  defdelegate change_assumption(arg1, arg2), to: Valentine.Composer.Assumptions
  defdelegate change_brainstorm_item(arg1), to: Valentine.Composer.Brainstorm
  defdelegate change_brainstorm_item(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate change_control(arg1), to: Valentine.Composer.Controls
  defdelegate change_control(arg1, arg2), to: Valentine.Composer.Controls
  defdelegate change_data_flow_diagram(arg1), to: Valentine.Composer.Documents
  defdelegate change_data_flow_diagram(arg1, arg2), to: Valentine.Composer.Documents
  defdelegate change_evidence(arg1), to: Valentine.Composer.EvidenceManagement
  defdelegate change_evidence(arg1, arg2), to: Valentine.Composer.EvidenceManagement
  defdelegate change_mitigation(arg1), to: Valentine.Composer.Mitigations
  defdelegate change_mitigation(arg1, arg2), to: Valentine.Composer.Mitigations
  defdelegate change_reference_pack_item(arg1), to: Valentine.Composer.ReferencePacks
  defdelegate change_reference_pack_item(arg1, arg2), to: Valentine.Composer.ReferencePacks
  defdelegate change_repo_analysis_agent(arg1), to: Valentine.Composer.AnalysisJobs
  defdelegate change_repo_analysis_agent(arg1, arg2), to: Valentine.Composer.AnalysisJobs
  defdelegate change_threat(arg1), to: Valentine.Composer.Threats
  defdelegate change_threat(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate change_threat_agent(arg1), to: Valentine.Composer.Threats
  defdelegate change_threat_agent(arg1, arg2), to: Valentine.Composer.Threats

  defdelegate change_threat_model_quality_review_finding(arg1),
    to: Valentine.Composer.AnalysisJobs

  defdelegate change_threat_model_quality_review_finding(arg1, arg2),
    to: Valentine.Composer.AnalysisJobs

  defdelegate change_threat_model_quality_review_run(arg1), to: Valentine.Composer.AnalysisJobs

  defdelegate change_threat_model_quality_review_run(arg1, arg2),
    to: Valentine.Composer.AnalysisJobs

  defdelegate change_user(arg1), to: Valentine.Composer.Users
  defdelegate change_user(arg1, arg2), to: Valentine.Composer.Users
  defdelegate change_workspace(arg1), to: Valentine.Composer.Workspaces
  defdelegate change_workspace(arg1, arg2), to: Valentine.Composer.Workspaces
  defdelegate check_workspace_permissions(arg1, arg2), to: Valentine.Composer.Workspaces
  defdelegate create_api_key(), to: Valentine.Composer.ApiKeys
  defdelegate create_api_key(arg1), to: Valentine.Composer.ApiKeys
  defdelegate create_api_key_for_workspace(arg1, arg2, arg3), to: Valentine.Composer.ApiKeys
  defdelegate create_application_information(), to: Valentine.Composer.Documents
  defdelegate create_application_information(arg1), to: Valentine.Composer.Documents
  defdelegate create_architecture(), to: Valentine.Composer.Documents
  defdelegate create_architecture(arg1), to: Valentine.Composer.Documents
  defdelegate create_assumption(), to: Valentine.Composer.Assumptions
  defdelegate create_assumption(arg1), to: Valentine.Composer.Assumptions
  defdelegate create_brainstorm_item(), to: Valentine.Composer.Brainstorm
  defdelegate create_brainstorm_item(arg1), to: Valentine.Composer.Brainstorm
  defdelegate create_control(), to: Valentine.Composer.Controls
  defdelegate create_control(arg1), to: Valentine.Composer.Controls
  defdelegate create_data_flow_diagram(), to: Valentine.Composer.Documents
  defdelegate create_data_flow_diagram(arg1), to: Valentine.Composer.Documents
  defdelegate create_evidence(), to: Valentine.Composer.EvidenceManagement
  defdelegate create_evidence(arg1), to: Valentine.Composer.EvidenceManagement
  defdelegate create_evidence_with_linking(arg1), to: Valentine.Composer.EvidenceManagement
  defdelegate create_evidence_with_linking(arg1, arg2), to: Valentine.Composer.EvidenceManagement
  defdelegate create_mitigation(), to: Valentine.Composer.Mitigations
  defdelegate create_mitigation(arg1), to: Valentine.Composer.Mitigations
  defdelegate create_reference_pack_item(), to: Valentine.Composer.ReferencePacks
  defdelegate create_reference_pack_item(arg1), to: Valentine.Composer.ReferencePacks
  defdelegate create_repo_analysis_agent(), to: Valentine.Composer.AnalysisJobs
  defdelegate create_repo_analysis_agent(arg1), to: Valentine.Composer.AnalysisJobs
  defdelegate create_threat(), to: Valentine.Composer.Threats
  defdelegate create_threat(arg1), to: Valentine.Composer.Threats
  defdelegate create_threat_agent(), to: Valentine.Composer.Threats
  defdelegate create_threat_agent(arg1), to: Valentine.Composer.Threats
  defdelegate create_threat_model_quality_review_finding(), to: Valentine.Composer.AnalysisJobs

  defdelegate create_threat_model_quality_review_finding(arg1),
    to: Valentine.Composer.AnalysisJobs

  defdelegate create_threat_model_quality_review_run(), to: Valentine.Composer.AnalysisJobs
  defdelegate create_threat_model_quality_review_run(arg1), to: Valentine.Composer.AnalysisJobs
  defdelegate create_user(), to: Valentine.Composer.Users
  defdelegate create_user(arg1), to: Valentine.Composer.Users
  defdelegate create_workspace(), to: Valentine.Composer.Workspaces
  defdelegate create_workspace(arg1), to: Valentine.Composer.Workspaces
  defdelegate delete_api_key(arg1), to: Valentine.Composer.ApiKeys
  defdelegate delete_application_information(arg1), to: Valentine.Composer.Documents
  defdelegate delete_architecture(arg1), to: Valentine.Composer.Documents
  defdelegate delete_assumption(arg1), to: Valentine.Composer.Assumptions
  defdelegate delete_brainstorm_item(arg1), to: Valentine.Composer.Brainstorm
  defdelegate delete_control(arg1), to: Valentine.Composer.Controls
  defdelegate delete_data_flow_diagram(arg1), to: Valentine.Composer.Documents
  defdelegate delete_evidence(arg1), to: Valentine.Composer.EvidenceManagement
  defdelegate delete_mitigation(arg1), to: Valentine.Composer.Mitigations
  defdelegate delete_reference_pack_collection(arg1, arg2), to: Valentine.Composer.ReferencePacks
  defdelegate delete_reference_pack_item(arg1), to: Valentine.Composer.ReferencePacks
  defdelegate delete_threat(arg1), to: Valentine.Composer.Threats
  defdelegate delete_threat_agent(arg1), to: Valentine.Composer.Threats

  defdelegate delete_threat_model_quality_review_findings_for_run(arg1),
    to: Valentine.Composer.AnalysisJobs

  defdelegate delete_threat_model_quality_review_run(arg1), to: Valentine.Composer.AnalysisJobs
  defdelegate delete_user(arg1), to: Valentine.Composer.Users
  defdelegate delete_workspace(arg1), to: Valentine.Composer.Workspaces
  defdelegate get_api_key(arg1), to: Valentine.Composer.ApiKeys
  defdelegate get_api_key_for_workspace(arg1, arg2), to: Valentine.Composer.ApiKeys
  defdelegate get_application_information!(arg1), to: Valentine.Composer.Documents
  defdelegate get_architecture!(arg1), to: Valentine.Composer.Documents
  defdelegate get_assumption!(arg1), to: Valentine.Composer.Assumptions
  defdelegate get_assumption!(arg1, arg2), to: Valentine.Composer.Assumptions
  defdelegate get_assumption_for_workspace(arg1, arg2), to: Valentine.Composer.Assumptions
  defdelegate get_assumption_for_workspace(arg1, arg2, arg3), to: Valentine.Composer.Assumptions
  defdelegate get_assumption_for_workspace!(arg1, arg2), to: Valentine.Composer.Assumptions
  defdelegate get_assumption_for_workspace!(arg1, arg2, arg3), to: Valentine.Composer.Assumptions
  defdelegate get_brainstorm_item(arg1), to: Valentine.Composer.Brainstorm
  defdelegate get_brainstorm_item(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate get_brainstorm_item!(arg1), to: Valentine.Composer.Brainstorm
  defdelegate get_brainstorm_item!(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate get_control!(arg1), to: Valentine.Composer.Controls
  defdelegate get_control_by_nist_id(arg1), to: Valentine.Composer.Controls
  defdelegate get_data_flow_diagram!(arg1), to: Valentine.Composer.Documents
  defdelegate get_data_flow_diagram_by_workspace_id(arg1), to: Valentine.Composer.Documents
  defdelegate get_evidence!(arg1), to: Valentine.Composer.EvidenceManagement
  defdelegate get_evidence!(arg1, arg2), to: Valentine.Composer.EvidenceManagement
  defdelegate get_evidence_for_workspace(arg1, arg2), to: Valentine.Composer.EvidenceManagement

  defdelegate get_evidence_for_workspace(arg1, arg2, arg3),
    to: Valentine.Composer.EvidenceManagement

  defdelegate get_evidence_for_workspace!(arg1, arg2), to: Valentine.Composer.EvidenceManagement

  defdelegate get_evidence_for_workspace!(arg1, arg2, arg3),
    to: Valentine.Composer.EvidenceManagement

  defdelegate get_funnel_metrics(arg1), to: Valentine.Composer.Brainstorm
  defdelegate get_mitigation!(arg1), to: Valentine.Composer.Mitigations
  defdelegate get_mitigation!(arg1, arg2), to: Valentine.Composer.Mitigations
  defdelegate get_mitigation_for_workspace(arg1, arg2), to: Valentine.Composer.Mitigations
  defdelegate get_mitigation_for_workspace(arg1, arg2, arg3), to: Valentine.Composer.Mitigations
  defdelegate get_mitigation_for_workspace!(arg1, arg2), to: Valentine.Composer.Mitigations
  defdelegate get_mitigation_for_workspace!(arg1, arg2, arg3), to: Valentine.Composer.Mitigations
  defdelegate get_reference_pack_item!(arg1), to: Valentine.Composer.ReferencePacks
  defdelegate get_repo_analysis_agent!(arg1), to: Valentine.Composer.AnalysisJobs
  defdelegate get_repo_analysis_agent!(arg1, arg2), to: Valentine.Composer.AnalysisJobs
  defdelegate get_repo_analysis_agent_for_owner(arg1, arg2), to: Valentine.Composer.AnalysisJobs

  defdelegate get_repo_analysis_agent_for_owner(arg1, arg2, arg3),
    to: Valentine.Composer.AnalysisJobs

  defdelegate get_threat!(arg1), to: Valentine.Composer.Threats
  defdelegate get_threat!(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate get_threat_agent!(arg1), to: Valentine.Composer.Threats
  defdelegate get_threat_agent!(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate get_threat_agent_for_workspace(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate get_threat_agent_for_workspace(arg1, arg2, arg3), to: Valentine.Composer.Threats
  defdelegate get_threat_agent_for_workspace!(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate get_threat_agent_for_workspace!(arg1, arg2, arg3), to: Valentine.Composer.Threats
  defdelegate get_threat_for_workspace(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate get_threat_for_workspace(arg1, arg2, arg3), to: Valentine.Composer.Threats
  defdelegate get_threat_for_workspace!(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate get_threat_for_workspace!(arg1, arg2, arg3), to: Valentine.Composer.Threats
  defdelegate get_threat_model_quality_review_run!(arg1), to: Valentine.Composer.AnalysisJobs

  defdelegate get_threat_model_quality_review_run!(arg1, arg2),
    to: Valentine.Composer.AnalysisJobs

  defdelegate get_threat_model_quality_review_run_for_owner(arg1, arg2),
    to: Valentine.Composer.AnalysisJobs

  defdelegate get_threat_model_quality_review_run_for_owner(arg1, arg2, arg3),
    to: Valentine.Composer.AnalysisJobs

  defdelegate get_threat_model_quality_review_run_for_workspace!(arg1, arg2),
    to: Valentine.Composer.AnalysisJobs

  defdelegate get_threat_model_quality_review_run_for_workspace!(arg1, arg2, arg3),
    to: Valentine.Composer.AnalysisJobs

  defdelegate get_type_metrics(arg1), to: Valentine.Composer.Brainstorm
  defdelegate get_user(arg1), to: Valentine.Composer.Users
  defdelegate get_workspace!(arg1), to: Valentine.Composer.Workspaces
  defdelegate get_workspace!(arg1, arg2), to: Valentine.Composer.Workspaces
  defdelegate list_api_keys(), to: Valentine.Composer.ApiKeys
  defdelegate list_api_keys_by_workspace(arg1), to: Valentine.Composer.ApiKeys
  defdelegate list_application_informations(), to: Valentine.Composer.Documents
  defdelegate list_architectures(), to: Valentine.Composer.Documents
  defdelegate list_assembly_candidates(arg1), to: Valentine.Composer.Brainstorm
  defdelegate list_assembly_candidates(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate list_assumptions(), to: Valentine.Composer.Assumptions
  defdelegate list_assumptions_by_workspace(arg1), to: Valentine.Composer.Assumptions
  defdelegate list_assumptions_by_workspace(arg1, arg2), to: Valentine.Composer.Assumptions
  defdelegate list_assumptions_with_enum_filters(arg1, arg2), to: Valentine.Composer.Assumptions
  defdelegate list_backlog_items(arg1), to: Valentine.Composer.Brainstorm
  defdelegate list_brainstorm_items(arg1), to: Valentine.Composer.Brainstorm
  defdelegate list_brainstorm_items(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate list_brainstorm_items_by_type(arg1), to: Valentine.Composer.Brainstorm
  defdelegate list_brainstorm_items_by_type(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate list_cluster_items(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate list_clusters_by_type(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate list_control_families(), to: Valentine.Composer.Controls
  defdelegate list_controls(), to: Valentine.Composer.Controls
  defdelegate list_controls_by_filters(arg1), to: Valentine.Composer.Controls
  defdelegate list_controls_in_families(arg1), to: Valentine.Composer.Controls
  defdelegate list_data_flow_diagrams(), to: Valentine.Composer.Documents
  defdelegate list_evidence(arg1), to: Valentine.Composer.EvidenceManagement
  defdelegate list_mitigations(), to: Valentine.Composer.Mitigations
  defdelegate list_mitigations_by_workspace(arg1), to: Valentine.Composer.Mitigations
  defdelegate list_mitigations_by_workspace(arg1, arg2), to: Valentine.Composer.Mitigations
  defdelegate list_mitigations_with_enum_filters(arg1, arg2), to: Valentine.Composer.Mitigations
  defdelegate list_reference_pack_items(), to: Valentine.Composer.ReferencePacks

  defdelegate list_reference_pack_items_by_collection(arg1, arg2),
    to: Valentine.Composer.ReferencePacks

  defdelegate list_reference_packs(), to: Valentine.Composer.ReferencePacks
  defdelegate list_repo_analysis_agents_by_owner(arg1), to: Valentine.Composer.AnalysisJobs
  defdelegate list_repo_analysis_agents_by_workspace(arg1), to: Valentine.Composer.AnalysisJobs
  defdelegate list_threat_agents(arg1), to: Valentine.Composer.Threats

  defdelegate list_threat_model_quality_review_findings_by_run(arg1),
    to: Valentine.Composer.AnalysisJobs

  defdelegate list_threat_model_quality_review_runs_by_owner(arg1),
    to: Valentine.Composer.AnalysisJobs

  defdelegate list_threat_model_quality_review_runs_by_workspace(arg1),
    to: Valentine.Composer.AnalysisJobs

  defdelegate list_threats(), to: Valentine.Composer.Threats
  defdelegate list_threats_by_ids(arg1), to: Valentine.Composer.Threats
  defdelegate list_threats_by_workspace(arg1), to: Valentine.Composer.Threats
  defdelegate list_threats_by_workspace(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate list_threats_with_enum_filters(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate list_users(), to: Valentine.Composer.Users
  defdelegate list_workspaces(), to: Valentine.Composer.Workspaces
  defdelegate list_workspaces_by_identity(arg1), to: Valentine.Composer.Workspaces
  defdelegate mark_used_in_threat(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate remove_assumption_from_evidence(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate remove_assumption_from_mitigation(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate remove_assumption_from_threat(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate remove_mitigation_from_assumption(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate remove_mitigation_from_evidence(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate remove_mitigation_from_threat(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate remove_threat_from_assumption(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate remove_threat_from_evidence(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate remove_threat_from_mitigation(arg1, arg2), to: Valentine.Composer.Relationships
  defdelegate request_repo_analysis_agent_cancel(arg1), to: Valentine.Composer.AnalysisJobs

  defdelegate request_threat_model_quality_review_run_cancel(arg1),
    to: Valentine.Composer.AnalysisJobs

  defdelegate sort_hierarchical_strings(arg1, arg2), to: Valentine.Composer.Controls
  defdelegate unmark_used_in_threat(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate update_api_key(arg1, arg2), to: Valentine.Composer.ApiKeys
  defdelegate update_application_information(arg1, arg2), to: Valentine.Composer.Documents
  defdelegate update_architecture(arg1, arg2), to: Valentine.Composer.Documents
  defdelegate update_assumption(arg1, arg2), to: Valentine.Composer.Assumptions
  defdelegate update_brainstorm_item(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate update_control(arg1, arg2), to: Valentine.Composer.Controls
  defdelegate update_data_flow_diagram(arg1, arg2), to: Valentine.Composer.Documents
  defdelegate update_evidence(arg1, arg2), to: Valentine.Composer.EvidenceManagement
  defdelegate update_mitigation(arg1, arg2), to: Valentine.Composer.Mitigations
  defdelegate update_position(arg1, arg2), to: Valentine.Composer.Brainstorm
  defdelegate update_reference_pack_item(arg1, arg2), to: Valentine.Composer.ReferencePacks
  defdelegate update_repo_analysis_agent(arg1, arg2), to: Valentine.Composer.AnalysisJobs
  defdelegate update_threat(arg1, arg2), to: Valentine.Composer.Threats
  defdelegate update_threat_agent(arg1, arg2), to: Valentine.Composer.Threats

  defdelegate update_threat_model_quality_review_run(arg1, arg2),
    to: Valentine.Composer.AnalysisJobs

  defdelegate update_user(arg1, arg2), to: Valentine.Composer.Users
  defdelegate update_workspace(arg1, arg2), to: Valentine.Composer.Workspaces
  defdelegate update_workspace_permissions(arg1, arg2, arg3), to: Valentine.Composer.Workspaces
end
