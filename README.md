# Oracle Opera Hospitality v5 REST API

A Node.js backend service that exposes REST API endpoints to communicate with an on-premises Oracle Opera Hospitality v5 database.

## Features

- **RESTful API**: Clean, modular REST API endpoints for guest management
- **Oracle Integration**: Production-ready connection pooling with the Oracle Opera v5 database
- **Docker Support**: Fully containerized for easy deployment
- **Error Handling**: Comprehensive error handling with proper HTTP status codes
- **Transaction Management**: ACID-compliant database operations with commit/rollback
- **Health Monitoring**: Built-in health check endpoint
- **Audit Logging**: Comprehensive logging of all API requests and responses to database
- **License Management**: API key validation with expiration, IP restrictions, and usage limits
- **Input Validation**: Robust validation of all inputs

## Tech Stack

- **Runtime**: Node.js 20 LTS
- **Framework**: Express.js
- **Database Driver**: node-oracledb
- **Deployment**: Docker & Docker Compose

## Prerequisites

- Docker and Docker Compose installed
- Access to an Oracle Opera Hospitality v5 database
- Network connectivity to the Oracle database from your Docker host

## Project Structure

```
opera-v5-api/
├── src/
│   ├── server.js                 # Main server file
│   ├── controllers/
│   │   └── guestController.js    # Guest business logic
│   ├── routes/
│   │   └── guestRoutes.js        # Guest API routes
│   └── db/
│       └── oracleClient.js       # Oracle connection pool
├── Dockerfile                     # Docker image definition
├── docker-compose.yml             # Docker Compose configuration
├── package.json                   # Node.js dependencies
├── .env.example                   # Environment variables template
└── README.md                      # This file
```

## Configuration

### Environment Variables

Create a `.env` file in the project root by copying `.env.example`:

```bash
cp .env.example .env
```

Then configure the following variables:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `ORACLE_HOST` | Oracle database host/IP address | - | Yes |
| `ORACLE_PORT` | Oracle database port | 1521 | No |
| `ORACLE_SERVICE_NAME` | Oracle service name or SID | - | Yes |
| `ORACLE_USER` | Database username | - | Yes |
| `ORACLE_PASSWORD` | Database password | - | Yes |
| `PORT` | Application port | 3000 | No |
| `NODE_ENV` | Environment (production/development) | production | No |
| `ORACLE_POOL_MIN` | Minimum connections in pool | 2 | No |
| `ORACLE_POOL_MAX` | Maximum connections in pool | 10 | No |
| `ORACLE_POOL_INCREMENT` | Connection pool increment | 2 | No |

### Example `.env` file:

```env
ORACLE_HOST=192.168.1.100
ORACLE_PORT=1521
ORACLE_SERVICE_NAME=OPERA
ORACLE_USER=opera_user
ORACLE_PASSWORD=SecurePassword123
PORT=3000
NODE_ENV=production
ORACLE_POOL_MIN=2
ORACLE_POOL_MAX=10
ORACLE_POOL_INCREMENT=2
```

## Installation & Running

### Option 1: Using Docker Compose (Recommended)

1. **Clone the repository** (or copy all files to your directory)

2. **Configure environment variables** (create `.env` file as shown above)

3. **Build and start the container**:
   ```bash
   docker-compose up -d --build
   ```

4. **Check logs**:
   ```bash
   docker-compose logs -f backend
   ```

5. **Stop the service**:
   ```bash
   docker-compose down
   ```

### Option 2: Using Docker directly

1. **Build the image**:
   ```bash
   docker build -t opera-api .
   ```

2. **Run the container**:
   ```bash
   docker run -d \
     --name opera-api-backend \
     -p 3000:3000 \
     -e ORACLE_HOST=your-host \
     -e ORACLE_PORT=1521 \
     -e ORACLE_SERVICE_NAME=your-service \
     -e ORACLE_USER=your-user \
     -e ORACLE_PASSWORD=your-password \
     opera-api
   ```

### Option 3: Local Development (without Docker)

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Configure environment** (create `.env` file)

3. **Start the server**:
   ```bash
   npm start
   ```

   Or for development with auto-reload:
   ```bash
   npm run dev
   ```

## API Endpoints

### Health Check

Check if the service is running:

```bash
curl http://localhost:3000/health
```

**Response**:
```json
{
  "status": "ok"
}
```

### Get Guest Information

Retrieve guest information by NAME_ID:

**Endpoint**: `GET /api/guests/:nameId`

**Example**:
```bash
curl http://localhost:3000/api/guests/12345
```

**Success Response** (200):
```json
{
  "nameId": 12345,
  "guestName": "John Doe"
}
```

**Error Responses**:

- **400 Bad Request** (invalid nameId):
  ```json
  {
    "error": "Bad Request",
    "message": "nameId must be a valid numeric value"
  }
  ```

