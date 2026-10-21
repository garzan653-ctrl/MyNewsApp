# My News

My News is a Flutter app with a Python backend. The backend collects current
headlines from RSS feeds, groups closely related coverage, and keeps up to
seven days of articles in SQLite. The app shows publisher-provided story
summaries inline and can generate cached AI analysis of the available coverage.

## Run the complete app locally

Install Docker Desktop and Flutter, open a terminal in this project directory,
and set your OpenAI key in the environment (do not commit it):

```bash
export OPENAI_API_KEY=your-openai-api-key
docker compose up --build
```

On Windows PowerShell, use `$env:OPENAI_API_KEY="your-openai-api-key"` before
starting Docker Compose. Open [http://localhost:8000](http://localhost:8000)
for the app, [http://localhost:8000/health](http://localhost:8000/health) for
server status, or [http://localhost:8000/docs](http://localhost:8000/docs)
for the API.
The backend fetches the first headlines on startup and refreshes every 15
minutes. Its Docker volume keeps the SQLite database across restarts.

To run the Flutter client separately, start the backend with Docker Compose,
then run:

```bash
flutter pub get
flutter run -d chrome --dart-define=MY_NEWS_API_URL=http://localhost:8000
```

Android emulator builds use `http://10.0.2.2:8000` by default. To connect a
physical phone or another device, set `MY_NEWS_API_URL` to the backend's
reachable address.

## Run on an iPhone

The backend currently collects headlines from BBC News, NPR, The Guardian, and
Al Jazeera. Story details display each available RSS summary without leaving
the app; original publisher links remain optional citations. RSS feeds do not
provide full article text consistently. My News displays and summarizes the
publisher-supplied excerpts rather than republishing full copyrighted articles.
Add or replace RSS/Atom URLs with the `MY_NEWS_FEEDS` backend setting.

After deploying the app with the Render Blueprint below, open the resulting
HTTPS `onrender.com` URL in iPhone Safari. To install it like an app, use Safari's
Share button and choose **Add to Home Screen**. This uses the hosted web app;
installing the native iOS build still requires macOS and Xcode.

For local iPhone testing on the same Wi-Fi network as the computer, find the
computer's local IP address and run on a Mac with Xcode installed:

```bash
flutter pub get
flutter run -d <iphone-device-id> \
  --dart-define=MY_NEWS_API_URL=http://YOUR-COMPUTER-IP:8000
```

Start the backend on a network-accessible interface (`--host 0.0.0.0`) and
allow its port through the computer's firewall. Approve the iPhone's local
network access prompt. Replace the example address with an HTTPS URL when using
a deployed backend. The iOS simulator can use
`http://127.0.0.1:8000`; a physical iPhone cannot use the computer's localhost.

Building or installing the native iOS app requires macOS, Xcode, and Apple's
code signing. The GitHub Actions workflow builds and tests an unsigned iOS
simulator app on a hosted Mac; it does not install an app on a physical iPhone.
To install on a physical device, select an Apple development team in Xcode and
run `flutter run` with that device connected. TestFlight/App Store distribution
requires Apple distribution signing and the corresponding Apple Developer
account.

## Deploy

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/garzan653-ctrl/MyNewsApp)

1. Select **Deploy to Render** from the repository's GitHub page, or create a
   new **Blueprint** in Render and choose this repository. Render reads
   `render.yaml` and builds the Flutter web app and backend together.
2. Sign in to Render and authorize access to the GitHub repository.
3. Deploy the service without an AI key. To enable AI analysis, add
   `OPENAI_API_KEY` later as a secret environment variable in the service
   dashboard. Do not add it to source code, Flutter build arguments, or GitHub.
4. After the service deploys, open its HTTPS `onrender.com` URL on the iPhone.
   The same address serves both the app and API.

The Blueprint uses Render's free web-service plan and does not provision a
persistent disk. The service may spin down when idle and take longer to respond
on the first request after inactivity. SQLite headlines, cached AI results,
and daily analysis counts can be lost when Render replaces or restarts the
instance; the service refreshes the news feeds again on startup. Choose a paid
plan with persistent storage if you need continuous availability and durable
history, and review Render's current pricing before enabling one.

AI analysis is generated only when requested, stored with its source-version
fingerprint, and reused for unchanged coverage. The default model is
`gpt-4o-mini`; set `OPENAI_MODEL` to another compatible chat-completions model
if desired. The default limit is 25 newly generated analyses per UTC day; set
`MY_NEWS_MAX_AI_ANALYSES_PER_DAY` to adjust it. OpenAI API access and usage
billing must be enabled for the server key. Errors are reported in the app,
and the API key remains on the backend.

## GitHub

Push the project folder to a GitHub repository you own. The included GitHub
Actions workflow runs Flutter analysis and tests, backend API tests, and an
iOS simulator build on every push to `main` or `master` and for pull requests.

## Backend configuration

| Environment variable | Default | Description |
| --- | --- | --- |
| `MY_NEWS_FEEDS` | BBC World, NPR, The Guardian, Al Jazeera RSS feeds | Comma-separated RSS/Atom feed URLs |
| `MY_NEWS_DATABASE` | `backend/data/news.sqlite3` | SQLite database file |
| `MY_NEWS_REFRESH_SECONDS` | `900` | Seconds between feed refreshes (minimum 60) |
| `MY_NEWS_WEB_DIR` | `build/web` | Flutter web build served by the backend |
| `OPENAI_API_KEY` | unset | Private server-side OpenAI API credential; required for AI analysis |
| `OPENAI_MODEL` | `gpt-4o-mini` | OpenAI chat-completions model for analysis |
| `MY_NEWS_MAX_AI_ANALYSES_PER_DAY` | `25` | Daily UTC cap on newly generated analyses; `0` disables analysis |
| `LOG_LEVEL` | `INFO` | Python server log level |

## API

- `GET /health` — database, article-count, and configured-feed status
- `GET /stories` — recent stories, newest first; accepts an optional `limit`
- `GET /stories/{id}` — grouped publisher coverage for one story
- `POST /stories/{id}/analysis` — generate and cache AI coverage analysis

The backend retains articles for seven days, removes expired records, and caps
the cache at 750 articles. Story groupings are based on overlapping headline
keywords. Detail pages include publisher-provided feed summaries and links to
original articles. AI analysis works after `OPENAI_API_KEY` is configured and
uses only the headline and RSS excerpts returned by the feeds.
