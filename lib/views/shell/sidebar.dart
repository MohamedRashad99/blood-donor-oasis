import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/navigation_provider.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback? onItemSelected;

  const Sidebar({super.key, this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    final menuItems = [
      _MenuItem(0, AppConstants.navTitles[0], Icons.dashboard_rounded),
      _MenuItem(1, AppConstants.navTitles[1], Icons.people_alt_rounded),
      _MenuItem(2, AppConstants.navTitles[2], Icons.person_search_rounded),
      _MenuItem(3, AppConstants.navTitles[3], Icons.campaign_rounded),
      _MenuItem(4, AppConstants.navTitles[4], Icons.history_edu_rounded),
      _MenuItem(5, AppConstants.navTitles[5], Icons.bar_chart_rounded),
      _MenuItem(6, AppConstants.navTitles[6], Icons.file_upload_rounded),
      _MenuItem(7, AppConstants.navTitles[7], Icons.settings_rounded),
    ];

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          left: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header / Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: AppColors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConstants.orgName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Text(
                        AppConstants.appTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryRedDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Navigation List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = navProvider.currentIndex == item.index;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      navProvider.setIndex(item.index);
                      onItemSelected?.call();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.redSoftBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryRed.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected ? AppColors.primaryRed : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppColors.primaryRedDark : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sidebar Footer / Supervision & Location
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppConstants.orgLocation,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, size: 12, color: AppColors.primaryRed),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppConstants.supervisor,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final int index;
  final String title;
  final IconData icon;

  const _MenuItem(this.index, this.title, this.icon);
}
