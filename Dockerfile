# Stage 1: Download and extract fonts
FROM --platform=linux/amd64 alpine:latest AS fonts
RUN apk add --no-cache curl unzip
RUN mkdir /fonts && \
    curl -sSL -o JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip && \
    unzip -j JetBrainsMono.zip 'JetBrainsMonoNerdFontPropo-*.ttf' -d /fonts

# Stage 2: Download binaries
FROM --platform=linux/amd64 alpine:latest AS binaries
ARG SLIDES_VERSION=0.9.0
ARG TTYD_VERSION=1.7.7
ARG LL_VERSION=0.0.11
ARG BAT_VERSION=0.26.0
RUN apk add --no-cache curl
RUN mkdir /bin-download && cd /bin-download && \
    curl -sSL https://github.com/maaslalani/slides/releases/download/v${SLIDES_VERSION}/slides_${SLIDES_VERSION}_linux_amd64.tar.gz | tar xz && \
    curl -sSL https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64 > ttyd && \
    curl -sSL https://github.com/fnando/ll/releases/download/v${LL_VERSION}/ll-x86_64-unknown-linux-gnu.tar.gz | tar xz && \
    curl -sSL https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz | tar xz && \
    mv bat-v${BAT_VERSION}-x86_64-unknown-linux-musl/bat . && \
    chmod +x slides ttyd ll bat

# Stage 3: Final image
FROM --platform=linux/amd64 ruby:3.4-alpine

# Install runtime dependencies and build tools
RUN apk add --no-cache \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    bash \
    bash-completion \
    build-base \
    ca-certificates \
    chromium \
    chromium-chromedriver \
    curl \
    fish \
    ffmpeg \
    font-liberation \
    font-noto \
    font-noto-emoji \
    freetype \
    git \
    gtk+3.0 \
    harfbuzz \
    imagemagick \
    jq \
    less \
    mesa-gl \
    nss \
    python3 \
    py3-pip \
    py3-virtualenv \
    sudo \
    ttf-dejavu \
    ttf-freefont \
    udev \
    zsh \
    && fc-cache -f

ARG USER=screenkit
ENV TERM=xterm-256color
ENV PATH="/venv/bin:/source/bin:/${USER}/bin:$PATH"
ENV CHROME_BIN=/usr/bin/chromium-browser
ENV CHROME_PATH=/usr/lib/chromium/

# Copy binaries and fonts from builder stages
COPY --from=binaries /bin-download/slides /usr/local/bin/slides
COPY --from=binaries /bin-download/ttyd /usr/local/bin/ttyd
COPY --from=binaries /bin-download/ll /usr/local/bin/ll
COPY --from=binaries /bin-download/bat /usr/local/bin/bat
COPY --from=fonts /fonts /usr/local/share/fonts

# Update font cache
RUN fc-cache -f

# Create user
RUN adduser -D -h /${USER} -s /bin/zsh -u 1001 ${USER} \
    && chown -R ${USER}:${USER} /${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER}

RUN mkdir -p /venv && chown -R ${USER}:${USER} /venv
RUN mkdir -p /${USER}-local && chown -R ${USER}:${USER} /${USER}-local

# Install screenkit gem
RUN gem install screenkit && \
    mkdir -p /usr/share/bash-completion/completions && \
    mkdir -p /usr/share/zsh/site-functions && \
    mkdir -p /usr/share/fish/vendor_completions.d && \
    screenkit completion --shell bash > /usr/share/bash-completion/completions/screenkit && \
    screenkit completion --shell zsh > /usr/share/zsh/site-functions/_screenkit && \
    screenkit completion --shell fish > /usr/share/fish/vendor_completions.d/screenkit.fish && \
    echo 'autoload -Uz compinit && compinit' >> /etc/zsh/zshrc && \
    echo 'source /usr/share/bash-completion/bash_completion' >> /etc/bash/bashrc && \
    apk del build-base

USER ${USER}
WORKDIR /${USER}

# Create Python virtual environment
RUN python3 -m venv /venv
RUN /venv/bin/pip install ffmpeg-normalize

WORKDIR /source

ENTRYPOINT [ "screenkit" ]
