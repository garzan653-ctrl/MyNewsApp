import sqlite3
import tempfile
import unittest
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import patch

from fastapi.testclient import TestClient

import app as news_app


class NewsApiTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.database_path = Path(self.temp_dir.name) / "news.sqlite3"
        self.database_patch = patch.object(news_app, "DATABASE_PATH", self.database_path)
        self.database_patch.start()
        self.feeds_patch = patch.object(news_app, "FEEDS", ())
        self.feeds_patch.start()
        news_app._initialize_database()

        now = datetime.now(timezone.utc).isoformat()
        articles = [
            (
                "https://npr.org/climate-bill",
                "Senate passes major climate bill after overnight vote",
                "NPR",
                "The Senate approved a major climate and energy bill.",
                now,
                now,
            ),
            (
                "https://bbc.com/climate-bill",
                "Major climate bill passes Senate after marathon overnight voting",
                "BBC News",
                "Lawmakers passed a landmark climate bill overnight.",
                now,
                now,
            ),
            (
                "https://bbc.com/wildfire",
                "Wildfire prompts evacuation orders in western county",
                "BBC News",
                "Residents were ordered to evacuate.",
                now,
                now,
            ),
        ]
        with closing(sqlite3.connect(self.database_path)) as connection, connection:
            connection.executemany(
                """
                INSERT INTO articles
                    (url, title, publisher, description, published_at, fetched_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                articles,
            )

    def tearDown(self):
        self.feeds_patch.stop()
        self.database_patch.stop()
        self.temp_dir.cleanup()

    def test_stories_group_similar_headlines_and_detail_returns_source_links(self):
        with TestClient(news_app.app) as client:
            response = client.get("/stories")
            self.assertEqual(response.status_code, 200)
            stories = response.json()["stories"]
            self.assertEqual(len(stories), 2)

            climate = next(story for story in stories if story["publisherCount"] == 2)
            self.assertEqual(set(climate["publishers"]), {"NPR", "BBC News"})
            detail = client.get(f'/stories/{climate["id"]}')
            self.assertEqual(detail.status_code, 200)
            story = detail.json()
            self.assertEqual(story["publisherCount"], 2)
            self.assertEqual({source["publisher"] for source in story["sources"]}, {"NPR", "BBC News"})
            self.assertTrue(all(source["url"].startswith("https://") for source in story["sources"]))
            self.assertIsNone(story["ai"])

    def test_missing_story_returns_not_found(self):
        with TestClient(news_app.app) as client:
            response = client.get("/stories/not-a-story")
        self.assertEqual(response.status_code, 404)

    def test_health_reports_database_and_feed_status(self):
        with TestClient(news_app.app) as client:
            response = client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok", "articles": 3, "feeds": 0})

    def test_default_feed_publishers_use_short_outlet_names(self):
        self.assertEqual(
            news_app._publisher({}, "", "https://feeds.bbci.co.uk/news/world/rss.xml"),
            "BBC News",
        )
        self.assertEqual(
            news_app._publisher({}, "", "https://feeds.npr.org/1001/rss.xml"),
            "NPR",
        )
        self.assertEqual(
            news_app._publisher({}, "", "https://www.theguardian.com/world/rss"),
            "The Guardian",
        )
        self.assertEqual(
            news_app._publisher({}, "", "https://www.aljazeera.com/xml/rss/all.xml"),
            "Al Jazeera",
        )
        self.assertEqual(
            news_app._publisher(
                {
                    "link": "https://www.npr.org/2026/10/19/news-story",
                    "source": {"title": "NPR Topics: News"},
                },
                "",
                "https://feeds.npr.org/1001/rss.xml",
            ),
            "NPR",
        )


if __name__ == "__main__":
    unittest.main()
