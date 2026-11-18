WITH
    payer_name AS (
        SELECT
            py.payerId,
            COALESCE(p.personName, i.institutionName, d.departmentName) AS payer
        FROM payer py
        LEFT JOIN person p ON p.personId = py.personId
        LEFT JOIN institution i ON i.institutionId = py.institutionId
        LEFT JOIN department d ON d.departmentId = py.departmentId
    ),
    spent AS (
        SELECT
            ps.fundingSourceId,
            SUM(ca.amount) AS amount
        FROM charge_allocation ca
        JOIN policy_share ps ON ps.policyShareId = ca.policyShareId
        JOIN charge c ON c.chargeId = ca.chargeId
        JOIN usage_record u ON u.usageId = c.usageId
        JOIN event e ON e.eventId = u.eventId
        WHERE c.state = 'finalized' AND e.startAt < :end
        GROUP BY ps.fundingSourceId
    ),
    projected AS (
        SELECT
            ps.fundingSourceId,
            ROUND(SUM(est.quantity * r.unitPrice * ps.basisPoint / 10000.0)) AS amount
        FROM estimate est
        JOIN rate r ON r.rateId = est.rateId
        JOIN event e ON e.eventId = est.eventId
        JOIN experiment x ON x.experimentId = e.experimentId
        JOIN allocation_policy ap
            ON ap.projectId = x.projectId
            AND ap.validFrom <= e.startAt
            AND ap.validTo >= e.endAt
        JOIN policy_share ps ON ps.allocationPolicyId = ap.allocationPolicyId
        WHERE
            e.eventStatus = 'planned'
            AND e.startAt >= :start
            AND e.startAt < :end
            AND est.estimationTime = (
                SELECT MAX(newer.estimationTime)
                FROM estimate newer
                WHERE
                    newer.eventId = est.eventId
                    AND newer.rateId = est.rateId
            )
        GROUP BY ps.fundingSourceId
    )
SELECT
    f.fundingSourceName AS funding_source,
    pn.payer,
    f.budget,
    COALESCE(s.amount, 0) AS spent_amount,
    CAST(COALESCE(pr.amount, 0) AS INTEGER) AS forecast_amount,
    CAST(
        f.budget - COALESCE(s.amount, 0) - COALESCE(pr.amount, 0)
        AS INTEGER
    ) AS remaining_amount
FROM funding_source f
JOIN payer_name pn ON pn.payerId = f.payerId
LEFT JOIN spent s ON s.fundingSourceId = f.fundingSourceId
LEFT JOIN projected pr ON pr.fundingSourceId = f.fundingSourceId
ORDER BY remaining_amount, f.fundingSourceId;
