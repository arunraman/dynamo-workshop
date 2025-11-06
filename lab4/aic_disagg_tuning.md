# Advanced Disagg Perf Tuning 
## Challenges in Disaggregated Serving Deployment
__Challenge1__ – Is disaggregated serving always better than aggregated serving? How much perf gain is reasonable?

A: For example, considering __ISL:OSL=1:4000__, do we have perf gain by using disaggregated serving? – __NO__

__Challenge2__ – How to configure disaggregated serving to solve the problem __throughput @ latency__

- Parallelism of the worker
- How many p and d
- Depend on ISL, OSL, TTFT, TPOT
- The tuning efforts are tremendous

![challenges_in_disagg](images/challenges_in_disagg.png)

## Disagg pd QPS Matching Methology 
### We can firstly __find a worker that meets SLA and under constraints__

- Enumerate parallelism combination of a worker, tp x pp x attn dp x moe tp x moe ep
- Find max batch size of the worker which meets TTFT and TPOT respectively (Disagg is awesome! We can achieve this separately)
- Ensure there's no OOM

![find_worker_SLA](images/find_worker_SLA.png)

### __Match__ the N prefill worker candidates with M decode worker candidates in view of __sequence throughput seq/s__

- Seq/s of prefill = how many sequences I can process and finish context phase per second => __producer__
- Seq/s of decode = how many sequences I can process and finish the whole generation phase per second => __consumer__
- The throughput should __match__ between xP and yD
- Finally, sweep X and Y for a given (prefill, decode) worker combination, find the best seq/s/gpu, thus the best tokens/s/gpu

![qps_match](images/qps_match.png)

# disagg best perf tuning based on AIC