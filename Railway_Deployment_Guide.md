
# 🚀 Railway Deployment Guide for DataBridge (FastAPI + Celery + PostgreSQL + Redis)

## ✅ What You’ll Deploy
1. FastAPI API app
2. Celery background worker
3. PostgreSQL database
4. Redis (as Celery broker)
5. Connected via GitHub CI/CD

---

## 🧱 Project Structure Example

```
project/
├── api/
│   ├── main.py
│   ├── routes/
│   └── celery_app.py
├── workers/
│   └── tasks.py
├── Dockerfile
├── requirements.txt
├── .railway/
│   └── railway.json
└── docker-compose.yml
```

---

## 🧑‍💻 Step-by-Step Setup

### 1. Push Code to GitHub
```bash
git init
git remote add origin https://github.com/yourname/databridge
git add .
git commit -m "Initial commit"
git push -u origin main
```

### 2. Create a Railway Project
- Go to https://railway.app
- Sign in via GitHub
- Click "New Project" → Deploy from GitHub
- Select your repo

### 3. Add PostgreSQL
- In the dashboard, click "Add Plugin" → PostgreSQL
- Copy `DATABASE_URL`

### 4. Add Redis
- Click "Add Plugin" → Redis
- Copy the Redis connection string

### 5. Set Environment Variables

| Name           | Value                    |
|----------------|--------------------------|
| DATABASE_URL   | from PostgreSQL plugin   |
| REDIS_URL      | from Redis plugin        |
| SECRET_KEY     | your random key          |
| ENV            | production               |

---

## 🐳 Dockerfile (FastAPI)

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 🔁 Celery Worker Dockerfile (or CMD Override)

```dockerfile
CMD ["celery", "-A", "api.celery_app", "worker", "--loglevel=info"]
```

Deploy a second service for this worker if needed.

---

## ⚙️ Optional Procfile
```procfile
web: uvicorn api.main:app --host=0.0.0.0 --port=8000
```

---

## ✅ Final Steps
- Push to GitHub, Railway auto-deploys
- View logs, test endpoints
- Add a `/ping` healthcheck
- Monitor Celery via Flower or logs

---

## 🔧 What’s Next?
- docker-compose for local dev
- Celery + Redis setup
- FastAPI tenant ID middleware
