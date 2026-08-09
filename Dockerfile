FROM dart:stable AS build

WORKDIR /app

# Copy the world_model package first (it's a local dependency of the agent).
COPY world_model/ world_model/

# Copy the agent package.
COPY agent/ agent/

# Resolve dependencies for the agent.
WORKDIR /app/agent
RUN dart pub get

# Compile the server to a native executable for fast startup and low memory usage on Cloud Run.
RUN dart compile exe bin/server.dart -o bin/server

# Build a minimal production image using a distroless base.
FROM scratch

# Copy the compiled native binary from the build stage.
COPY --from=build /runtime/ /
COPY --from=build /app/agent/bin/server /app/bin/server

# Cloud Run injects the PORT environment variable.
ENV PORT=8080
EXPOSE 8080

# Run the compiled server binary.
ENTRYPOINT ["/app/bin/server"]
