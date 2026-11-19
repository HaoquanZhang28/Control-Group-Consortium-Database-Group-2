SELECT
    resource.resourceName AS resource,
    resource_type.resourceTypeKind AS resource_kind,
    ROUND(COALESCE(SUM(CASE WHEN event.eventType = 'experiment' THEN MAX(0,(strftime('%s', MIN(event.endAt, :end)) - strftime('%s', MAX(event.startAt, :start))) / 3600.0) ELSE 0 END), 0), 2) AS booked_hours,
    ROUND(COALESCE(SUM(CASE WHEN event.eventType != 'experiment' THEN MAX(0, (strftime('%s', MIN(event.endAt, :end)) - strftime('%s', MAX(event.startAt, :start))) / 3600.0) ELSE 0 END), 0), 2) AS blocked_hours,
    ROUND((strftime('%s', :end) - strftime('%s', :start)) / 3600.0 - COALESCE(SUM(CASE WHEN event.eventType <> 'experiment' THEN MAX(0, (strftime('%s', MIN(event.endAt, :end)) - strftime('%s', MAX(event.startAt, :start))) / 3600.0) ELSE 0 END), 0), 2) AS available_hours
FROM resource
JOIN resource_type ON resource_type.resourceTypeId = resource.resourceTypeId
LEFT JOIN event_resource ON event_resource.resourceId = resource.resourceId
LEFT JOIN event ON event.eventId = event_resource.eventId
AND event.eventStatus != 'cancelled'
AND event.startAt < :end
AND event.endAt > :start
GROUP BY resource.resourceId, resource.resourceName, resource_type.resourceTypeKind
ORDER BY booked_hours DESC, resource.resourceId;