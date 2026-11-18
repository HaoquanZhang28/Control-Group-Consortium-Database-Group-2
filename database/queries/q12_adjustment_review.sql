SELECT
    a.reason,
    p.personName AS authorized_by,
    COUNT(*) AS adjustments,
    COUNT(DISTINCT a.chargeId) AS affected_charges,
    SUM(CASE WHEN a.amount < 0 THEN -a.amount ELSE 0 END) AS credit_amount,
    SUM(CASE WHEN a.amount > 0 THEN a.amount ELSE 0 END) AS fee_amount
FROM adjustment a
JOIN person p ON p.personId = a.authorizedBy
JOIN charge c ON c.chargeId = a.chargeId
JOIN usage_record u ON u.usageId = c.usageId
JOIN event e ON e.eventId = u.eventId
WHERE
    c.state = 'finalized'
    AND e.startAt >= :start
    AND e.startAt < :end
GROUP BY a.reason, a.authorizedBy
ORDER BY credit_amount DESC;
