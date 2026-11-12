FROM ubuntu:22.04
RUN apt-get update && apt-get install -y wget unzip
WORKDIR /app

# Scarica il motore server ufficiale di Godot 4 direttamente su Render
RUN wget https://github.com \
    && unzip Godot_v4.3-stable_linux.x86_64.zip \
    && mv Godot_v4.3-stable_linux.x86_64 godot_server \
    && chmod +x godot_server \
    && rm Godot_v4.3-stable_linux.x86_64.zip

COPY server.pck ./
EXPOSE 8080
CMD ["./godot_server", "--headless", "--main-pack", "server.pck"]
