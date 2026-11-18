PRAGMA foreign_keys = ON;

CREATE TABLE "institution" (
  institutionId INTEGER PRIMARY KEY,
  institutionName TEXT NOT NULL UNIQUE,
  institutionType TEXT NOT NULL CHECK (
    institutionType IN (
      'university',
      'hospital',
      'research_institute',
      'consortium'
    )
  )
);

CREATE TABLE "department" (
  departmentId INTEGER PRIMARY KEY,
  institutionId INTEGER NOT NULL REFERENCES "institution",
  departmentName TEXT NOT NULL,
  UNIQUE (institutionId, departmentName)
);

CREATE TABLE "person" (
  personId INTEGER PRIMARY KEY,
  personName TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL
);

CREATE TABLE "affiliation" (
  affiliationId INTEGER PRIMARY KEY,
  personId INTEGER NOT NULL REFERENCES "person",
  institutionId INTEGER NOT NULL REFERENCES "institution",
  validFrom TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validFrom) IS validFrom),
  validTo TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validTo) IS validTo) CHECK (validTo > validFrom),
  UNIQUE (personId, institutionId, validFrom)
);

CREATE TABLE "role" (
  roleId INTEGER PRIMARY KEY,
  roleName TEXT NOT NULL UNIQUE,
  canViewConfidential INTEGER NOT NULL CHECK (canViewConfidential IN (0, 1))
);

CREATE TABLE "person_role" (
  personId INTEGER NOT NULL REFERENCES "person",
  roleId INTEGER NOT NULL REFERENCES "role",
  PRIMARY KEY (personId, roleId)
);

CREATE TABLE "site" (
  siteId INTEGER PRIMARY KEY,
  institutionId INTEGER NOT NULL REFERENCES "institution",
  siteName TEXT NOT NULL UNIQUE,
  siteTimeZone TEXT NOT NULL
);

CREATE TABLE "resource_type" (
  resourceTypeId INTEGER PRIMARY KEY,
  resourceTypeName TEXT NOT NULL UNIQUE,
  resourceTypeKind TEXT NOT NULL CHECK (resourceTypeKind IN ('facility', 'equipment'))
);

CREATE TABLE "resource" (
  resourceId INTEGER PRIMARY KEY,
  resourceTypeId INTEGER NOT NULL REFERENCES "resource_type",
  resourceName TEXT NOT NULL UNIQUE,
  siteId INTEGER REFERENCES "site",
  serialNumber TEXT UNIQUE,
  movable INTEGER CHECK (movable IN (0, 1)),
  capability TEXT NOT NULL,
  limitation TEXT NOT NULL,
  maxSessionMinutes INTEGER NOT NULL CHECK (maxSessionMinutes > 0)
);

CREATE TABLE "equipment_placement" (
  equipmentPlacementId INTEGER PRIMARY KEY,
  equipmentId INTEGER NOT NULL REFERENCES "resource",
  facilityId INTEGER NOT NULL REFERENCES "resource",
  startAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', startAt) IS startAt),
  endAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', endAt) IS endAt) CHECK (endAt > startAt),
  UNIQUE (equipmentId, startAt),
  CHECK (equipmentId <> facilityId)
);

CREATE TABLE "configuration" (
  configurationId INTEGER PRIMARY KEY,
  facilityId INTEGER NOT NULL REFERENCES "resource",
  configurationName TEXT NOT NULL,
  configurationPurpose TEXT NOT NULL,
  UNIQUE (facilityId, configurationName)
);

CREATE TABLE "qualification" (
  qualificationId INTEGER PRIMARY KEY,
  qualificationName TEXT NOT NULL UNIQUE,
  qualificationKind TEXT NOT NULL CHECK (
    qualificationKind IN (
      'training',
      'certification',
      'regulatory_approval'
    )
  )
);

CREATE TABLE "person_qualification" (
  personQualificationId INTEGER PRIMARY KEY,
  personId INTEGER NOT NULL REFERENCES "person",
  qualificationId INTEGER NOT NULL REFERENCES "qualification",
  validFrom TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validFrom) IS validFrom),
  validTo TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validTo) IS validTo) CHECK (validTo > validFrom),
  Issuer TEXT NOT NULL,
  UNIQUE (personId, qualificationId, validFrom)
);

CREATE TABLE "resource_requirement" (
  resourceId INTEGER NOT NULL REFERENCES "resource",
  qualificationId INTEGER NOT NULL REFERENCES "qualification",
  PRIMARY KEY (resourceId, qualificationId)
);

