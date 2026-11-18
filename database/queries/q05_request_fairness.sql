WITH latest_decision AS (
    SELECT d.*
    FROM decision d
    WHERE NOT EXISTS (
        SELECT 1
        FROM decision newer
        WHERE
            newer.requestId = d.requestId
            AND (
                newer.decidedAt > d.decidedAt
                OR (
                    newer.decidedAt = d.decidedAt
                    AND newer.decisionId > d.decisionId
                )
            )
    )
)
SELECT
    i.institutionName AS institution,
    COUNT(*) AS requests,
    COALESCE(SUM(d.outcome IN ('approved', 'alternative')), 0) AS accommodated,
    COALESCE(SUM(d.outcome = 'rejected'), 0) AS rejected,
    SUM(d.decisionId IS NULL) AS pending,
    ROUND(
        100.0 * COALESCE(SUM(d.outcome IN ('approved', 'alternative')), 0)
        / COUNT(*),
        2
    ) AS accommodation_pct
FROM request r
JOIN institution i ON i.institutionId = r.requestingInstitutionId
LEFT JOIN latest_decision d ON d.requestId = r.requestId
WHERE r.desiredStart >= :start AND r.desiredStart < :end
GROUP BY i.institutionId
ORDER BY accommodation_pct, i.institutionId;
