import logging

import pandas as pd
import psycopg2
import requests


from aiogram import Bot, types
from aiogram.dispatcher import Dispatcher
from aiogram.utils import executor
from aiogram.utils.callback_data import CallbackData
from aiogram.dispatcher import FSMContext
from aiogram.dispatcher.filters.state import State, StatesGroup
from aiogram.contrib.fsm_storage.memory import MemoryStorage
import asyncio

import os
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
if os.path.exists(dotenv_path):
    load_dotenv(dotenv_path)

TOKEN = os.environ.get('TOKEN')
PG_HOST = os.environ.get('PG_HOST')
PG_USER = os.environ.get('PG_USER')
PG_PASS = os.environ.get('PG_PASS')
PG_DB = os.environ.get('PG_DB')
API_KEY = os.environ.get('API_KEY')

# Enable logging
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.INFO)

logger = logging.getLogger(__name__)

# def error(update: Update, context: CallbackContext):
#     """Log Errors caused by Updates."""
#     logger.warning(f'Update {update} caused error {context.error}')

queries = {}


def main():
    # db = pd.read_csv('autos.csv')
    dbs = []

    """Start the bot."""
    # Create the Updater and pass it your bot's token.
    # Make sure to set use_context=True to use the new context based callbacks
    # Post version 12 this will no longer be necessary

    bot = Bot(token=TOKEN)

    class Auto(StatesGroup):
        waiting_for_brand = State()
        waiting_for_model = State()
        waiting_for_year = State()
        waiting_for_links = State()

    # Get the dispatcher to register handlers
    dp = Dispatcher(bot, storage=MemoryStorage(), )

    # on different commands - answer in Telegram
    @dp.message_handler(commands=['start'])
    async def process_start_command(message: types.Message):
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True, one_time_keyboard=True)
        srch = types.KeyboardButton('/search')
        markup.add(srch)
        await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
        await asyncio.sleep(1)
        await bot.send_message(message.chat.id, 'Привет! Я бот для поиска авто на auto.ria.com\nЧтобы создать запрос '
                                                'нажми на кнопку поиска', reply_markup=markup)

    @dp.message_handler(commands=['rm'])
    async def process_rm_command(message: types.Message):
        await message.reply("Removing message templates", reply_markup=types.ReplyKeyboardRemove())

    @dp.message_handler(commands=['help'])
    async def process_help_command(message: types.Message):
        await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
        await asyncio.sleep(1)
        await message.reply("Для поиска авто воспользуйся командой /search!")

    @dp.message_handler(commands=['save'])
    async def save(message: types.Message, state):
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True, one_time_keyboard=True)
        sv = types.KeyboardButton('/save')
        srch = types.KeyboardButton('/search')
        markup.add(sv, srch)
        await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
        await asyncio.sleep(1)
        await bot.send_message(message.chat.id, 'Вы сохранили свой запрос!', reply_markup=markup)

        await subscribe(message, state)

    async def subscribe(message: types.Message, state):
        async with state.proxy() as data:
            await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
            await asyncio.sleep(1)
            await bot.send_message(message.chat.id, 'Проверяю наличие новых предложений по вашему запросу!')
            await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
            # await asyncio.sleep(1)
            # new_links = scrape_query(data['brand'], data['model'], data['year'], data['links'])
            new_links = api_query(data['brand'], data['model'], data['year'], data['links'])
            print(len(new_links), 'new links')
            if len(new_links) == 0:
                await bot.send_message(message.chat.id, 'Нет новых предложений 😢')
            else:
                for link in new_links:
                    if link not in data['links']:
                        data['links'].append(link)
                print(len(data['links']), 'links in total')
                await bot.send_message(message.chat.id, 'Новые предложения по вашему запросу')

                # await bot.send_message(message.chat.id, f'{new_links}')
                await links_index(message, new_links)

    @dp.message_handler(commands=['search'])
    async def search(message: types.Message):
        conn = psycopg2.connect(dbname=PG_DB,
                                user=PG_USER,
                                password=PG_PASS,
                                host=PG_HOST)
        cursor = conn.cursor()
        cursor.execute("SELECT brand FROM telegram_bot_db")
        auto_brands_db = cursor.fetchall()
        auto_brands = []
        for brand in auto_brands_db:
            if brand[0] not in auto_brands:
                auto_brands.append(brand[0])
        await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
        await asyncio.sleep(1)
        await bot.send_message(message.chat.id, 'Какая марка Вас интересует?')
        brands = sorted(auto_brands)
        brands[0] = '/' + brands[0]

        await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
        await message.answer(
            '/'.join([f'{b}\n' for b in brands])
        )
        await Auto.waiting_for_brand.set()

    @dp.message_handler(content_types=['text'], state=Auto.waiting_for_brand)
    async def models(message, state: FSMContext):
        # await state.update_data(brand=message.text.strip())
        conn = psycopg2.connect(dbname=PG_DB,
                                user=PG_USER,
                                password=PG_PASS,
                                host=PG_HOST)
        cursor = conn.cursor()
        cursor.execute("SELECT brand FROM telegram_bot_db")
        auto_brands_db = cursor.fetchall()
        auto_brands = []
        for brand in auto_brands_db:
            if brand[0] not in auto_brands:
                auto_brands.append(brand[0])

        if message.text[1::] in auto_brands:
            brand = message.text[1::]
            async with state.proxy() as data:
                data['brand'] = brand
            print(brand)
            queries['user'] = message.from_user.id
            queries['brand'] = brand

            await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
            await asyncio.sleep(1)
            await bot.send_message(message.chat.id, "Какая модель Вас интересует?")
            await Auto.waiting_for_model.set()
            conn = psycopg2.connect(dbname=PG_DB,
                                    user=PG_USER,
                                    password=PG_PASS,
                                    host=PG_HOST)
            cursor = conn.cursor()
            cursor.execute(f"SELECT model FROM telegram_bot_db WHERE brand = '{brand}'")
            auto_models_db = cursor.fetchall()
            auto_models = []
            for model in auto_models_db:
                if model[0] not in auto_models:
                    auto_models.append(model[0])

            models = sorted(auto_models)
            models[0] = '/' + models[0]

            await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
            await message.answer(
                '/'.join([f'{m}\n' for m in models])
            )
            await Auto.waiting_for_model.set()

    @dp.message_handler(content_types=['text'], state=Auto.waiting_for_model)
    async def years(message, state):
        async with state.proxy() as data:
            conn = psycopg2.connect(dbname=PG_DB,
                                    user=PG_USER,
                                    password=PG_PASS,
                                    host=PG_HOST)
            cursor = conn.cursor()
            cursor.execute(f"SELECT model FROM telegram_bot_db WHERE brand = '{data['brand']}'")
            auto_models_db = cursor.fetchall()
            auto_models = []
            for model in auto_models_db:
                if model[0] not in auto_models:
                    auto_models.append(model[0])
            if message.text[1::] in auto_models:
                model = message.text[1::]
                data['model'] = model
                print(model)
                queries['model'] = model
                dbs.clear()

                await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
                await asyncio.sleep(1)
                await bot.send_message(message.chat.id, 'Какой год выпуска Вас интересует?')

                conn = psycopg2.connect(dbname=PG_DB,
                                        user=PG_USER,
                                        password=PG_PASS,
                                        host=PG_HOST)
                cursor = conn.cursor()
                cursor.execute(
                    f"SELECT year FROM telegram_bot_db WHERE brand = '{data['brand']}' AND model = '{data['model']}'")
                auto_years_db = cursor.fetchall()
                auto_years = []
                for year in auto_years_db:
                    if year[0] not in auto_years:
                        auto_years.append(year[0])
                years = []
                for year in auto_years:
                    if year not in years:
                        years.append(year)
                years = sorted(years)
                years[0] = '/' + str(years[0])

                await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
                await message.answer(
                    '/'.join([f'{str(years[i])}\n' for i in range(0, len(years))])
                )
                await Auto.waiting_for_year.set()

    @dp.message_handler(content_types=['text'], state=Auto.waiting_for_year)
    async def links(message, state):
        async with state.proxy() as data:
            conn = psycopg2.connect(dbname=PG_DB,
                                    user=PG_USER,
                                    password=PG_PASS,
                                    host=PG_HOST)
            cursor = conn.cursor()
            cursor.execute(
                f"SELECT year FROM telegram_bot_db WHERE brand = '{data['brand']}' AND model = '{data['model']}'")
            auto_years_db = cursor.fetchall()
            auto_years = []
            for year in auto_years_db:
                if year[0] not in auto_years:
                    auto_years.append(year[0])
            if message.text[1::] == 'start':
                await process_start_command(message)
            elif message.text[1::] == 'search':
                await search(message)
            elif message.text[1::] == 'save':
                await save(message, state)
            elif message.text[1::] == 'rm':
                await process_rm_command(message)
            elif message.text[1::] == 'help':
                await process_help_command(message)
            elif message.text[1::] in auto_years:
                year = int(message.text[1::])
                data['year'] = year
                print(year)
                queries['year'] = year
                conn = psycopg2.connect(dbname=PG_DB,
                                        user=PG_USER,
                                        password=PG_PASS,
                                        host=PG_HOST)
                cursor = conn.cursor()
                cursor.execute(f"SELECT link FROM telegram_bot_db WHERE brand = '{data['brand']}' AND "
                               f"model = '{data['model']}' AND year = '{data['year']}'")
                auto_links_db = cursor.fetchall()
                auto_links = []
                for link in auto_links_db:
                    if link[0] not in auto_links:
                        auto_links.append(link[0])

                # dbs.append(dbs[0][db['year'] == year]['link'])
                # queries['links'] = dbs[1].values
                dbs.append(auto_links)
                queries['links'] = auto_links
                data['links'] = auto_links
                print(len(auto_links), 'links')

                await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
                await asyncio.sleep(1)
                await bot.send_message(message.chat.id, 'Предложения по вашему запросу')

                # await bot.send_message(message.chat.id, f'{auto_links}')
                await links_index(message, dbs[0])

                # queries_from = pd.read_csv('queries.csv')
                queries_df = pd.DataFrame(
                    data={'user': queries['user'], 'brand': queries['brand'], 'model': queries['model'],
                          'year': queries['year'], 'links': queries['links']})
                # if queries_df['brand'].values not in queries_from['brand'].values and queries_df['model'].values not in queries_from['model'].values\
                #         and queries_df['year'].values not in queries_from['year'].values:
                queries_df.to_csv('queries.csv', index=False, mode='a', header=False)
                markup = types.ReplyKeyboardMarkup(resize_keyboard=True, one_time_keyboard=True)
                sv = types.KeyboardButton('/save')
                srch = types.KeyboardButton('/search')
                markup.add(sv, srch)

                await bot.send_chat_action(message.chat.id, types.ChatActions.TYPING)
                await asyncio.sleep(1)
                await bot.send_message(message.chat.id, 'Если Вы хотите сохранить Ваш запрос и в дальнейшем получать '
                                                        'рассылку - нажмите кнопку сохранения.\nЕсли Вы хотите продолжить '
                                                        'поиск - нажмите кнопку поиска.', reply_markup=markup)
                await state.finish()

    links_callback = CallbackData("links", "page")

    def get_links_keyboard(count, page: int = 0) -> types.InlineKeyboardMarkup:
        keyboard = types.InlineKeyboardMarkup(row_width=1)
        has_next_page = count > page + 1

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
    async def links_index(message: types.Message, links):
        link_data = links[0]
        keyboard = get_links_keyboard(len(links))  # Page: 0

        await bot.send_message(
            chat_id=message.chat.id,
            text=f'{link_data}',
            reply_markup=keyboard
        )

    @dp.callback_query_handler(links_callback.filter())
    async def link_page_handler(query: types.CallbackQuery, callback_data: dict, state):
        async with state.proxy() as data:
            page = int(callback_data.get("page"))
            link_data = data['links'][page]
            keyboard = get_links_keyboard(len(data['links']), page)

            await query.message.edit_text(text=f'{link_data}', reply_markup=keyboard)

    def api_query(brand, model, year, links):
        new_links = []
        api_link_ria = 'https://developers.ria.com/auto/search?api_key=' + API_KEY + "&category_id=1"
        brands_api = 'https://developers.ria.com/auto/categories/1/marks?api_key=' + API_KEY
        brands_list = requests.get(brands_api).json()
        for i in range(len(brands_list)):
            if brands_list[i]['name'] == brand:
                brand_id = brands_list[i]['value']
                models_api = 'https://developers.ria.com/auto/categories/1/marks/' + str(
                    brand_id) + '/models?api_key=' + API_KEY
                models_list = requests.get(models_api).json()
                for j in range(len(models_list)):
                    if models_list[j]['name'] == model:
                        model_id = models_list[j]['value']
                        model_search_api = api_link_ria + '&marka_id=' + str(brand_id) + "&model_id=" + str(
                            model_id) + '&s_yers[0]=' + str(year) + '&po_yers[0]=' + str(year)
                        model_req = requests.get(model_search_api).json()
                        ads_id_list = model_req['result']['search_result']['ids']
                        list_ads = []
                        for k in range(len(ads_id_list)):
                            car_api = 'https://developers.ria.com/auto/info?api_key=' + API_KEY + '&auto_id=' + \
                                      ads_id_list[k]
                            cars_id_list = requests.get(car_api).json()
                            car_link = 'https://auto.ria.com/uk' + cars_id_list['linkToView']
                            list_ads.append(car_link)

                            if car_link not in links:
                                new_links.append(car_link)
                                conn = psycopg2.connect(dbname=PG_DB,
                                                        user=PG_USER,
                                                        password=PG_PASS,
                                                        host=PG_HOST)
                                cursor = conn.cursor()
                                cursor.execute(
                                    'INSERT INTO telegram_bot_db (brand, model, year, link) VALUES (%s, %s, %s, %s)',
                                    (brand, model, year, car_link))
                                conn.commit()
                    else:
                        j += 1
            else:
                i += 1

        return new_links

    #########
    # # log all errors
    # dispatcher.add_error_handler(error)

    # Start the Bot

    executor.start_polling(dp, skip_updates=True)

    # Run the bot until you press Ctrl-C or the process receives SIGINT,
    # SIGTERM or SIGABRT. This should be used most of the time, since
    # start_polling() is non-blocking and will stop the bot gracefully.
    # updater.idle()


if __name__ == '__main__':
    main()
