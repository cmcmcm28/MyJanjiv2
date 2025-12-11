# Flask Backend Setup Guide

## Installation

1. Navigate to the `Face recognition` folder:
```bash
cd "Face recognition"
```

2. Install Python dependencies:
```bash
pip install -r requirements.txt
```

Or install individually:
```bash
pip install Flask flask-cors opencv-python numpy psycopg2-binary deepface Pillow
```

## Database Setup

The backend uses PostgreSQL with pgvector extension. Make sure your database has:

1. A table named `pictures` with columns:
   - `picture` (text)
   - `embedding` (vector type for pgvector)

2. Create the table if it doesn't exist:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE TABLE IF NOT EXISTS pictures (
    id SERIAL PRIMARY KEY,
    picture TEXT,
    embedding vector(512)
);
```

## Running the Server

1. Update the database URI in `app.py` if needed:
```python
DB_URI = "your_postgresql_connection_string"
```

2. Run the Flask server:
```bash
python app.py
```

The server will start on `http://0.0.0.0:5000`

## API Endpoints

### POST /upload_ic
- Uploads IC image and registers face embedding
- Input: Multipart form-data with `ic_image` file
- Response: `{"status": "success", "message": "...", "redirect": "..."}`

### POST /process_frame
- Processes camera frame for face verification
- Input: JSON `{"image": "data:image/jpeg;base64,..."}`
- Response: `{"status": "success/fail/error", "score": 95, "message": "..."}`

### GET /health
- Health check endpoint
- Response: `{"status": "ok", "message": "Backend is running"}`

## CORS Configuration

CORS is enabled for all origins to allow Flutter app integration. The backend now includes:
- CORS headers on all responses
- OPTIONS request handling
- Support for cross-origin requests

## Changes Made

1. ✅ Added `flask-cors` for CORS support
2. ✅ Added CORS headers to all API responses
3. ✅ Added OPTIONS method handling for preflight requests
4. ✅ Improved error handling with traceback
5. ✅ Added health check endpoint
6. ✅ Updated haarcascade path to use local file
7. ✅ Enhanced base64 image handling (with/without data URL prefix)
8. ✅ Added image decoding validation

## Testing

Test the endpoints using curl or Postman:

```bash
# Health check
curl http://localhost:5000/health

# Upload IC
curl -X POST http://localhost:5000/upload_ic \
  -F "ic_image=@path/to/ic_image.jpg"

# Process frame
curl -X POST http://localhost:5000/process_frame \
  -H "Content-Type: application/json" \
  -d '{"image": "data:image/jpeg;base64,/9j/4AAQ..."}'
```

## Troubleshooting

1. **Database connection error**: Check your DB_URI connection string
2. **Import error**: Make sure all dependencies are installed
3. **Port already in use**: Change port in `app.py` or kill existing process
4. **Face detection fails**: Ensure haarcascade XML file is in the same directory

