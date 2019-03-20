# escape=`
ARG nanoServerVersion=1809
FROM mcr.microsoft.com/powershell:nanoserver-$nanoServerVersion as build
SHELL [ "pwsh", "-command" ]

#Download an archive tool
ENV arcVersion 3.1.1
ENV arcUrl https://github.com/mholt/archiver/releases/download/v${arcVersion}/arc_windows_amd64.exe
RUN Invoke-WebRequest ($env:arcUrl) -UseBasicParsing -OutFile arc.exe

#Download Prometheus
ENV prometheusVersion 2.8.0
ENV prometheusUrl https://github.com/prometheus/prometheus/releases/download/v${prometheusVersion}/prometheus-${prometheusVersion}.windows-amd64.tar.gz
RUN Invoke-WebRequest ($env:prometheusUrl) -UseBasicParsing -OutFile prometheus.tar.gz

#extract the archive
RUN .\arc.exe unarchive .\prometheus.tar.gz .\prometheus 

# Second build stage, copy the extracted files into a nanoserver container
FROM mcr.microsoft.com/windows/nanoserver:$nanoServerVersion
ENV prometheusVersion 2.8.0
COPY --from=build /prometheus/prometheus-${prometheusVersion}.windows-amd64/ /prometheus

#Expose a port from the container
EXPOSE     9090

ENTRYPOINT [ "C:\\prometheus\\prometheus.exe" ]

CMD        [ "--config.file=/prometheus/prometheus.yml", `
             "--storage.tsdb.path=/prometheus", `
             "--web.console.libraries=/prometheus/console_libraries", `
             "--web.console.templates=/prometheus/consoles" ]