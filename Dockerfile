FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build
WORKDIR /client
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --dart-define=MY_NEWS_API_URL=

FROM python:3.12-slim
WORKDIR /app
ENV PYTHONUNBUFFERED=1 \
    MY_NEWS_DATABASE=/data/news.sqlite3 \
    MY_NEWS_WEB_DIR=/app/web
COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt
COPY backend/app.py /app/backend/app.py
COPY --from=flutter-build /client/build/web /app/web
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app:app --app-dir /app/backend --host 0.0.0.0 --port ${PORT:-8000}"]
