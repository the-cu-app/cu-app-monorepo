import 'package:flutter/material.dart';
import 'supahyper_ds.dart';
import 'pages/ds_connect_account_screen.dart';

void main() {
  runApp(const SupahyperDSApp());
}

class SupahyperDSApp extends StatelessWidget {
  const SupahyperDSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUPAHYPER Design System',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Geist',
        colorScheme: ColorScheme.fromSeed(
          seedColor: DSColors.primary,
          brightness: Brightness.light,
        ),
      ),
      home: const DSShowcase(),
    );
  }
}

class DSShowcase extends StatefulWidget {
  const DSShowcase({super.key});

  @override
  State<DSShowcase> createState() => _DSShowcaseState();
}

class _DSShowcaseState extends State<DSShowcase> {
  int _currentIndex = 0;
  bool _switchValue = false;
  
  final List<Widget> _pages = [
    const DSConnectAccountScreen(),
    const ComponentGallery(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance),
            label: 'Connect',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets),
            label: 'Components',
          ),
        ],
      ),
    );
  }
}

class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  bool _switchValue = false;
  final TextEditingController _inputController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.background,
      appBar: AppBar(
        backgroundColor: DSColors.surface,
        title: const DSText(
          'Component Gallery',
          variant: DSTextVariant.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        padding: DSSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Typography', _buildTypography()),
            _buildSection('Buttons', _buildButtons()),
            _buildSection('Inputs', _buildInputs()),
            _buildSection('Chips', _buildChips()),
            _buildSection('Badges', _buildBadges()),
            _buildSection('Avatars', _buildAvatars()),
            _buildSection('Loaders', _buildLoaders()),
            _buildSection('Switches', _buildSwitches()),
            _buildSection('Icons', _buildIcons()),
            const SizedBox(height: DSSpacing.space20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(
          title,
          variant: DSTextVariant.titleLarge,
          fontWeight: DSTypography.weightBold,
        ),
        const SizedBox(height: DSSpacing.space4),
        content,
        const DSDivider(thickness: 1),
        const SizedBox(height: DSSpacing.space8),
      ],
    );
  }
  
  Widget _buildTypography() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DSText('Display Large', variant: DSTextVariant.displayLarge),
        const DSText('Headline Medium', variant: DSTextVariant.headlineMedium),
        const DSText('Title Medium', variant: DSTextVariant.titleMedium),
        const DSText('Body Large', variant: DSTextVariant.bodyLarge),
        const DSText('Label Small', variant: DSTextVariant.labelSmall),
        DSText.mono('Mono: \$1,234.56'),
      ],
    );
  }
  
  Widget _buildButtons() {
    return Wrap(
      spacing: DSSpacing.space3,
      runSpacing: DSSpacing.space3,
      children: [
        DSButton(
          label: 'Primary',
          onPressed: () {},
          variant: DSButtonVariant.primary,
        ),
        DSButton(
          label: 'Secondary',
          onPressed: () {},
          variant: DSButtonVariant.secondary,
        ),
        DSButton(
          label: 'Success',
          onPressed: () {},
          variant: DSButtonVariant.success,
          leadingIcon: Icons.check,
        ),
        DSButton(
          label: 'Danger',
          onPressed: () {},
          variant: DSButtonVariant.danger,
          trailingIcon: Icons.warning,
        ),
        DSButton(
          label: 'Loading',
          onPressed: () {},
          isLoading: true,
        ),
        DSButton(
          label: 'Disabled',
          onPressed: null,
        ),
      ],
    );
  }
  
  Widget _buildInputs() {
    return Column(
      children: [
        DSInput(
          label: 'Email',
          placeholder: 'Enter your email',
          controller: _inputController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: DSSpacing.space4),
        DSInput(
          label: 'Password',
          placeholder: 'Enter your password',
          obscureText: true,
          helperText: 'Must be at least 8 characters',
        ),
        const SizedBox(height: DSSpacing.space4),
        DSInput(
          label: 'Error State',
          placeholder: 'Invalid input',
          errorText: 'This field is required',
        ),
      ],
    );
  }
  
  Widget _buildChips() {
    return Wrap(
      spacing: DSSpacing.space2,
      runSpacing: DSSpacing.space2,
      children: [
        DSChip(
          label: 'Default',
          onTap: () {},
        ),
        DSChip(
          label: 'Selected',
          selected: true,
          onTap: () {},
        ),
        DSChip(
          label: 'With Icon',
          leadingIcon: Icons.star,
          onTap: () {},
        ),
        DSChip(
          label: 'Deletable',
          onDelete: () {},
        ),
        const DSChip(
          label: 'Disabled',
          enabled: false,
        ),
      ],
    );
  }
  
  Widget _buildBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        DSBadge(
          count: 3,
          child: DSIcon(Icons.notifications, size: DSIconSize.lg),
        ),
        DSBadge(
          count: 99,
          variant: DSBadgeVariant.error,
          child: DSIcon(Icons.mail, size: DSIconSize.lg),
        ),
        DSBadge(
          count: 150,
          variant: DSBadgeVariant.success,
          child: DSIcon(Icons.shopping_cart, size: DSIconSize.lg),
        ),
        DSBadge(
          showDot: true,
          variant: DSBadgeVariant.warning,
          child: DSIcon(Icons.person, size: DSIconSize.lg),
        ),
      ],
    );
  }
  
  Widget _buildAvatars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        DSAvatar(
          size: DSAvatarSize.xs,
          name: 'XS',
        ),
        DSAvatar(
          size: DSAvatarSize.sm,
          name: 'Small',
        ),
        DSAvatar(
          size: DSAvatarSize.md,
          name: 'Medium',
        ),
        DSAvatar(
          size: DSAvatarSize.lg,
          icon: Icons.person,
        ),
        DSAvatar(
          size: DSAvatarSize.xl,
          name: 'John Doe',
          backgroundColor: DSColors.success,
        ),
      ],
    );
  }
  
  Widget _buildLoaders() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        DSLoader(
          type: DSLoaderType.circular,
          size: DSLoaderSize.small,
        ),
        DSLoader(
          type: DSLoaderType.circular,
          size: DSLoaderSize.medium,
        ),
        DSLoader(
          type: DSLoaderType.dots,
          size: DSLoaderSize.medium,
        ),
        DSLoader(
          type: DSLoaderType.linear,
          size: DSLoaderSize.medium,
        ),
      ],
    );
  }
  
  Widget _buildSwitches() {
    return Column(
      children: [
        DSSwitch(
          value: _switchValue,
          onChanged: (value) => setState(() => _switchValue = value),
          label: 'Enable notifications',
          description: 'Get updates about your account',
        ),
        const SizedBox(height: DSSpacing.space4),
        DSSwitch(
          value: !_switchValue,
          onChanged: (value) => setState(() => _switchValue = !value),
        ),
      ],
    );
  }
  
  Widget _buildIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        DSIcon(Icons.home, size: DSIconSize.xs),
        DSIcon(Icons.search, size: DSIconSize.sm),
        DSIcon(Icons.favorite, size: DSIconSize.md, color: DSColors.error),
        DSIcon(Icons.settings, size: DSIconSize.lg),
        DSIcon(Icons.star, size: DSIconSize.xl, color: DSColors.warning),
      ],
    );
  }
  
  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}