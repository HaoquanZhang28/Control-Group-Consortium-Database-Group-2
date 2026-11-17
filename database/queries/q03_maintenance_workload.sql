WITH event_load AS (
    SELECT
        e.eventId,
        e.eventType,
        (
            julianday(MIN(e.endAt, :end)) - julianday(MAX(e.startAt, :start))
        ) * 24 AS hours,
        (
            SELECT COUNT(*)
            FROM event_resource er
            WHERE er.eventId = e.eventId
        ) AS resources,
        (
            SELECT COUNT(*)
            FROM staff_assignment sa
            WHERE sa.eventId = e.eventId
        ) AS staff
    FROM event e
    WHERE
        e.eventType <> 'experiment'
        AND e.eventStatus <> 'cancelled'
        AND e.startAt < :end
        AND e.endAt > :start
)
SELECT
    eventType AS activity,
    COUNT(*) AS event_count,
    ROUND(SUM(hours), 2) AS event_hours,
    ROUND(SUM(hours * resources), 2) AS resource_hours,
    ROUND(SUM(hours * staff), 2) AS assigned_staff_hours
FROM event_load
GROUP BY eventType
ORDER BY resource_hours DESC;
