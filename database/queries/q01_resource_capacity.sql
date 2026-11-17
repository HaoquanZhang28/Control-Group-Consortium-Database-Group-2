WITH
    clipped AS (
        SELECT
            er.resourceId,
            e.eventType,
            MAX(
                0,
                (
                    julianday(MIN(e.endAt, :end)) - julianday(MAX(e.startAt, :start))
                ) * 24
            ) AS hours
        FROM event_resource er
        JOIN event e ON e.eventId = er.eventId
        WHERE
            e.eventStatus <> 'cancelled'
            AND e.startAt < :end
            AND e.endAt > :start
    ),
    totals AS (
        SELECT
            resourceId,
            SUM(CASE WHEN eventType = 'experiment' THEN hours ELSE 0 END) AS booked,
            SUM(CASE WHEN eventType <> 'experiment' THEN hours ELSE 0 END) AS blocked
        FROM clipped
        GROUP BY resourceId
    )
SELECT
    r.resourceName AS resource,
    t.resourceTypeKind AS resource_kind,
    ROUND(COALESCE(x.booked, 0), 2) AS booked_hours,
    ROUND(COALESCE(x.blocked, 0), 2) AS blocked_hours,
    ROUND(
        (julianday(:end) - julianday(:start)) * 24 - COALESCE(x.blocked, 0),
        2
    ) AS available_hours
FROM resource r
JOIN resource_type t ON t.resourceTypeId = r.resourceTypeId
LEFT JOIN totals x ON x.resourceId = r.resourceId
ORDER BY booked_hours DESC, r.resourceId;
