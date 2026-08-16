## Why

Navigator currently authenticates directly to OpenAI or Azure OpenAI with provider-specific credentials. The deployment is moving to LiteLLM as the single LLM gateway, so Navigator needs to send all AI-assisted requests through that OpenAI-compatible gateway using gateway credentials and model aliases.

## What Changes

- Route every AI-assisted request through one configured LiteLLM base URL using the OpenAI-compatible protocol.
- Authenticate requests with a LiteLLM gateway key and select the gateway model alias from LiteLLM-specific runtime configuration.
- Keep the existing AI-assisted user workflows and request tuning, including the maximum token limit, unchanged.
- Update Docker Compose and operator documentation to describe the LiteLLM gateway configuration.
- **BREAKING**: Remove the direct `OPENAI_API_KEY`, `OPENAI_MODEL`, and `AZURE_OPENAI_*` runtime configuration contract. Deployments must provide `LITELLM_BASE_URL`, `LITELLM_API_KEY`, and optionally `LITELLM_MODEL`.
- Non-goals: deploying or configuring the LiteLLM service itself, changing model routing policy inside LiteLLM, or changing Navigator's workspace API-key feature.
- Rollout: configure and validate the LiteLLM gateway variables before deploying this version; no database migration is required.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ai-assisted-analysis`: AI-assisted analysis uses the configured LiteLLM gateway rather than direct OpenAI or Azure OpenAI provider credentials.

## Impact

- Runtime configuration in `valentine/config/runtime.exs`.
- Provider request construction in `Valentine.AIProvider`, which is shared by interactive AI features, repository analysis, and threat-model quality review.
- Runtime configuration tests, Docker Compose environment forwarding, and English/French setup documentation.
- The existing ReqLLM dependency remains in place and uses its OpenAI-compatible `base_url` and `api_key` request options; no new dependency is required.