CREATE TABLE "project" (
  projectId INTEGER PRIMARY KEY,
  projectCode TEXT NOT NULL UNIQUE,
  projectTitle TEXT NOT NULL,
  principalInvestigatorId INTEGER NOT NULL REFERENCES "person",
  projectVisibility TEXT NOT NULL CHECK (
    projectVisibility IN ('public', 'internal', 'confidential')
  )
);

CREATE TABLE "project_member" (
  projectId INTEGER NOT NULL REFERENCES "project",
  personId INTEGER NOT NULL REFERENCES "person",
  responsibility TEXT NOT NULL,
  PRIMARY KEY (projectId, personId)
);

CREATE TABLE "experiment" (
  experimentId INTEGER PRIMARY KEY,
  projectId INTEGER NOT NULL REFERENCES "project",
  leadResearcherId INTEGER NOT NULL REFERENCES "person",
  experimentName TEXT NOT NULL,
  startAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', startAt) IS startAt),
  endAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', endAt) IS endAt) CHECK (endAt > startAt)
);

CREATE TABLE "request" (
  requestId INTEGER PRIMARY KEY,
  experimentId INTEGER NOT NULL REFERENCES "experiment",
  requestingInstitutionId INTEGER NOT NULL REFERENCES "institution",
  requesterId INTEGER NOT NULL REFERENCES "person",
  submittedAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', submittedAt) IS submittedAt),
  desiredStart TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', desiredStart) IS desiredStart),
  desiredEnd TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', desiredEnd) IS desiredEnd) CHECK (desiredEnd > desiredStart),
  staffingMinutes INTEGER NOT NULL CHECK (staffingMinutes >= 0),
  priority INTEGER NOT NULL CHECK (priority BETWEEN 1 AND 3),
  safetyNotes TEXT NOT NULL,
  specialConditions TEXT NOT NULL,
  expectedOutcome TEXT NOT NULL,
  CHECK (submittedAt <= desiredStart)
);

CREATE TABLE "request_need" (
  requestId INTEGER NOT NULL REFERENCES "request",
  resourceTypeId INTEGER NOT NULL REFERENCES "resource_type",
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  estimatedMinutes INTEGER NOT NULL CHECK (estimatedMinutes > 0),
  PRIMARY KEY (requestId, resourceTypeId)
);

CREATE TABLE "event" (
  eventId INTEGER PRIMARY KEY,
  experimentId INTEGER REFERENCES "experiment",
  eventType TEXT NOT NULL CHECK (
    eventType IN (
      'experiment',
      'setup',
      'calibration',
      'maintenance',
      'cleaning',
      'inspection',
      'reconfiguration'
    )
  ),
  startAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', startAt) IS startAt),
  endAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', endAt) IS endAt) CHECK (endAt > startAt),
  eventStatus TEXT NOT NULL CHECK (eventStatus IN ('planned', 'completed', 'cancelled')),
  CHECK (
    eventType <> 'experiment'
    OR experimentId IS NOT NULL
  )
);

CREATE TABLE "decision" (
  decisionId INTEGER PRIMARY KEY,
  requestId INTEGER NOT NULL REFERENCES "request",
  decidedBy INTEGER NOT NULL REFERENCES "person",
  decidedAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', decidedAt) IS decidedAt),
  outcome TEXT NOT NULL CHECK (
    outcome IN (
      'approved',
      'alternative',
      'rejected',
      'withdrawn'
    )
  ),
  eventId INTEGER REFERENCES "event",
  rationale TEXT NOT NULL,
  CHECK (
    (
      outcome IN ('approved', 'alternative')
      AND eventId IS NOT NULL
    )
    OR (
      outcome IN ('rejected', 'withdrawn')
      AND eventId IS NULL
    )
  )
);

CREATE TABLE "event_resource" (
  eventId INTEGER NOT NULL REFERENCES "event",
  resourceId INTEGER NOT NULL REFERENCES "resource",
  PRIMARY KEY (eventId, resourceId)
);

CREATE TABLE "event_configuration" (
  eventId INTEGER NOT NULL REFERENCES "event",
  configurationId INTEGER NOT NULL REFERENCES "configuration",
  PRIMARY KEY (eventId, configurationId)
);

CREATE TABLE "event_change" (
  eventChangeId INTEGER PRIMARY KEY,
  eventId INTEGER NOT NULL REFERENCES "event",
  changedBy INTEGER NOT NULL REFERENCES "person",
  changedAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', changedAt) IS changedAt),
  oldStart TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', oldStart) IS oldStart),
  oldEnd TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', oldEnd) IS oldEnd),
  newStart TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', newStart) IS newStart),
  newEnd TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', newEnd) IS newEnd),
  oldStatus TEXT NOT NULL,
  newStatus TEXT NOT NULL,
  reason TEXT NOT NULL
);

