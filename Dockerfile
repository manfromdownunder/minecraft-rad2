# Use a minimal Debian base image
FROM debian:bullseye-slim

# Set build-time variables
ARG JAVA_VERSION="temurin-8-jdk"

# Set default environment variables
ENV MINECRAFT_VERSION="1.16.5" \
    SERVER_PORT="25565" \
    ...

# Install initial dependencies and tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common wget git curl unzip tar nano logrotate gnupg2 apt-transport-https && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/apt/keyrings && \
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print $2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends $JAVA_VERSION && \
    curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    apt-get install -y libxfixes3 libxdamage1 libxcomposite1 libatk1.0-0 libnss3 libxss1 libasound2 libpangocairo-1.0-0 libcups2 libxrandr2 libgbm1 libatk-bridge2.0-0 libxkbcommon0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a directory for the Minecraft server
WORKDIR /minecraft-server

# Clone the install repo, download mods and perform cleanup
RUN git clone https://github.com/manfromdownunder/docker-minecraft-rad2.git && \
    cp docker-minecraft-rad2/downloadmods.sh . && \
    cp docker-minecraft-rad2/modslist.txt . && \
    cp docker-minecraft-rad2/downloadFromCurseForge.js . && \
    chmod +x ./downloadmods.sh && \
    ./downloadmods.sh modslist.txt 

# Accept the Minecraft EULA and configure server properties
RUN echo "eula=true" > eula.txt && \
    { \
        echo "enable-rcon=${RCON_ENABLED}"; \
        echo "rcon.password=${RCON_PASSWORD}"; \
        echo "rcon.port=${RCON_PORT}"; \
        echo "difficulty=${DIFFICULTY}"; \
        echo "gamemode=${GAMEMODE}"; \
        echo "hardcore=${HARDCORE}"; \
        echo "level-name=${LEVEL_NAME}"; \
        echo "level-seed=${LEVEL_SEED}"; \
        echo "max-build-height=${MAX_BUILD_HEIGHT}"; \
        echo "max-players=${MAX_PLAYERS}"; \
        echo "motd=${MOTD}"; \
        echo "player-idle-timeout=${PLAYER_IDLE_TIMEOUT}"; \
        echo "prevent-proxy-connections=${PREVENT_PROXY_CONNECTIONS}"; \
        echo "pvp=${PVP}"; \
        echo "snooper-enabled=${SNOOPER_ENABLED}"; \
        echo "view-distance=${VIEW_DISTANCE}"; \
        echo "allow-flight=${ALLOW_FLIGHT}"; \
        echo "allow-nether=${ALLOW_NETHER}"; \
    } > server.properties

# Copy the start-server script into the image
COPY start-server.sh /minecraft-server/start-server.sh

# Make the script executable
RUN chmod +x /minecraft-server/start-server.sh

# Expose the Minecraft server port and RCON port
EXPOSE $SERVER_PORT $RCON_PORT

# Start the Minecraft server via the script
CMD ["/minecraft-server/start-server.sh"]
