FROM python:3.8

ENV SCRIPT=bot.py

ENV PYTHONDONTWRITTEBYTECODE 1
ENV PYTHONUNBUFFERED 1

COPY . ./

RUN pip install --no-cache-dir -r requirements.txt

CMD [ "bash", "-c", "python3 ${SCRIPT}"]
