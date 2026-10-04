import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../widgets/app_widgets.dart';

/// Debug-only gallery. Sample data and interactions never touch app storage.
class DesignSystemPreview extends StatefulWidget {
  const DesignSystemPreview({super.key});
  @override
  State<DesignSystemPreview> createState() => _DesignSystemPreviewState();
}

class _DesignSystemPreviewState extends State<DesignSystemPreview> {
  final _form = GlobalKey<FormState>();
  bool _blur = true;
  bool _busy = false;
  String _garment = 'Kurta';
  String _fit = 'Formal fit';
  DateTime? _date;
  int _tab = 0;

  Future<void> _simulateSave() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preview saved')));
    }
  }

  Widget _page(List<Widget> children) => ListView.separated(
    padding: const EdgeInsets.all(AppSpacing.screenPadding),
    itemCount: children.length,
    itemBuilder: (_, index) => children[index],
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
  );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 6,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Design system'),
        actions: [
          AppIconButton(
            icon: Icons.close,
            label: 'Close preview',
            onPressed: () => context.go('/home'),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Buttons'),
            Tab(text: 'Fields'),
            Tab(text: 'Surfaces'),
            Tab(text: 'Selection'),
            Tab(text: 'Feedback'),
            Tab(text: 'Navigation'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _page([
            const AppSectionLabel('Actions'),
            AppButton(
              label: 'Save customer',
              icon: Icons.add,
              onPressed: () {},
            ),
            AppButton(
              label: 'Secondary action',
              variant: AppButtonVariant.outlined,
              onPressed: () {},
            ),
            AppButton(
              label: 'Selected action',
              variant: AppButtonVariant.olive,
              onPressed: () {},
            ),
            AppButton(
              label: 'Delete customer',
              variant: AppButtonVariant.destructive,
              onPressed: _showConfirmation,
            ),
            const AppButton(label: 'Disabled action', onPressed: null),
            AppButton(
              label: 'Save preview',
              isLoading: _busy,
              onPressed: _simulateSave,
            ),
            AppButton(
              label: 'Text action',
              variant: AppButtonVariant.text,
              onPressed: () {},
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: AppIconButton(
                icon: Icons.edit_outlined,
                label: 'Edit preview',
                onPressed: () {},
              ),
            ),
          ]),
          _page([
            const AppSectionLabel('Persistent labels & validation'),
            Form(
              key: _form,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Full name',
                    hint: 'Enter customer name',
                    helper: 'Use the name your customer prefers.',
                    textInputAction: TextInputAction.next,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a customer name'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppTextField(
                    label: 'Phone number',
                    kind: AppFieldKind.phone,
                    hint: '0300 412 8876',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppTextField(
                    label: 'Total price',
                    kind: AppFieldKind.amount,
                    hint: '0',
                    errorText: 'Enter a price greater than zero',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppTextField(
                    label: 'Search customers',
                    kind: AppFieldKind.search,
                    hint: 'Name or phone',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppTextField(
                    label: 'Unavailable field',
                    hint: 'Disabled',
                    enabled: false,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppDateField(
                    label: 'Delivery date',
                    value: _date,
                    onChanged: (date) => setState(() => _date = date),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Validate form',
                    onPressed: () => _form.currentState!.validate(),
                  ),
                ],
              ),
            ),
          ]),
          _page([
            const AppSectionLabel('Cards'),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faisal Shah', style: AppTypography.body),
                  SizedBox(height: AppSpacing.sm),
                  Text('Shalwar Kameez · 2 pieces'),
                  AppSeparator(),
                  AppMoneyText(2800),
                ],
              ),
            ),
            const AppCard(
              variant: AppCardVariant.selected,
              child: Text('Selected card'),
            ),
            const AppCard(
              variant: AppCardVariant.carbon,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIS MONTH'),
                  SizedBox(height: AppSpacing.sm),
                  AppMoneyText(184500, large: true),
                ],
              ),
            ),
            SwitchListTile.adaptive(
              title: const Text('Glass blur'),
              subtitle: const Text('Turn off to inspect solid fallbacks.'),
              value: _blur,
              onChanged: (value) => setState(() => _blur = value),
            ),
            AppCard(
              variant: AppCardVariant.carbon,
              child: Column(
                children: [
                  GlassSurface(
                    tone: GlassTone.dark,
                    blurEnabled: _blur,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('GLASS ON CARBON'),
                        SizedBox(height: AppSpacing.sm),
                        AppMoneyText(46200),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassSurface(
                    blurEnabled: _blur,
                    child: const Text(
                      'Glass on white',
                      style: AppTypography.title,
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Open editing sheet',
              variant: AppButtonVariant.outlined,
              onPressed: _showSheet,
            ),
          ]),
          _page([
            const AppSectionLabel('Garment selection'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ['Shalwar Kameez', 'Kurta', 'Waistcoat']
                  .map(
                    (garment) => AppSelectionChip(
                      label: garment,
                      selected: _garment == garment,
                      onPressed: () => setState(() => _garment = garment),
                    ),
                  )
                  .toList(),
            ),
            AppSegmentedControl<String>(
              options: const [
                AppSelectionOption(value: 'Formal fit', label: 'Formal fit'),
                AppSelectionOption(value: 'Casual fit', label: 'Casual fit'),
              ],
              selected: _fit,
              onChanged: (fit) => setState(() => _fit = fit),
            ),
            const AppSectionLabel('Production & payment badges'),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusBadge(label: 'Received'),
                AppStatusBadge(label: 'Cutting', tone: AppBadgeTone.olive),
                AppStatusBadge(label: 'Stitching', tone: AppBadgeTone.olive),
                AppStatusBadge(
                  label: 'Ready',
                  icon: Icons.check,
                  tone: AppBadgeTone.strong,
                ),
                AppStatusBadge(label: 'Delivered', tone: AppBadgeTone.muted),
                AppStatusBadge(
                  label: 'Paid in full',
                  icon: Icons.check_circle_outline,
                ),
                AppStatusBadge(
                  label: 'Overdue 2 days',
                  icon: Icons.schedule,
                  tone: AppBadgeTone.strong,
                ),
              ],
            ),
          ]),
          _page([
            AppCard(
              child: AppFeedback(
                title: 'No customers yet',
                message: 'Add your first customer to get started.',
                actionLabel: 'Add customer',
                onAction: () {},
              ),
            ),
            AppCard(
              child: AppFeedback.error(
                message: 'Your changes could not be saved.',
                actionLabel: 'Retry',
                onAction: _simulateSave,
              ),
            ),
            const AppCard(child: AppLoading()),
            AppButton(label: 'Show confirmation', onPressed: _showConfirmation),
          ]),
          _page([
            const Text('Floating navigation', style: AppTypography.title),
            const Text(
              'Select a tab to inspect its active state. This sample stays in the preview.',
            ),
            AppBottomNavigation(
              selectedIndex: _tab,
              blurEnabled: _blur,
              onSelected: (index) => setState(() => _tab = index),
              items: const [
                AppNavigationItem(label: 'Home', icon: Icons.home_outlined),
                AppNavigationItem(
                  label: 'Customers',
                  icon: Icons.person_outline,
                ),
                AppNavigationItem(
                  label: 'Orders',
                  icon: Icons.receipt_long_outlined,
                ),
                AppNavigationItem(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                ),
              ],
            ),
            const Text(
              'The app reserves space beneath lists and hides global navigation on detail and entry screens.',
            ),
          ]),
        ],
      ),
    ),
  );

  void _showConfirmation() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this sample?'),
      content: const Text('This preview does not contain customer records.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Delete sample',
          expand: false,
          variant: AppButtonVariant.destructive,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );

  void _showSheet() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xl,
        AppSpacing.screenPadding,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Edit measurement', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xl),
          const AppTextField(
            label: 'Chest (inches)',
            hint: '40.5',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Save sample',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}
