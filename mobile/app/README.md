# CU Core Banking App - White-Label Credit Union Banking Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20|%20Android-lightgrey.svg)](https://flutter.dev/)

**CU Core Banking App** is a white-label banking application platform designed for credit unions. It provides a modern, AI-powered banking experience with customizable branding, advanced budget management tools, and comprehensive financial tracking capabilities.

## Key Features

### Modern Banking
- **Real-Time Account Monitoring**: Live balance updates and transaction tracking
- **Multi-Institution Support**: Connect external accounts via Plaid integration
- **Advanced Analytics**: Spending insights and financial health tracking
- **Secure Transactions**: Biometric authentication for all sensitive operations
- **24/7 AI Support**: Get financial advice and support anytime

### AI-Powered Budget Management
- **AI-Enforced Budget Locks**: Create commitments that are locked with biometric authentication
- **Real-Time Violation Detection**: Instant alerts when you attempt to break commitments
- **Personality-Driven AI Coach**: Choose from 5 different AI coaching personalities
- **Emergency Override System**: Secure emergency spending options for genuine crises

### White-Label Platform
- **Customizable Branding**: Full control over colors, logos, and visual identity
- **Credit Union Configuration**: Per-CU settings and feature flags
- **Variable Branding System**: Dynamic theming based on CU configuration
- **Multi-Tenant Architecture**: Support multiple credit unions from a single codebase

## CU Configuration System

The platform includes a comprehensive configuration system that allows each credit union to customize their deployment:

### Configuration Options

**Branding & Identity**
- Primary and secondary brand colors
- Logo and icon customization
- Custom typography and font families
- Light and dark theme variants

**Feature Flags**
- Enable/disable specific features per CU
- Custom feature settings and limits
- A/B testing support
- Gradual feature rollouts

**Behavioral Settings**
- Default AI coaching personality
- Budget commitment difficulty levels
- Alert and notification preferences
- Security and authentication requirements

### Configuration Files

The configuration system uses environment-based settings:

```dart
// Example CU configuration structure
{
  "cu_id": "unique-cu-identifier",
  "name": "Credit Union Name",
  "branding": {
    "primary_color": "#1976D2",
    "secondary_color": "#FFC107",
    "logo_url": "https://...",
    "theme_mode": "light"
  },
  "features": {
    "ai_coaching": true,
    "budget_commitments": true,
    "external_accounts": true,
    "analytics_dashboard": true
  },
  "settings": {
    "default_ai_personality": "supportive",
    "max_commitments": 10,
    "notification_enabled": true
  }
}
```

## Variable Branding

The app supports dynamic branding that adapts to each credit union's identity:

### Theming System

**Dynamic Color Schemes**
- Runtime theme switching based on CU configuration
- Support for light and dark modes
- Accent and semantic colors
- Material Design 3 integration

**Asset Management**
- Remote logo and icon loading
- Cached branding assets
- Fallback branding for offline mode
- SVG and raster image support

**Typography**
- Custom font family support
- Configurable text styles and sizes
- Accessibility-compliant typography
- Web font loading and caching

### Implementation

```dart
// Example of using CU-specific branding
final cuConfig = await CUConfigService.loadConfig();

MaterialApp(
  theme: ThemeData(
    primaryColor: Color(int.parse(cuConfig.branding.primaryColor)),
    // ... other theme properties
  ),
  // ... app configuration
)
```

## Getting Started

### Prerequisites

- Flutter 3.0+
- Dart SDK
- iOS 12.0+ / Android API 21+
- Supabase account
- Plaid account (for external bank connections)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/cu-app.git
   cd cu-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   ```dart
   // Update lib/config/supabase_config.dart
   static const String url = 'YOUR_SUPABASE_URL';
   static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. **Set up the database**
   ```bash
   # Run the SQL schema file in your Supabase dashboard
   # File: supabase_schema.sql
   ```

5. **Configure your Credit Union**
   ```dart
   // Update lib/config/cu_config.dart
   // Add your CU-specific branding and settings
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## Architecture

