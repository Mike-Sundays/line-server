# README

## Summary

This is a rails application that serves the requested line of a preloaded file, through a REST API. It has one endpoint:

`GET /lines/<line index>`

Since it is not mentioned, I assume that the line indexes start at 0, so asking for line 0 will give the first line, and so on.

**Assumptions**
- Each line is terminated with a newline ("\n").
- Any given line will fit into memory.
- The line is valid ASCII (e.g. not Unicode).

## How to setup

The application has several dependencies:
- A ruby version needs to be installed (I used 3.3.6)
- Docker also needs to be installed (we will run redis containers)

To setup the project, run the `setup.sh` script with the `./setup.sh` command.

This will setup 3 redis instances, for each environment (dev, test - used for tests, prod). It will also run bundle install to 
install all the gems

## How to run

To run the server, execute the following command:

```bash
./run.sh <path_of_the_file_to_be_loaded>
```

To run the tests, use `rails test`

## Questions

**How does the system work?**

As the system boots up, the several rails initializers will run. `initialize_redis_connection_pool` and `reusable_file_handlers`
will create connection pools both for communicating with redis and for opening files.

The `precompute_line_beggining.rb` will also run - and this is an important part of the system. It will call the `save_line_offset_to_redis.rb`
at the server startup.

The logic of the file will be responsible for reading the byte offset of the beginning of each line. Since each line is valid ASCII, we know that
each char will occupy 1 byte. For example, if the file content is:

```
Chasing dreams under neon lights.
Whispers of adventure in the wind.

Lost in thought, found in motion.
```

The byte offsets will be `[0, 34, 69, 70]`. So, the idea is to precompute the offsets and save them on a hash on redis (with the line numbers as keys,
and the calculated offsets as values) for quick retrieval as the endpoint is called. 

If they already exist on redis, we do not recalculate them again.

