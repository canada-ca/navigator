## MODIFIED Requirements

### Requirement: Provider-agnostic AI integration
Navigator SHALL route all AI-assisted analysis through the configured AI gateway using its OpenAI-compatible API rather than authenticating directly to upstream model providers.

#### Scenario: Running AI-assisted analysis through a gateway
- **WHEN** a workspace uses AI-assisted analysis and the AI gateway URL, gateway key, and model alias are configured
- **THEN** Navigator routes repository-analysis and threat-model quality-review requests to that gateway
- **AND** authenticates with the gateway key
- **AND** sends the configured model alias while leaving upstream-provider selection to the gateway
- **AND** the user-facing workflow remains unchanged regardless of the upstream provider selected by the gateway

#### Scenario: Using the default gateway model alias
- **WHEN** the AI gateway URL and key are configured without an explicit model alias
- **THEN** Navigator sends `openai-gpt-5.6-luna` as the model alias

#### Scenario: Rejecting incomplete gateway configuration
- **WHEN** an AI-assisted workflow is invoked without a configured AI gateway URL or gateway key
- **THEN** Navigator fails the request with a gateway-configuration error before contacting an LLM endpoint
- **AND** does not fall back to direct OpenAI or Azure OpenAI credentials
