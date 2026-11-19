SELECT
    eventType AS activity,
    COUNT(*) AS event_count,
    ROUND(SUM(hours), 2) AS event_hours,
    ROUND(SUM(hours * resources), 2) AS resource_hours,
    ROUND(SUM(hours * staff), 2) AS assigned_staff_hours
FROM (
    SELECT
        event.eventId,
        event.eventType,
        (strftime('%s', MIN(event.endAt, :end)) - strftime('%s', MAX(event.startAt, :start))) / 3600.0 AS hours,
        (SELECT COUNT(*) FROM event_resource WHERE event_resource.eventId = event.eventId) AS resources,
        (SELECT COUNT(*) FROM staff_assignment WHERE staff_assignment.eventId = event.eventId) AS staff
    FROM event
    WHERE event.eventType != 'experiment'
        AND event.eventStatus != 'cancelled'
        AND event.startAt < :end
        AND event.endAt > :start
)
GROUP BY eventType
ORDER BY resource_hours DESC;