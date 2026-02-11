FROM mcr.microsoft.com/dotnet/sdk:9.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    less \
    gnupg \
    lsb-release \
  && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN useradd -m -u 10001 -s /bin/bash pwsh
ENV HOME=/home/pwsh
ENV POWERSHELL_TELEMETRY_OPTOUT=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install PowerShell modules
# NOTE: Microsoft.Graph meta-package doesn't install all sub-modules.
# Install the specific sub-modules we need explicitly.
RUN pwsh -NoLogo -NoProfile -Command " \
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module Microsoft.Graph.Authentication -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.Users -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.Groups -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.Identity.DirectoryManagement -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.DeviceManagement -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.DeviceManagement.Administration -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.DeviceManagement.Enrollment -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.Sites -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.Mail -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.Reports -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.Identity.Governance -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module Microsoft.Graph.DirectoryObjects -RequiredVersion 2.35.1 -Scope AllUsers -Force; \
    Install-Module ExchangeOnlineManagement -RequiredVersion 3.9.2 -Scope AllUsers -Force"

WORKDIR /work
RUN chown -R pwsh:pwsh /work

USER pwsh

CMD ["sleep", "infinity"]
