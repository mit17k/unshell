-- Agent runs per workspace over the last week, with failure rate.
WITH recent_runs AS (
    SELECT
        r.workspace_id,
        r.agent,
        r.status,
        r.finished_at - r.started_at AS duration
    FROM agent_runs AS r
    WHERE r.started_at >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT
    w.name                                              AS workspace,
    COUNT(*)                                            AS runs,
    ROUND(AVG(EXTRACT(EPOCH FROM rr.duration)), 1)      AS avg_seconds,
    ROUND(100.0 * SUM(CASE WHEN rr.status = 'failed' THEN 1 ELSE 0 END) / COUNT(*), 2)
                                                        AS failure_pct
FROM recent_runs AS rr
JOIN workspaces AS w ON w.id = rr.workspace_id
GROUP BY w.name
HAVING COUNT(*) > 10
ORDER BY failure_pct DESC, runs DESC
LIMIT 20;
