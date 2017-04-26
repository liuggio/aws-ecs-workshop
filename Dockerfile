FROM python:3.4-alpine

RUN apk update && apk add curl && rm -rf /var/cache/apk/*

ADD app /application
WORKDIR /application
RUN pip install -r requirements.txt

HEALTHCHECK --interval=25s --timeout=10s --retries=3 \
      CMD curl -f http://0.0.0.0:8080 || exit 1

CMD ["python", "app.py"]
EXPOSE 8080
