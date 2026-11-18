SELECT
    substr(e.startAt, 1, 7) AS month,
    SUM(e.eventStatus = 'completed') AS completed_sessions,
    SUM(e.eventStatus = 'planned') AS planned_sessions,
    SUM(e.eventStatus = 'cancelled') AS cancelled_sessions,
    COUNT(DISTINCT x.projectId) AS active_projects
FROM event e
JOIN experiment x ON x.experimentId = e.experimentId
WHERE
    e.eventType = 'experiment'
    AND e.startAt >= :start
    AND e.startAt < :end
GROUP BY substr(e.startAt, 1, 7)
ORDER BY month;
