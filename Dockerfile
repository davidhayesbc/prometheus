# escape=`
ARG nanoServerVersion=1809
ARG baseImage=mcr.microsoft.com/windows/nanoserver

FROM $baseImage:$nanoServerVersion as build
ARG arcVersion=3.1.1
ARG prometheusVersion

#Download an archive tool
ENV arcUrl https://github.com/mholt/archiver/releases/download/v${arcVersion}/arc_windows_amd64.exe
RUN md c:\temp
RUN curl %arcUrl% -o c:\temp\arc.exe -L 

#Download Prometheus
ENV prometheusVersion $prometheusVersion
ENV prometheusFile=prometheus-${prometheusVersion}.windows-amd64
ENV prometheusUrl https://github.com/prometheus/prometheus/releases/download/v${prometheusVersion}/${prometheusFile}.tar.gz
RUN curl %prometheusUrl% -o c:\temp\prometheus.tar.gz -L

#extract the archive
RUN c:\temp\arc.exe unarchive c:\temp\prometheus.tar.gz c:\temp\prometheus 
#Move the Prometheus Directory to take aout the version number
WORKDIR  c:\temp\prometheus\
RUN rename %prometheusFile% prometheus

# Second build stage, copy the extracted files into a nanoserver container
FROM $baseImage:$nanoServerVersion
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