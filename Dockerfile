# Dockerfile for Strong4Life
# Multi-stage build for production

# ===========================================
# Stage 1: Build
# ===========================================
ARG ELIXIR_VERSION=1.17.3
ARG OTP_VERSION=27.2
ARG DEBIAN_VERSION=bullseye-20241202

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}-slim"

FROM ${BUILDER_IMAGE} AS builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV="prod"

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

# Compile the release (must run before assets to generate colocated hooks)
RUN mix compile

# Compile assets
RUN mix assets.deploy

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

# Copy release overlays
COPY rel rel

# Generate release
RUN mix release

# ===========================================
# Stage 2: Runtime
# ===========================================
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app
RUN chown nobody /app

# Set runner ENV
ENV MIX_ENV="prod"
ENV PHX_SERVER=true

# Only copy the final release from the build stage
COPY --from=builder /app/_build/${MIX_ENV}/rel/strong4life ./

# Set permissions and ownership (must be done before USER switch)
# Use 755 to ensure binaries are executable by any user (needed for docker-compose user override)
RUN chmod -R 755 /app/bin && \
    chown -R nobody:root /app

USER nobody

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

EXPOSE 4000

CMD ["/app/bin/server"]
