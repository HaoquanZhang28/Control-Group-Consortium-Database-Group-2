SELECT
    substr(i.periodStart, 1, 7) AS billing_month,
    COUNT(DISTINCT i.invoiceId) AS invoices,
    SUM(CASE WHEN i.status = 'paid' THEN ca.amount ELSE 0 END) AS paid_amount,
    SUM(CASE WHEN i.status = 'issued' THEN ca.amount ELSE 0 END) AS outstanding_amount,
    SUM(ca.amount) AS invoiced_amount
FROM invoice i
JOIN invoice_lines il ON il.invoiceId = i.invoiceId
JOIN charge_allocation ca ON ca.chargeAllocationId = il.chargeAllocationId
WHERE i.periodStart >= :start AND i.periodStart < :end
GROUP BY substr(i.periodStart, 1, 7)
ORDER BY billing_month;
