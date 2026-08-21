## 1. Gateway Configuration

- [x] 1.1 Replace direct OpenAI and Azure runtime settings with grouped AI gateway URL, key, and model-alias settings.
- [x] 1.2 Update `Valentine.AIProvider` to construct custom OpenAI-compatible model inputs and validated gateway request options without direct-provider fallback.
- [x] 1.3 Update affected diagnostic logging for the custom model representation.

## 2. Automated Coverage

- [x] 2.1 Add focused `Valentine.AIProvider` tests for model aliases, gateway request options, option precedence, token limits, and incomplete configuration.
- [x] 2.2 Extend runtime configuration tests to verify AI gateway environment-variable mapping and removal of legacy direct-provider settings.

## 3. Deployment Guidance

- [x] 3.1 Replace Docker Compose's OpenAI key forwarding with generic AI gateway variables.
- [x] 3.2 Update the English and French README setup instructions with the gateway migration contract.

## 4. Verification

- [x] 4.1 Run `make fmt` and confirm formatting produces no unexpected changes.
- [x] 4.2 Run focused AI-provider and runtime-config tests, then run `make test`.
- [x] 4.3 Confirm the accepted gateway behavior is represented in the OpenSpec delta and record the manual gateway workflow check as deployment-dependent.

Manual gateway workflow check: deployment-dependent and not run locally because no AI gateway endpoint or key was provided.

## 5. Vendor-Neutral Configuration Refinement

- [x] 5.1 Replace the LiteLLM-prefixed environment variables and internal config key with `AI_BASE_URL`, `AI_API_KEY`, `AI_MODEL`, and `:ai_gateway`.
- [x] 5.2 Update automated coverage, Docker Compose, bilingual documentation, and OpenSpec artifacts for the vendor-neutral OpenAI-compatible gateway contract.
- [x] 5.3 Run formatting, focused tests, the full test suite, and strict OpenSpec validation.

## 6. Default Gateway Model

- [x] 6.1 Change the application, Docker Compose, documentation, and OpenSpec default model alias to `openai-gpt-5.6-luna`.
- [x] 6.2 Update default-model coverage and run formatting, focused tests, and strict OpenSpec validation.
