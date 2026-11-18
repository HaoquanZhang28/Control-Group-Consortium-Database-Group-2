WITH
    collaborators AS (
        SELECT
            pm.projectId,
            COUNT(DISTINCT pm.personId) AS researchers,
            COUNT(DISTINCT a.institutionId) AS institutions
        FROM project_member pm
        JOIN affiliation a ON a.personId = pm.personId
        JOIN institution i ON i.institutionId = a.institutionId
        WHERE
            i.institutionType <> 'consortium'
            AND a.validFrom <= :at
            AND a.validTo > :at
        GROUP BY pm.projectId
    ),
    sponsors AS (
        SELECT
            x.projectId,
            COUNT(DISTINCT fs.payerId) AS paying_parties,
            SUM(ca.amount) AS shared_amount
        FROM charge_allocation ca
        JOIN policy_share ps ON ps.policyShareId = ca.policyShareId
        JOIN funding_source fs ON fs.fundingSourceId = ps.fundingSourceId
        JOIN charge c ON c.chargeId = ca.chargeId
        JOIN usage_record u ON u.usageId = c.usageId
        JOIN event e ON e.eventId = u.eventId
        JOIN experiment x ON x.experimentId = e.experimentId
        WHERE
            c.state = 'finalized'
            AND e.startAt >= :start
            AND e.startAt < :end
        GROUP BY x.projectId
    )
SELECT
    p.projectCode AS project,
    c.researchers,
    c.institutions,
    COALESCE(s.paying_parties, 0) AS paying_parties,
    COALESCE(s.shared_amount, 0) AS shared_amount
FROM collaborators c
JOIN project p ON p.projectId = c.projectId
LEFT JOIN sponsors s ON s.projectId = p.projectId
WHERE c.institutions > 1
ORDER BY c.institutions DESC, p.projectId;