- **404 Not Found** (guest doesn't exist):
  ```json
  {
    "error": "Not Found",
    "message": "Guest with nameId 12345 not found"
  }
  ```

- **500 Internal Server Error** (database error):
  ```json
  {
    "error": "Internal Server Error",
    "message": "An error occurred while retrieving guest information"
  }
  ```

### Update Guest Information

Update guest information by confirmation number:

**Endpoint**: `PUT /api/guests/:confirmationNo`

**Headers**:
- `Content-Type: application/json`
- `x-api-key: your-license-key` (required for authentication)

**URL Parameter**:
- `confirmationNo` - The reservation confirmation number (numeric)

**Request Body Parameters** (at least one required):
- `first_name` (string, optional) - Guest's first name
- `last_name` (string, optional) - Guest's last name
- `address` (string, optional) - Guest's address
- `doc_type` (string, optional) - Document type (e.g., "PASSPORT", "ID")
- `doc_number` (string, optional) - Document number

**Example**:
```bash
curl -X PUT http://localhost:3000/api/guests/12345 \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-license-key" \
  -d '{
    "first_name": "Jane",
    "last_name": "Smith",
    "address": "123 Main Street",
    "doc_type": "PASSPORT",
    "doc_number": "AB123456"
  }'
```

**Request Body** (you can update one or more fields):
```json
{
  "first_name": "Jane",
  "last_name": "Smith",
  "address": "123 Main Street",
  "doc_type": "PASSPORT",
  "doc_number": "AB123456"
}
```

**Success Response** (200):
```json
{
  "confirmationNo": 12345,
  "nameId": 67890,
  "updatedFields": ["first_name", "last_name", "address", "doc_type", "doc_number"],
  "message": "Guest information updated successfully"
}
```

**Error Responses**:

- **400 Bad Request** (invalid confirmationNo):
  ```json
  {
    "error": "Bad Request",
    "message": "confirmationNo must be a valid numeric value"
  }
  ```

- **400 Bad Request** (no fields provided):
  ```json
  {
    "error": "Bad Request",
    "message": "At least one field must be provided for update (first_name, last_name, address, doc_type, doc_number)"
  }
  ```

- **404 Not Found** (confirmation number doesn't exist):
  ```json
  {
    "error": "Not Found",
    "message": "Guest with confirmation number 12345 not found"
  }
  ```

- **500 Internal Server Error** (database error):
  ```json
  {
    "error": "Internal Server Error",
    "message": "An error occurred while updating guest information"
  }
  ```

## License Management & Audit Logging

### API Authentication

All API endpoints (except `/health`) require a valid license key passed in the `x-api-key` header.

```bash
curl -H "x-api-key: your-license-key" http://localhost:3000/api/guests/12345
```

### License Features

The system supports:
- **Expiration Dates**: Licenses automatically expire after a set date
- **IP Restrictions**: Restrict access to specific IP addresses
- **Rate Limiting**: Set daily request limits per license
- **Active Status**: Instantly revoke access by deactivating a license

### Audit Logs

Every API request is logged to the `API_REQUEST_LOG` table with:
- Request details (method, path, headers, body)
- Response details (status, body, duration)
- Client info (IP, user agent)
- License key used

For detailed database setup and management, see [database/README.md](database/README.md).

## Testing Examples

### Complete Test Workflow

```bash
# 1. Check service health
curl http://localhost:3000/health

# 2. Get guest information (assuming guest with ID 100 exists)
curl http://localhost:3000/api/guests/100

# 3. Update guest name
curl -X PUT http://localhost:3000/api/guests/100 \
  -H "Content-Type: application/json" \
  -d '{"guestName": "Updated Guest Name"}'

# 4. Verify the update
curl http://localhost:3000/api/guests/100

# 5. Test error handling - invalid nameId
curl http://localhost:3000/api/guests/abc

# 6. Test error handling - non-existent guest
curl http://localhost:3000/api/guests/999999
```

### Using PowerShell (Windows)

```powershell
# Health check
Invoke-RestMethod -Uri http://localhost:3000/health

# Get guest
Invoke-RestMethod -Uri http://localhost:3000/api/guests/100

# Update guest
$body = @{ guestName = "Updated Name" } | ConvertTo-Json
Invoke-RestMethod -Uri http://localhost:3000/api/guests/100 -Method Put -Body $body -ContentType "application/json"
```

## Database Schema

The API expects the following table structure in the Opera database:

```sql
-- Example table structure (for reference)
CREATE TABLE NAMES (
  NAME_ID NUMBER PRIMARY KEY,
  GUESTNAME VARCHAR2(200)
);

-- Example data for testing
INSERT INTO NAMES (NAME_ID, GUESTNAME) VALUES (100, 'John Doe');
INSERT INTO NAMES (NAME_ID, GUESTNAME) VALUES (200, 'Jane Smith');
COMMIT;
```

## Troubleshooting

### Connection Issues

If the service cannot connect to Oracle:

1. **Check network connectivity**:
   ```bash
   docker exec opera-api-backend ping your-oracle-host
   ```

2. **Verify Oracle credentials** in your `.env` file

3. **Check Oracle listener status** on the database server

4. **Ensure firewall rules** allow traffic on Oracle port (default 1521)

### View Logs

```bash
# Docker Compose
docker-compose logs -f backend

# Docker
docker logs -f opera-api-backend
```

### Check Container Health

```bash
docker ps
```

Look for the "STATUS" column - it should show "healthy" after the startup period.

## Security Considerations

- **Never commit** `.env` files to version control
- Use strong passwords for database access
- Run the container as a non-root user (already configured in Dockerfile)
- Consider using Docker secrets for sensitive data in production
- Implement rate limiting for production deployments
- Use HTTPS/TLS in production environments
- Regularly update dependencies for security patches

## Performance Optimization

- **Connection Pooling**: Configured with min/max pool sizes - adjust based on load
- **Auto-commit**: Disabled by default for better transaction control
- **Graceful Shutdown**: Ensures all connections are properly closed
- **Health Checks**: Monitors application availability

## License

ISC

## Support

For issues or questions, please check the logs first using the troubleshooting section above.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

Built for Oracle Opera Hospitality v5 integration.
