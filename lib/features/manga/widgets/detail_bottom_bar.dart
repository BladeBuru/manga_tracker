import 'package:flutter/material.dart';
import '../../manga/dto/reading_status.enum.dart';

class DetailBottomBar extends StatelessWidget {
  final ReadingStatus? status;
  final bool hasCustomLink;
  final VoidCallback onAddToLibrary;
  final VoidCallback onManageStatus;
  final VoidCallback onAddLink;
  final VoidCallback onReadOnline;
  final VoidCallback onOpenLinkMenu; // "..." à droite
  final VoidCallback onShowRecommendations;

  const DetailBottomBar({
    super.key,
    required this.status,
    required this.hasCustomLink,
    required this.onAddToLibrary,
    required this.onManageStatus,
    required this.onAddLink,
    required this.onReadOnline,
    required this.onOpenLinkMenu,
    required this.onShowRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));
    ButtonStyle primary() => ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      shape: shape,
      textStyle: const TextStyle(fontSize: 17),
    );

    Widget recoBtn() => SizedBox(
      width: 52,
      height: double.infinity,
      child: Tooltip(
        message: 'Recommandations',
        child: ElevatedButton(
          style: primary().copyWith(
            padding: const MaterialStatePropertyAll(EdgeInsets.zero),
            elevation: const MaterialStatePropertyAll(0),
            minimumSize: const MaterialStatePropertyAll(Size.zero),
          ),
          onPressed: onShowRecommendations,
          child: const Icon(Icons.auto_awesome, size: 22),
        ),
      ),
    );

    // Pas encore dans la bibliothèque
    if (status == null) {
      return _bar(context, [
        Expanded(
          child: SizedBox(
            height: double.infinity,
            child: ElevatedButton.icon(
              style: primary(),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Ajouter à "À lire plus tard"'),
              onPressed: onAddToLibrary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        recoBtn(),
      ]);
    }

    // Dans la bibliothèque
    final leftButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: status!.color.withAlpha(50),
        foregroundColor: status!.color,
        elevation: 0,
        shape: shape,
      ),
      onPressed: onManageStatus,
      child: Icon(status!.icon),
    );

    final rightButton = hasCustomLink
        ? SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: ElevatedButton.icon(
              style: primary(),
              onPressed: onReadOnline,
              icon: const Icon(Icons.link),
              label: const Padding(
                padding: EdgeInsets.only(right: 24),
                child: Text('Lire en ligne', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 8,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                color: Theme.of(context).colorScheme.onPrimary,
                onPressed: onOpenLinkMenu,
                tooltip: 'Gérer le lien',
              ),
            ),
          ),
        ],
      ),
    )
        : ElevatedButton.icon(
      style: primary(),
      onPressed: onAddLink,
      icon: const Icon(Icons.link_off),
      label: const Text('Ajouter un lien', style: TextStyle(fontSize: 17)),
    );

    return _bar(context, [
      Flexible(flex: 3, child: SizedBox(height: double.infinity, child: leftButton)),
      const SizedBox(width: 15),
      Flexible(flex: 5, child: SizedBox(height: double.infinity, child: rightButton)),
      const SizedBox(width: 12),
      recoBtn(),
    ]);
  }

  Widget _bar(BuildContext context, List<Widget> children) => Container(
    height: 70,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
    child: Row(children: children),
  );
}
