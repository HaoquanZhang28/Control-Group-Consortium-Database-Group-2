WITH
    charge_totals AS (
        SELECT
            c.chargeId,
            u.eventId,
            c.state,
            u.quantity * r.unitPrice AS base_amount,
            COALESCE(
                (
                    SELECT SUM(a.amount)
                    FROM adjustment a
                    WHERE a.chargeId = c.chargeId
                ),
                0
            ) AS adjustment_amount
        FROM charge c
        JOIN usage_record u ON u.usageId = c.usageId
        JOIN rate r ON r.rateId = c.rateId
    ),
    actual AS (
        SELECT
            x.projectId,
            SUM(c.base_amount) AS gross_amount,
            SUM(c.adjustment_amount) AS adjustment_amount,
            SUM(c.base_amount + c.adjustment_amount) AS realized_amount
        FROM charge_totals c
        JOIN event e ON e.eventId = c.eventId
        JOIN experiment x ON x.experimentId = e.experimentId
        WHERE
            c.state = 'finalized'
            AND e.startAt >= :start
            AND e.startAt < :end
        GROUP BY x.projectId
    ),
    projected AS (
        SELECT
            x.projectId,
            SUM(est.quantity * r.unitPrice) AS forecast_amount
        FROM estimate est
        JOIN rate r ON r.rateId = est.rateId
        JOIN event e ON e.eventId = est.eventId
        JOIN experiment x ON x.experimentId = e.experimentId
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
        GROUP BY x.projectId
    )
SELECT
    p.projectCode AS project,
    CASE
        WHEN p.projectVisibility = 'public' THEN p.projectTitle
        ELSE 'Restricted project'
    END AS title,
    COALESCE(a.gross_amount, 0) AS gross_amount,
    COALESCE(a.adjustment_amount, 0) AS adjustment_amount,
    COALESCE(a.realized_amount, 0) AS realized_amount,
    COALESCE(f.forecast_amount, 0) AS forecast_amount
FROM project p
LEFT JOIN actual a ON a.projectId = p.projectId
LEFT JOIN projected f ON f.projectId = p.projectId
ORDER BY realized_amount DESC, p.projectId;
