import logging
import random

import pandas as pd

# import config as keys
import psycopg2

import requests
from aiogram import Bot, types
from aiogram.dispatcher import Dispatcher
from aiogram.utils import executor
from aiogram.utils.callback_data import CallbackData

import os
from dotenv import load_dotenv
dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)

# Enable logging
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.INFO)

logger = logging.getLogger(__name__)


# def error(update: Update, context: CallbackContext):
#     """Log Errors caused by Updates."""
#     logger.warning(f'Update {update} caused error {context.error}')

queries = {}


def main():
    db = pd.read_csv('autos.csv')
    dbs = []

    """Start the bot."""
    # Create the Updater and pass it your bot's token.
    # Make sure to set use_context=True to use the new context based callbacks
    # Post version 12 this will no longer be necessary
    # bot = Bot(token=keys.TOKEN)

    TOKEN = os.environ.get('TOKEN')
    bot = Bot(token=TOKEN)

    # Get the dispatcher to register handlers
    dp = Dispatcher(bot)

    # on different commands - answer in Telegram
    @dp.message_handler(commands=['start'])
    async def process_start_command(message: types.Message):
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True, one_time_keyboard=True)
        srch = types.KeyboardButton('/search')
        markup.add(srch)
        await bot.send_message(message.chat.id, 'Привет! Я бот для поиска авто на auto.ria.com\nЧтобы создать запрос '
                                                'нажми на кнопку поиска', reply_markup=markup)

    @dp.message_handler(commands=['rm'])
    async def process_rm_command(message: types.Message):
        await message.reply("Removing message templates", reply_markup=types.ReplyKeyboardRemove())

    @dp.message_handler(commands=['help'])
    async def process_help_command(message: types.Message):
        await message.reply("Для поиска авто воспользуйся командой /search!")

    @dp.message_handler(commands=['save'])
    async def save(message: types.Message):
        await bot.send_message(message.chat.id, 'Вы сохранили свой запрос!')

        await subscribe(message)

    async def subscribe(message: types.Message):
        qrs = pd.read_csv('queries.csv')
        bs = []
        ms = []
        ys = []
        links = []
        for b in qrs['brand'].values:
           if b not in bs:
               bs.append(b)
        for m in qrs['model'].values:
            if m not in ms:
                ms.append(m)
        for y in qrs['year'].values:
            if y not in ys:
                ys.append(y)
        for l in qrs['links'].values:
            if l not in links:
                links.append(l)
        # for j in range(0, len(bs)):
        #     brands_api = 'https://developers.ria.com/auto/categories/1/marks?api_key=' + API_KEY
        #     brands_list = requests.get(brands_api).json()
        #     for i in range(len(brands_list)):
        #         print(brands_list)
        #         print(bs[j])
        #         if brands_list[i]['name'] == bs[j]:
        #             brand_id = brands_list[i]['value']
        #             models_api = 'https://developers.ria.com/auto/categories/1/marks/' + str(
        #                 brand_id) + '/models?api_key=' + API_KEY
        #             models_list = requests.get(models_api).json()
        #             for k in range(len(models_list)):
        #                 if models_list[k]['name'] == ms[j]:
        #                     model_id = models_list[k]['value']
        #                     model_search_api = api_link_ria + '&marka_id=' + str(brand_id) + "&model_id=" + str(
        #                         model_id) + '&countpage=3' + '&page=1'
        #                     model = requests.get(model_search_api).json()
        #                     ads_id_list = model['result']['search_result']['ids']
        #                     list_ads = []
        #                     for l in range(len(ads_id_list)):
        #                         car_api = 'https://developers.ria.com/auto/info?api_key=' + API_KEY + '&auto_id=' + \
        #                                   ads_id_list[l]
        #                         cars_id_list = requests.get(car_api).json()
        #                         car_link = 'https://auto.ria.com/uk' + cars_id_list['linkToView']
        #                         await bot.send_message(message.chat.id, f"{car_link}")
        #                         list_ads.append(car_link)
        #                     print(list_ads)
        #                 else:
        #                     i += 1
        #         else:
        #             i += 1
        await bot.send_message(message.chat.id, f'{random.choice(links)}')

    @dp.message_handler(commands=['search'])
    async def search(message: types.Message):
        conn = psycopg2.connect(dbname="telegram_bot_db",
                                user="postgres_user",
                                password="postgres_password",
                                host="localhost",
                                port=5432)
        cursor = conn.cursor()
        cursor.execute("SELECT brand FROM telegram_bot_db")
        auto_brands_db = cursor.fetchall()
        auto_brands = []
        for brand in auto_brands_db:
            if brand[0] not in auto_brands:
                auto_brands.append(brand[0])
        await bot.send_message(message.chat.id, 'Какая марка Вас интересует?')
        brands = [
            b.replace('-', '_').replace('ЗАЗ', 'ZAZ').replace('ВАЗ', 'VAZ').replace('ГАЗ', 'GAZ').replace('Богдан', 'Bogdan').replace('УАЗ', 'YAZ')
            # for b in db["brand"].unique()
            for b in auto_brands
        ]
        brands = sorted(brands)
        brands[0] = '/' + brands[0]

        await message.answer(
            '/'.join([f'{b}\n' for b in brands])
        )

    @dp.message_handler(content_types=['text'])
    async def models(message):
        conn = psycopg2.connect(dbname="telegram_bot_db",
                                user="postgres_user",
                                password="postgres_password",
                                host="localhost",
                                port=5432)
        cursor = conn.cursor()
        cursor.execute("SELECT brand FROM telegram_bot_db")
        auto_brands_db = cursor.fetchall()
        auto_brands = []
        for brand in auto_brands_db:
            if brand[0] not in auto_brands:
                auto_brands.append(brand[0])

        models = []
        years = []
        # if message.text[1::].replace('_', '-') in db['brand'].unique():
        if message.text[1::].replace('_', '-') in auto_brands:
            brand = message.text[1::]
            brand = brand.replace('_', '-')
            print(brand)
            queries['user'] = message.from_user.id
            queries['brand'] = brand

            await bot.send_message(message.chat.id, "Какая модель Вас интересует?")

            conn = psycopg2.connect(dbname="telegram_bot_db",
                                    user="postgres_user",
                                    password="postgres_password",
                                    host="localhost",
                                    port=5432)
            cursor = conn.cursor()
            cursor.execute(f"SELECT model FROM telegram_bot_db WHERE brand = '{brand}'")
            auto_models_db = cursor.fetchall()
            auto_models = []
            for model in auto_models_db:
                if model[0] not in auto_models:
                    auto_models.append(model[0])

            # for model in db[db['brand'] == brand]['model'].values:
            for model in auto_models:
                model = model.split()[0].replace("-", "_")
                if model not in models:
                    models.append(model)
            models = sorted(models)
            models[0] = '/' + models[0]

            await message.answer(
                '/'.join([f'{m}\n' for m in models])
            )
        elif message.text[1::].replace('_', '-') in db['model'].str.split(' ', 1, expand=True)[0].values:
        # elif message.text[1::].replace('_', '-') in models:
            model = message.text[1::]
            model = model.replace('_', '-')
            print(model)
            queries['model'] = model
            dbs.clear()
            dbs.append(db[db['model'].str.split(' ', 1, expand=True)[0].values == model])
            # dbs.append(models)

            await bot.send_message(message.chat.id, 'Какой год выпуска Вас интересует?')

            conn = psycopg2.connect(dbname="telegram_bot_db",
                                    user="postgres_user",
                                    password="postgres_password",
                                    host="localhost",
                                    port=5432)
            cursor = conn.cursor()
            cursor.execute(f"SELECT year FROM telegram_bot_db WHERE model = '{model}'")
            auto_years_db = cursor.fetchall()
            auto_years = []
            for year in auto_years_db:
                if year[0] not in auto_years:
                    auto_years.append(year[0])
            # print(auto_years)
            for year in db[db['model'].str.split(' ', 1, expand=True)[0].values == model]['year'].values:
            # for year in auto_years:
                if year not in years:
                    years.append(year)
            years = sorted(years)
            years[0] = '/' + years[0].astype(str)
            # years[0] = '/' + years[0]

            await message.answer(
                '/'.join([f'{str(years[i])}\n' for i in range(0, len(years))])
            )

        elif int(message.text[1::]) in db['year'].values:
        # elif int(message.text[1::]) in years:
            year = int(message.text[1::])
            print(year)
            queries['year'] = year
            # conn = psycopg2.connect(dbname="telegram_bot_db",
            #                         user="postgres_user",
            #                         password="postgres_password",
            #                         host="localhost",
            #                         port=5432)
            # cursor = conn.cursor()
            # cursor.execute(f"SELECT link FROM telegram_bot_db WHERE year = '{year}'")
            # auto_links_db = cursor.fetchall()
            # auto_links = []
            # for link in auto_links_db:
            #     if link[0] not in auto_links:
            #         auto_links.append(link[0])

            dbs.append(dbs[0][db['year'] == year]['link'])
            queries['links'] = dbs[1].values
            # dbs.append(auto_links)
            print(len(dbs[1]), 'links')
            await bot.send_message(message.chat.id, 'Предложения по вашему запросу')
            #
            # for link in links:
            #
            #     await bot.send_message(message.chat.id, f'{link}')

            await links_index(message)
            # queries_from = pd.read_csv('queries.csv')
            queries_df = pd.DataFrame(data={'user': queries['user'], 'brand': queries['brand'], 'model': queries['model'],
                                            'year': queries['year'], 'links': queries['links']})
            # if queries_df['brand'].values not in queries_from['brand'].values and queries_df['model'].values not in queries_from['model'].values\
            #         and queries_df['year'].values not in queries_from['year'].values:
            queries_df.to_csv('queries.csv', index=False, mode='a', header=False)
            markup = types.ReplyKeyboardMarkup(resize_keyboard=True, one_time_keyboard=True)
            sv = types.KeyboardButton('/save')
            srch = types.KeyboardButton('/search')
            markup.add(sv, srch)
            await bot.send_message(message.chat.id, 'Если Вы хотите сохранить Ваш запрос и в дальнейшем получать '
                                                    'рассылку - нажмите кнопку сохранения.\nЕсли Вы хотите продолжить '
                                                    'поиск - нажмите кнопку поиска.', reply_markup=markup)


    links_callback = CallbackData("links", "page")

    def get_links_keyboard(page: int = 0) -> types.InlineKeyboardMarkup:
        keyboard = types.InlineKeyboardMarkup(row_width=1)
        has_next_page = len(dbs[1]) > page + 1

        if page != 0:
            keyboard.add(
                types.InlineKeyboardButton(
                    text="< Назад",
                    callback_data=links_callback.new(page=page - 1)
                )
            )

        keyboard.add(
            types.InlineKeyboardButton(
                text=f"• {page + 1}",
                callback_data="dont_click_me"
            )
        )

        if has_next_page:
            keyboard.add(
                types.InlineKeyboardButton(
                    text="Вперёд >",
                    callback_data=links_callback.new(page=page + 1)
                )
            )

        return keyboard

    @dp.message_handler(commands=["links"])
    async def links_index(message: types.Message):

        link_data = dbs[1].values[0]
        # link_data = dbs[1][0]
        keyboard = get_links_keyboard()  # Page: 0

        await bot.send_message(
            chat_id=message.chat.id,
            text=f'{link_data}',
            reply_markup=keyboard
        )

    @dp.callback_query_handler(links_callback.filter())
    async def link_page_handler(query: types.CallbackQuery, callback_data: dict):
        page = int(callback_data.get("page"))

        link_data = dbs[1].values[page]
        # link_data = dbs[1][page]
        keyboard = get_links_keyboard(page)

        await query.message.edit_text(text=f'{link_data}', reply_markup=keyboard)

    #########
    # # log all errors
    # dispatcher.add_error_handler(error)

    # Start the Bot
    executor.start_polling(dp)

    # Run the bot until you press Ctrl-C or the process receives SIGINT,
    # SIGTERM or SIGABRT. This should be used most of the time, since
    # start_polling() is non-blocking and will stop the bot gracefully.
    # updater.idle()


if __name__ == '__main__':
    main()
