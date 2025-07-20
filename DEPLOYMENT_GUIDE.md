# CalendarAI Deployment Guide

This application requires **two separate deployments**:

## Architecture
- **Backend**: Rails API (needs Ruby hosting service)
- **Frontend**: Static HTML/CSS/JS (can use static hosting)

## Backend Deployment (Rails API)

### Recommended Services:
- **Railway.app** (easiest Rails deployment)
- **Render.com** (good free tier)
- **Heroku** (classic choice)
- **DigitalOcean App Platform**

### Railway Deployment Steps:
1. Go to [railway.app](https://railway.app)
2. Create account and "New Project"
3. "Deploy from GitHub repo" → select your `aical8` repo
4. Railway will auto-detect Rails and deploy the backend folder
5. Set environment variables (see Backend Environment Variables below)
6. Your API will be available at: `https://your-app-name.railway.app`

### Backend Environment Variables:
```env
# Database (Railway provides this automatically)
DATABASE_URL=postgresql://...

# Security
SECRET_KEY_BASE=your-secret-key-base-here
RAILS_MASTER_KEY=your-master-key-here

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# AI
OPENAI_API_KEY=sk-your-openai-api-key

# CORS (your frontend domain)
FRONTEND_URL=https://your-frontend-domain.com

# Rails Environment
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

## Frontend Deployment

### Recommended Services:
- **Vercel** (easiest static deployment)
- **Netlify**
- **GitHub Pages**

### Vercel Deployment Steps:
1. Go to [vercel.com](https://vercel.com)
2. "Import project" → select your GitHub repo
3. Set **Root Directory** to `frontend`
4. Deploy!
5. Update environment variables to point to your backend

### Update Frontend Configuration:
After backend is deployed, update `frontend/app.js`:
```javascript
// Replace localhost with your Railway backend URL
const API_BASE_URL = 'https://your-app-name.railway.app/api/v1';
```

## OAuth Redirect URIs

Update Google Cloud Console with your production URLs:

**Authorized Redirect URIs:**
- `https://your-app-name.railway.app/api/v1/gmail/callback`

**Authorized JavaScript Origins:**
- `https://your-frontend-domain.com`

## Quick Start Guide

### 1. Deploy Backend First (Railway):
```bash
# Railway CLI (optional)
npm install -g @railway/cli
railway login
railway link
railway up
```

### 2. Deploy Frontend (Vercel):
```bash
# Vercel CLI (optional)
npm install -g vercel
cd frontend
vercel
```

### 3. Update Environment Variables:
- Add all backend environment variables to Railway
- Update frontend API_BASE_URL to point to Railway backend
- Update Google OAuth redirect URIs

## Database Setup

Railway automatically provisions PostgreSQL. Run migrations:
```bash
# In Railway dashboard, run:
bundle exec rails db:migrate
bundle exec rails db:seed
```

## SSL & HTTPS

Both Railway and Vercel provide HTTPS automatically. Make sure:
- `config.force_ssl = true` in production.rb ✓
- Google OAuth redirect URIs use https:// ✓
- Frontend API calls use https:// ✓

## Monitoring

After deployment:
- Check Railway logs for backend errors
- Check Vercel function logs for frontend issues
- Test OAuth flow end-to-end
- Verify database connections

## Support

If you run into issues:
1. Check Railway deployment logs
2. Verify all environment variables are set
3. Test API endpoints directly: `https://your-app-name.railway.app/health`
4. Check CORS configuration matches your frontend domain
