FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends libsndfile1 curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY service.py /app/service.py
COPY speech_runtime.py /app/speech_runtime.py
COPY launcher.py /app/launcher.py
RUN python -m py_compile /app/service.py /app/speech_runtime.py /app/launcher.py

EXPOSE 9019 8080
HEALTHCHECK --interval=5s --timeout=3s --retries=20 CMD curl -fsS http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["python", "/app/launcher.py"]
CMD ["serve"]
