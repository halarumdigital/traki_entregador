import 'package:flutter/material.dart';

/// Ilustração customizada do entregador de moto
/// Baseada no design do Figma (roxo #8719CA)
class DeliveryIllustration extends StatelessWidget {
  final double width;
  final Color color;

  const DeliveryIllustration({
    Key? key,
    this.width = 300,
    this.color = const Color(0xff8719CA),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.7,
      child: CustomPaint(
        painter: _DeliveryPainter(color: color),
        child: Container(),
      ),
    );
  }
}

class _DeliveryPainter extends CustomPainter {
  final Color color;

  _DeliveryPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final lightPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Propor��ões baseadas no Figma
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Roda traseira
    canvas.drawCircle(
      Offset(cx - size.width * 0.25, cy + size.height * 0.15),
      size.width * 0.12,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(cx - size.width * 0.25, cy + size.height * 0.15),
      size.width * 0.06,
      paint,
    );

    // Roda dianteira
    canvas.drawCircle(
      Offset(cx + size.width * 0.28, cy + size.height * 0.15),
      size.width * 0.12,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(cx + size.width * 0.28, cy + size.height * 0.15),
      size.width * 0.06,
      paint,
    );

    // Corpo da moto
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + size.height * 0.08),
        width: size.width * 0.4,
        height: size.height * 0.15,
      ),
      Radius.circular(size.width * 0.03),
    );
    canvas.drawRRect(bodyRect, paint);

    // Assento
    final seatPath = Path();
    seatPath.moveTo(cx - size.width * 0.1, cy);
    seatPath.quadraticBezierTo(
      cx,
      cy - size.height * 0.05,
      cx + size.width * 0.1,
      cy,
    );
    seatPath.lineTo(cx + size.width * 0.08, cy + size.height * 0.05);
    seatPath.lineTo(cx - size.width * 0.08, cy + size.height * 0.05);
    seatPath.close();
    canvas.drawPath(seatPath, darkPaint);

    // Guidão
    final handlePath = Path();
    handlePath.moveTo(cx + size.width * 0.15, cy - size.height * 0.05);
    handlePath.lineTo(cx + size.width * 0.25, cy - size.height * 0.12);
    handlePath.lineTo(cx + size.width * 0.28, cy - size.height * 0.08);
    canvas.drawPath(handlePath, paint..strokeWidth = size.width * 0.02..style = PaintingStyle.stroke);

    // Entregador (cabeça)
    canvas.drawCircle(
      Offset(cx - size.width * 0.05, cy - size.height * 0.25),
      size.width * 0.08,
      darkPaint,
    );

    // Entregador (corpo)
    final bodyPersonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.05, cy - size.height * 0.05),
        width: size.width * 0.15,
        height: size.height * 0.25,
      ),
      Radius.circular(size.width * 0.02),
    );
    canvas.drawRRect(bodyPersonRect, paint);

    // Caixa de entrega (baú)
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.28, cy - size.height * 0.08),
        width: size.width * 0.2,
        height: size.height * 0.25,
      ),
      Radius.circular(size.width * 0.02),
    );
    canvas.drawRRect(boxRect, lightPaint);

    // Ícone de localização na caixa
    final locationPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cx - size.width * 0.28, cy - size.height * 0.1),
      size.width * 0.04,
      locationPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
