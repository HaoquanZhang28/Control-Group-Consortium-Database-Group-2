SELECT
    resource.resourceName AS resource,
    event.eventType AS activity,
    event.startAt,
    event.endAt,
    COALESCE(project.projectCode, 'Operations') AS project,
    COUNT(DISTINCT staff_assignment.personId) AS assigned_staff
FROM event_resource
JOIN event ON event.eventId = event_resource.eventId
JOIN resource ON resource.resourceId = event_resource.resourceId
LEFT JOIN experiment ON experiment.experimentId = event.experimentId
LEFT JOIN project ON project.projectId = experiment.projectId
LEFT JOIN staff_assignment ON staff_assignment.eventId = event.eventId
WHERE
    event.eventStatus != 'cancelled'
    AND event.startAt <= :at
    AND event.endAt > :at
GROUP BY event.eventId, resource.resourceId
ORDER BY resource.resourceId;