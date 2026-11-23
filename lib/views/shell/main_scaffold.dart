import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../providers/navigation_provider.dart';
import 'sidebar.dart';
import 'top_bar.dart';

// Sections
import '../dashboard/dashboard_view.dart';
import '../donors/donors_view.dart';
import '../search/donor_search_view.dart';
import '../campaigns/campaigns_view.dart';
import '../donation_history/donation_history_view.dart';
import '../reports/reports_view.dart';
import '../import/import_view.dart';
import '../settings/settings_view.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final pages = [
      const DashboardView(),
      const DonorsView(),
      const DonorSearchView(),
      const CampaignsView(),
      const DonationHistoryView(),
      const ReportsView(),
      const ImportView(),
      const SettingsView(),
    ];

    final currentPage = navProvider.currentIndex < pages.length
        ? pages[navProvider.currentIndex]
        : pages[0];

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop
          ? null
          : Drawer(
              child: SafeArea(
                child: Sidebar(
                  onItemSelected: () {
                    _scaffoldKey.currentState?.closeDrawer();
                  },
                ),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            // Desktop Fixed Sidebar
            if (isDesktop) const Sidebar(),

            // Main View Area
            Expanded(
              child: Column(
                children: [
                  TopBar(
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  Expanded(
                    child: Container(
                      color: AppColors.bgSurface,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(isDesktop ? 20 : 12),
                              child: currentPage,
                            ),
                          ),
                          // Global Footer
                          _buildFooter(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                size: 14,
                color: AppColors.primaryRed,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${AppConstants.orgName} • ${AppConstants.slogan}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            AppConstants.supervisor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
