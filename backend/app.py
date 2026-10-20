import asyncio
import calendar
import hashlib
import html
import logging
import os
import re
import sqlite3
from contextlib import asynccontextmanager, closing
from datetime import datetime, timedelta, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse

import feedparser
import httpx
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("my_news")

DEFAULT_FEEDS = (
    "https://feeds.bbci.co.uk/news/world/rss.xml",
    "https://feeds.npr.org/1001/rss.xml",
    "https://www.theguardian.com/world/rss",
    "https://www.aljazeera.com/xml/rss/all.xml",
)
KNOWN_PUBLISHERS = {
    "feeds.bbci.co.uk": "BBC News",
    "bbc.com": "BBC News",
    "www.bbc.com": "BBC News",
    "feeds.npr.org": "NPR",
    "npr.org": "NPR",
    "www.npr.org": "NPR",
    "www.theguardian.com": "The Guardian",
    "theguardian.com": "The Guardian",
    "www.aljazeera.com": "Al Jazeera",
    "aljazeera.com": "Al Jazeera",
}
FEEDS = tuple(
    feed.strip()
    for feed in os.getenv("MY_NEWS_FEEDS", ",".join(DEFAULT_FEEDS)).split(",")
    if feed.strip()
)
DATABASE_PATH = Path(
    os.getenv("MY_NEWS_DATABASE", str(Path(__file__).parent / "data" / "news.sqlite3"))
)
STATIC_DIR = Path(os.getenv("MY_NEWS_WEB_DIR", str(Path(__file__).parent.parent / "build" / "web")))
REFRESH_SECONDS = max(60, int(os.getenv("MY_NEWS_REFRESH_SECONDS", "900")))
RETENTION_DAYS = 7
MAX_ARTICLES = 750
STOP_WORDS = {
    "about", "after", "against", "amid", "among", "and", "are", "been",
    "before", "being", "between", "but", "can", "could", "during", "for",
    "from", "has", "have", "into", "its", "more", "most", "new", "not",
    "over", "said", "says", "than", "that", "the", "their", "them", "then",
    "there", "these", "they", "this", "those", "through", "under", "was",
    "were", "what", "when", "where", "which", "while", "will", "with",
    "would", "you", "your",
}


class _TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def clean_text(value):
    if not value:
        return ""
    parser = _TextExtractor()
    parser.feed(str(value))
    return re.sub(r"\s+", " ", html.unescape(" ".join(parser.parts))).strip()


def _tokens(headline):
    return {
        word
        for word in re.findall(r"[a-z0-9]{3,}", headline.casefold())
        if word not in STOP_WORDS
    }


def _published_at(entry):
    parsed = entry.get("published_parsed") or entry.get("updated_parsed")
    if parsed:
        return datetime.fromtimestamp(
            calendar.timegm(parsed), timezone.utc
        ).isoformat()
    return datetime.now(timezone.utc).isoformat()


def _publisher(entry, feed_title, feed_url):
    source = entry.get("source", {})
    publisher = clean_text(source.get("title")) if hasattr(source, "get") else ""
    source_host = (urlparse(entry.get("link", "")).hostname or "").casefold()
    if source_host in KNOWN_PUBLISHERS:
        return KNOWN_PUBLISHERS[source_host]
    if publisher:
        return publisher[:120]
    hostname = (urlparse(feed_url).hostname or "").casefold()
    if hostname in KNOWN_PUBLISHERS:
        return KNOWN_PUBLISHERS[hostname]
    if feed_title:
        return clean_text(feed_title)[:120]
    hostname = urlparse(entry.get("link", feed_url)).hostname or "News source"
    return hostname.removeprefix("www.").split(".")[0].replace("-", " ").title()


