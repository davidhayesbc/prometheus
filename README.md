# prometheus
Prometheus Docker Container on Windows nanoserver
Sample run
docker run -it -p 80:9090 --mount source=prometheusData,target=c:/data local/prom --storage.tsdb.path=/data --config.file=/data/prometheus.yml   