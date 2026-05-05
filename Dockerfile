# =============================================================================
# LiteLLM Proxy - Dockerfile
# =============================================================================
# Builds the LiteLLM proxy with custom configuration.
# =============================================================================

FROM ghcr.io/berriai/litellm:main-latest

# Copy custom configuration
COPY litellm_config.yaml /app/litellm_config.yaml

# Expose the proxy port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Run the proxy
CMD ["--config", "/app/litellm_config.yaml", "--port", "4000", "--host", "0.0.0.0"]
