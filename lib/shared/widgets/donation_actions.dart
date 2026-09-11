import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/donation_links.dart';
import '../../core/localization/app_localizations.dart';

class DonationActions extends StatelessWidget {
  final bool compact;

  const DonationActions({super.key, this.compact = false});

  static Future<void> showSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: DonationActions(),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('donation_link_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paypal = OutlinedButton.icon(
      onPressed: () => _open(context, DonationLinks.paypal),
      icon: const FaIcon(FontAwesomeIcons.paypal, size: 16),
      label: Text(context.tr('support_paypal')),
    );
    final coffee = OutlinedButton.icon(
      onPressed: () => _open(context, DonationLinks.buyMeACoffee),
      icon: const FaIcon(FontAwesomeIcons.mugHot, size: 16),
      label: Text(context.tr('buy_me_a_coffee')),
    );

    return compact
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _open(context, DonationLinks.paypal),
                icon: const FaIcon(FontAwesomeIcons.paypal, size: 17),
                tooltip: context.tr('support_paypal'),
              ),
              IconButton(
                onPressed: () => _open(context, DonationLinks.buyMeACoffee),
                icon: const FaIcon(FontAwesomeIcons.mugHot, size: 17),
                tooltip: context.tr('buy_me_a_coffee'),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [paypal, const SizedBox(height: 10), coffee],
          );
  }
}
