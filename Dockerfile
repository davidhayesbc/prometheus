# escape=`
ARG nanoServerVersion=1809
FROM mcr.microsoft.com/powershell:nanoserver-$nanoServerVersion as build
ARG arcVersion=3.1.1
ARG prometheusVersion
SHELL [ "pwsh", "-command" ]

#Download an archive tool
ENV arcUrl https://github.com/mholt/archiver/releases/download/v${arcVersion}/arc_windows_amd64.exe
RUN md c:\temp
RUN Invoke-WebRequest ($env:arcUrl) -UseBasicParsing -OutFile c:\temp\arc.exe

#Download Prometheus
ENV prometheusVersion $prometheusVersion
ENV prometheusUrl https://github.com/prometheus/prometheus/releases/download/v${prometheusVersion}/prometheus-${prometheusVersion}.windows-amd64.tar.gz
RUN Invoke-WebRequest ($env:prometheusUrl) -UseBasicParsing -OutFile c:\temp\prometheus.tar.gz

#extract the archive
RUN c:\temp\arc.exe unarchive c:\temp\prometheus.tar.gz c:\temp\prometheus 
#Move the Prometheus Directory to take aout the version number
RUN mv c:\temp\prometheus\prometheus-$env:prometheusVersion.windows-amd64\ c:\temp\prometheus\prometheus

# Second build stage, copy the extracted files into a nanoserver container
FROM mcr.microsoft.com/windows/nanoserver:$nanoServerVersion
COPY --from=build c:/temp/prometheus/prometheus/ /prometheus
LABEL maintainer="david.hayes@spindriftpages.net"

#Expose a port from the container
EXPOSE     9090

#Expose a volume
VOLUME ["C:\\data"]

ENTRYPOINT [ "C:\\prometheus\\prometheus.exe" ]

CMD        [ "--config.file=/prometheus/prometheus.yml", `
             "--storage.tsdb.path=/data", `
             "--web.console.libraries=/prometheus/console_libraries", `
             "--web.console.templates=/prometheus/consoles" ]