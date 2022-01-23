FROM python:3.8-slim-buster

ENV PYTHONDONTWRITTEBYTECODE 1
ENV PYTHONUNBUFFERED 1

ENV DATABASE_URL 'postgresql://postgres_user:postgres_password@localhost/telegram_bot_db'


RUN apt-get update && pip install --upgrade pip && \
    apt-get -y install libpq-dev gcc && \
    pip install psycopg2

COPY requirements.txt ./requirements.txt
RUN pip install -r requirements.txt

COPY . ./

EXPOSE 5432

CMD [ "python3", "bot.py"]