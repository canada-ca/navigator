## 1. Gateway Configuration

- [x] 1.1 Replace direct OpenAI and Azure runtime settings with grouped LiteLLM gateway URL, key, and model-alias settings.
- [x] 1.2 Update `Valentine.AIProvider` to construct custom OpenAI-compatible model inputs and validated LiteLLM request options without direct-provider fallback.
- [x] 1.3 Update affected diagnostic logging for the custom model representation.

## 2. Automated Coverage

- [x] 2.1 Add focused `Valentine.AIProvider` tests for model aliases, gateway request options, option precedence, token limits, and incomplete configuration.
- [x] 2.2 Extend runtime configuration tests to verify LiteLLM environment-variable mapping and removal of legacy direct-provider settings.

## 3. Deployment Guidance

- [x] 3.1 Replace Docker Compose's OpenAI key forwarding with LiteLLM gateway variables.
- [x] 3.2 Update the English and French README setup instructions with the LiteLLM migration contract.

## 4. Verification

- [x] 4.1 Run `make fmt` and confirm formatting produces no unexpected changes.
- [x] 4.2 Run focused AI-provider and runtime-config tests, then run `make test`.
- [x] 4.3 Confirm the accepted gateway behavior is represented in the OpenSpec delta and record the manual gateway workflow check as deployment-dependent.

Manual gateway workflow check: deployment-dependent and not run locally because no LiteLLM gateway endpoint or key was provided.
