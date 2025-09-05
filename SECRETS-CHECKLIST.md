# Secrets & Environment Variables Checklist

目的：列出專案在 CI / 本機 / 佈署環境中常用的 secrets/環境變數名稱、用途與設定範例，方便一次性在 GitHub / k8s / CI 中完成設定。

---

## 必備 Secrets（建議優先設定）
- DATABASE_CONNECTION_STRING  
  - 用途：資料庫連線字串（應包含帳號密碼或使用受管身分）。  
  - 範例：Server=db.prod.example.com;Database=ecommerce;User Id=app;Password=VerySecret!  
  - 置放：GitHub Actions Secret / Cloud Secret Manager / k8s Secret (key: connection)  
  - 週期：每 90 天輪替（視政策）

- REDIS_CONNECTION_STRING  
  - 用途：Redis 連線（快取 / distributed locks / outbox）。  
  - 範例：redis://:password@redis.prod:6379/0

- KAFKA_BOOTSTRAP_SERVERS  
  - 用途：Kafka brokers list。  
  - 範例：kafka1:9092,kafka2:9092  
  - 可選：KAFKA_SASL_USERNAME、KAFKA_SASL_PASSWORD

- JWT_SIGNING_KEY  
  - 用途：簽發/驗證 JWT 的私鑰或 HMAC key（長字串或 base64）。  
  - 建議：使用長隨機 key（或 RSA/ECDSA 私鑰），不要放在程式碼中。

- JWT_ISSUER / JWT_AUDIENCE  
  - 用途：JWT 設定（可視為非敏感或低敏感，視情況放 Secrets 或 Variables）。

- STRIPE_API_KEY  
  - 用途：Stripe 金流（secret key）。使用測試 key 在 dev，production 使用 live key。  
  - 範例：sk_test_xxx

- PAYPAL_CLIENT_ID / PAYPAL_SECRET  
  - 用途：PayPal API 憑證

- PAYMENT_PROVIDER_*（ECPAY / NewebPay 等）  
  - 範例：ECPAY_API_KEY / ECPAY_HASH_KEY / ECPAY_HASH_IV

- PAYMENT_PROVIDER_CERT  
  - 用途：若需上傳 pfx/pem 憑證，請 base64 編碼後存放於 secret。  
  - 儲存方式：將檔案 base64 後儲存為一個 string secret

- DOCKER_REGISTRY_USERNAME / DOCKER_REGISTRY_PASSWORD  
  - 用途：CI login to registry（若需要自動推映像）

- SMTP_USERNAME / SMTP_PASSWORD（如有）  
- SENTRY_DSN / DATADOG_API_KEY / [OBSERVABILITY_KEYS]（如有）

---

## 建議命名與 .NET 映射
- ConnectionStrings__Default -> Configuration.GetConnectionString("Default")  
 （在環境變數中用兩個底線表示冒號）
- 用 env 名稱：JWT_SIGNING_KEY、REDIS_CONNECTION_STRING、KAFKA_BOOTSTRAP_SERVERS

---

## GitHub（Repo）上設定步驟（UI）
1. 進入 Repository → Settings → Secrets and variables → Actions  
2. 點 New repository secret  
3. Name: DATABASE_CONNECTION_STRING, Value: <value> → Add secret  
4. 針對敏感部署步驟，可改放到 Settings → Environments（production）加上 required reviewers

gh CLI 範例：
- gh secret set DATABASE_CONNECTION_STRING --body "Server=...;User Id=...;Password=..."
- gh secret set DOCKER_REGISTRY_PASSWORD --body "$(cat token.txt)"

---

## 在 GitHub Actions workflow 使用（範例）
env:
  CONNECTION_STRING: ${{ secrets.DATABASE_CONNECTION_STRING }}
  JWT_KEY: ${{ secrets.JWT_SIGNING_KEY }}
steps:
  - name: Login to Docker
    uses: docker/login-action@v2
    with:
      username: ${{ secrets.DOCKER_REGISTRY_USERNAME }}
      password: ${{ secrets.DOCKER_REGISTRY_PASSWORD }}

不要在 workflow logs 中輸出 secrets（避免 echo ${{ secrets.X }}）。

---

## 憑證檔（.pfx/.pem）處理建議
1. base64 編碼後存成一個 secret：
   - base64 cert.pfx > cert.pfx.b64
   - gh secret set PAYMENT_PROVIDER_CERT --body "$(cat cert.pfx.b64)"
2. 在 workflow 中寫回檔案：
echo "${{ secrets.PAYMENT_PROVIDER_CERT }}" | base64 -d > /tmp/cert.pfx

注意：GitHub Secrets 單值大小限制（約 64KB），大型檔請改用 Cloud Secret Manager。

---

## Kubernetes（k8s）示例
- 建 secret（literal）：
  - kubectl create secret generic ecommerce-secrets --from-literal=DATABASE_CONNECTION_STRING='Server=...' --from-literal=JWT_SIGNING_KEY='...'
- Deployment 以 envFrom 或 secretKeyRef 注入：
env:
  - name: DATABASE_CONNECTION_STRING
    valueFrom:
      secretKeyRef:
        name: ecommerce-secrets
        key: DATABASE_CONNECTION_STRING

若使用雲端 Managed Secrets（KeyVault, Secrets Manager），請以 IAM / Managed Identity 授權 Pod 存取，避免直接在 manifest 放 secrets。

---

## 本機開發建議
- 使用 dotnet user-secrets（只在開發機上，不會 commit）：
  - dotnet user-secrets init
  - dotnet user-secrets set "ConnectionStrings:Default" "Server..."
- 或使用 .env（加入 .gitignore）

---

## 安全建議（必讀）
- 永遠不要把 secrets commit。  
- 最小權限原則：每個 secret 僅給需要的 workflow / 環境。  
- 在 production 使用 Environments 並啟用 protection（required reviewers / wait timer）。  
- 啟用 audit logs / secret rotation policy（定期輪替）。  
- 若可能，用雲端 Secret Manager（Key Vault / Secrets Manager）並使用短期憑證或動態秘密（dynamic secrets）。

---

## 短期建議與優先順序（設定時序）
1. 優先：DATABASE_CONNECTION_STRING、REDIS、JWT_SIGNING_KEY、DOCKER registry（若自動推映）。  
2. 接著：KAFKA（若使用）、第三方金流（Stripe/PayPal）測試金鑰。  
3. 最後：觀察性 keys、SMTP、可選的憑證檔。

---

## 我可以幫你做的事（選項）
- 幫你把這份 checklist 加到 PR 或推到 feature/init-multitenant（README / docs）。  
- 幫你在 PR 說明中列出要你在 GitHub Secrets 新增的每一項（含範例）。  
- 幫你產生 workflow 範例（把 secrets 注入並做 build/test/push).