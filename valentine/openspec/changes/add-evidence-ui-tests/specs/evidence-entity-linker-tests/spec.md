## ADDED Requirements

### Requirement: EntityLinkerComponent supports evidence linking to assumptions
The component SHALL handle evidence as source entity when linking to assumptions.

#### Scenario: Link assumption to evidence
- **WHEN** saving with evidence as source and assumptions as target with new links
- **THEN** system calls add_assumption_to_evidence for new links

#### Scenario: Remove assumption from evidence
- **WHEN** saving with evidence as source and assumptions as target with removed links
- **THEN** system calls remove_assumption_from_evidence for removed links

### Requirement: EntityLinkerComponent supports evidence linking to threats
The component SHALL handle evidence as source entity when linking to threats.

#### Scenario: Link threat to evidence
- **WHEN** saving with evidence as source and threats as target with new links
- **THEN** system calls add_threat_to_evidence for new links

#### Scenario: Remove threat from evidence
- **WHEN** saving with evidence as source and threats as target with removed links
- **THEN** system calls remove_threat_from_evidence for removed links

### Requirement: EntityLinkerComponent supports evidence linking to mitigations
The component SHALL handle evidence as source entity when linking to mitigations.

#### Scenario: Link mitigation to evidence
- **WHEN** saving with evidence as source and mitigations as target with new links
- **THEN** system calls add_mitigation_to_evidence for new links

#### Scenario: Remove mitigation from evidence
- **WHEN** saving with evidence as source and mitigations as target with removed links
- **THEN** system calls remove_mitigation_from_evidence for removed links

### Requirement: EntityLinkerComponent displays evidence name
The component SHALL format evidence entity content as evidence name for display.

#### Scenario: Display evidence in linker
- **WHEN** rendering evidence entity in linker component
- **THEN** component displays evidence.name

### Requirement: EntityLinkerComponent sends saved message for evidence
The component SHALL send saved message with evidence entity type after successful save.

#### Scenario: Flash message after evidence linking
- **WHEN** saving evidence links successfully
- **THEN** component displays "Linked evidence updated" flash message
