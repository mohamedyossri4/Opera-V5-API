# Use official Node.js LTS (Long Term Support) image
FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Install Oracle Instant Client dependencies
# Required for oracledb to work
RUN apk add --no-cache libaio libnsl libc6-compat wget unzip && \
  mkdir -p /usr/lib/instantclient && \
  cd /tmp && \
  wget https://download.oracle.com/otn_software/linux/instantclient/219000/instantclient-basiclite-linux.x64-21.9.0.0.0dbru.zip && \
  unzip instantclient-basiclite-linux.x64-21.9.0.0.0dbru.zip && \
  mv instantclient_*_*/* /usr/lib/instantclient/ && \
  rm -rf instantclient-basiclite-linux.x64-21.9.0.0.0dbru.zip instantclient_*_* && \
  rm -f /usr/lib/instantclient/libclntsh.so /usr/lib/instantclient/libocci.so && \
  ln -s /usr/lib/instantclient/libclntsh.so.21.1 /usr/lib/instantclient/libclntsh.so && \
  ln -s /usr/lib/instantclient/libocci.so.21.1 /usr/lib/instantclient/libocci.so

# Set Oracle environment variables
ENV LD_LIBRARY_PATH=/usr/lib/instantclient

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy application source code
COPY src ./src

# Create a non-root user for security
RUN addgroup -g 1001 -S nodejs && \
  adduser -S nodejs -u 1001 && \
  chown -R nodejs:nodejs /usr/src/app

# Switch to non-root user
USER nodejs

# Expose application port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the application
CMD ["npm", "start"]
