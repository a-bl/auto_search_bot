import requests
from bs4 import BeautifulSoup
import pandas as pd
import json
import psycopg2
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

url = 'https://auto.ria.com/uk/legkovie/'
params = {'page': 51}
# set a number greater than the number of the first page to start the cycle
pages = 52
n = 0

itemsBrand = []
itemsModel = []
itemsPrice = []
itemsYear = []
itemsRegion = []
itemsTransmission = []
itemsFuel = []
itemsEngineCapacity = []
itemsMileage = []
itemsLink = []


to_json = []

while params['page'] <= pages:
    response = requests.get(url, params=params)
    soup = BeautifulSoup(response.text, 'lxml')
    items = soup.find_all('section', class_='ticket-item')

    for n, i in enumerate(items, start=n+1):
        itemBrand = i.find('span', class_='blue bold').text.split()[0]
        itemsBrand.append(itemBrand)
        itemModel = ' '.join(i.find('span', class_='blue bold').text.split()[1::])
        itemsModel.append(itemModel)
        itemPrice = i.find('span', class_='bold green size22').text.strip()
        itemsPrice.append(itemPrice)
        itemYear = i.find('a', class_='address').text.split()[-1]
        itemsYear.append(itemYear)
        itemRegion = i.find('li', class_='item-char view-location js-location').text.strip().split(' (')[0]
        itemsRegion.append(itemRegion)
        itemTransmission = i.find_all('li', class_='item-char')[3].text.replace(' ', '')
        itemsTransmission.append(itemTransmission)
        itemFuel = i.find_all('li', class_='item-char')[2].text.split(',')[0]
        itemsFuel.append(itemFuel)
        itemEngineCapacity = i.find_all('li', class_='item-char')[2].text.split(',')[-1]
        itemsEngineCapacity.append(itemEngineCapacity)
        itemMileage = i.find('li', class_='item-char js-race').text
        itemsMileage.append(itemMileage)
        itemLink = i.find('a', class_='m-link-ticket').get('href')
        itemsLink.append(itemLink)

        print(f'{n}: {itemBrand},\n     Model: {itemModel},\n     Price: {itemPrice} $,\n     Year: {itemYear},\n     '
              f'Region: {itemRegion},\n     Transmission: {itemTransmission},\n     Fuel type: {itemFuel},\n     '
              f'Engine capacity: {itemEngineCapacity},\n     Mileage: {itemMileage}')
        item_to_json = {
            'brand': itemBrand,
            'model': itemModel,
            'price': itemPrice,
            'year': itemYear,
            'region': itemRegion,
            'transmission': itemTransmission,
            'fuel_type': itemFuel,
            'engine_capacity': itemEngineCapacity,
            'mileage': itemMileage,
            'link': itemLink
        }
        to_json.append(item_to_json)

    # last_page_num = int(soup.find('a', class_='page-link js-next').get('data-page'))
    # print(last_page_num)
    last_page_num = 1407
    pages = last_page_num if pages < last_page_num else pages
    params['page'] += 1

df = pd.DataFrame({
    'brand': itemsBrand,
    'model': itemsModel,
    'price': itemsPrice,
    'year': itemsYear,
    'region': itemsRegion,
    'transmission': itemsTransmission,
    'fuel_type': itemsFuel,
    'engine_capacity': itemsEngineCapacity,
    'mileage': itemsMileage,
    'link': itemsLink
})

brands = []
for brand in df['brand'].values:
    brands.append(brand.replace('-', '_').replace('ЗАЗ', 'ZAZ').replace('ВАЗ', 'VAZ').replace('ГАЗ',
                  'GAZ').replace('Богдан', 'Bogdan').replace('УАЗ', 'YAZ').replace('ИЖ', 'IZH').replace('Москвич/АЗЛК',
                  'Moskuych').replace('ЛуАЗ', 'LyAZ'))
df['brand'] = brands

models = []
for model in df['model'].values:
    models.append(model.split()[0].replace("-", "_"))
