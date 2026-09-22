# Excluded from configured four-worker comparisons

This batch requested 100 runs/four workers after an eight-worker pilot. A dashboard lifecycle defect left four finished iframes alive in addition to the four configured active workers. The operator canceled the batch when this was observed. Do not pool this attempt into four-worker frame-time or completion-rate comparisons.

The exact artifacts remain unchanged. There were 306 dispatched requests, 1,883,806 known input tokens (~$0.07912), three canceled API requests with unknown provider usage, one completed stall assessment, four operator-stopped runs and 95 runs canceled before starting. See [the analysis](../../upgrade-pilot-analysis.md) for the evidence and subsequent harness correction.
