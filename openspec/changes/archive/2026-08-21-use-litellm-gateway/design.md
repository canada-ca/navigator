## Context

`Valentine.AIProvider` is the shared configuration boundary for chat, control categorization, threat generation, repository analysis, and threat-model quality review. It currently selects either an OpenAI model spec or an Azure model spec and translates multiple provider-specific environment variables into ReqLLM request options. OpenAI-compatible gateways such as LiteLLM centralize upstream credentials and routing, so Navigator no longer needs direct-provider selection or vendor-specific gateway variable names.

The change affects runtime configuration, a shared provider module, one diagnostic log line, tests, Docker Compose, and setup documentation. It does not affect schemas, routes, exports, permissions, or real-time collaboration.

## Goals / Non-Goals

**Goals:**

- Send all Navigator AI traffic to the configured OpenAI-compatible gateway base URL.
- Authenticate only with the configured AI gateway key.
- Allow any gateway model alias, including aliases absent from ReqLLM's bundled model catalog.
- Fail locally before an AI request when gateway URL or key configuration is missing, preventing accidental fallback to the public OpenAI endpoint.
- Preserve existing maximum-token and per-call option behavior.

**Non-Goals:**

- Provisioning the gateway, managing its keys, or defining its upstream providers and routing rules.
- Supporting direct OpenAI or Azure OpenAI credentials alongside the gateway.
- Changing workspace API keys, application authentication, authorization, database schemas, routes, exports, or LiveView collaboration semantics.

## Decisions

1. **Use ReqLLM's OpenAI provider with per-request `base_url` and `api_key`.** LiteLLM and similar gateways implement the OpenAI protocol, and ReqLLM documents custom `base_url` as the supported path for OpenAI-compatible services. This avoids a new provider module or dependency. A gateway-specific ReqLLM provider was considered but would duplicate protocol behavior without adding product value.

2. **Store gateway settings under `config :req_llm, :ai_gateway`.** `valentine/config/runtime.exs` will load `AI_BASE_URL` and `AI_API_KEY` into one keyword list and load the alias from `AI_MODEL`, defaulting to `openai-gpt-5.6-luna`. The vendor-neutral names allow compatible gateways to replace LiteLLM without another application configuration migration. Keeping the gateway contract grouped prevents old direct-provider settings from participating in selection.

3. **Represent the model as `%{provider: :openai, id: alias}`.** ReqLLM accepts a model map to bypass catalog lookup. This is necessary because gateway aliases are deployment-defined and may not exist in ReqLLM's static model catalog. The affected quality-review diagnostic will inspect rather than interpolate the model value.

4. **Validate gateway URL and key lazily in `Valentine.AIProvider.request_opts/2`.** AI functionality is optional, so application startup remains available without gateway configuration. When an AI workflow is invoked, missing configuration raises a targeted error before ReqLLM can fall back to its public OpenAI defaults or ambient `OPENAI_API_KEY` values.

5. **Replace rather than deprecate the old runtime contract.** Supporting both configurations would preserve ambiguity about whether requests bypass the gateway. Rollback is performed by deploying the previous Navigator release, not by toggling provider selection in this version.

## Risks / Trade-offs

- [Gateway outage becomes a single point of failure for AI features] → Navigator's non-AI workflows remain available, while AI request failures continue through existing workflow error handling.
- [A configured alias may not support structured output or tools] → Operators must map `AI_MODEL` to a compatible route; Navigator continues sending the same structured-output requests it sends today.
- [Base URLs without the OpenAI-compatible path fail] → Documentation requires the full proxy API base URL, normally ending in `/v1`, and tests verify the value is passed through unchanged apart from removing trailing slashes.
- [Removing direct-provider variables is a breaking deployment change] → Document the exact replacement variables and require gateway configuration before rollout.

## Migration Plan

1. Create or select a gateway key and a model alias that supports Navigator's chat, tool, and structured-output usage.
2. Set `AI_BASE_URL` to the gateway's OpenAI-compatible API root, `AI_API_KEY` to the gateway key, and optionally `AI_MODEL` to the chosen alias.
3. Remove the old OpenAI/Azure variables and deploy this version.
4. Exercise an interactive AI action and a background analysis/review workflow through the gateway.
5. Roll back by restoring the previous Navigator version and its previous provider variables if the gateway route is not ready.

## Open Questions

None. Gateway provisioning and alias policy remain owned by the deployment's gateway configuration.