### Core Services
- **AI Coaching Service**: AI-powered financial coaching and real-time monitoring
- **Budget Commitment Engine**: Locked commitment creation and enforcement
- **Banking Service**: Account management and Plaid integration
- **CU Configuration Service**: Multi-tenant configuration management
- **Branding Service**: Dynamic theme and asset management
- **Transaction Monitor**: Real-time transaction tracking

### Security Features
- **Biometric Authentication**: Face ID / Fingerprint for sensitive operations
- **Tamper-Evident Logging**: Cryptographic audit trails for all actions
- **Row-Level Security**: Database-level access control
- **End-to-End Encryption**: All sensitive data encrypted in transit and at rest

### Database Schema
```sql
-- Key tables
budget_commitments          -- Budget commitments and restrictions
commitment_violations       -- Violation tracking
commitment_audit_log        -- Tamper-evident change log
cu_configurations          -- Credit union specific settings
cu_branding                -- Branding and theme configurations
user_profiles              -- User account information
```

## Budget Commitment System

### How It Works

1. **Create a Commitment**: Choose merchant restrictions, category limits, or spending caps
2. **AI Analysis**: AI analyzes your spending patterns and suggests realistic goals
3. **Biometric Lock**: Authenticate with Face ID/Fingerprint to lock in your commitment
4. **Real-Time Monitoring**: AI watches every transaction 24/7 for violations
5. **Instant Enforcement**: Violations trigger immediate alerts

### Commitment Types

- **Merchant Restrictions**: Block spending at specific stores (Starbucks, Amazon, etc.)
- **Category Limits**: Set monthly limits for dining, entertainment, shopping
- **Amount Limits**: Cap total spending in any category or timeframe
- **Savings Goals**: Commit to saving specific amounts with spending restrictions

### Difficulty Levels

- **Easy**: Flexible enforcement, warnings before penalties
- **Medium**: Balanced approach with moderate penalties
- **Hard**: Strict enforcement, immediate penalties
- **Extreme**: Maximum penalties, commitment resets

### AI Personalities

- **Motivational**: Energetic cheerleader that celebrates wins
- **Strict**: No-nonsense trainer with tough love approach
- **Supportive**: Understanding friend that provides emotional support
- **Analytical**: Data-driven insights focused on numbers and trends
- **Humorous**: Uses comedy to make financial discipline fun

## Development

### Project Structure
```
lib/
├── screens/           # UI screens
├── services/          # Business logic and API services
├── widgets/           # Reusable UI components
├── models/           # Data models
├── config/           # Configuration files
└── utils/            # Helper utilities
```

### Key Files
- `lib/services/ai_coaching_service.dart` - AI coaching and monitoring
- `lib/services/budget_commitment_service.dart` - Commitment management
- `lib/services/cu_config_service.dart` - CU configuration management
- `lib/services/branding_service.dart` - Dynamic branding and theming
- `lib/widgets/violation_alert_widget.dart` - Real-time violation alerts
- `supabase_schema.sql` - Complete database schema

### Running Tests
```bash
flutter test
flutter test integration_test/
```

### Building for Production
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
```

## Roadmap

- [ ] **Enhanced Multi-Tenancy**: Advanced CU isolation and management
- [ ] **Advanced AI**: Machine learning for personalized insights
- [ ] **Investment Integration**: Connect investment accounts and goals
- [ ] **Merchant Partnerships**: Exclusive offers and cashback
- [ ] **Family Accounts**: Shared commitments and parental controls
- [ ] **Wearable Support**: Apple Watch and Android Wear integration
- [ ] **Admin Portal**: Web-based CU configuration dashboard

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Flutter Team** for the amazing framework
- **Supabase** for backend-as-a-service
- **Plaid** for banking API integration
- **Material Design** for UI/UX inspiration

## Support

- **Email**: support@cu.app
- **Documentation**: [docs.cu.app](https://docs.cu.app)
- **Issues**: [GitHub Issues](https://github.com/yourusername/cu-app/issues)

---

**CU Core Banking App - White-Label Credit Union Banking Platform**

*Modern banking technology for credit unions*
