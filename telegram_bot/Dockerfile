FROM python:3.8-slim-buster

ENV PYTHONDONTWRITTEBYTECODE 1
ENV PYTHONUNBUFFERED 1

COPY . ./

RUN apt-get update && pip install --upgrade pip && \
    apt-get -y install libpq-dev gcc && \
    pip install -r requirements.txt

CMD [ "python3", "bot.py"]