df['model'] = models

df.to_sql('telegram_bot_db', engine, if_exists='replace', index=False)
df.to_csv('autos.csv', index=False)

with open('autos.json', 'w') as f:
    f.write(json.dumps(to_json, indent=4))

# def scrape_query(links):
#     pages = 2
#     n = 0
#     while params['page'] <= pages:
#         response = requests.get(url, params=params)
#         soup = BeautifulSoup(response.text, 'lxml')
#         items = soup.find_all('section', class_='ticket-item')
#
#         for n, i in enumerate(items, start=n + 1):
#             itemBrand = i.find('span', class_='blue bold').text.split()[0]
#             itemsBrand.append(itemBrand.replace('-', '_').replace('ЗАЗ', 'ZAZ').replace('ВАЗ', 'VAZ').replace('ГАЗ',
#                 'GAZ').replace('Богдан', 'Bogdan').replace('УАЗ', 'YAZ').replace('ИЖ', 'IZH').replace('Москвич/АЗЛК',
#                 'Moskuych').replace('ЛуАЗ', 'LyAZ'))
#             itemModel = ' '.join(i.find('span', class_='blue bold').text.split()[1::])
#             itemsModel.append(itemModel.split()[0].replace("-", "_"))
#             itemPrice = i.find('span', class_='bold green size22').text.strip()
#             itemsPrice.append(itemPrice)
#             itemYear = i.find('a', class_='address').text.split()[-1]
#             itemsYear.append(itemYear)
#             itemRegion = i.find('li', class_='item-char view-location js-location').text.strip().split(' (')[0]
#             itemsRegion.append(itemRegion)
#             itemTransmission = i.find_all('li', class_='item-char')[3].text.replace(' ', '')
#             itemsTransmission.append(itemTransmission)
#             itemFuel = i.find_all('li', class_='item-char')[2].text.split(',')[0]
#             itemsFuel.append(itemFuel)
#             itemEngineCapacity = i.find_all('li', class_='item-char')[2].text.split(',')[-1]
#             itemsEngineCapacity.append(itemEngineCapacity)
#             itemMileage = i.find('li', class_='item-char js-race').text
#             itemsMileage.append(itemMileage)
#             itemLink = i.find('a', class_='m-link-ticket').get('href')
#             itemsLink.append(itemLink)
#
#             print(
#                 f'{n}: {itemBrand},\n     Model: {itemModel},\n     Price: {itemPrice} $,\n     Year: {itemYear},\n     '
#                           f'Region: {itemRegion},\n     Transmission: {itemTransmission},\n     Fuel type: {itemFuel},\n     '
#                           f'Engine capacity: {itemEngineCapacity},\n     Mileage: {itemMileage}')
#
#         last_page_num = 20
#         pages = last_page_num if pages < last_page_num else pages
#         params['page'] += 1
#
#     df = pd.DataFrame({
#         'brand': itemsBrand,
#         'model': itemsModel,
#         'price': itemsPrice,
#         'year': itemsYear,
#         'region': itemsRegion,
#         'transmission': itemsTransmission,
#         'fuel_type': itemsFuel,
#         'engine_capacity': itemsEngineCapacity,
#         'mileage': itemsMileage,
#         'link': itemsLink
#     })
#
#     conn = psycopg2.connect(dbname=PG_DB,
#                             user=PG_USER,
#                             password=PG_PASS,
#                             host=PG_HOST)
#     cursor = conn.cursor()
#     new_links = []
#     for link in df['link']:
#         if link not in links:
#             cursor.execute('INSERT INTO telegram_bot_db (brand, model, price, year, region, transmission, fuel engine,'
#                            'engine capacity, mileage, link) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)',
#                            (df['brand'], df['model'], df['price'], df['year'], df['region'], df['transmission'],
#                             df['fuel_engine'], df['engine_capacity'], df['mileage'], df['link']))
#             cursor.commit()
#             new_links.append(link)
#     return new_links