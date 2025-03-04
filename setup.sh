docker run --name redis_dev -p 6379:6379 -d redis
docker run --name redis_test -p 6380:6379 -d redis
docker run --name redis_prod -p 6381:6379 -d redis
