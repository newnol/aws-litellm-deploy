# ============================================================
# Dockerfile for LiteLLM Proxy
# ============================================================
FROM ghcr.io/berriai/litellm:main-latest

WORKDIR /app

# Expose LiteLLM port
EXPOSE 4000

# Health check using python3 urllib (curl not available in litellm image)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/readiness')" || exit 1

# Run LiteLLM proxy
CMD ["--port", "4000", "--host", "0.0.0.0"]
