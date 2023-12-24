### Google Cloud secrets


1. Open secret manager URL and Enable the API
`https://console.cloud.google.com/marketplace/product/google/secretmanager.googleapis.com?project={{ PROJECT_ID }}`


2. Generate account.json and copy it to the /scripts/secrets/google_cloud/ folder

```shell
export PROJECT_ID={{ PROJECT_ID }}

gcloud iam service-accounts \
    --project $PROJECT_ID \
    create external-secrets

gcloud iam service-accounts \
    --project $PROJECT_ID \
    keys create account.json \
    --iam-account=external-secrets@$PROJECT_ID.iam.gserviceaccount.com
```


3. Prepare `.env`, `secrets-map.yaml`, `secrets.sh` files in certain folder and generate secrets:
```shell
chmod +x secrets.sh && ./secrets.sh
```