CREATE TABLE staff_availability (
  staffAvailabilityId INTEGER PRIMARY KEY,
  personId INTEGER NOT NULL REFERENCES "person",
  startAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', startAt) IS startAt),
  endAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', endAt) IS endAt) CHECK (endAt > startAt),
  UNIQUE (personId, startAt)
);

CREATE TABLE "staff_assignment" (
  eventId INTEGER NOT NULL REFERENCES "event",
  personId INTEGER NOT NULL REFERENCES "person",
  duty TEXT NOT NULL,
  PRIMARY KEY (eventId, personId)
);

CREATE TABLE "payer" (
  payerId INTEGER PRIMARY KEY,
  personId INTEGER UNIQUE REFERENCES "person",
  institutionId INTEGER UNIQUE REFERENCES "institution",
  departmentId INTEGER UNIQUE REFERENCES "department",
  CHECK (
    (personId IS NOT NULL) + (institutionId IS NOT NULL) + (departmentId IS NOT NULL) = 1
  )
);

CREATE TABLE "funding_source" (
  fundingSourceId INTEGER PRIMARY KEY,
  payerId INTEGER NOT NULL REFERENCES "payer",
  fundingSourceName TEXT NOT NULL UNIQUE,
  fundingSourceType TEXT NOT NULL CHECK (
    fundingSourceType IN (
      'grant',
      'departmental',
      'institutional',
      'sponsor'
    )
  ),
  budget INTEGER NOT NULL CHECK (budget > 0),
  validFrom TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validFrom) IS validFrom),
  validTo TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validTo) IS validTo) CHECK (validTo > validFrom)
);

CREATE TABLE "consumable" (
  consumableId INTEGER PRIMARY KEY,
  consumableName TEXT NOT NULL UNIQUE,
  unit TEXT NOT NULL
);

CREATE TABLE "rate" (
  rateId INTEGER PRIMARY KEY,
  resourceTypeId INTEGER REFERENCES "resource_type",
  consumableId INTEGER REFERENCES "consumable",
  staffService TEXT,
  unitPrice INTEGER NOT NULL CHECK (unitPrice >= 0),
  validFrom TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validFrom) IS validFrom),
  validTo TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validTo) IS validTo) CHECK (validTo > validFrom),
  CHECK (
    (resourceTypeId IS NOT NULL) + (consumableId IS NOT NULL) + (staffService IS NOT NULL) = 1
  )
);

CREATE TABLE funding_eligibility (
  fundingSourceId INTEGER NOT NULL REFERENCES "funding_source",
  rateId INTEGER NOT NULL REFERENCES "rate",
  PRIMARY KEY (fundingSourceId, rateId)
);

CREATE TABLE "allocation_policy" (
  allocationPolicyId INTEGER PRIMARY KEY,
  projectId INTEGER NOT NULL REFERENCES "project",
  validFrom TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validFrom) IS validFrom),
  validTo TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validTo) IS validTo) CHECK (validTo > validFrom),
  authorizedBy INTEGER NOT NULL REFERENCES "person",
  rationale TEXT NOT NULL,
  UNIQUE (projectId, validFrom)
);

CREATE TABLE "policy_share" (
  policyShareId INTEGER PRIMARY KEY,
  allocationPolicyId INTEGER NOT NULL REFERENCES "allocation_policy",
  fundingSourceId INTEGER NOT NULL REFERENCES "funding_source",
  beneficiaryProjectId INTEGER NOT NULL REFERENCES "project",
  basisPoint INTEGER NOT NULL CHECK (
    basisPoint > 0
    AND basisPoint <= 10000
  ),
  UNIQUE (
    allocationPolicyId,
    fundingSourceId,
    beneficiaryProjectId
  )
);

CREATE TABLE "usage_record" (
  usageId INTEGER PRIMARY KEY,
  eventId INTEGER NOT NULL REFERENCES "event",
  resourceId INTEGER REFERENCES "resource",
  staffPersonId INTEGER REFERENCES "person",
  consumableId INTEGER REFERENCES "consumable",
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  recordedAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', recordedAt) IS recordedAt),
  CHECK (
    (resourceId IS NOT NULL) + (staffPersonId IS NOT NULL) + (consumableId IS NOT NULL) = 1
  )
);

CREATE TABLE "estimate" (
  estimateId INTEGER PRIMARY KEY,
  eventId INTEGER NOT NULL REFERENCES "event",
  rateId INTEGER NOT NULL REFERENCES "rate",
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  estimationTime TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', estimationTime) IS estimationTime),
  assumption TEXT NOT NULL,
  UNIQUE (eventId, rateId, estimationTime)
);

