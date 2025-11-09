# CU Core Banking App - Deployment Checklist

## ✅ Pre-Deployment Steps

### 1. Install Dependencies
```bash
cd cu_core_banking_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Configure Supabase
1. Create new Supabase project at https://supabase.com
2. Run `supabase_schema.sql` in SQL Editor
3. Create `.env` file:
```env
SUPABASE_URL=your-project-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 3. Add CU Configuration
In Supabase, insert your first CU:
```sql
INSERT INTO cu_configurations (cu_id, name, short_name, domain, routing_number, logo_url, primary_color, secondary_color, contact_email, contact_phone)
VALUES ('navyfederal', 'Navy Federal Credit Union', 'NFCU', 'navyfederal.app', '256074974', 'https://cdn.navyfederal.app/logo.svg', '#003366', '#DCB767', 'support@navyfederal.app', '1-888-842-6328');
```

### 4. Initialize App
In `main.dart`, add:
```dart
await CUConfigService().initialize(cuId: 'navyfederal');
```

### 5. Build & Test
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release

# Web
flutter build web --release
```

## 🚀 Multi-CU Deployment

### For Each Credit Union:

1. **Create Configuration Row** in Supabase `cu_configurations`
2. **Upload Logo** to Supabase Storage or CDN
3. **Set Feature Flags** in `cu_feature_flags` table
4. **Configure API Endpoints** in `cu_api_endpoints` table
5. **Generate Figma Content** (optional):
```bash
python scripts/generate_feature_content.py navyfederal --output figma_content_navyfederal.csv
```
6. **Build with CU ID**:
```bash
flutter build apk --dart-define=CU_ID=navyfederal
flutter build apk --dart-define=CU_ID=becu
flutter build apk --dart-define=CU_ID=golden1
```

## 📦 Package Structure

```
cu_core_banking_app/
├── lib/
│   ├── config/
│   │   └── cu_config_service.dart ✅ NEW
│   ├── services/
│   │   ├── cu_core_service.dart ✅ NEW
│   │   ├── banking_service.dart
│   │   ├── transfers_service.dart
│   │   ├── bill_pay_service.dart
│   │   ├── card_service.dart
│   │   └── check_deposit_service.dart
│   ├── screens/
│   ├── widgets/
│   └── providers/
└── supabase_schema.sql ✅ UPDATED
```

## 🔐 Security Checklist

- [ ] Row Level Security (RLS) enabled on all tables
- [ ] API keys stored in environment variables
- [ ] Biometric auth configured for iOS/Android
- [ ] SSL pinning enabled for production
- [ ] Audit logging configured

## 🎨 Branding Per CU

Each CU automatically gets:
- Custom logo (from `cu_configurations.logo_url`)
- Brand colors (primary/secondary)
- Custom product names (e.g., "NFCU Premier Checking")
- Domain-based emails (e.g., `test@navyfederal.app`)
- AI-generated Figma content with CU-specific branding

## 📊 Monitoring

Setup monitoring for:
- API response times
- Feature flag usage
- Error rates per CU
- User authentication metrics

## 🔄 Continuous Deployment

1. Push to `main` branch
2. GitHub Actions builds for iOS/Android/Web
3. Deploy Supabase Edge Functions:
```bash
supabase functions deploy generate-feature-content
```
4. Deploy to App Store / Play Store
5. Web deployment to Vercel/Cloudflare

## 🎨 Figma Content Generation

Generate design-ready content for any CU:

```bash
# Single CU
python scripts/generate_feature_content.py navyfederal \
  --output figma_content_navyfederal.csv

# Batch all CUs
for cu_id in navyfederal becu golden1 penfed alliant; do
  python scripts/generate_feature_content.py "$cu_id" \
    --output "figma_content_${cu_id}.csv"
done
```

**Features:**
- ✅ 60+ banking features covered
- ✅ CU-specific branding (e.g., "Contact Navy Federal")
- ✅ Figma-ready CSV format
- ✅ Cached results (fast regeneration)
- ✅ Direct Google Sheets import

See: `FEATURE_CONTENT_GENERATOR_MIGRATION.md` for details

---

**Ready to deploy 200+ credit unions from ONE codebase!** 🎉
