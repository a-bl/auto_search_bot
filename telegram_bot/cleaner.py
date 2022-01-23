import pandas as pd
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)

PG_HOST = os.environ.get('PG_HOST')
PG_PORT = os.environ.get('PG_PORT')
PG_USER = os.environ.get('PG_USER')
PG_PASS = os.environ.get('PG_PASS')
PG_DB = os.environ.get('PG_DB')

engine = create_engine(f'postgresql://{PG_USER}:{PG_PASS}@{PG_HOST}:{PG_PORT}/{PG_DB}')

db = pd.read_csv('autos.csv')

brands = []
for brand in db['brand'].values:
    brands.append(brand.replace('-', '_').replace('ЗАЗ', 'ZAZ').replace('ВАЗ', 'VAZ').replace('ГАЗ',
                  'GAZ').replace('Богдан', 'Bogdan').replace('УАЗ', 'YAZ').replace('ИЖ', 'IZH').replace('Москвич/АЗЛК',
                  'Moskuych').replace('ЛуАЗ', 'LyAZ'))
db['brand'] = brands

models = []
for model in db['model'].values:
    models.append(model.split()[0].replace("-", "_"))
db['model'] = models

db.to_sql('telegram_bot_db', engine, if_exists='replace', index=False)