CREATE TABLE "charge" (
  chargeId INTEGER PRIMARY KEY,
  usageId INTEGER NOT NULL UNIQUE REFERENCES "usage_record",
  rateId INTEGER NOT NULL REFERENCES "rate",
  allocationPolicyId INTEGER NOT NULL REFERENCES "allocation_policy",
  state TEXT NOT NULL CHECK (state IN ('draft', 'finalized')),
  createdAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', createdAt) IS createdAt)
);

CREATE TABLE "adjustment" (
  adjustmentId INTEGER PRIMARY KEY,
  chargeId INTEGER NOT NULL REFERENCES "charge",
  amount INTEGER NOT NULL CHECK (amount <> 0),
  reason TEXT NOT NULL,
  authorizedBy INTEGER NOT NULL REFERENCES "person",
  authorizedAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', authorizedAt) IS authorizedAt)
);

CREATE TABLE "charge_allocation" (
  chargeAllocationId INTEGER PRIMARY KEY,
  chargeId INTEGER NOT NULL REFERENCES "charge",
  policyShareId INTEGER NOT NULL REFERENCES "policy_share",
  amount INTEGER NOT NULL CHECK (amount >= 0),
  UNIQUE (chargeId, policyShareId)
);

CREATE TABLE "invoice" (
  invoiceId INTEGER PRIMARY KEY,
  fundingSourceId INTEGER NOT NULL REFERENCES "funding_source",
  periodStart TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', periodStart) IS periodStart),
  periodEnd TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', periodEnd) IS periodEnd) CHECK (periodEnd > periodStart),
  issuedAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', issuedAt) IS issuedAt),
  status TEXT NOT NULL CHECK (status IN ('issued', 'paid')),
  UNIQUE (fundingSourceId, periodStart, periodEnd)
);

CREATE TABLE invoice_lines (
  invoiceId INTEGER NOT NULL REFERENCES "invoice",
  chargeAllocationId INTEGER NOT NULL UNIQUE REFERENCES "charge_allocation",
  PRIMARY KEY (invoiceId, chargeAllocationId)
);

CREATE TABLE "credential" (
  credentialId INTEGER PRIMARY KEY,
  personId INTEGER NOT NULL REFERENCES "person",
  issuerInstitutionId INTEGER NOT NULL REFERENCES "institution",
  externalSubject TEXT NOT NULL,
  validFrom TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validFrom) IS validFrom),
  validTo TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validTo) IS validTo) CHECK (validTo > validFrom),
  UNIQUE (issuerInstitutionId, externalSubject)
);

CREATE TABLE "access_grant" (
  accessGrantId INTEGER PRIMARY KEY,
  personId INTEGER NOT NULL REFERENCES "person",
  resourceId INTEGER NOT NULL REFERENCES "resource",
  projectId INTEGER REFERENCES "project",
  validFrom TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validFrom) IS validFrom),
  validTo TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', validTo) IS validTo) CHECK (validTo > validFrom),
  authorizedBy INTEGER NOT NULL REFERENCES "person",
  UNIQUE (personId, resourceId, projectId, validFrom)
);

CREATE TABLE "access_log" (
  accessLogId INTEGER PRIMARY KEY,
  credentialId INTEGER NOT NULL REFERENCES "credential",
  resourceId INTEGER NOT NULL REFERENCES "resource",
  eventId INTEGER REFERENCES "event",
  occurredAt TEXT NOT NULL CHECK (strftime('%Y-%m-%dT%H:%M:%S', occurredAt) IS occurredAt),
  result TEXT NOT NULL CHECK (result IN ('granted', 'denied')),
  reason TEXT NOT NULL
);

CREATE INDEX idx_events_time ON "event" (startAt, endAt, eventStatus);
CREATE INDEX idx_reservations_resource ON "event_resource" (resourceId, eventId);
CREATE INDEX idx_assignments_person ON "staff_assignment" (personId, eventId);
CREATE INDEX idx_placement_time ON "equipment_placement" (equipmentId, startAt, endAt);
CREATE INDEX idx_usage_event ON "usage_record" (eventId);
CREATE INDEX idx_access_time ON "access_log" (occurredAt, result);
CREATE INDEX idx_request_experiment ON "request" (experimentId, submittedAt);
CREATE INDEX idx_decision_request ON "decision" (requestId, decidedAt, decisionId);
CREATE INDEX idx_qualifications_person ON "person_qualification" (personId, qualificationId, validFrom, validTo);
CREATE INDEX idx_allocations_charge ON "charge_allocation" (chargeId);
CREATE INDEX idx_invoice_period ON "invoice" (periodStart, periodEnd);
CREATE INDEX idx_adjustment_charge ON "adjustment" (chargeId);