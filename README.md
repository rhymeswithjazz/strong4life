# Strong4Life

A mobile-friendly workout tracking web app built with Elixir/Phoenix and LiveView. Self-hostable on Synology NAS via Portainer/Docker.

## Features

- **Pre-built Workout Program**: The proven "Strong for Life" 3-day A/B split with big compound lifts
- **Progressive Overload Tracking**: Log weights, reps, and RPE for each set
- **Suggested Weights**: Automatically suggests weights based on your last session
- **Rest Timer**: Built-in rest timer with customizable durations
- **Progress Charts**: Visualize your strength gains over time
- **PWA Support**: Add to home screen for app-like experience
- **Self-Hosted**: Your data stays on your server

## The Program

Alternate between Workout A and Workout B across 3 days per week:

**Workout A:**
- Barbell Squat: 3×5
- Barbell Bench Press: 3×5
- Barbell Row: 3×8
- Face Pulls: 3×15

**Workout B:**
- Barbell Overhead Press: 3×5
- Barbell Deadlift: 3×5
- Close Grip Bench Press: 3×8
- Dumbbell Lunges: 3×10

## Tech Stack

- **Backend**: Elixir 1.17+ / Phoenix 1.8+
- **Frontend**: Phoenix LiveView (no separate JS framework)
- **Database**: PostgreSQL 16
- **Styling**: Tailwind CSS
- **Email**: Swoosh with SMTP adapter
- **Containerization**: Docker + Docker Compose

## Local Development

### Prerequisites

- Elixir 1.17+
- PostgreSQL 16+
- Node.js (for assets)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/strong4life.git
   cd strong4life
   ```

2. Start PostgreSQL (using Docker):
   ```bash
   docker compose up -d
   ```

3. Install dependencies and setup database:
   ```bash
   mix setup
   ```

4. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

5. Visit [`localhost:4000`](http://localhost:4000)

## Production Deployment (Portainer)

### Prerequisites

- Docker Hub account
- Synology NAS with Portainer installed
- SMTP server for email

### GitHub Setup

1. Create a repository on GitHub

2. Add the following secrets to your repository:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Docker Hub access token (create at hub.docker.com)

3. Push your code:
   ```bash
   git remote add origin https://github.com/yourusername/strong4life.git
   git push -u origin main
   ```

### Portainer Deployment

1. In Portainer, go to **Stacks** > **Add Stack**

2. Name your stack `strong4life`

3. Paste the contents of `docker-compose.prod.yml` or use the Web editor

4. Add environment variables:
   ```
   DOCKERHUB_USERNAME=yourusername
   DB_PASSWORD=your-secure-password
   SECRET_KEY_BASE=generate-with-mix-phx.gen.secret
   PHX_HOST=your-nas-ip-or-hostname
   SMTP_HOST=your-smtp-server
   SMTP_PORT=587
   SMTP_USERNAME=your-smtp-username
   SMTP_PASSWORD=your-smtp-password
   SMTP_FROM_EMAIL=noreply@yourdomain.com
   ```

5. Deploy the stack

6. Access the app at `http://your-nas-ip:4000`

### Generating Secrets

Generate a secret key base:
```bash
mix phx.gen.secret
```

### Updating the App

When you push to `main`, GitHub Actions will:
1. Run tests
2. Build a new Docker image
3. Push to Docker Hub with the `latest` tag

To update your Portainer deployment:
1. Go to your stack in Portainer
2. Click **Pull and redeploy**

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection URL | Yes |
| `SECRET_KEY_BASE` | Phoenix secret key | Yes |
| `PHX_HOST` | Hostname for URL generation | Yes |
| `SMTP_HOST` | SMTP server hostname | For email |
| `SMTP_PORT` | SMTP server port (default: 587) | For email |
| `SMTP_USERNAME` | SMTP username | For email |
| `SMTP_PASSWORD` | SMTP password | For email |
| `SMTP_FROM_EMAIL` | From address for emails | For email |

## License

MIT
