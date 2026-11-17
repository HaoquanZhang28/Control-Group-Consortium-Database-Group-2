SELECT
    r.resourceName AS resource,
    e.eventType AS activity,
    e.startAt,
    e.endAt,
    COALESCE(p.projectCode, 'Operations') AS project,
    COUNT(DISTINCT sa.personId) AS assigned_staff
FROM event_resource er
JOIN event e ON e.eventId = er.eventId
JOIN resource r ON r.resourceId = er.resourceId
LEFT JOIN experiment x ON x.experimentId = e.experimentId
LEFT JOIN project p ON p.projectId = x.projectId
LEFT JOIN staff_assignment sa ON sa.eventId = e.eventId
WHERE
    e.eventStatus <> 'cancelled'
    AND e.startAt <= :at
    AND e.endAt > :at
GROUP BY e.eventId, r.resourceId
ORDER BY r.resourceId;
