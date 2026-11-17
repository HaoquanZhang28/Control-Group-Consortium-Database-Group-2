SELECT
    p.personName AS person,
    q.qualificationName AS qualification,
    pq.validTo AS expires_at,
    CAST(julianday(pq.validTo) - julianday(:at) AS INTEGER) AS days_remaining,
    COUNT(DISTINCT rr.resourceId) AS required_resources
FROM person_qualification pq
JOIN person p ON p.personId = pq.personId
JOIN qualification q ON q.qualificationId = pq.qualificationId
JOIN resource_requirement rr ON rr.qualificationId = q.qualificationId
WHERE
    pq.validTo > :at
    AND julianday(pq.validTo) <= julianday(:at) + 60
    AND NOT EXISTS (
        SELECT 1
        FROM person_qualification newer
        WHERE
            newer.personId = pq.personId
            AND newer.qualificationId = pq.qualificationId
            AND newer.validFrom <= pq.validTo
            AND newer.validTo > pq.validTo
    )
GROUP BY pq.personQualificationId
ORDER BY pq.validTo, p.personId;
