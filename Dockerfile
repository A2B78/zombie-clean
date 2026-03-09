# ======================================================
# PipelineAI - Generated Dockerfile (Generic)
# ======================================================

FROM ubuntu:22.04
WORKDIR /app
COPY . .
EXPOSE 3000
CMD ["./start.sh"]
