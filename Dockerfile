# escape=`
ARG nanoServerVersion=1809
FROM mcr.microsoft.com/powershell:nanoserver-$nanoServerVersion as build
SHELL [ "pwsh", "-command" ]

#Download an archive tool
ENV arcVersion 3.1.1
ENV arcUrl https://github.com/mholt/archiver/releases/download/v${arcVersion}/arc_windows_amd64.exe
RUN md c:\temp
RUN Invoke-WebRequest ($env:arcUrl) -UseBasicParsing -OutFile c:\temp\arc.exe

#Download Prometheus
ENV prometheusVersion 2.8.1
ENV prometheusUrl https://github.com/prometheus/prometheus/releases/download/v${prometheusVersion}/prometheus-${prometheusVersion}.windows-amd64.tar.gz
RUN Invoke-WebRequest ($env:prometheusUrl) -UseBasicParsing -OutFile prometheus.tar.gz

#extract the archive
RUN c:\temp\arc.exe unarchive .\prometheus.tar.gz .\prometheus 

RUN mv .\prometheus\prometheus-$env:prometheusVersion.windows-amd64\ .\prometheus\prometheus

# Second build stage, copy the extracted files into a nanoserver container
FROM mcr.microsoft.com/windows/nanoserver:$nanoServerVersion
COPY --from=build /prometheus/prometheus/ /prometheus

#Expose a port from the container
EXPOSE     9090

#Expose a volume
VOLUME ["C:\\data"]

ENTRYPOINT [ "C:\\prometheus\\prometheus.exe" ]

CMD        [ "--config.file=/prometheus/prometheus.yml", `
             "--storage.tsdb.path=/data", `
             "--web.console.libraries=/prometheus/console_libraries", `
             "--web.console.templates=/prometheus/consoles" ]