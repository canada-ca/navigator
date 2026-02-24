## ADDED Requirements

### Requirement: Composer adds assumption to evidence
The system SHALL link an assumption to evidence and return updated evidence with preloaded associations.

#### Scenario: Successfully add assumption to evidence
- **WHEN** calling add_assumption_to_evidence with valid evidence and assumption
- **THEN** system creates evidence_assumption join record and returns evidence with preloaded assumptions

#### Scenario: Handle duplicate assumption links
- **WHEN** calling add_assumption_to_evidence for already linked assumption
- **THEN** system handles duplicate gracefully using on_conflict: nothing

### Requirement: Composer removes assumption from evidence
The system SHALL unlink an assumption from evidence and return updated evidence.

#### Scenario: Successfully remove assumption from evidence
- **WHEN** calling remove_assumption_from_evidence with linked assumption
- **THEN** system deletes evidence_assumption join record and returns evidence with preloaded assumptions

#### Scenario: Remove non-existent assumption link
- **WHEN** calling remove_assumption_from_evidence for unlinked assumption
- **THEN** system completes without errors

### Requirement: Composer adds threat to evidence
The system SHALL link a threat to evidence and return updated evidence with preloaded associations.

#### Scenario: Successfully add threat to evidence
- **WHEN** calling add_threat_to_evidence with valid evidence and threat
- **THEN** system creates evidence_threat join record and returns evidence with preloaded threats

#### Scenario: Handle duplicate threat links
- **WHEN** calling add_threat_to_evidence for already linked threat
- **THEN** system handles duplicate gracefully using on_conflict: nothing

### Requirement: Composer removes threat from evidence
The system SHALL unlink a threat from evidence and return updated evidence.

#### Scenario: Successfully remove threat from evidence
- **WHEN** calling remove_threat_from_evidence with linked threat
- **THEN** system deletes evidence_threat join record and returns evidence with preloaded threats

#### Scenario: Remove non-existent threat link
- **WHEN** calling remove_threat_from_evidence for unlinked threat
- **THEN** system completes without errors

### Requirement: Composer adds mitigation to evidence
The system SHALL link a mitigation to evidence and return updated evidence with preloaded associations.

#### Scenario: Successfully add mitigation to evidence
- **WHEN** calling add_mitigation_to_evidence with valid evidence and mitigation
- **THEN** system creates evidence_mitigation join record and returns evidence with preloaded mitigations

#### Scenario: Handle duplicate mitigation links
- **WHEN** calling add_mitigation_to_evidence for already linked mitigation
- **THEN** system handles duplicate gracefully using on_conflict: nothing

### Requirement: Composer removes mitigation from evidence
The system SHALL unlink a mitigation from evidence and return updated evidence.

#### Scenario: Successfully remove mitigation from evidence
- **WHEN** calling remove_mitigation_from_evidence with linked mitigation
- **THEN** system deletes evidence_mitigation join record and returns evidence with preloaded mitigations

#### Scenario: Remove non-existent mitigation link
- **WHEN** calling remove_mitigation_from_evidence for unlinked mitigation
- **THEN** system completes without errors

### Requirement: Composer gets evidence with preloaded associations
The system SHALL support loading evidence with specified associations preloaded.

#### Scenario: Get evidence with preload list
- **WHEN** calling get_evidence! with preload list
- **THEN** system returns evidence with specified associations loaded

#### Scenario: Get evidence without preload
- **WHEN** calling get_evidence! with nil preload
- **THEN** system returns evidence without additional preloads
