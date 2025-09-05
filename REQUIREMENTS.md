# ECommerce — 需求規格書 (Multitenant Backend)

版本: 0.2
作者: Copilot for xul4m3
日期: 2025-09-05

目標簡述
- 建置基於 .NET 8 的多租戶電子商務後端，使用 Finbuckle.MultiTenant 作為租戶解析/中介層，資料儲存以 PostgreSQL，快取/短期狀態以 Redis，事件序列與整合使用 Kafka（Outbox pattern）。

技術棧（必須明確）
- 平台: .NET 8 (ASP.NET Core)
- 多租戶: Finbuckle.MultiTenant (middleware/resolver)
  - 初始採「single database + tenant_id column」策略，由 Finbuckle 負責從 header, hostname 或 JWT 提取 tenant identifier。
- ORM: Entity Framework Core (Npgsql provider) for PostgreSQL
- DB: PostgreSQL (>=15)
- Cache/Session/Distributed Lock: Redis (StackExchange.Redis)
- Event bus / Integration: Kafka（Outbox pattern）
- Webhook 签章: HMAC-SHA256 (shared secret)
- CI/CD: GitHub Actions (build/test/publish)
- Container: Docker (Dockerfile + docker-compose for local dev)
- Logging/Tracing: Structured JSON logs, OpenTelemetry (optional), Prometheus metrics, Jaeger/Zipkin traces
- Testing: xUnit / NUnit + Testcontainers (Postgres, Kafka) for integration tests

關鍵實作細節
- Finbuckle.MultiTenant 用法
  - 在 ASP.NET Core pipeline 中註冊 Finbuckle，並支援 multi-tenant resolution via:
    - Header: X-Tenant-ID
    - JWT claim: tenant_id
    - Hostname (optional)
  - 對於每個 request，Finbuckle 應把 tenant identifier 注入到 request context，並讓 repository/service 層使用該 tenant_id 做資料隔離。
- 資料隔離
  - 初版: single DB，多個表（products, orders...）皆含 tenant_id 欄位，所有查詢強制加入 tenant filter（建議在 EF Core 的 SaveChanges / Query Filters 中自動套用）。
  - 後續可演進為 schema-per-tenant 或 db-per-tenant。
- Outbox pattern
  - 所有會改變系統狀態的重要事務同時寫入 domain tables 與 outbox_events 表（同一 DB transaction）。
  - background worker 定期讀取未送出的 outbox event，發布到 Kafka，更新 outbox event 狀態及 attempts。
- Redis
  - 用於短期快取（product listing）、分散式鎖（如 stock 扣款）、以及作為一級緩存以減少 DB 負載。
- Webhook
  - Webhook payload 用 JSON，HTTP Header 包含 X-Signature: sha256=<hex-hmac(payload, secret)>, X-Event-Type, X-Tenant-ID。
  - 送達重試採 exponential backoff，最大重試次數（例如 5 次），失敗則寫入 dead-letter table。
- 身份驗證 / 授權
  - JWT 為主要驗證方式，JWT payload 必含 tenant_id, sub (user id), roles。
  - RBAC (Admin, TenantAdmin, Merchant, Customer)；對於敏感操作在服務層再次檢查 tenant_id 與角色。
- 測試
  - Unit tests 覆蓋 service 邏輯與中介層行為。
  - Integration tests 使用 Testcontainers 啟動 Postgres、Kafka、Redis，並模擬 Finbuckle 的 tenant resolution。
  - Contract tests for webhook consumers（建議）。

部署/Infrastructure
- 本地開發: docker-compose (postgres, redis, zookeeper, kafka, app)
- CI: GitHub Actions build (dotnet restore/build/test) + docker build
- Secrets: DB_CONNECTION_STRING, REDIS_CONNECTION, KAFKA_BOOTSTRAP, WEBHOOK_SECRET, DOCKER_REGISTRY_TOKEN 等應放在 repo/organization secrets 或雲端 secret manager。
- DB Migration: 使用 EF Core Migrations，自動在 CI/CD 或部署啟動時套用 migration（可選開關）。

非功能需求（補充）
- Observability: 每個 request 帶 request-id, correlation-id；outbox metrics (pending count)，webhook failure metrics。
- 性能: 95% read < 300ms（取決於資料量與索引）
- 可用性/恢復: Outbox + Kafka 保證事件至少一次交付；幂等事件處理設計。

資料模型（補足〝tenant_id〞相關）
- tenants (id, name, status, config JSON, created_at)
- users (id, tenant_id, email, password_hash, roles, created_at)
- products (id, tenant_id, sku, name, description, price_cents, currency, stock, status)
- orders (id, tenant_id, customer_id, total_cents, currency, status, created_at)
- order_items (id, order_id, product_id, qty, price_cents)
- outbox_events (id, aggregate_type, aggregate_id, event_type, payload JSON, status, attempts, created_at, last_attempt_at)
- webhooks (id, tenant_id, url, secret, events_subscribed, status)

API 設計要點（含 tenant 驗證）
- 版號: /api/v1/
- 所有 endpoint 要求 Authorization: Bearer <jwt> 或 X-Tenant-ID header（若使用 header，需同時送過一個 app token）
- 範例: POST /api/v1/tenants (平台级操作)
- 範例: POST /api/v1/tenants/{tenantId}/products （Server 端須核對 tenantId 與 JWT 的 tenant_id 是否一致）

驗收條件（補強）
- 在 Postgres DB 中同一 product sku 在不同 tenant 下能共存（tenant_id 作為隔離鍵）。
- Finbuckle 在 pipeline 中能正確解析 X-Tenant-ID 與 JWT claim，並注入 tenantContext。
- 下單時庫存扣減在 DB transaction 中完成，outbox 一併寫入同一事務。
- Outbox worker 在 Kafka 不可用時會重試並保留事件；Kafka 恢復後事件可被成功發送且不重複遺失。
- Webhook 傳送帶有正確 HMAC-SHA256 簽章，且在失敗達最大重試後移入 dead-letter。

測試建議（開發／QA）
- Integration tests: 模擬 multi-tenant header/jwt，驗證 query filter 與自動套用 tenant_id。
- Webhook consumer: 驗證簽章、重試與 dead-letter。
- End-to-End: 使用 Testcontainers 啟動 Postgres/Redis/Kafka，跑一套從建立商品→下單→outbox→webhook 的流程。

交付項目（更新）
- README + 技術選型說明（含 Finbuckle 指引）
- OpenAPI 草案（包含 tenant header/claims 說明）
- Source code scaffold (.NET 8 + Finbuckle)
- GitHub Actions workflow
- Gherkin 驗收場景（含 tenant resolver、Redis、Postgres、Outbox）

附註
- 我已把 Finbuckle 多租戶的需求及具體實作建議加入本文件。若你要我直接把這個文件推上你的 repo，我可以在你授權後幫你完成 PR，或將檔案打包傳給你。