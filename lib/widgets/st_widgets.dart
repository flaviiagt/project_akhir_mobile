import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

// Kartu putih bersudut 24 dengan bayangan
class StCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const StCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F2537),
            blurRadius: 24,
            offset: Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// Logo bulat dengan ikon pesawat
class StLogo extends StatelessWidget {
  final double size;
  const StLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.flight_takeoff, color: Colors.white, size: size * 0.55),
    );
  }
}

// App bar: logo + "STUDYTRIP" + judul halaman (+ lonceng & avatar seperti dashboard)
class StAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showActions;
  const StAppBar({super.key, required this.title, this.showActions = true});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final hasBack = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleSpacing: hasBack ? 0 : 20,
      title: Row(
        children: [
          const StLogo(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'STUDYTRIP',
                  style: AppText.label(size: 11, color: AppColors.brown),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.headline(18, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: showActions
          ? [
              // Lonceng hanya tampilan; Anggota 2 yang menyambungkannya (FR-26)
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.secondary,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 4, right: 16),
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ]
          : null,
    );
  }
}

/// Label section kecil huruf kapital
class StSectionLabel extends StatelessWidget {
  final String text;
  const StSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text.toUpperCase(), style: AppText.label()),
  );
}

// Tombol pil dengan indikator loading
class StButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  const StButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: outlined ? AppColors.primary : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton(onPressed: loading ? null : onPressed, child: child)
          : FilledButton(onPressed: loading ? null : onPressed, child: child),
    );
  }
}

// Bar atas halaman login/register: tombol kembali + logo kecil + "StudyTrip"
class StAuthHeader extends StatelessWidget {
  const StAuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (Navigator.of(context).canPop())
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          )
        else
          const SizedBox(width: 4),
        const StLogo(size: 28),
        const SizedBox(width: 8),
        Text('StudyTrip', style: AppText.headline(17)),
      ],
    );
  }
}

// Input dengan label huruf kapital di atas, isian abu hangat, sudut 16
class StField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const StField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  OutlineInputBorder _b(Color c, [double w = 0]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label.toUpperCase(), style: AppText.label(size: 11)),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9AA9B7)),
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.container,
            border: _b(Colors.transparent),
            enabledBorder: _b(Colors.transparent),
            focusedBorder: _b(AppColors.teal, 1.5),
            errorBorder: _b(AppColors.error, 1.5),
            focusedErrorBorder: _b(AppColors.error, 2),
          ),
        ),
      ],
    );
  }
}

// Avatar default: lingkaran abu-abu dengan siluet kepala dan bahu putih
class StDefaultAvatar extends StatelessWidget {
  final double size;
  const StDefaultAvatar({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DefaultAvatarPainter()),
    );
  }
}

class _DefaultAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF9E9E9E),
    );
    final white = Paint()..color = Colors.white;
    // kepala
    canvas.drawCircle(Offset(w * 0.5, w * 0.37), w * 0.19, white);
    // bahu
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, w * 0.94),
        width: w * 0.64,
        height: w * 0.58,
      ),
      white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
