## Why

Navigator currently authenticates directly to OpenAI or Azure OpenAI with provider-specific credentials. The deployment is moving to an OpenAI-compatible gateway, initially LiteLLM, so Navigator needs to send all AI-assisted requests through that gateway using vendor-neutral gateway credentials and model aliases.

## What Changes

- Route every AI-assisted request through one configured AI gateway base URL using the OpenAI-compatible protocol.
- Authenticate requests with an AI gateway key and select the gateway model alias from vendor-neutral runtime configuration.
- Default the gateway model alias to `openai-gpt-5.6-luna` when `AI_MODEL` is not set.
- Keep the existing AI-assisted user workflows and request tuning, including the maximum token limit, unchanged.
- Update Docker Compose and operator documentation to describe the OpenAI-compatible gateway configuration, with LiteLLM as the initial example.
- **BREAKING**: Remove the direct `OPENAI_API_KEY`, `OPENAI_MODEL`, `AZURE_OPENAI_*`, and interim `LITELLM_*` runtime configuration contracts. Deployments must provide `AI_BASE_URL`, `AI_API_KEY`, and optionally `AI_MODEL`.
- Non-goals: deploying or configuring the LiteLLM service itself, changing model routing policy inside LiteLLM, or changing Navigator's workspace API-key feature.
- Rollout: configure and validate the generic AI gateway variables before deploying this version; no database migration is required.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ai-assisted-analysis`: AI-assisted analysis uses the configured OpenAI-compatible gateway rather than direct OpenAI or Azure OpenAI provider credentials.

## Impact

- Runtime configuration in `valentine/config/runtime.exs`.
- Provider request construction in `Valentine.AIProvider`, which is shared by interactive AI features, repository analysis, and threat-model quality review.
- Runtime configuration tests, Docker Compose environment forwarding, and English/French setup documentation.
- The existing ReqLLM dependency remains in place and uses its OpenAI-compatible `base_url` and `api_key` request options; no new dependency is required.
