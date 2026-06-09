import 'package:flutter/material.dart';

enum AppDestination { today, archive, recap, profile }

extension AppDestinationPresentation on AppDestination {
  String get label => switch (this) {
    AppDestination.today => 'Today',
    AppDestination.archive => 'Archive',
    AppDestination.recap => 'Recap',
    AppDestination.profile => 'Profile',
  };

  IconData get icon => switch (this) {
    AppDestination.today => Icons.home_outlined,
    AppDestination.archive => Icons.bookmarks_outlined,
    AppDestination.recap => Icons.auto_awesome_outlined,
    AppDestination.profile => Icons.account_circle_outlined,
  };
}
