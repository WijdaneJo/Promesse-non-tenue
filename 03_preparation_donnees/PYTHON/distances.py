import os 
import pandas as pd 
from sqlalchemy import create_engine 
from dotenv import load_dotenv 

load_dotenv()

user = os.getenv("DB_USER")
password = os.getenv("DB_PASSWORD")
host = os.getenv("DB_HOST")
port = os.getenv("DB_PORT")
database = os.getenv("DB_NAME")

engine = create_engine(f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"
)

print ("connected to database")

requete = """
SELECT DISTINCT
    o.order_id,
    geo_c.avg_lat AS customer_lat,
    geo_c.avg_lng AS customer_lng,
    geo_s.avg_lat AS seller_lat,
    geo_s.avg_lng AS seller_lng
FROM intermediate.orders AS o
LEFT JOIN staging.customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN intermediate.geolocation_pref AS geo_c
    ON c.customer_zip_code_prefix = geo_c.geolocation_zip_code_prefix
LEFT JOIN staging.order_items AS it
    ON o.order_id = it.order_id
LEFT JOIN staging.sellers AS s
    ON it.seller_id = s.seller_id
LEFT JOIN intermediate.geolocation_pref AS geo_s
    ON s.seller_zip_code_prefix = geo_s.geolocation_zip_code_prefix
"""

df = pd.read_sql(requete, engine)

print("Lignes chargées :", len(df))
print("Commandes distinctes :", df["order_id"].nunique())
print(df.head())

import numpy as np

def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # rayon de la Terre en km
    lat1, lon1, lat2, lon2 = map(np.radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = np.sin(dlat/2)**2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon/2)**2
    return 2 * R * np.arcsin(np.sqrt(a))

df["distance_km"] = haversine(
    df["customer_lat"], df["customer_lng"],
    df["seller_lat"], df["seller_lng"]
)

print(df["distance_km"].describe())

distances = (
    df.groupby("order_id")["distance_km"]
      .max()
      .reset_index()
)

print("Commandes :", len(distances))

distances.to_sql(
    "distances",
    engine,
    schema="intermediate",
    if_exists="replace",
    index=False
)

print("Table intermediate.distances écrite.")