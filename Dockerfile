# Use official Node.js LTS (Long Term Support) image
FROM node:20-alpine


# Install dependencies
RUN npm ci --only=production

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
