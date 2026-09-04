# 店智 AI｜WiseShop OS

給小微店家使用的 **local-first 自動營運管理系統**，也是「創業歸故里」場域驗證用 MVP。

## 現在就能使用

- 營運總覽：今日營收、待處理訂單、低庫存、顧客概況
- 訂單中心：門市／LINE／IG 等多通路訂單集中管理
- 智慧庫存：依近 7 日銷售速度、供應交期、安全係數估算補貨量
- 顧客 CRM：消費次數、累計消費、VIP／常客／新客標記
- 收支管理：快速記帳與營運淨額
- 自動化中心：低庫存、VIP 回訪、每日結帳、異常銷售規則
- AI 店長：完全本機、零 API 成本的資料問答與下一步建議
- 智慧洞察：營運健康分數與場域驗證 KPI
- PWA：可安裝、支援離線殼層
- IndexedDB：資料先存本機，網路不穩也能操作
- CSV 匯出、裝置通知、BarcodeDetector 漸進式支援

## 為什麼第一版採 local-first

場域驗證階段最重要的是「店家能不能真的每天用」。因此第一版不要求店家先註冊雲端帳號、不依賴 API Key，也避免網路中斷就停擺。正式 SaaS 化時再啟用多租戶雲端同步。

## 2026 技術導入路線

### 已直接導入

1. **PWA + Service Worker**：可安裝、離線啟動
2. **IndexedDB local-first**：大量結構化營運資料存在裝置
3. **Predictive rules**：以銷速 × 交期 × 安全係數推估補貨
4. **Browser Notification**：低庫存可發裝置提醒
5. **BarcodeDetector progressive enhancement**：支援的裝置直接使用新 Web API
6. **AI Adapter concept**：本機 AI 店長先零成本工作

### 正式版後端（下一階段）

- **Supabase Postgres + RLS**：店家資料租戶隔離
- **Supabase Realtime**：店員手機、平板、店長電腦同步
- **Supabase Edge Functions**：保護 OpenAI／LINE 等私密金鑰與 webhook
- **OpenAI Responses API + Agents SDK / MCP**：讓 AI 能查訂單、庫存並在授權下執行操作
- **LINE Messaging API**：會員事件、客服、訂單提醒、回訪
- **n8n**：跨服務工作流、自架自動化、人類確認節點
- **Transformers.js + WebGPU（可選）**：相容裝置進行瀏覽器端小模型推理，降低雲端成本；需保留 WASM／雲端降級路徑

> 不把 API 金鑰直接寫進 GitHub Pages。所有具有秘密金鑰、支付、LINE webhook 或 AI 寫入操作的功能，都應放在 Server / Edge Function。

## 場域驗證建議

先找 3–5 家臺中地方商家，連續使用 2–4 週，量化：

- 每日整理訂單時間下降比例
- 缺貨／忘記補貨次數
- 回訪名單建立時間
- 每日結帳彙整時間
- 店家每週主動開啟次數

這些指標可直接放進創業競賽成果報告。

## GitHub Pages

本專案不需要 build step。GitHub Pages 指向 `main / root` 即可部署。
