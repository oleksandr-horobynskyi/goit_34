import urllib
from sqlalchemy import create_engine, text
from config import (
    SQL_SERVER,
    SQL_PORT,
    SQL_DATABASE,
    SQL_USERNAME,
    SQL_PASSWORD,
    SQL_DRIVER
)

connection_string = (
    f"DRIVER={{{SQL_DRIVER}}};"
    f"SERVER={SQL_SERVER},{SQL_PORT};"
    f"DATABASE={SQL_DATABASE};"
    f"UID={SQL_USERNAME};"
    f"PWD={SQL_PASSWORD};"
    "Encrypt=no;"
    "TrustServerCertificate=yes;"
)

connection_url = f"mssql+pyodbc:///?odbc_connect={urllib.parse.quote_plus(connection_string)}"
engine = create_engine(connection_url)

with engine.connect() as conn:
    result = conn.execute(text("SELECT @@VERSION"))
    for row in result:
        print(row[0])
