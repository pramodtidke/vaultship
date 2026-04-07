# ---- Build stage ----
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files first (layer caching)
COPY app/package*.json ./

# Install only production deps
RUN npm install --omit=dev

# ---- Final stage ----
FROM node:18-alpine AS final

# Run as non-root user (security best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy deps from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy app source
COPY app/index.js ./

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "index.js"]
