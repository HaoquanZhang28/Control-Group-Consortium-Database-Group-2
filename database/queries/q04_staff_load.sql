WITH
    availability AS (
        SELECT
            personId,
            SUM(
                (julianday(MIN(endAt, :end)) - julianday(MAX(startAt, :start))) * 24
            ) AS hours
        FROM staff_availability
        WHERE startAt < :end AND endAt > :start
        GROUP BY personId
    ),
    assignments AS (
        SELECT
            sa.personId,
            COUNT(*) AS event_count,
            SUM(
                (julianday(MIN(e.endAt, :end)) - julianday(MAX(e.startAt, :start))) * 24
            ) AS hours
        FROM staff_assignment sa
        JOIN event e ON e.eventId = sa.eventId
        WHERE
            e.eventStatus <> 'cancelled'
            AND e.startAt < :end
            AND e.endAt > :start
        GROUP BY sa.personId
    )
SELECT
    p.personName AS staff_member,
    ROUND(v.hours, 2) AS available_hours,
    COALESCE(a.event_count, 0) AS assigned_events,
    ROUND(COALESCE(a.hours, 0), 2) AS assigned_hours,
    ROUND(100.0 * COALESCE(a.hours, 0) / NULLIF(v.hours, 0), 2) AS workload_pct
FROM availability v
JOIN person p ON p.personId = v.personId
LEFT JOIN assignments a ON a.personId = v.personId
ORDER BY workload_pct DESC, p.personId;
