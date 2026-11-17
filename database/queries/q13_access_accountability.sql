SELECT
    substr(al.occurredAt, 1, 7) AS month,
    COUNT(*) AS access_attempts,
    SUM(al.result = 'granted') AS granted,
    SUM(al.result = 'denied') AS denied,
    ROUND(100.0 * SUM(al.result = 'denied') / COUNT(*), 2) AS denial_pct,
    COUNT(DISTINCT c.personId) AS distinct_people
FROM access_log al
JOIN credential c ON c.credentialId = al.credentialId
WHERE al.occurredAt >= :start AND al.occurredAt < :end
GROUP BY substr(al.occurredAt, 1, 7)
ORDER BY month;
