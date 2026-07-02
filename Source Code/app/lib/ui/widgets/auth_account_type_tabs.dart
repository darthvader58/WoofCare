import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';

enum AuthAccountType { member, organization }

extension AuthAccountTypeLabel on AuthAccountType {
  String get label {
    switch (this) {
      case AuthAccountType.member:
        return 'Member';
      case AuthAccountType.organization:
        return 'Organization';
    }
  }
}

class AuthAccountTypeTabs extends StatelessWidget {
  final AuthAccountType selected;
  final ValueChanged<AuthAccountType> onChanged;

  const AuthAccountTypeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: WoofCareColors.textBoxColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WoofCareColors.borderOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children:
            AuthAccountType.values.map((type) {
              final isSelected = selected == type;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? WoofCareColors.offWhite
                              : Colors.transparent,
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          type.label,
                          style: TextStyle(
                            color: WoofCareColors.primaryTextAndIcons,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: isSelected ? 48 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: WoofCareColors.primaryTextAndIcons,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
