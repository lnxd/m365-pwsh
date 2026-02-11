FROM mcr.microsoft.com/dotnet/sdk:9.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    less \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 10001 -s /bin/bash pwsh
ENV HOME=/home/pwsh
ENV POWERSHELL_TELEMETRY_OPTOUT=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install PowerShell modules (pinned versions)
RUN pwsh -NoLogo -NoProfile -Command \
    "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
     Install-Module Microsoft.Graph -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
     Install-Module ExchangeOnlineManagement -RequiredVersion 3.9.2 -Scope AllUsers -Force"

WORKDIR /work
RUN chown -R pwsh:pwsh /work

USER pwsh

CMD ["sleep", "infinity"]
