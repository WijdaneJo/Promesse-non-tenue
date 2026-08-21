import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

connexion = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD")
)
cur = connexion.cursor()

dossier = r"C:\Users\dell\Documents\GitHub\Promesse-non-tenue\02_qualification_donnees\dataset"

fichiers = {
    "olist_customers_dataset.csv": "raw.customers",
    "olist_geolocation_dataset.csv": "raw.geolocation",
    "olist_order_items_dataset.csv": "raw.order_items",
    "olist_order_payments_dataset.csv": "raw.order_payments",
    "olist_order_reviews_dataset.csv": "raw.order_reviews",
    "olist_orders_dataset.csv": "raw.orders",
    "olist_products_dataset.csv": "raw.products",
    "olist_sellers_dataset.csv": "raw.sellers",
    "product_category_name_translation.csv": "raw.category_name_translation"
}

for fichier, table in fichiers.items():
    chemin = os.path.join(dossier, fichier)

    cur.execute(f"TRUNCATE {table}")

    with open(chemin, encoding="utf-8") as f:
        cur.copy_expert(
            f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true)", f
        )

    cur.execute(f"SELECT COUNT(*) FROM {table}")
    print(f"{table:35} {cur.fetchone()[0]:>9} lignes")

connexion.commit()
cur.close()
connexion.close()
print("\nChargement terminé.")