This is a computationally expensive operation, but it will only run at the startup of the server. After that, we will have O(1) access time on redis,
because we can use [File#seek](https://ruby-doc.org/3.3.7/File.html) to travel directly to the precomputed offset corresponding the beginning of each line.

I tried to optimize the pre-computations, as I explain in the following section.

**How will your system perform with a 1 GB file? a 10 GB file? a 100 GB file?**

This logic is in `save_line_offset_to_redis.rb`

The pre-computation of the files will be an expensive operation. I tried to optimize it in the following way:

- Using the parallel gem to spawn various processes. Each one will read a certain chunk of the file. For example, for a file
with 100 000 lines, process 1 will read from 0 to 24999, process 2 from 25000 to 49999 and so on.
- Each process will save the line numbers and offsets to the hash and save them to redis in batches of a certain size. This will minimize
the number of network calls. I also use [pipelining](https://redis.io/docs/latest/develop/use/pipelining/) to make the operation more efficient.
- Only one line of the file is in memory at each time with [File#each_line](https://stackoverflow.com/a/39033675)

From my benchmarks, using more than 4 processes had diminishing returns. With 4, I had:

- File with 100000 lines 0.219378 seconds ~ `456 621 lines/second`. File size: 2.47 MB ~ `11.26 MB/second` 
- File with 10000000 precomputed in 21.672352 seconds ~ `461 424 lines/second`. File size: 266 MB ~ `12.28 MB/second`
- File with 100000000 precomputed in 508.090569 seconds ~ `196 815 lines/second`. File size: 2.69 GB ~ `5.3 MB/second`

This was tested on a Mac M1 Air 2020. 

I did not the time to benchmark anymore. But we are getting diminishing performance for bigger files. This may be due to several factors:
- Each chunk will probably occupy more memory for larger files
- Larger files are normally [slower to be read](https://stackoverflow.com/questions/70910606/ssd-single-large-disk-read-vs-many-small-disk-reads#:~:text=Thus%2C%20keep%20in%20mind%20that,caches%20on%20high%2Dperformance%20SSDs.)
- Communication overhead with redis
- I am using only one redis hash instead of separating it in several, [which degrades performance](https://stackoverflow.com/questions/24617615/redis-optimal-hash-set-entry-size)

If I had more time, I would probably benchmark with different `num_of_processes` and `batch_size`, and try to find a formula 
to calculate the optimum size. I would also separate the big redis hash into several smaller hashes that span a certain interval of lines - this could
even open the door to having them distributed in several redis instances (sharding).

**How will your system perform with 100 users? 10000 users? 1000000 users?**

As mentioned before, as the line offsets are stored in Redis, we can have fast read access to them by just using `File#seek` and traveling
directly to the byte position at the beginning of the line. This is handled by `line_reader.rb`:

- It does some initial validations to check if the file exists and the line number is within the range of the file.
- If so, we have an in-memory caching layer (following LRU eviction to evict the least requested ones if cache is full), which is checked first to see if the line has already been asked and cached.
- If not, we go to redis, get the line offset, travel directly to it in the file and get the value of the line. We cache it and return it to the user.

The performance here is dependent on several factors:

- Puma number of threads and worker processes
- Balance between file handler pool and redis connection pool.
- Line is already cached or not.

I did some benchmarks for 100 concurrent users with the `wrk` terminal program: 

- Puma - 16 Threads, 4 workers (16*4 = 64 total number of threads)
- Redis - 64 connection pool size
- File pool - 64 connection pool size
- No caching of lines enabled

```
wrk -t12 -c100 -d30s http://localhost:3000/api/line/1 
Running 30s test @ http://localhost:3000/api/line/1
  12 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    47.75ms   46.85ms 528.02ms   83.46%
    Req/Sec   218.42     53.93   380.00     70.43%
  78362 requests in 30.07s, 39.44MB read
Requests/sec:   2605.63
Transfer/sec:      1.31MB
```

Though it has some spikes (large max value of latency, probably thread contention), it is generally a good performance result. 
If I enable the cache.

```
wrk -t12 -c100 -d30s http://localhost:3000/api/line/1 
Running 30s test @ http://localhost:3000/api/line/1
  12 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    45.31ms   45.00ms 372.45ms   83.37%
    Req/Sec   232.88     57.46   430.00     69.85%
  83515 requests in 30.09s, 42.04MB read
Requests/sec:   2775.72
Transfer/sec:      1.40MB
```

It has a small improvement.

For 1000 concurrent requests (no caching), it is clearly not enough:

```
wrk -t12 -c1000 -d30s http://localhost:3000/api/line/1
Running 30s test @ http://localhost:3000/api/line/1
  12 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   127.18ms  260.49ms   2.00s    90.71%
    Req/Sec   107.88     82.42   474.00     68.42%
  34822 requests in 30.06s, 17.53MB read
  Socket errors: connect 0, read 228201, write 1684, timeout 216
Requests/sec:   1158.54
Transfer/sec:    597.17KB
```

I had a tremendous amount of socket read errors, higher latency and less requests per second indicating that the current configurations are clearly not sufficient.
Unfortunately, I did not have more time to further optimize, since I only had a week. Ideas:

- Finding a better balance of pool sizes for file handlers and redis connections, taking into account the Puma server configs.
- Monitoring redis and disk usage to find where the bottleneck is


**What documentation, websites, papers, etc did you consult in doing this assignment?**

The already mentioned links, and:

- [Idea of reading lines from large files](https://stackoverflow.com/questions/71446467/what-is-the-fastest-way-to-read-a-line-from-a-very-large-file-when-you-know-the)
- [Redis gem documentation, with performance suggestions](https://github.com/redis/redis-rb?tab=readme-ov-file#pipelining)
- [Ruby parallel gem docs](https://github.com/grosser/parallel)

**What third-party libraries or other tools does the system use? How did you choose each library or framework you used?**

- LRU Cache - looking for an efficient LRU cache to evict the less requested number of lines, this seemed like it had good benchmarks on Github
and is thread safe (even though it is somewhat old).
- Parallel - for parallelization, high number of stars on github 
- Redis-rb - redis client that matches closely the Redis API, which was useful for commands such as `hmset` to save the redis hashes.

**How long did you spend on this exercise? If you had unlimited more time to spend on this, how would you spend it and how would you prioritize each item?**

I spent 4 hours each day, during 7 days. If I had more time, I would:

- Have investigated further how to optimize for a high number of concurrent users (guided by benchmarks)
- Refactored the code to make it more clear (smaller methods, single responsibility classes, more readability)
- Do a larger number of tests (test the caching layer, have more variability in the text files I use for testing, think more about edge cases)
- At the moment, I have configuration values hardcoded, which is not a good practice, so I would probably have an .env file with those (puma threads, workers, connection pool sizes, cache sizes, ...) for different env's
- Also try to optimize further the initial file processing (after I had optimized for concurrency, since that is the main issue)

**If you were to critique your code, what would you have to say about it?**

See above.