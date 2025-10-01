
from flask import Flask, request, render_template_string

import mysql.connector
import hashlib
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.storage.blob import BlobServiceClient
import datetime


app = Flask(__name__)


# Dane do połączenia z bazą (adres, login z main.tf, hasło z Key Vault)
MYSQL_HOST = "mysql-burstable-05-new-9542653542.mysql.database.azure.com"
MYSQL_USER = "mysqladminuser"
MYSQL_DB = "testowabaza"
KEYVAULT_URL = "https://kvworkshopt2s05.vault.azure.net/"
KEYVAULT_SECRET = "mysql-password"

# Dane storage
STORAGE_ACCOUNT_URL = "https://stworkshop05storage.blob.core.windows.net/"
STORAGE_CONTAINER = "logi_logowan"


# Formularz logowania z Bootstrap
LOGIN_FORM = '''
<!doctype html>
<html lang="pl">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
        <title>Logowanie</title>
    </head>
    <body class="bg-light">
        <div class="container d-flex justify-content-center align-items-center" style="min-height: 100vh;">
            <div class="card shadow p-4" style="width: 22rem;">
                <h3 class="mb-4 text-center">Logowanie</h3>
                <form method="post">
                    <div class="mb-3">
                        <label for="login" class="form-label">Login</label>
                        <input type="text" class="form-control" id="login" name="login" required>
                    </div>
                    <div class="mb-3">
                        <label for="password" class="form-label">Hasło</label>
                        <input type="password" class="form-control" id="password" name="password" required>
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Zaloguj</button>
                </form>
                {% if message %}
                    <div class="mt-3 alert {% if message == 'SUKCES LOGOWANIA' %}alert-success{% else %}alert-danger{% endif %}" role="alert">
                        {{ message }}
                    </div>
                {% endif %}
            </div>
        </div>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>
'''

@app.route('/', methods=['GET', 'POST'])
def login():
    message = None
    if request.method == 'POST':
        login = request.form.get('login')
        password = request.form.get('password')
        log_status = 'BLAD logowania'
        if not login or not password:
            message = 'Podaj login i hasło.'
        else:
            # Hashowanie hasła SHA1
            password_sha1 = hashlib.sha1(password.encode('utf-8')).hexdigest()
            try:
                # Pobierz hasło z Key Vault
                credential = DefaultAzureCredential()
                secret_client = SecretClient(vault_url=KEYVAULT_URL, credential=credential)
                MYSQL_PASSWORD = secret_client.get_secret(KEYVAULT_SECRET).value

                conn = mysql.connector.connect(
                    host=MYSQL_HOST,
                    user=MYSQL_USER,
                    password=MYSQL_PASSWORD,
                    database=MYSQL_DB,
                    ssl_ca='DigiCertGlobalRootCA.crt.pem'
                )
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) FROM user WHERE login=%s AND password=%s", (login, password_sha1))
                result = cursor.fetchone()
                if result and result[0] == 1:
                    message = 'SUKCES LOGOWANIA'
                    log_status = 'SUKCES LOGOWANIA'
                else:
                    message = 'BLAD logowania'
                    log_status = 'BLAD logowania'
                cursor.close()
                conn.close()
            except mysql.connector.Error as db_err:
                print(f"Błąd bazy danych: {db_err}")
                message = f'Błąd połączenia z bazą: {db_err}'
                log_status = f'BŁĄD: {db_err}'
            except Exception as e:
                print(f"Błąd ogólny: {e}")
                message = f'Błąd aplikacji: {e}'
                log_status = f'BŁĄD: {e}'

        # Logowanie próby logowania do Azure Storage
        try:
            credential = DefaultAzureCredential()
            blob_service_client = BlobServiceClient(account_url=STORAGE_ACCOUNT_URL, credential=credential)
            container_client = blob_service_client.get_container_client(STORAGE_CONTAINER)
            log_entry = f"{datetime.datetime.utcnow().isoformat()} | login: {login} | status: {log_status}\n"
            blob_name = f"log_{datetime.datetime.utcnow().strftime('%Y%m%d')}.txt"
            try:
                blob_client = container_client.get_blob_client(blob_name)
                existing = b""
                if blob_client.exists():
                    existing = blob_client.download_blob().readall()
                blob_client.upload_blob(existing + log_entry.encode('utf-8'), overwrite=True)
            except Exception as log_err:
                print(f"Błąd logowania do storage: {log_err}")
        except Exception as storage_err:
            print(f"Błąd połączenia ze storage: {storage_err}")

    return render_template_string(LOGIN_FORM, message=message)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)