def _initialize_database():
    DATABASE_PATH.parent.mkdir(parents=True, exist_ok=True)
    with closing(sqlite3.connect(DATABASE_PATH, timeout=30)) as connection, connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS articles (
                url TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                publisher TEXT NOT NULL,
                description TEXT NOT NULL,
                published_at TEXT NOT NULL,
                fetched_at TEXT NOT NULL
            )
            """
        )
        connection.execute(
            "CREATE INDEX IF NOT EXISTS articles_published_at ON articles(published_at)"
        )


async def _fetch_feed(client, feed_url):
    try:
        response = await client.get(feed_url)
        response.raise_for_status()
    except httpx.HTTPError as error:
        logger.warning("Could not fetch news feed %s: %s", feed_url, error)
        return []

    parsed = feedparser.parse(response.content)
    if parsed.bozo and not parsed.entries:
        logger.warning("Could not parse news feed %s: %s", feed_url, parsed.bozo_exception)
        return []

    articles = []
    for entry in parsed.entries:
        title = clean_text(entry.get("title"))
        url = entry.get("link", "").strip()
        if not title or not url or urlparse(url).scheme not in {"http", "https"}:
            continue
        summary = entry.get("summary", "")
        if not summary and entry.get("content"):
            summary = entry["content"][0].get("value", "")
        articles.append(
            (
                url,
                title[:500],
                _publisher(entry, parsed.feed.get("title", ""), feed_url),
                clean_text(summary)[:1200],
                _published_at(entry),
                datetime.now(timezone.utc).isoformat(),
            )
        )
    return articles


async def refresh_news():
    if not FEEDS:
        logger.error("No RSS feeds configured; set MY_NEWS_FEEDS.")
        return
    timeout = httpx.Timeout(12, connect=6)
    headers = {"User-Agent": "MyNews/1.0 (RSS news reader)"}
    async with httpx.AsyncClient(timeout=timeout, headers=headers, follow_redirects=True) as client:
        results = await asyncio.gather(
            *(_fetch_feed(client, feed_url) for feed_url in FEEDS)
        )

    articles = [article for feed_articles in results for article in feed_articles]
    now = datetime.now(timezone.utc)
    oldest_allowed = (now - timedelta(days=RETENTION_DAYS)).isoformat()
    newest_allowed = (now + timedelta(days=1)).isoformat()
    articles = [
        article
        for article in articles
        if oldest_allowed <= article[4] <= newest_allowed
    ]
    with closing(sqlite3.connect(DATABASE_PATH, timeout=30)) as connection, connection:
        connection.executemany(
            """
            INSERT INTO articles
                (url, title, publisher, description, published_at, fetched_at)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(url) DO UPDATE SET
                title = excluded.title,
                publisher = excluded.publisher,
                description = excluded.description,
                published_at = excluded.published_at,
                fetched_at = excluded.fetched_at
            """,
            articles,
        )
        connection.execute("DELETE FROM articles WHERE published_at < ?", (oldest_allowed,))
        connection.execute(
            """
            DELETE FROM articles
            WHERE url NOT IN (
                SELECT url FROM articles ORDER BY published_at DESC LIMIT ?
            )
            """,
            (MAX_ARTICLES,),
        )
    logger.info("News refresh completed: %s articles from %s feeds", len(articles), len(FEEDS))


async def _refresh_loop():
    while True:
        try:
            await refresh_news()
        except Exception:
            logger.exception("Unexpected error while refreshing news feeds")
        await asyncio.sleep(REFRESH_SECONDS)


def _load_articles():
    with closing(sqlite3.connect(DATABASE_PATH, timeout=30)) as connection:
        connection.row_factory = sqlite3.Row
        rows = connection.execute(
            """
            SELECT url, title, publisher, description, published_at
            FROM articles
            WHERE published_at >= ?
            ORDER BY published_at DESC
            LIMIT ?
            """,
            (
                (datetime.now(timezone.utc) - timedelta(days=RETENTION_DAYS)).isoformat(),
                MAX_ARTICLES,
            ),
        ).fetchall()
    return [dict(row) for row in rows]


def _group_articles(articles):
    groups = []
    group_tokens = []
    for article in articles:
        article_tokens = _tokens(article["title"])
        best_group = None
        best_score = 0.0
        for index, group in enumerate(group_tokens):
            for tokens in group:
                common = article_tokens & tokens
                union = article_tokens | tokens
                score = len(common) / len(union) if union else 0.0
                if len(common) >= 2 and score >= 0.45 and score > best_score:
                    best_group = index
                    best_score = score
        if best_group is None:
            groups.append([article])
            group_tokens.append([article_tokens])
        else:
            groups[best_group].append(article)
            group_tokens[best_group].append(article_tokens)
    return groups


def _story_id(articles):
    oldest = min(articles, key=lambda article: (article["published_at"], article["url"]))
    return hashlib.sha256(oldest["url"].encode("utf-8")).hexdigest()[:20]


def _to_story(articles, include_detail=False):
    newest = articles[0]
    publishers = sorted({article["publisher"] for article in articles}, key=str.casefold)
    story = {
        "id": _story_id(articles),
        "headline": newest["title"],
        "updatedAt": newest["published_at"],
        "publisherCount": len(publishers),
        "publishers": publishers,
    }
    if include_detail:
        descriptions = []
        seen_descriptions = set()
        for article in articles:
            description = article["description"].strip()
            normalized = description.casefold()
            if description and normalized not in seen_descriptions:
                seen_descriptions.add(normalized)
                descriptions.append(f'{article["publisher"]}: {description}')
        overview = (
            "Publisher-provided summaries: " + " ".join(descriptions[:3])
            if descriptions
            else f"Recent coverage from {', '.join(publishers)}. "
            "Open the original reports below for the full articles."
        )
        story.update(
            {
                "overview": overview,
                "sources": [
                    {
                        "publisher": article["publisher"],
                        "title": article["title"],
                        "url": article["url"],
                        "publishedAt": article["published_at"],
                    }
                    for article in articles
                ],
                "background": [],
                "ai": None,
            }
        )
    return story


@asynccontextmanager
async def lifespan(_app):
    _initialize_database()
    refresh_task = asyncio.create_task(_refresh_loop())
    try:
        yield
    finally:
        refresh_task.cancel()
        try:
            await refresh_task
        except asyncio.CancelledError:
            pass


app = FastAPI(title="My News API", version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "OPTIONS"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    try:
        with closing(sqlite3.connect(DATABASE_PATH, timeout=5)) as connection:
            count = connection.execute("SELECT COUNT(*) FROM articles").fetchone()[0]
        return {"status": "ok", "articles": count, "feeds": len(FEEDS)}
    except sqlite3.Error as error:
        logger.exception("Health check could not read the news database")
        raise HTTPException(status_code=503, detail="News database unavailable") from error


@app.get("/stories")
def get_stories(limit: int = Query(default=100, ge=1, le=200)):
    groups = _group_articles(_load_articles())
    stories = [_to_story(group) for group in groups]
    stories.sort(key=lambda story: story["updatedAt"], reverse=True)
    return {"stories": stories[:limit]}


@app.get("/stories/{story_id}")
def get_story(story_id: str):
    for group in _group_articles(_load_articles()):
        if _story_id(group) == story_id:
            return _to_story(group, include_detail=True)
    raise HTTPException(status_code=404, detail="Story not found")


if STATIC_DIR.is_dir() and (STATIC_DIR / "index.html").is_file():
    app.mount("/", StaticFiles(directory=STATIC_DIR, html=True), name="web")


@app.get("/", include_in_schema=False)
def root():
    if STATIC_DIR.is_dir() and (STATIC_DIR / "index.html").is_file():
        return FileResponse(STATIC_DIR / "index.html")
    return {"name": "My News API", "health": "/health", "stories": "/stories"}
